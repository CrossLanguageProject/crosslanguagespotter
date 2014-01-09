require 'test_helper'
require 'codemodels'
require 'codemodels/xml'
require 'codemodels/properties'
require 'codemodels/html'
require 'codemodels/js'

class TestSpotter < Test::Unit::TestCase

def setup
end

def test_models_loading
	models = CrossLanguageSpotter._load_models('./test/data/angular_puzzle')
    assert_equal 4,models.count
    assert models.has_key?('/app.js')
    assert models.has_key?('/index.html')
    assert models.has_key?('/slidingPuzzle.js')
    assert models.has_key?('/wordSearchPuzzle.js')
end

def test_features_calc
    dir = './test/data/angular_puzzle'
    spotter = CrossLanguageSpotter::Spotter.new()
    spotter.features_for_dir(dir)
end

def test_oracle
    dir = './test/data/angular_puzzle'
    oracle_loader = OracleLoader.new
    oracle_loader.to_train_data(dir,'./test/data/angular-puzzle.GS')
end


end