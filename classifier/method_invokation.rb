require 'csv'
require 'set'
require 'model_loading'

module MethodInvokation

$verbose = true

def self.load_golden_set(metaoracle,src,prefix,only_different_extensions=true)
	set = Set.new
	puts "Loading golden standard" if $verbose
	CSV.foreach(metaoracle,:headers=>true) do |row|
		# I add $src so that the filenames are the same of the ones
		# which appears in the observed set
		ext_a = File.extname(row['file_a'])
		ext_b = File.extname(row['file_b'])
		if ext_a!=ext_b || (only_different_extensions==false)
			id_a = NodeId.new(prefix+row['file_a'],row['traverse_index_a'].to_i)
			id_b = NodeId.new(prefix+row['file_b'],row['traverse_index_b'].to_i)
			puts " * '#{prefix+row['file_a']}':#{row['traverse_index_a'].to_i} -> '#{prefix+row['file_b']}' #{row['traverse_index_b'].to_i}" if $verbose
			set << CrossLanguageRelation.new([id_a,id_b])
		else
			puts "skipping same extension element"
		end
	end
	puts "Golden standard: #{set.count} elements"
	set
end

raise "specify project name" if ARGV.count<1
PROJECT_NAME = ARGV[0]

case PROJECT_NAME
when 'angular-puzzle'
	BASE = "../projects/angular-puzzle"
	SRC  = "../projects/angular-puzzle/original_repo"
when 'buzz'
	BASE = "../projects/buzz"
	SRC = "../projects/buzz/original_repo"
else
	raise "Unvalid project name: #{PROJECT_NAME}"
end

def self.golden_set
	golden_set = load_golden_set("#{BASE}/data/#{PROJECT_NAME}_metaoracle.csv",SRC,"#{BASE}/original_repo/")
	puts "Golden set loaded"
	golden_set
end

def self.project
	project = Project.new(SRC,$verbose)
	puts "Project loaded"
	project
end

GOLDEN_SET = golden_set()
PROJECT    = project()

end # module