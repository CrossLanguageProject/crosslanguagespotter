#!/usr/bin/env ruby
#require 'bundler'
#Bundler.setup
require 'codemodels'
require 'codemodels/js'
require 'codemodels/html'
require 'csv'
require 'model_loading'
require 'console'
require 'code_processing'

include CodeModels

##
## Command line arguments processing - begin
##

error "oracle2metaoracle <input> <srcdir> <output>" if ARGV.count < 3

ipath    = ARGV[0]
$srcpath = ARGV[1]
opath    = ARGV[2]

error "input file does not exit" unless File.exist?(ipath)
warn "overriding existing file..." if File.exist?(opath)

##
## Command line arguments processing - end
##

def candidates_included_in_all_the_others(candidates_in_correct_position)
	candidates_in_correct_position.each do |small|
		ok = true
		candidates_in_correct_position.each do |big|
			if small!=big
				unless big.source.position.include?(small.source.position)
					ok = false
				end
			end
		end
		return small if ok
	end
	nil
end

def find_node(model,surface_form,position)
	verbose_msg "Looking for '#{surface_form}'"
	candidates_in_correct_position = []
	candidates_in_other_positions = []
	max_embedding_level = -1
	model.traverse(:also_foreign) do |n|
		if n.collect_values_with_count.has_key?(surface_form)
			if n.source.position(:absolute).include?(position)
				if n.source.embedding_level>=max_embedding_level
					if n.source.embedding_level>max_embedding_level
						candidates_in_correct_position.clear
					end
					max_embedding_level = n.source.embedding_level
					candidates_in_correct_position << n
				end
			else
				candidates_in_other_positions << n
			end
		end
	end
	if candidates_in_correct_position.count!=1
		smallest_candidate = candidates_included_in_all_the_others(candidates_in_correct_position)
		unless smallest_candidate
			puts "I did not find exactly once '#{surface_form}' at #{position}. I found it there #{candidates_in_correct_position.count} times (found elsewhere #{candidates_in_other_positions.count} times)"


			candidates_in_other_positions.each do |wp|
				puts " * #{wp.source.position(:absolute)}"
			end
			puts "Candidate in corresponding position:"
			candidates_in_correct_position.each do |c|
				puts " * #{c} (embedded? #{c.source.embedded?})"
			end
			raise "Candidates found in #{position} are #{candidates_in_correct_position.count}"
		else
			puts "More than one candidate, I pick up the smallest"
			return smallest_candidate
		end
	end
	candidates_in_correct_position[0]
end

#
# SCRIPT START
#

model_loader = ModelLoader.new
models = Hash.new do |h,k|
	h[k] = model_loader.model(File.join($srcpath,k))
end

$file_lines = Hash.new do |h,k|
	h[k] = File.readlines(File.join($srcpath,k))
end

$ok = 0
$ko = 0

# the given column is calculated counting 4 for each tab,
# while the output count just 1 also per tab
def convert_from_tabcolumn_to_plaincolumn(file,line_index,tabcol)
	line = $file_lines[file][line_index-1]
	tabcol_to_plaincol(line,tabcol)
end

OracleRelationEnd = Struct.new :file, :line, :col, :surface_form
MetaOracleRelationEnd = Struct.new :file, :index

File.open(opath,'w') do |output|
	CSV(csv = "") do |csv|
		csv << %w{file_a traverse_index_a file_b traverse_index_b}
		oracle_values     = {}
		metaoracle_values = {}
		File.open(ipath,'r').each_with_index do |input_line,l|	
			input_line.strip!
			unless input_line.start_with?('#')
				values = input_line.split "\t"
				# we order them to facilitate searching for duplicates
				end_a = OracleRelationEnd.new values[0], values[1].to_i, values[2].to_i, values[3]
				end_b = OracleRelationEnd.new values[4], values[5].to_i, values[6].to_i, values[7]
				if end_b.file < end_a.file
					end_a, end_b = end_b, end_a
				end

				file_a         = values[0]
				line_a         = values[1].to_i
				col_a          = values[2].to_i
				surface_form_a = values[3]
				file_b         = values[4]
				line_b         = values[5].to_i
				col_b          = values[6].to_i			
				surface_form_b = values[7]


				if values.count!=8
					raise "Line #{l+1}, error: #{input_line}. Values: #{values}"
				end
				if oracle_values.values.include?([end_a,end_b])
					raise "Line #{l+1} is a duplicate of line #{oracle_values.find {|k,v| v==[end_a,end_b]}}"
				else
					oracle_values[l] = [end_a,end_b]
				end				

				model_a = models[file_a]
				model_b = models[file_b]

				plain_col_a = convert_from_tabcolumn_to_plaincolumn(file_a,line_a,col_a)
				plain_col_b = convert_from_tabcolumn_to_plaincolumn(file_b,line_b,col_b)

				pos_a = SourcePosition.new(SourcePoint.new(line_a,plain_col_a),SourcePoint.new(line_a,plain_col_a+surface_form_a.length-1))
				pos_b = SourcePosition.new(SourcePoint.new(line_b,plain_col_b),SourcePoint.new(line_b,plain_col_b+surface_form_b.length-1))
				begin
					node_a = find_node(model_a,surface_form_a,pos_a)
				rescue Exception => e
					puts "Line #{l+1}) problem with '#{surface_form_a}', file: #{file_a}, pos #{pos_a}: #{e}"
				end
				begin
					node_b = find_node(model_b,surface_form_b,pos_b)
				rescue Exception => e
					puts "Line #{l+1}) problem with '#{surface_form_b}', file: #{file_b}, pos #{pos_b}: #{e}"
				end

				if node_a and node_b
				 	$ok+=1
				 	trindex_a = traverse_index(node_a)
				 	trindex_b = traverse_index(node_b)

					metaoracle_end_a = MetaOracleRelationEnd.new file_a,trindex_a
					metaoracle_end_b = MetaOracleRelationEnd.new file_b,trindex_b
					if metaoracle_end_b.file < metaoracle_end_a.file
						metaoracle_end_a, metaoracle_end_b = metaoracle_end_b, metaoracle_end_a
					end
					if metaoracle_values.values.include?([metaoracle_end_a,metaoracle_end_b])
						raise "Line #{l+1} (#{[metaoracle_end_a,metaoracle_end_b]}) is a duplicate of line #{metaoracle_values.find {|k,v| v==[metaoracle_end_a,metaoracle_end_b]}}"
					else
						metaoracle_values[l+1] = [metaoracle_end_a,metaoracle_end_b]
					end	

				 	csv << [file_a,trindex_a,file_b,trindex_b]
				else
				 	$ko+=1
				end
			end
		end
	end
	output.write(csv)
end

puts "OK: #{$ok}"
puts "KO: #{$ko}"
