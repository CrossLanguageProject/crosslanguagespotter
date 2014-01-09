require 'set'
require 'crosslanguagespotter/figures_evaluator'

class Array
    # select array items with index
    # give a block both the item with index of array
    # filtered by a select statement
    def select_with_index
        index = -1
        select { |x| index += 1; yield(x, index) }
    end

    # return indices array of array item
    # example all indices of a in string "aaabaaabba"
    def aindices(o)
        out = Array.new
        select_with_index { |x, i|
        out << i if x == o }
        out
    end
end

module CrossLanguageSpotter

class JaroReferencesProducer

    attr_accessor :verbose

    def initialize(parameters)
        @threshold = parameters[:threshold]
        @verbose = parameters[:verbose]
        @winkleradjust = parameters[:winkleradjust]
    end

    # It should produce a set of node ids
    def produce_set(project)
        set = Set.new
        puts "Jaro method:" if @verbose

        block1 = Proc.new do |ni,nj|
            context_ni = context(ni).sequence_of_values.map{|v| v.to_s}
            context_nj = context(nj).sequence_of_values.map{|v| v.to_s}
            if jaro_coefficient(context_ni,context_nj)>@threshold
                id_i = NodeId.from_node(ni)
                id_j = NodeId.from_node(nj)
                set << CrossLanguageRelation.new([id_i,id_j])
            end
        end     
        project.iter_over_shared_ids_instances {|ni,nj| block1.call(ni,nj) }                
        puts "Jaro method, set produced: #{set.count} elements" if @verbose
        set
    end

    def jaro_coefficient_from_nodes(ni,nj)
        jaro_coefficient_from_context(context(ni),context(nj))
    end

    def jaro_coefficient_from_context(context_ni,context_nj)
        s1 = context_ni.sequence_of_values.map{|v| v.to_s}
        s2 = context_nj.sequence_of_values.map{|v| v.to_s}  
        jaro_coefficient(s1,s2) 
    end

    def jaro_coefficient(s1,s2)
        # if strings (without trailing & leadning spaces) are equal - return 1
        #return 1 if str1.strip==str2.strip
        # either string blank - return 0
        #return 0 if str1.size==0 or str2.size==0
        m = 0 # number of matching chars
        tr = 0 # number of transpositions

        # get character array length
        s1l = s1.length
        s2l = s2.length
        # str2 should be the longer string
        if s1l > s2l
            s1, s2 = s2, s1
        end
        # hash from all unique str2 chars + occurances
        # example 'aba': hash={ a => 0, b => 0 } a: first occurance, b first occurance
        # if the first a was visited: { a => 1, b => 0} a: second occuance, b second occurance
        found = Hash[*s2.uniq.sort.collect {|v| [v,0]}.flatten]
        # matching distance definition
        md = (([s1l,s2l].max / 2) - 1).to_i
        s1.each_with_index do |c,i|
            # find number of matching chars
            if !found[c].nil? # character exists in str2
                # calculates distance between 2 matching characters compare with md
                if !s2.aindices(c)[found[c]].nil?
                    x = (s2.aindices(c)[found[c]] - i).abs
                    if x <= md
                        found[c] += 1 # increase occurance of character
                        m += 1 # increase number of matching characters
                        # transpositions?
                        if (x != 0)
                            tr += 1
                        end
                    end
                end
            end
        end
        tr = (tr/2).to_i
        # calc jaro-distance
        third = 1.0/3
        jd = (third * m / s1l) + (third * m / s2l) + (third * (m - tr) / m)
        out = jd
        # winkleradjust? if first l characters are the same
        if @winkleradjust
            l = 0
            (0..s1l-1).each { |i| s1[i]==s2[i] ? l+=1 : break }
            out = jd + (l * 0.1 * (1 - jd))
        end
        out
    end

end

end