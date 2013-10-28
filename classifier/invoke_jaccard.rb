require 'methods/jaccard_method'
require 'method_invokation'

comparator = CrossLanguageReferencesProducerMethodsComparator.new($golden_set,$project)

for i in 0..10
	threshold = 0.04*i
	puts "Working on threshold #{threshold}..."
	figures = comparator.add(JaccardReferencesProducer,{:threshold => threshold})

	puts "Figure threshold #{threshold}: #{figures}"
end