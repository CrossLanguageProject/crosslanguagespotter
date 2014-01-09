require 'set'
require 'crosslanguagespotter/jaccard'
require 'crosslanguagespotter/figures_evaluator'

module CrossLanguageSpotter

class TverskyReferencesProducer

    attr_accessor :verbose

    def initialize(parameters)
        @threshold = parameters[:threshold]
        @alpha     = parameters[:alpha]
    end

    # It should produce a set of node ids
    def produce_set(project)
        set = Set.new
        puts "Tversky method:" if @verbose
        block = Proc.new do |ni,nj|
            context_ni = context(ni).values & project.shared_ids
            context_nj = context(nj).values & project.shared_ids 
            j = tversky_coefficient(context_ni,context_nj)
            if j>=@threshold
                id_i = NodeId.from_node(ni)
                id_j = NodeId.from_node(nj)
                puts " * '#{id_i.file}':#{id_i.index} -> '#{id_j.file}':#{id_j.index}" if @verbose
                set << CrossLanguageRelation.new([id_i,id_j])
            end
        end     
        project.iter_over_shared_ids_instances {|ni,nj| block.call(ni,nj) }     
        puts "Tversky method, set produced: #{set.count} elements" if @verbose
        set
    end

    def tversky_coefficient(context_ni,context_nj)
        shared = context_ni & context_nj
        others = (context_ni.count-shared.count)+(context_nj.count-shared.count)
        shared.count.to_f/(shared.count.to_f+@alpha*others.to_f)
    end

end

end