require 'methods/tversky_method'
require 'method_invokation'

comparator = CrossLanguageReferencesProducerMethodsComparator.new($golden_set,$project)

for t in 1..10
	threshold = 0.1*t
	for a in 0..4
		alpha = 0.25*a
		puts "Working on threshold #{threshold}, alpha #{alpha}..."
		figures = comparator.add(TverskyReferencesProducer,{:threshold => threshold, :alpha => alpha})

		puts "Figure threshold #{threshold}, alpha #{alpha}: #{figures}"
	end
end