class KeyParametersProcedureBinder
	
	attr_reader :procedure

	def initialize procedure
		@procedure = procedure

		@parameters = {}
		@has_rest = false

		procedure.parameters.each do |parameter| 
			@parameters[parameter[1]] = nil if parameter[0] == :key || parameter[0] == :keyreq
			@has_rest = true if parameter[0] == :keyrest
		end
	end

	def call *value_parameters, **key_parameters
		@procedure.call *value_parameters, **apply(key_parameters)
	end

	def has_key? key
		@has_rest || @parameters.include?(key)
	end

	def apply hsh
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
