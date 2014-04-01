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
    def indices_of_value(value)
        out = Array.new
        select_with_index do |x, i|
            out << i if x == value
        end
        out
    end

end

module CrossLanguageSpotter

class JaroReferencesProducer

    attr_accessor :verbose

    def initialize(parameters={})
        @threshold              = parameters[:threshold]     || 0.5
        @verbose                = parameters[:verbose]       || false
        @winkleradjust          = parameters[:winkleradjust] || false
        @winkler_scaling_factor = 0.1
        @winkler_max_prefix     = 3
    end

    def related?(context_ni,context_nj)
        j = jaro_coefficient(context_ni,context_nj)
        j>=@threshold
    end    

    def jaro_coefficient_from_nodes(ni,nj)
        jaro_coefficient_from_context(context(ni),context(nj))
    end

    def jaro_coefficient_from_context(context_ni,context_nj)
        s1 = context_ni.sequence_of_values.map{|v| v.to_s}
        s2 = context_nj.sequence_of_values.map{|v| v.to_s}  
        jaro_coefficient(s1,s2) 
    end

    def matching(s1,s2)
        _matching_and_transpositions(s1,s2)[:m]
    end

    def transpositions(s1,s2)
        _matching_and_transpositions(s1,s2)[:tr]
    end

    def _matching_distance(s1,s2)
        s1l = s1.length
        s2l = s2.length
        md = (([s1l,s2l].max / 2) - 1).to_i
        return 0 if md<0
        md
    end

    def _matching_and_transpositions(s1,s2)
        return _matching_and_transpositions(s2,s1) if s1.length>s2.length

        s1l = s1.length
        s2l = s2.length
        return {m:0,tr:0} if s1l==0 or s2l==0
       
        # matching distance definition
        md = _matching_distance(s1,s2)
        
        matchIndexes = Array.new(s1l,-1)
        matchFlags   = Array.new(s2l,false)
        matches = 0;

        s1l.times do |mi|
            c1 = s1[mi]
            xb = [mi-md,0].max
            xe = [mi+md+1,s2l].min
            done = false
            (xb...xe).each do |xi|            
                if !done && !matchFlags[xi] && c1 == s2[xi]
                  matchIndexes[mi] = xi
                  matchFlags[xi] = true
                  matches+=1
                  done = true
                end
            end
        end

        ms1 = Array.new matches
        ms2 = Array.new matches
        
        si = 0
        s1l.times do |i|
            if matchIndexes[i] != -1
                ms1[si] = s1[i]
                si+=1
            end
        end

        si = 0
        s2l.times do |i|
            if matchFlags[i]
                ms2[si] = s2[i]
                si+=1
            end
        end

        transpositions = 0
        s1l.times do |mi|
            transpositions+=1 if ms1[mi] != ms2[mi]
        end

        {m:matches,tr:transpositions}   
    end

    def _length_of_winkler_prefix(s1,s2)
        return _length_of_winkler_prefix(s2,s1) if s1.length>s2.length
        l = 0
        (0..s1.length-1).each { |i| s1[i]==s2[i] ? l+=1 : break }
        [l,@winkler_max_prefix].min
    end

    def jaro_coefficient(s1,s2)
        return jaro_coefficient(s2,s1) if s1.length>s2.length
        s1l = s1.length
        s2l = s2.length
        
        h  = _matching_and_transpositions(s1,s2)
        m  = h[:m]
        tr = h[:tr]
        
        return 0.0 unless m>0
        
        tr = (tr/2).to_i
        # calc jaro-distance
        third = 1.0/3
        jd = (third * m / s1l) + (third * m / s2l) + (third * (m - tr) / m)
        out = jd
        # winkleradjust? if first l characters are the same
        if @winkleradjust
            l = _length_of_winkler_prefix(s1,s2)
            out = jd + (l * @winkler_scaling_factor * (1.0 - jd))
        end
        out
    end

end

end