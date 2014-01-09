require 'simplecov'
SimpleCov.start do
	add_filter "/test/"	
end

require 'crosslanguagespotter'
require 'test/unit'

include CrossLanguageSpotter
