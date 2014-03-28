$: << './lib'
require 'crosslanguagespotter'
include CrossLanguageSpotter

oracle_loader = OracleLoader.new
classifier = oracle_loader.build_weka_classifier('./test/data/angular_puzzle','./test/data/angular-puzzle.GS')

path = './test/data/angular_puzzle'
spotter = CrossLanguageSpotter::Spotter.new()
project = Project.new(path)
relations = spotter.classify_relations(project,classifier)

generate_report_file(relations,'example.html')