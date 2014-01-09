module CrossLanguageSpotter

class CrossLanguageReferencesProducer

    def initialize(parameters)
    end

    # It should produce a set of CrossLanguageRelation
    def produce_set(project)
    end

end

# It compare different methods, each methods can be instantiated
# different times using different parameters
class CrossLanguageReferencesProducerMethodsComparator
    # map per class, per params of the figures obtained agains the given gold set
    attr_reader :results

    def initialize(gold_set,project)
        @gold_set = gold_set
        @results = Hash.new {|h,k| h[k]={}}
        @project = project
    end

    def add(clazz,parameters)
        producer = clazz.new(parameters)
        observed_set = producer.produce_set(@project)
        fe = FiguresEvaluator.new(@gold_set,observed_set)
        result = fe.all_figures
        @results[clazz][parameters] = result
        result
    end 

end

class NodeId
    attr_reader :file
    attr_reader :node_index

    def index
        @node_index
    end

    def self.from_node(node)
        new(node.source.artifact.final_host.filename,traverse_index(node))
    end

    def initialize(file,node_index)
        @file = file
        @node_index = node_index
    end

    def eql?(other)
        return false unless other.is_a?(NodeId)
        self.file.eql?(other.file) && self.node_index.eql?(other.node_index)
    end

    def ==(other)
        return self.eql?(other)
    end

    def hash
        @file.hash*7+@node_index.hash
    end

    def <=>(other)
        res = self.file <=> other.file
        if res==0
            self.node_index <=> other.node_index
        else
            res
        end
    end

    def to_s
        "#{@file}:#{@node_index}"
    end

end

# It is a set of two node_ids (unordered)
class CrossLanguageRelation
    attr_reader :node_ids

    def initialize(node_ids)
        raise "Two elements expected, #{node_ids.count} found" unless node_ids.count==2
        node_id_a = node_ids[0]
        node_id_b = node_ids[1]
        if (node_id_a<=>node_id_b)<0
            @node_ids = [node_id_a,node_id_b]
        else
            @node_ids = [node_id_b,node_id_a]
        end     
        #puts "SORTING GAVE #{@node_ids}"
    end

    def eql?(other)
        return false unless other.is_a?(CrossLanguageRelation)
        self.node_ids.eql?(other.node_ids)
    end

    def ==(other)
        return self.eql?(other)
    end

    def hash
        @node_ids[0].hash*7+@node_ids[1].hash
    end

    def to_s
        "CrossLanguageRelation #{@node_ids[0]} <-> #{@node_ids[1]}"
    end

end

# Calculates precision, recall, f-measure
class FiguresEvaluator

    # Gold set is the "truth", observed is calculated from
    # some method and compared with the gold set
    def initialize(gold_set,observed_set)
        @gold_set     = gold_set
        @observed_set = observed_set
    end

    def precision
        @precision = calc_precision unless @precision
        @precision
    end

    def recall
        @recall = calc_recall unless @recall
        @recall
    end

    def f_measure(beta=1.0)
        beta_square = beta**2.0
        (2*(beta_square)*precision*recall)/(beta_square*precision+recall)
    end

    def all_figures(beta=1.0)
        {precision:precision,recall:recall,f_measure:f_measure(beta),beta:beta}
    end

    private

    def calc_precision
        intersection_size = @gold_set.intersection(@observed_set).count.to_f
        intersection_size/@observed_set.count.to_f
    end

    def calc_recall
        intersection_size = @gold_set.intersection(@observed_set).count.to_f
        intersection_size/@gold_set.count.to_f              
    end

end

end