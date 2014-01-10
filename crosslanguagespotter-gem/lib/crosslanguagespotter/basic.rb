# encoding: utf-8

require "codemodels"
require "codemodels/html"
require "codemodels/js"

require 'crosslanguagespotter/figures_evaluator'
require 'crosslanguagespotter/methods/context'
require 'crosslanguagespotter/methods/tversky'
require 'crosslanguagespotter/methods/jaro'
require 'crosslanguagespotter/model_loading'
require 'csv'
require 'set'
require 'crosslanguagespotter/jaccard'

module CrossLanguageSpotter

    def self._load_models(dir,base_path='',models={})
        Dir.foreach(dir) do |f| 
            if f!='.' and f!='..'
                path = dir+'/'+f
                if File.directory?(path)
                    _load_models(path,base_path+'/'+dir,models)
                else
                    begin
                        models[base_path+'/'+f] = CodeModels.parse_file(path)
                    rescue Exception => e
                        puts "No model available for #{path}: #{e}"
                    end
                end
            end
        end
        return models
    end
  
    class Spotter

        def initialize
            @verbose = false
        end

        def find_relations(dir)
            models = CrossLanguageSpotter._load_models(dir)
            _calc(dir,models)
        end

        def features_for_dir(dir)
            project = Project.new(dir,@verbose)
            return features_for_project(project)
        end

        def classify_relations(project,classifier)
            features_data = features_for_project(project)
            data = []
            list_of_original_features_rows = []
            features_data.each do |rel,row|
                row[:result] = false
                data.push(row)
                list_of_original_features_rows.push(row)
            end
            keys = {shared_length: :numeric,
                tfidf_shared: :numeric,itfidf_shared: :numeric,
                perc_shared_length_min: :numeric,
                perc_shared_length_max: :numeric,
                diff_min: :numeric,diff_max: :numeric,
                perc_diff_min: :numeric,perc_diff_max: :numeric,
                context: :numeric,jaccard: :numeric,jaro: :numeric,tversky: :numeric,
                result: :boolean}
            data_instances = hash2weka_instances("data",data,keys,:result)
            classifier.classify(data_instances)
            i=0
            results = []
            data_instances.enumerate_instances.each do |instance|
                result = instance.value(instance.class_attribute)
                if result>0
                    results.push(list_of_original_features_rows[i])
                end
                i+=1
            end
            return results
        end

        def features_for_project(project)
            results = {}
            tversky_producer = TverskyReferencesProducer.new  ({:alpha => 0.5, :threshold => 0.0})
            context_producer  = ContextReferencesProducer.new ({:alpha => 1.0, :threshold => 0.0})
            context_points_map = context_producer.points_map(project)
            jaro_producer = JaroReferencesProducer.new ({:winkleradjust=>false,:threshold=>0.0})
            block = Proc.new do |ni,nj|
                context_ni = context(ni).values & project.shared_ids
                context_nj = context(nj).values & project.shared_ids 
                shared_length = (context_ni & context_nj).count
                
                file_i = ni.source.artifact(:absolute).filename
                file_j = ni.source.artifact(:absolute).filename
                tfidf_shared = 0
                itfidf_shared = 0
                (context_ni & context_nj).each do |v|
                    tfidf_shared += project.tf_idf(file_i,v)+project.tf_idf(file_j,v)
                    itfidf_shared += project.itf_idf(file_i,v)+project.itf_idf(file_j,v)
                end

                perc_shared_length_i = context_ni.count==0 ? 0.0 : shared_length.to_f/context_ni.count.to_f
                perc_shared_length_j = context_nj.count==0 ? 0.0 : shared_length.to_f/context_nj.count.to_f
                perc_shared_length   = [perc_shared_length_i,perc_shared_length_j]
                perc_shared_length_min = (perc_shared_length[0]<perc_shared_length[1]) ? perc_shared_length[0] : perc_shared_length[1]
                perc_shared_length_max = (perc_shared_length[0]<perc_shared_length[1]) ? perc_shared_length[1] : perc_shared_length[0]
                diffs = [context_ni.count-shared_length,context_nj.count-shared_length]
                diff_min = diffs.min
                diff_max = diffs.max
                perc_diff_i = context_ni.count==0 ? 0.0 : diffs[0].to_f/context_ni.count.to_f
                perc_diff_j = context_nj.count==0 ? 0.0 : diffs[1].to_f/context_nj.count.to_f
                perc_diffs = [perc_diff_i,perc_diff_j]
                perc_diff_min = (perc_diffs[0]<perc_diffs[1]) ? perc_diffs[0] : perc_diffs[1]
                perc_diff_max = (perc_diffs[0]<perc_diffs[1]) ? perc_diffs[1] : perc_diffs[0]
                id_i = NodeId.from_node(ni)
                id_j = NodeId.from_node(nj)
                rel = CrossLanguageRelation.new([id_i,id_j])

                jaccard = Jaccard.coefficient(context_ni,context_nj)
                jaccard = 0.0 if jaccard.nan?
                tversky = tversky_producer.tversky_coefficient(context_ni,context_nj)
                tversky = 0.0 if tversky.nan?
                context = context_points_map.points(Pair.new(ni,nj))
                jaro    = jaro_producer.jaro_coefficient_from_nodes(ni,nj)
                jaro    = 0.0 if jaro.nan?

                results[rel] = {
                    node_a_file:         ni.source.artifact(:absolute).filename,
                    node_a_begin_line:   ni.source.position(:absolute).begin_line,
                    node_a_end_line:     ni.source.position(:absolute).end_line,
                    node_a_begin_column: ni.source.position(:absolute).begin_column,
                    node_a_end_column:   ni.source.position(:absolute).end_column,

                    node_b_file:         nj.source.artifact(:absolute).filename,
                    node_b_begin_line:   nj.source.position(:absolute).begin_line,
                    node_b_end_line:     nj.source.position(:absolute).end_line,
                    node_b_begin_column: nj.source.position(:absolute).begin_column,
                    node_b_end_column:   nj.source.position(:absolute).end_column,

                    shared_length:shared_length,
                    tfidf_shared:tfidf_shared,itfidf_shared:itfidf_shared,
                    perc_shared_length_min:perc_shared_length_min,
                    perc_shared_length_max:perc_shared_length_max,
                    diff_min:diff_min,diff_max:diff_max,
                    perc_diff_min:perc_diff_min,perc_diff_max:perc_diff_max,
                    context:context,jaccard:jaccard,jaro:jaro,tversky:tversky}
            end     
            project.iter_over_shared_ids_instances {|ni,nj| block.call(ni,nj) }   
            return results
        end

    end

end