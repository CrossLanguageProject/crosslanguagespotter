# encoding: utf-8

require "codemodels"
require "codemodels/html"
require "codemodels/js"

module CrossLanguageSpotter

    def self._load_models(dir,base_path='',models={})
        Dir.foreach(dir) do |f| 
            if f!='.' and f!='..'
                path = dir+'/'+f
                if File.directory?(path)
                    _load_models(path,base_path+'/'+dir,models)
                else
                    begin
                        models[base_path+'/'+f] = CodeModels.parse_file(path)
                    rescue Exception => e
                        puts "No model available for #{path}: #{e}"
                    end
                end
            end
        end
        return models
    end
  
    class Spotter

        def find_relations(dir)

        end

    end

end