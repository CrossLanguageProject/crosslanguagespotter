require 'methods/jaro_method'
require 'method_invokation'

comparator = CrossLanguageReferencesProducerMethodsComparator.new($golden_set,$project)

all_figures = {}

for wa in [false,true]
	for t in 1..10
		threshold = 0.1*t
		puts "Working on threshold #{threshold}, winkleradjust #{wa}..."
		params = {:winkleradjust => wa, :threshold => threshold, :verbose => true}
		figures = comparator.add(JaroReferencesProducer,params)

		puts "Figure threshold #{threshold}, winkleradjust #{wa}: #{figures}"
		all_figures[params] = figures
	end
end
