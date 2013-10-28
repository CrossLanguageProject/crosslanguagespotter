require 'model_loading'
require 'set'

def collect_values_with_declarator(node)
	declarators_per_value = Hash.new {|h,k| h[k]=[]}
	self.class.ecore.eAllAttributes.each do |a|
		v = self.send(:"#{a.name}")
		if v!=nil
			if a.many
				v.each {|el| values[el]+=1}
			else
				values[v]+=1
			end
		end
	end
	values			
end

class Context

	attr_reader :sequence_of_values

	def initialize
		@map = Hash.new {|h,k| h[k]=[]}
		@sequence_of_values = []
		@register_sequence = []
	end

	def values
		@map.keys.select {|k| @map[k].count>0}
	end

	def count
		values.count
	end

	def has_value?(v)
		values.include?(v)
	end

	def declarators_per_value(value)
		@map[value]
	end

	def sequence_of_values
		@sequence_of_values
	end

	def register(value,declarator)
		@sequence_of_values << value
		@map[value] << declarator unless @map[value].include?(declarator)
		@register_sequence << {value:value, declarator:value}
	end

	def merge(other)
		other.values.each do |v|
			other.declarators_per_value(v).each do |d|
				register(v,d)
			end
		end
	end

	def clone
		new_instance = Context.new
		@register_sequence.each do |r|
			new_instance.register(r[:value],r[:declarator])
		end
		new_instance
	end

	def intersection(values)
		new_instance = self.clone
		new_instance.intersection!(values)
		new_instance
	end

	def intersection!(values)
		@map.keys.each do |k|
			if values.is_a? Array
				@map[k] = [] unless values.include?(k)
			elsif values.is_a? Context
				if values.has_value?(k)
					@map[k].concat(values.declarators_per_value(k))
				else
					@map[k] = []
				end
			else
				raise "error"
			end				
		end
		self
	end

	def count
		values.count
	end

	def to_a
		a = []
		values.sort.each do |v|
			a << {value:v,declarators:declarators_per_value(v)}
		end
		a
	end

	def to_s
		to_a.to_s
	end

end

def context(node)
	ctx = Context.new
	container = node.container_also_foreign
	if container
		ctx.merge(context(container))

		# RGen attributes of the father
		container.collect_values_with_count.keys.each do |value|
			ctx.register(value,container)
		end

		# siblings in different containment reference
		container.all_children_also_foreign.each do |sibling|
			if (sibling.eContainingFeature!=node.eContainingFeature) || (node.eContainingFeature==nil && node!=sibling)
				sibling.traverse(:also_foreign) do |n|
					n.collect_values_with_count.keys.each do |value|
						ctx.register(value,n)
					end
				end				
			end
		end		
	end
	ctx
end

