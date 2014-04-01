require 'java'

module CrossLanguageSpotter

# Initialize a RandomTree classifier using the given
# instances
# TODO make it a private method of WekaClassifier
def build_classifier(training_instances)
    c = Java::weka::classifiers::trees::RandomTree.new
    c.build_classifier(training_instances)
    c
end

class WekaClassifier

    def initialize(training_instances)
        @weka_classifier = build_classifier(training_instances)
    end

    def classify(data_instances)
        results = []
        data_instances.enumerate_instances.each do |instance|
            #puts "Classifying #{instance}"
            r = @weka_classifier.classify_instance(instance)
            puts "Result: #{r} #{instance}"
            results.push({result: r==0.0, instance: instance})
        end
        return results
    end

end

# TODO: make it a private method of WekaClassifier
def hash2weka_instances(name,data,keys,class_value)
    boolean_values = Java::weka::core::FastVector.new
    boolean_values.add_element("true")
    boolean_values.add_element("false")

    # fill attributes
    attributes = Java::weka::core::FastVector.new
    attributes_map = {}
    attributes_indexes = {}
    i = 0    
    keys.each do |k,v|
        raise "Null key in keys: #{keys}" unless k
        raise "Null value for key #{k} in keys: #{keys}" unless v!=nil
        if v==:numeric
            # creates a numeric attribute
            a = Java::weka::core::Attribute.new(k.to_s)
        elsif v==:boolean
            a = Java::weka::core::Attribute.new(k.to_s,boolean_values)
        else
            raise "Unknown attribute type: #{v}"
        end
        attributes.add_element(a)
        attributes_map[k] = a
        attributes_indexes[k] = i
        i+=1
    end
    instances = Java::weka::core::Instances.new name, attributes, data.count

    # fill instances
    data.each do |row|
        instance = Java::weka::core::Instance.new keys.count
        keys.each do |k,v|
            a = attributes_map[k]
            if v==:numeric
                instance.setValue(a,row[k])
            elsif v==:boolean
                instance.setValue(a,row[k].to_s)
            else
                raise "Unknown attribute type: #{v}"
            end
        end
        instances.add(instance)
    end

    if class_value
        puts "Setting classIndex #{attributes_indexes[class_value]}"
        instances.setClassIndex(attributes_indexes[class_value])
    end

    #puts instances.to_s

    return instances
end

end
