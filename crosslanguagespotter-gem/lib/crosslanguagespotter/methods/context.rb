require 'set'
require 'crosslanguagespotter/figures_evaluator'

module CrossLanguageSpotter

class Pair

    def initialize(a,b)
        raise "error" unless a.source.position(:absolute)
        raise "error" unless b.source.position(:absolute)
        if b.source.artifact(:absolute).filename < a.source.artifact(:absolute).filename
            @nodes = [b,a]
        else
            @nodes = [a,b]
        end
    end

    def first
        nodes[0]
    end

    def second
        nodes[1]
    end

    def nodes
        @nodes
    end

    def eql?(other)
        return false unless other.is_a?(Pair)
        self.nodes[0]==other.nodes[0] && self.nodes[1]==other.nodes[1]
    end

    def ==(other)
        self.eql?(other)
    end

    def to_s
        "[#{nodes[0]} <-> #{nodes[1]}]"
    end

    def hash
        nodes[0].hash*3+nodes[1].hash
    end

end

class PointsMap

    def initialize(alpha)
        @alpha = alpha
        @points = Hash.new {|h,k| h[k]=0.0}
    end

    def points(pair)
        @points[pair]
    end

    def register_context_contribute(pair,value)
        @points[pair] += 0.2*@alpha*value.to_f
    end

    def register_child_contribute(pair)
        @points[pair] += 0.1
    end

    def each(threshold, &block)
        @points.select{|k,v| v>=threshold}.each(&block)
    end

end

class ContextReferencesProducer

    attr_accessor :verbose

    def initialize(parameters)
        @threshold = parameters[:threshold]
        @verbose = parameters[:verbose]
        @alpha = parameters[:alpha]
    end

    def points_map(project)
        # fill points map
        points_map = PointsMap.new(@alpha)
        block1 = Proc.new do |ni,nj|
            context_ni = context(ni)
            context_nj = context(nj)
            shared_ctx = context_nj.intersection(context_ni).to_a
            shared_ctx.each do |shared_ctx_entry|
                v = shared_ctx_entry[:value]
                context_ni.declarators_per_value(v).each do |di|
                    context_nj.declarators_per_value(v).each do |dj|
                        points_map.register_child_contribute(Pair.new(di,dj))
                    end
                end
            end
            points_map.register_context_contribute(Pair.new(ni,nj),shared_ctx.count)
        end     
        project.iter_over_shared_ids_instances {|ni,nj| block1.call(ni,nj) }
        points_map
    end

    # It should produce a set of node ids
    def produce_set(project)
        set = Set.new
        puts "Context method:" if @verbose
                
        points_map = points_map(project)
        
        # look into points map
        points_map.each(@threshold).each do |pair,value|
            f = pair.first
            s = pair.second
            id_i = NodeId.from_node(f)
            id_j = NodeId.from_node(s)
            set << CrossLanguageRelation.new([id_i,id_j])
        end

        puts "Context method, set produced: #{set.count} elements" if @verbose
        set
    end

end

end