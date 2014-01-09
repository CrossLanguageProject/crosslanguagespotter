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


end