require 'set'
require 'crosslanguagespotter/jaccard'
require 'crosslanguagespotter/figures_evaluator'

module CrossLanguageSpotter

class TverskyReferencesProducer

    attr_accessor :verbose

    def initialize(parameters)
        @threshold = parameters[:threshold] || 0.5
        @alpha     = parameters[:alpha]     || 1.0
        @beta      = parameters[:beta]      || 1.0
    end

    def related?(context_ni,context_nj)
        j = tversky_coefficient(context_ni,context_nj)
        j>=@threshold
    end

    def tversky_coefficient(context_ni,context_nj)
        shared = context_ni & context_nj
        others = @alpha*(context_ni.count-shared.count)+@beta*(context_nj.count-shared.count)
        shared.count.to_f/(shared.count.to_f+others)
    end

end

end