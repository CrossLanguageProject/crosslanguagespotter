# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'crosslanguagespotter/version'

Gem::Specification.new do |s|
  s.platform    = 'java'
  s.name        = 'crosslanguagespotter'
  s.version     = CrossLanguageSpotter::VERSION
  s.summary     = "Automatic Spotter of Cross-Language references"
  s.description = "Automatic Spotter of Cross-Language references"
  s.authors     = ["Federico Tomassetti"]
  s.email       = 'f.tomassetti@gmail.com'
  s.homepage    = 'https://github.com/CrossLanguageProject/crosslanguagerelationsspotter'
  s.license     = "Apache v2"

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_dependency('codemodels')
  s.add_dependency('codemodels-js')
  s.add_dependency('codemodels-html')
  s.add_dependency('codemodels-java')
  s.add_dependency('codemodels-ruby')
  s.add_dependency('codemodels-xml')
  s.add_dependency('codemodels-properties')
  s.add_dependency('htmlentities')
  s.add_dependency('liquid')

  s.add_development_dependency "bundler"
  s.add_development_dependency "rake"  
  s.add_development_dependency "simplecov"
  s.add_development_dependency "rubygems-tasks"  
end
