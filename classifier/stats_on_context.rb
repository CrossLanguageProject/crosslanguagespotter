#require 'methods/structured_context_method'
require 'figures_evaluator'
require 'methods/context_method'
require 'methods/tversky_method'
require 'methods/jaro_method'
require 'method_invokation'
require 'csv'
require 'set'
require 'jaccard'

$results = []
$tversky_producer = TverskyReferencesProducer.new  ({:alpha => 0.5, :threshold => 0.0})
$context_producer  = ContextReferencesProducer.new ({:alpha => 1.0, :threshold => 0.0})
$context_points_map = $context_producer.points_map(MethodInvokation::PROJECT)
$jaro_producer = JaroReferencesProducer.new ({:winkleradjust=>false,:threshold=>0.0})
$positive_count = 0
$matched_in_golden_set = Set.new
block = Proc.new do |ni,nj|
	if (ni.source.artifact(:absolute).filename.end_with?('index.html') && traverse_index(ni)==194)
		puts "NI: #{ni.source.artifact(:absolute).filename}, INDEX: #{traverse_index(ni)}"
		id_i = NodeId.from_node(ni)
		id_j = NodeId.from_node(nj)
		rel = CrossLanguageRelation.new([id_i,id_j])
		rel = CrossLanguageRelation.new([id_i,id_j])
		rel = CrossLanguageRelation.new([id_i,id_j])
		rel = CrossLanguageRelation.new([id_i,id_j])
		puts "(rel is : #{rel})"
	end
	if (nj.source.artifact(:absolute).filename.end_with?('index.html') && traverse_index(nj)==194)
		puts "NJ: #{nj.source.artifact(:absolute).filename}, INDEX: #{traverse_index(nj)}"
		id_i = NodeId.from_node(ni)
		id_j = NodeId.from_node(nj)
		rel = CrossLanguageRelation.new([id_i,id_j])
		puts "(rel is : #{rel})"		
	end	
	context_ni = context(ni).values & MethodInvokation::PROJECT.shared_ids
	context_nj = context(nj).values & MethodInvokation::PROJECT.shared_ids 
	shared_length = (context_ni & context_nj).count
	
	file_i = ni.source.artifact(:absolute).filename
	file_j = ni.source.artifact(:absolute).filename
	tfidf_shared = 0
	itfidf_shared = 0
	(context_ni & context_nj).each do |v|
		tfidf_shared += MethodInvokation::PROJECT.tf_idf(file_i,v)+MethodInvokation::PROJECT.tf_idf(file_j,v)
		itfidf_shared += MethodInvokation::PROJECT.itf_idf(file_i,v)+MethodInvokation::PROJECT.itf_idf(file_j,v)
	end

	perc_shared_length_i = context_ni.count==0 ? 0.0 : shared_length.to_f/context_ni.count.to_f
	perc_shared_length_j = context_nj.count==0 ? 0.0 : shared_length.to_f/context_nj.count.to_f
	perc_shared_length   = [perc_shared_length_i,perc_shared_length_j]
	perc_shared_length_min = (perc_shared_length[0]<perc_shared_length[1]) ? perc_shared_length[0] : perc_shared_length[1]
	perc_shared_length_max = (perc_shared_length[0]<perc_shared_length[1]) ? perc_shared_length[1] : perc_shared_length[0]
	diffs = [context_ni.count-shared_length,context_nj.count-shared_length]
	diff_min = diffs.min
	diff_max = diffs.max
	perc_diff_i = context_ni.count==0 ? 0.0 : diffs[0].to_f/context_ni.count.to_f
	perc_diff_j = context_nj.count==0 ? 0.0 : diffs[1].to_f/context_nj.count.to_f
	perc_diffs = [perc_diff_i,perc_diff_j]
	perc_diff_min = (perc_diffs[0]<perc_diffs[1]) ? perc_diffs[0] : perc_diffs[1]
	perc_diff_max = (perc_diffs[0]<perc_diffs[1]) ? perc_diffs[1] : perc_diffs[0]
	id_i = NodeId.from_node(ni)
	id_j = NodeId.from_node(nj)
	rel = CrossLanguageRelation.new([id_i,id_j])
	positive = MethodInvokation::GOLDEN_SET.include?(rel)
	if positive
		($matched_in_golden_set << rel) 
		($positive_count+=1)
	end

	jaccard = Jaccard.coefficient(context_ni,context_nj)
	jaccard = 0.0 if jaccard.nan?
	tversky = $tversky_producer.tversky_coefficient(context_ni,context_nj)
	tversky = 0.0 if tversky.nan?
	context = $context_points_map.points(Pair.new(ni,nj))
	jaro    = $jaro_producer.jaro_coefficient_from_nodes(ni,nj)
	jaro    = 0.0 if jaro.nan?

	$results << {positive:positive,
		shared_length:shared_length,
		tfidf_shared:tfidf_shared,itfidf_shared:itfidf_shared,
		perc_shared_length_min:perc_shared_length_min,
		perc_shared_length_max:perc_shared_length_max,
		diff_min:diff_min,diff_max:diff_max,
		perc_diff_min:perc_diff_min,perc_diff_max:perc_diff_max,
		context:context,jaccard:jaccard,jaro:jaro,tversky:tversky}
end		
MethodInvokation::PROJECT.iter_over_shared_ids_instances {|ni,nj| block.call(ni,nj) }	
CSV.open("stats_on_context.csv", "w") do |csv|
	csv << ['shared_length','tfidf_shared','itfidf_shared','perc_shared_length_min','perc_shared_length_max',
		'diff_min','diff_max','perc_diff_min','perc_diff_max',
		'context','jaccard','jaro','tversky',
		'class']	
	$results.each {|r| csv << [r[:shared_length],
		r[:tfidf_shared],r[:itfidf_shared],
		r[:perc_shared_length_min],r[:perc_shared_length_max],
		r[:diff_min],r[:diff_max],
		r[:perc_diff_min],r[:perc_diff_max],
		r[:context],r[:jaccard],r[:jaro],r[:tversky],
		r[:positive]] }
end

puts "Positives: #{$positive_count}"
puts "Matched in golden set: #{$matched_in_golden_set.count}"

not_found = MethodInvokation::GOLDEN_SET-$matched_in_golden_set
puts "Not found: #{not_found.count}"
not_found.each do |el|
	puts "* #{el}"
end