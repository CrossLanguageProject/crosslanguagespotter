require 'test_helper'
require 'codemodels'
require 'codemodels/xml'
require 'codemodels/properties'
require 'codemodels/html'
require 'codemodels/js'

class TestParsing < Test::Unit::TestCase

def setup
end

def test_parse_html_file
	root = CodeModels.parse_file('./test/data/example.html')
	assert root.is_a?(CodeModels::Html::HtmlDocument)
end

def test_parse_js_file
    root = CodeModels.parse_file('./test/data/example.js')
    assert root.is_a?(CodeModels::Js::AstRoot)
end

end