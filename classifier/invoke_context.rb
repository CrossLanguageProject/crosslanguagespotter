require 'methods/context_method'
require 'method_invokation'

comparator = CrossLanguageReferencesProducerMethodsComparator.new($golden_set,$project)

all_figures = {}

for a in 0..4
	alpha = a*0.5
	for t in 0..10
		threshold = 0.25*t
		puts "Working on alpha #{alpha}, threshold #{threshold}..."
		params = {:alpha => alpha, :threshold => threshold, :verbose => true}
		figures = comparator.add(ContextReferencesProducer,params)

		puts "Figure alpha #{alpha}, threshold #{threshold}: #{figures}"
		all_figures[params] = figures
	end
end
