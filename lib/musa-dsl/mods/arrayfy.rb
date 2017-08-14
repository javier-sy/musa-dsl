class Object
	def arrayfy
		[self]
	end
end

class Array
	def arrayfy
		self
	end

	def repeat_to_size(new_size)
		pos = -1
		new_size -= 1

		new_array = []
		new_array << self[(pos += 1) % size] while (pos + size) < new_size


puts "repeat_to_size: self = #{self} new_array = #{new_array}"

		new_array
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
