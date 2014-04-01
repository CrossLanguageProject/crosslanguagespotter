require 'test_helper'

class TestJaro < Test::Unit::TestCase

	def test_array_select_with_index
		a = [1,2,3,4,5,6,6,8,9]
		assert_equal [2,4,6,6,8], a.select_with_index {|x,i| x.even? }
	end

	def test_array_indices_of_value
		a = [1,2,3,4,5,6,6,8,9]
		assert_equal [1], a.indices_of_value(2)
		assert_equal [5,6], a.indices_of_value(6)
	end

	def test_jaro_matching_distance
		jrp = JaroReferencesProducer.new
		assert_equal 2,jrp._matching_distance("MARTHA".split(//),"MARHTA".split(//))
		assert_equal 1,jrp._matching_distance("CRATE".split(//),"TRACE".split(//))
		assert_equal 2,jrp._matching_distance("DWAYNE".split(//),"DUANE".split(//))
	end

	def test_jaro_matching
		jrp = JaroReferencesProducer.new
		assert_equal 6,jrp.matching("MARTHA".split(//),"MARHTA".split(//))
		assert_equal 3,jrp.matching("CRATE".split(//),"TRACE".split(//))
		assert_equal 4,jrp.matching("DWAYNE".split(//),"DUANE".split(//))
	end

	def test_length_of_winkler_prefix
		jrp = JaroReferencesProducer.new
		assert_equal 3,jrp._length_of_winkler_prefix("CIAO","CIAO")
		assert_equal 2,jrp._length_of_winkler_prefix("AB","ABCD")
		assert_equal 2,jrp._length_of_winkler_prefix("ABCD","AB")
		assert_equal 0,jrp._length_of_winkler_prefix("ABCD","BCD")
	end

	def test_jaro_transpositions
		jrp = JaroReferencesProducer.new
		assert_equal 0,jrp.transpositions("DwAyNE".split(//),"DuANE".split(//))
		assert_equal 2,jrp.transpositions("MARTHA".split(//),"MARHTA".split(//))
		assert_equal 0,jrp.transpositions("CRATE".split(//),"TRACE".split(//))
		assert_equal 0,jrp.transpositions("DWAYNE".split(//),"DUANE".split(//))
	end

	def test_jaro_coefficient
		jrp = JaroReferencesProducer.new
		assert_equal 0.0,jrp.jaro_coefficient("ciao".split(//),"qwer".split(//)) # all characters different
		assert_in_delta 0.944,jrp.jaro_coefficient("MARTHA".split(//),"MARHTA".split(//)), 0.01
		assert_in_delta 0.822,jrp.jaro_coefficient("DWAYNE".split(//),"DUANE".split(//)), 0.01
		assert_in_delta 0.767,jrp.jaro_coefficient("DIXON".split(//),"DICKSONX".split(//)), 0.01
	end

	def test_jaro_coefficient_with_winkler
		jrp = JaroReferencesProducer.new(winkleradjust:true)
		assert_equal 0.0,jrp.jaro_coefficient("ciao".split(//),"qwer".split(//)) # all characters different
		assert_in_delta 0.9608,jrp.jaro_coefficient("MARTHA".split(//),"MARHTA".split(//)), 0.01
		assert_in_delta 0.84,jrp.jaro_coefficient("DWAYNE".split(//),"DUANE".split(//)), 0.01
		assert_in_delta 0.813,jrp.jaro_coefficient("DIXON".split(//),"DICKSONX".split(//)), 0.01
	end	

end

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