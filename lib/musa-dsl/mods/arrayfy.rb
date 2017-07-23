class Object
	def arrayfy
		[self]
	end
end

class Array
	def arrayfy
		self
	end

	def repeat_to_size(size)
		pos = -1
		size -= 1

		osize = self.size
		
		array = []
		array << self[(pos += 1) % osize] while (pos + osize) < size

		array
	end


	def explode_ranges
		array = []

		each do |element|
			if element.is_a? Range
				element.to_a.each { |element| array << element }
			else
				array << element
			end
		end

		array
	end
end
