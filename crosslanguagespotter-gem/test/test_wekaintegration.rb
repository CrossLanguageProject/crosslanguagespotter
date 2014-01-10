require 'test_helper'

class TestWekaIntegration < Test::Unit::TestCase

def setup
    @train_data = [
        {a: 10.0, b:7,  c:false},
        {a: 12.0, b:3,  c:false},
        {a: 18.4, b:-4, c:true}
    ]
    @sample_data = [
        {a: 10.5, b:6},
        {a: 12.1, b:2},
        {a: 21.4, b:-8}
    ]
    @sample_data2 = [
        {a: 10.5, b:6, c:false},
        {a: 12.1, b:2, c:false},
        {a: 21.4, b:-8, c:false}
    ]
end

def test_hash2weka_instances_with_train_data
    instances = hash2weka_instances('my_dataset',@train_data,{a: :numeric, b: :numeric, c: :boolean},:c)
end

def test_hash2weka_instances_with_data_to_classify
    instances = hash2weka_instances('my_dataset',@sample_data,{a: :numeric, b: :numeric},nil)
end

def test_build_classifier
    instances = hash2weka_instances('my_dataset',@train_data,{a: :numeric, b: :numeric, c: :boolean},:c)
    c = build_classifier(instances)
end

def test_classify    
    train_instances = hash2weka_instances('my_train_dataset',@train_data,{a: :numeric, b: :numeric, c: :boolean},:c)
    data_instances = hash2weka_instances('my_sample_dataset',@sample_data2,{a: :numeric, b: :numeric, c: :boolean},:c)
    classifier = WekaClassifier.new(train_instances)
    results = classifier.classify(data_instances)
    puts "Results: #{results}"
end

end