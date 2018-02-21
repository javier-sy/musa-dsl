class KeyParametersProcedureBinder
	
	attr_reader :procedure

	def initialize procedure
		@procedure = procedure

		@parameters = {}
		@has_rest = false
		@value_parameters_count = 0

		procedure.parameters.each do |parameter| 
			@parameters[parameter[1]] = nil if parameter[0] == :key || parameter[0] == :keyreq
			@has_rest = true if parameter[0] == :keyrest

			@value_parameters_count += 1 if parameter[0] == :req || parameter[0] == :opt
		end
	end

	def call *value_parameters, **key_parameters
		_call value_parameters, key_parameters
	end

	def _call value_parameters, key_parameters

		effective_key_parameters = apply(key_parameters)

		if effective_key_parameters.empty?
			if value_parameters.nil? || value_parameters.empty? || @value_parameters_count == 0
				@procedure.call
			else
				@procedure.call *value_parameters.first(@value_parameters_count)
			end
		else
			if value_parameters.nil? || value_parameters.empty?
				@procedure.call **effective_key_parameters
			else
				@procedure.call *value_parameters, **effective_key_parameters
			end
		end
	end

	def has_key? key
		@has_rest || @parameters.include?(key)
	end

	def apply hsh
		hsh ||= {}

		result = @parameters.clone

		@parameters.each_key do |parameter_name|
			result[parameter_name] = hsh[parameter_name]
		end

		if @has_rest
			hsh.each do |key, value|
				result[key] = value unless result.key?(key)
			end
		end

		result
	end

	def inspect
		"KeyParametersProcedureBinder: parameters = #{@parameters} has_rest = #{@has_rest}"
	end

	alias to_s inspect
end
