require "codemodels"
require "codemodels/html"
require "codemodels/js"
require "crosslanguagespotter/context"

module CrossLanguageSpotter

AngularParser = CodeModels::Html::AngularJs.parser_considering_angular_embedded_code


def traverse_index(node)
    root = node.root(:also_foreign)
    i = 1
    root.traverse(:also_foreign) do |n|
        return i if (n==node) && (n.source.position(:absolute)==node.source.position(:absolute))
        i+=1
    end
    raise "Error..."
end

def node_at_traverse_index(root,index)
    i = 1
    root.traverse(:also_foreign) do |n|
        return n if (i==index)
        i+=1
    end
    raise "Error... traverse_index: #{index}. Reached #{i}"
end


def offset_referred_to_host(node)
    base = node.eContainer ? offset_referred_to_host(node.eContainer) : 0
    if node.eContainingFeature && node.eContainingFeature==:foreign_asts
        base+node.eContainer.source.begin_pos.line-1
    else
        base
    end
end

def line_referred_to_host(node,line)
    offset_referred_to_host(node)+line
end

def host_lines(node)
    [line_referred_to_host(node,node.source.begin_line),
        line_referred_to_host(node,node.source.end_line)]
end

def is_in_line?(node,line)
    line>=line_referred_to_host(node,node.source.begin_pos.line) && line<=line_referred_to_host(node,node.source.end_pos.line)  
end

class ModelLoader

    def initialize
        @models = Hash.new do |h,k|
            h[k] = load_model(k)
        end
    end

    def model(path)
        @models[path]
    end

private

    def load_model(relpath)
        complete_path =relpath
        raise "Unexisting file #{complete_path}" unless File.exist?(complete_path)
        if relpath.end_with?'.html'
            model = AngularParser.parse_file(complete_path)
        elsif relpath.end_with?'.js'
            model = CodeModels.parse_file(complete_path)
        else
            raise "I don't know what to do with: #{complete_path}"
        end
    end

end

class SequentialAst

    attr_reader :node
    attr_reader :value
    attr_reader :reference_labels

    def initialize(node,value,reference_labels)
        @node = node
        @value = value
        @reference_labels = reference_labels
    end

end

class Project

    def initialize(src,verbose=false)
        @models = {}
        @verbose = verbose
        load_all_models(src)    
        @values_map_per_file = {}
        @value_frequencies = Hash.new {|h,k| h[k]={} }  
        @idf = {}
    end

    def models
        @models
    end

    def sequential_asts
        sequential_asts = []
        @nodes_per_file.each do |f,nodes|
            nodes.each do |n|
                attribute_values_of_n = n.collect_values_with_count.keys
                context = context(n) if attribute_values_of_n.count > 0
                attribute_values_of_n.each do |v|
                    sequential_asts << SequentialAst.new(n,v,context.values)
                end
            end
        end
        sequential_asts
    end
    
    def shared_ids
        @shared_ids = calc_shared_ids unless @shared_ids
        @shared_ids
    end

    def files
        files = Set.new
        @files_per_values.values.each do |fs|
            fs.each {|f| files<<f}
        end
        files
    end

    def iter_over_shared_ids_instances(&block)
        shared_ids.each do |v|
            iter_value_for_all_extensions(v,&block)
        end
    end

    def iter_over_shared_ids_instances_case_insensitive(&block)
        shared_ids.each do |v|
            iter_value_for_all_extensions_case_insensitive(v,&block)
        end
    end

    def iter_value_for_all_extensions(v,&block)
        extensions = []
        @files_per_values[v].each do |el|
            ext = File.extname(el)  
            extensions << ext unless extensions.include?(ext)
        end
        for i in 0...extensions.count
            ext_i = extensions[i]
            for j in (i+1)...extensions.count
                ext_j = extensions[j]
                 iter_value_in_extensions(v,ext_i,ext_j,&block)
            end
        end     
    end

    def iter_value_for_all_extensions_case_insensitive(v,&block)
        extensions = []
        @files_per_values[v].each do |el|
            ext = File.extname(el)  
            extensions << ext unless extensions.include?(ext)
        end
        for i in 0...extensions.count
            ext_i = extensions[i]
            for j in (i+1)...extensions.count
                ext_j = extensions[j]
                iter_value_in_extensions_case_insensitive(v,ext_i,ext_j,&block)
            end
        end     
    end

    def iter_value_in_extensions(v,ext_i,ext_j,&block)
        raise "Error" if ext_i==ext_j
        files_i = []
        files_j = []
        vs = [v]
        vs.each do |v_el|
            @files_per_values[v_el].each do |el|
                files_i << el if File.extname(el)==ext_i
                files_j << el if File.extname(el)==ext_j
            end
        end
        nodes_i = []
        nodes_j = []
        files_i.each do |f|
            vs.each do |v_el|
                @nodes_per_value_and_file_map[v_el][f].each {|n| nodes_i << n}
            end
        end
        files_j.each do |f|
            vs.each do |v_el|
                @nodes_per_value_and_file_map[v_el][f].each {|n| nodes_j << n}
            end
        end
        for ni in nodes_i
            for nj in nodes_j
                block.call(ni,nj)
            end
        end
    end

    def iter_value_in_extensions_case_insensitive(v,ext_i,ext_j,&block)
        raise "Error" if ext_i==ext_j
        files_i = []
        files_j = []
        vs = values_case_insensitve(v)
        vs.each do |v_el|
            @files_per_values[v_el].each do |el|
                files_i << el if File.extname(el)==ext_i
                files_j << el if File.extname(el)==ext_j
            end
        end
        nodes_i = []
        nodes_j = []
        files_i.each do |f|
            vs.each do |v_el|
                @nodes_per_value_and_file_map[v_el][f].each {|n| nodes_i << n}
            end
        end
        files_j.each do |f|
            vs.each do |v_el|
                @nodes_per_value_and_file_map[v_el][f].each {|n| nodes_j << n}
            end
        end
        for ni in nodes_i
            for nj in nodes_j
                block.call(ni,nj)
            end
        end
    end 

    def tf_idf(file,value)
        value_frequency(file,value)*idf(value)
    end

    def itf_idf(file,value)
        itf(file,value)*idf(value)
    end

    private

    def idf(value)
        unless @idf[value]
            pos = 0
            neg = 0
            files.each do |f|
                values_per_file(f).has_key?(value) ? pos+=1 : neg+=1
            end
            @idf[value] = Math.log((pos+neg).to_f/pos.to_f)
        end
        @idf[value]
    end

    def itf(file,value)
        Math.log(1.0/value_frequency(file,value))
    end

    def value_frequency(file,value)
        unless @value_frequencies[file][value]
            values_map = values_per_file(file)
            total = values_map.values.inject(:+)
            @value_frequencies[file][value] = values_map[value].to_f/total.to_f
        end
        @value_frequencies[file][value]
    end

    def values_per_file(file)
        unless @values_map_per_file[file]
            @values_map_per_file[file] = @ml.model(file).collect_values_with_count_subtree(:also_foreign)
        end
        @values_map_per_file[file]
    end

    def values_case_insensitve(v)
        @files_per_values.keys.select {|el| el.to_s.downcase==v.to_s.downcase}
    end

    def calc_shared_ids
        shared = []
        @files_per_values.each do |v,s|
            extensions = []
            s.each do |el|
                ext = File.extname(el)  
                extensions << ext unless extensions.include?(ext)
            end
            if extensions.count>1
                shared << v
            end
        end
        shared
    end

    def load_all_models(src)
        @ml = ModelLoader.new
        @nodes_per_file = Hash.new {|h,k| h[k] = []}
        @files_per_values = Hash.new {|h,k| h[k] = Set.new}

        # nodes per value, file
        @nodes_per_value_and_file_map = Hash.new {|h,k| h[k] = Hash.new {|h,k| h[k] = [] }} 

        Dir["#{src}/**/*.html"].each do |f|
            puts "Loading model from #{f}" if @verbose
            load_model_from_file(f)
        end
        Dir["#{src}/**/*.js"].each do |f|           
            puts "Loading model from #{f}" if @verbose
            load_model_from_file(f) 
        end     
    end

    def load_model_from_file(f)
        m = @ml.model(f)
        @models[f]=m
        m.traverse_also_foreign do |n|
            @nodes_per_file[f] << n
            values = n.collect_values_with_count.keys
            values.each do |v|
                @files_per_values[v] << f
                @nodes_per_value_and_file_map[v][f] << n
            end     
        end
    end

end

end