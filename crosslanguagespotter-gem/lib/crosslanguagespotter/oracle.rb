require 'codemodels'
require 'codemodels/js'
require 'codemodels/html'
require 'csv'
require 'crosslanguagespotter/model_loading'
#require 'console'
#require 'code_processing'

include CodeModels

module CrossLanguageSpotter

OracleRelationEnd = Struct.new :file, :line, :col, :surface_form
MetaOracleRelationEnd = Struct.new :file, :index

class OracleLoader

    def build_weka_classifier(srcpath,oraclepath)        
        features_data = to_train_data(srcpath,oraclepath)
        data = []
        features_data.each do |rel,row|
            data.push(row)
        end
        keys = {    shared_length: :numeric,
                    tfidf_shared: :numeric,
                    itfidf_shared: :numeric,
                    perc_shared_length_min: :numeric,
                    perc_shared_length_max: :numeric,
                    diff_min: :numeric,
                    diff_max: :numeric,
                    perc_diff_min: :numeric,
                    perc_diff_max: :numeric,
                    context: :numeric,
                    jaccard: :numeric,
                    jaro: :numeric,
                    tversky: :numeric,
                    result: :boolean}
        train_instances = hash2weka_instances("oracle",data,keys,:result)
        WekaClassifier.new(train_instances)
    end

    def to_train_data(srcpath,oraclepath)
        project = Project.new(srcpath)

        spotter = Spotter.new
        features = spotter.features_for_project(project)

        @file_lines = Hash.new do |h,k|
            h[k] = File.readlines(k)
        end

        ok_a = ok_b = ko_a = ko_b = 0
         
        train_data = {}
        File.open(oraclepath,'r').each_with_index do |input_line,l|  
            input_line.strip!
            unless input_line.start_with?('#')
                values = input_line.split ":"
                if values.count!=8
                    raise "Line #{l+1}, error: #{input_line}. Values: #{values}"
                end
                # we order them to facilitate searching for duplicates
                end_a = OracleRelationEnd.new values[0], values[1].to_i, values[2].to_i, values[3]
                end_b = OracleRelationEnd.new values[4], values[5].to_i, values[6].to_i, values[7]
                if end_b.file < end_a.file
                    end_a, end_b = end_b, end_a
                end

                file_a         = values[0]
                line_a         = values[1].to_i
                col_a          = values[2].to_i
                surface_form_a = values[3]
                file_b         = values[4]
                line_b         = values[5].to_i
                col_b          = values[6].to_i         
                surface_form_b = values[7]
                #if values[8]=='t'
                #    result = true
                #elsif values[8]=='f'
                #    result = false
                #else
                #    raise "Exptected true or false"
                #end

                #if oracle_values.values.include?([end_a,end_b])
                #    raise "Line #{l+1} is a duplicate of line #{oracle_values.find {|k,v| v==[end_a,end_b]}}"
                #else
                #    oracle_values[l] = [end_a,end_b]
                #end             

                file_a = "#{srcpath}/#{file_a}"
                file_b = "#{srcpath}/#{file_b}"

                model_a = project.models[file_a]
                model_b = project.models[file_b]

                raise "Model not found for #{file_a}. Available: #{project.models.keys}" unless model_a                    
                raise "Model not found for #{file_b}. Available: #{project.models.keys}" unless model_b

                plain_col_a = convert_from_tabcolumn_to_plaincolumn(file_a,line_a,col_a)
                plain_col_b = convert_from_tabcolumn_to_plaincolumn(file_b,line_b,col_b)

                pos_a = SourcePosition.new(SourcePoint.new(line_a,plain_col_a),SourcePoint.new(line_a,plain_col_a+surface_form_a.length-1))
                pos_b = SourcePosition.new(SourcePoint.new(line_b,plain_col_b),SourcePoint.new(line_b,plain_col_b+surface_form_b.length-1))
                begin
                    node_a = find_node(model_a,surface_form_a,pos_a)
                    ok_a+=1
                rescue Exception => e
                    ko_a+=1
                    puts "Line #{l+1}) problem with '#{surface_form_a}', file: #{file_a}, pos #{pos_a}: #{e}"
                end
                begin
                    node_b = find_node(model_b,surface_form_b,pos_b)
                    ok_b+=1
                rescue Exception => e
                    ko_b+=1
                    puts "Line #{l+1}) problem with '#{surface_form_b}', file: #{file_b}, pos #{pos_b}: #{e}"
                end

                if node_a and node_b
                    trindex_a = traverse_index(node_a)
                    trindex_b = traverse_index(node_b)

                    metaoracle_end_a = MetaOracleRelationEnd.new file_a,trindex_a
                    metaoracle_end_b = MetaOracleRelationEnd.new file_b,trindex_b
                    if metaoracle_end_b.file < metaoracle_end_a.file
                        metaoracle_end_a, metaoracle_end_b = metaoracle_end_b, metaoracle_end_a
                    end
                    #if metaoracle_values.values.include?([metaoracle_end_a,metaoracle_end_b])
                    #    raise "Line #{l+1} (#{[metaoracle_end_a,metaoracle_end_b]}) is a duplicate of line #{metaoracle_values.find {|k,v| v==[metaoracle_end_a,metaoracle_end_b]}}"
                    #else
                    #    metaoracle_values[l+1] = [metaoracle_end_a,metaoracle_end_b]
                    #end 

                    id_a = NodeId.from_node(node_a)
                    id_b = NodeId.from_node(node_b)
                    rel = CrossLanguageRelation.new([id_a,id_b])
                    f = features[rel]
                    raise "Unknown features for #{rel} (a:#{node_a.source.artifact(:absolute).filename} L#{node_a.source.position(:absolute).begin_line},b:#{node_b.source.artifact(:absolute).filename} L#{node_b.source.position(:absolute).begin_line})" unless f
                    entry = { result: true }
                    f.each do |k,v|
                        entry[k] = v
                    end
                    train_data[rel] = entry
                end
            end        
        end

        # all the others are implicitly negative examples
        project.iter_over_shared_ids_instances do |node_a,node_b| 
            id_a = NodeId.from_node(node_a)
            id_b = NodeId.from_node(node_b)
            rel = CrossLanguageRelation.new([id_a,id_b])
            unless train_data.has_key?(rel)
                f = features[rel]
                entry = { result: false }
                f.each do |k,v|
                    entry[k] = v
                end
                train_data[rel] = entry
            end
        end

        pos = 0
        neg = 0
        train_data.each do |k,v|
            if v[:result]
                pos+=1
                #puts v
            else
                neg+=1
            end
        end
        return train_data
    end

    private

    def candidates_included_in_all_the_others(candidates_in_correct_position)
        candidates_in_correct_position.each do |small|
            ok = true
            candidates_in_correct_position.each do |big|
                if small!=big
                    unless big.source.position.include?(small.source.position)
                        ok = false
                    end
                end
            end
            return small if ok
        end
        nil
    end

    def verbose_msg(msg)
    end

    def find_node(model,surface_form,position)
        verbose_msg "Looking for '#{surface_form}'"
        candidates_in_correct_position = []
        candidates_in_other_positions = []
        max_embedding_level = -1
        model.traverse(:also_foreign) do |n|
            if n.collect_values_with_count.has_key?(surface_form)
                if n.source.position(:absolute).include?(position)
                    if n.source.embedding_level>=max_embedding_level
                        if n.source.embedding_level>max_embedding_level
                            candidates_in_correct_position.clear
                        end
                        max_embedding_level = n.source.embedding_level
                        candidates_in_correct_position << n
                    end
                else
                    candidates_in_other_positions << n
                end
            end
        end
        if candidates_in_correct_position.count!=1
            smallest_candidate = candidates_included_in_all_the_others(candidates_in_correct_position)
            unless smallest_candidate
                puts "I did not find exactly once '#{surface_form}' at #{position}. I found it there #{candidates_in_correct_position.count} times (found elsewhere #{candidates_in_other_positions.count} times)"


                candidates_in_other_positions.each do |wp|
                    puts " * #{wp.source.position(:absolute)}"
                end
                puts "Candidate in corresponding position:"
                candidates_in_correct_position.each do |c|
                    puts " * #{c} (embedded? #{c.source.embedded?})"
                end
                raise "Candidates found in #{position} are #{candidates_in_correct_position.count}"
            else
                puts "More than one candidate, I pick up the smallest"
                return smallest_candidate
            end
        end
        candidates_in_correct_position[0]
    end

    # the given column is calculated counting 4 for each tab,
    # while the output count just 1 also per tab
    def convert_from_tabcolumn_to_plaincolumn(file,line_index,tabcol)
        line = @file_lines[file][line_index-1]
        tabcol_to_plaincol(line,tabcol)
    end

    def tabcol_to_plaincol(line,tabcol)
        c   = 0
        i   = 0
        while c<tabcol
            c+=((line[i]=="\t") ? 4 : 1)
            i+=1
        end
        raise "error" unless c==tabcol
        i
    end

end

end