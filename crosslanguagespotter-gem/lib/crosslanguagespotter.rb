# encoding: utf-8

curr_dir = File.dirname(__FILE__)

Dir["#{curr_dir}/crosslanguagespotter/*.rb"].each { |rb| require rb }
