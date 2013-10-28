require 'methods/subtree_method'
require 'method_invokation'

comparator = CrossLanguageReferencesProducerMethodsComparator.new($golden_set,$project)

for t in 1..10
	threshold = t
	puts "Working on threshold #{threshold}..."
	figures = comparator.add(SubtreeReferencesProducer,{:threshold => threshold})

	puts "Figure threshold #{threshold}: #{figures}"
end