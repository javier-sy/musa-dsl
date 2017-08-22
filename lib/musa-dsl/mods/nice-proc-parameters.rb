class Proc
	def select_key_parameters(**hash)

		raise "Proc.select_key_parameters DEPRECATED"

		parameters = parameters.collect { |parameter| [ parameter[1], hash[parameter[1]] ] if parameter[0] == :key || parameter[0] == :keyreq }.compact.to_h

		if parameters.find { |parameter| parameter[0] == :keyrest }

			hash.each do |k, v|

				if !parameters[k]
					parameters[k] = v
				end
			end
		end

		parameters
	end

	def make_list_parameters(proc, **hash)
		raise "Proc.make_list_parameters DEPRECATED"

		proc.parameters.collect { |parameter| { parameter[1] => hash[parameter[1]] } if parameter[0] == :opt || parameter[0] == :req }.reduce({}, :update)
	end

	def find_hash_parameter(proc, parameter_name)
		raise "Proc.find_hash_parameter DEPRECATED"

		proc.parameters.find { |parameter| parameter[0] == :keyrest || parameter[1] == parameter_name && (parameter[0] == :key || parameter[0] == :keyreq) }
	end
end