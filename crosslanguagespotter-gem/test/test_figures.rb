require 'test_helper'

class TestTversky < Test::Unit::TestCase

class DummyShared

	def initialize(size)
		@size = size
	end

	def count
		@size
	end

end

class DummyContext

	def self.pair(size_a,size_b,size_shared)
		[DummyContext.new(size_a,size_shared),DummyContext.new(size_b,size_shared)]
	end

	def initialize(size,shared)
		@size   = size
		@shared = shared
	end

	def &(other)
		DummyShared.new(@shared)
	end

	def count
		@size
	end

end

def test_tversky_coefficient
	trp = TverskyReferencesProducer.new({ alpha: 0.5, beta:0.7 })
	ctx_a, ctx_b = DummyContext.pair(2,5,2)
	assert_in_delta 2.0/(2.0+0.7*3), trp.tversky_coefficient(ctx_a, ctx_b), 0.00001
	ctx_a, ctx_b = DummyContext.pair(3,5,2)
	assert_in_delta 2.0/(2.0+0.5*1.0+0.7*3), trp.tversky_coefficient(ctx_a, ctx_b), 0.00001
	ctx_a, ctx_b = DummyContext.pair(1,1,1)
	assert_in_delta 1.0/(1.0), trp.tversky_coefficient(ctx_a, ctx_b), 0.00001
end

def test_related	
	ctx_a, ctx_b = DummyContext.pair(2,5,2) # 0.4878		
	assert_equal true, TverskyReferencesProducer.new(
		{ alpha: 0.5, beta:0.7, threshold: 0.47 }
		).related?(ctx_a,ctx_b)
	assert_equal false, TverskyReferencesProducer.new(
		{ alpha: 0.5, beta:0.7, threshold: 0.49 }
		).related?(ctx_a,ctx_b)

	ctx_a, ctx_b = DummyContext.pair(3,5,2) # 0.434782
	assert_equal true, TverskyReferencesProducer.new(
		{ alpha: 0.5, beta:0.7, threshold: 0.43 }
		).related?(ctx_a,ctx_b)
	assert_equal false,  TverskyReferencesProducer.new(
		{ alpha: 0.5, beta:0.7, threshold: 0.435 }
		).related?(ctx_a,ctx_b)

	ctx_a, ctx_b = DummyContext.pair(1,1,1) # 1.0
	assert_equal true, TverskyReferencesProducer.new(
		{ alpha: 0.5, beta:0.7, threshold: 0.99 }
		).related?(ctx_a,ctx_b)
	assert_equal true,  TverskyReferencesProducer.new(
		{ alpha: 0.5, beta:0.7, threshold: 1.00 }
		).related?(ctx_a,ctx_b)
	assert_equal false,  TverskyReferencesProducer.new(
		{ alpha: 0.5, beta:0.7, threshold: 1.01 }
		).related?(ctx_a,ctx_b)
end

end

class TestJaccard < Test::Unit::TestCase

def test_jaccard_best_match
	a = [1, 2, 3]
	b = [1, 2]
	c = [1, 3]
	assert_equal([[1, 2, 3], [1, 2]], Jaccard.best_match([a, b, c]) )
end

end