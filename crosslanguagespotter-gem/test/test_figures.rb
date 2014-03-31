require 'test_helper'

class TestFigures < Test::Unit::TestCase

def setup
end

def test_jaccard_best_match
	a = [1, 2, 3]
	b = [1, 2]
	c = [1, 3]
	assert_equal([[1, 2, 3], [1, 2]], Jaccard.best_match([a, b, c]) )
end

end