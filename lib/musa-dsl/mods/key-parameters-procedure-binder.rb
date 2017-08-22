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

	def call hash
		@procedure.call apply(hash)
	end

	def has_key? key
		@has_rest || @parameters.include?(key)
	end

	def apply hash
		result = @parameters.clone

		@parameters.each_key do |parameter_name|
			result[parameter_name] = hash[parameter_name]
		end

		if @has_rest
			hash.each do |key, value|
				result[key] = value unless result.key? key
			end
		end

		result
	end
end
