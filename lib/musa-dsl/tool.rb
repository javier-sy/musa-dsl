module Musa
	module Tool
		def self.grant_array(object_or_array)
			if object_or_array.is_a? Array
				object_or_array.dup
			else
				[object_or_array]
			end
		end

		def self.fill_with_repeat_array(array, size)
			pos = -1
			size -= 1

			osize = array.size
			
			array << array[(pos += 1) % osize] while (pos + osize) < size

			array
		end

		def self.explode_ranges_on_array(array)
			r = []

			array.each do |element|
				if element.is_a? Range
					element.to_a.each { |element| r << element }
				else
					r << element
				end
			end

			r
		end

		def self.make_array_of(object_range_or_array)
			object_range_or_array = [object_range_or_array] unless object_range_or_array.is_a?(Array)

			r = []

			object_range_or_array.each do |element|
				if element.is_a? Range
					element.to_a.each { |element| r << element }
				else
					r << element
				end
			end

			r
		end

		def self.make_hash_key_parameters(proc, **hash)

			parameters = proc.parameters.collect { |parameter| [ parameter[1], hash[parameter[1]] ] if parameter[0] == :key || parameter[0] == :keyreq }.compact.to_h

			if proc.parameters.find { |parameter| parameter[0] == :keyrest }

				hash.each do |k, v|

					if !parameters[k]
						parameters[k] = v
					end
				end
			end

			parameters
		end

		def self.make_list_parameters(proc, **hash)
			proc.parameters.collect { |parameter| { parameter[1] => hash[parameter[1]] } if parameter[0] == :opt || parameter[0] == :req }.reduce({}, :update)
		end

		def self.find_hash_parameter(proc, parameter_name)
			proc.parameters.find { |parameter| parameter[0] == :keyrest || parameter[1] == parameter_name && (parameter[0] == :key || parameter[0] == :keyreq) }
		end

		def self.list_of_hashes_product(list_of_hashes_1, list_of_hashes_2)
			result = []

			list_of_hashes_1.each do |hash1|
				list_of_hashes_2.each do |hash2|
					result << hash1.merge(hash2)
				end
			end

			result
		end
	end
end