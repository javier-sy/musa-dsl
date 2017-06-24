class Array
	def deep_clone
		self.collect { |element| element.deep_clone if !element.nil? }
	end
end

class Hash
	def deep_clone
		result = {}
		
		self.each { |key, value| result[key.deep_clone] = value.deep_clone }
		
		result
	end
end	

class Object
	def deep_clone
		self.clone
	end
end