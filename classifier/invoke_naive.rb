require 'methods/naive'
require 'method_invokation'

comparator = CrossLanguageReferencesProducerMethodsComparator.new($golden_set,$project)
figures_cs = comparator.add(NaiveReferencesProducer,{:case_insensitive=>false})
figures_ci = comparator.add(NaiveReferencesProducer,{:case_insensitive=>true})

puts "Figure cs: #{figures_cs}"
puts "Figure ci: #{figures_ci}"
