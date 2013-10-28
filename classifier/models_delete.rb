require 'bundler'
Bundler.setup
require 'js-lightmodels'
include LightModels

project_dirs = ['../projects/angular-puzzle']
project_dirs.each do |root|	
	models_dir = File.join(root,'models')
	Dir["#{models_dir}/*"].each {|f| FileUtils.rm_rf(f) }	
end