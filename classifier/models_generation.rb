require 'bundler'
Bundler.setup
require 'js-lightmodels'
require 'html-lightmodels'
include LightModels

project_dirs = ['../projects/angular-puzzle']
project_dirs.each do |root|
	src = File.join(root,'original_repo')
	dest = File.join(root,'models')
	Js.generate_models_in_dir(src,dest)
	Html.generate_models_in_dir(src,dest)
end