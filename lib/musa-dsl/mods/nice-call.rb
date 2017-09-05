class Proc
	def call_nice value_or_key_args = nil, key_args = nil

		raise "Proc.call_nice: DEPRECATED"
		
		if !value_or_key_args.nil? && !value_or_key_args.empty?
			if !key_args.nil? && !key_args.empty?
				call *value_or_key_args, **key_args
			else
				call *value_or_key_args
			end
		else
			if !key_args.nil? && !key_args.empty?
				call **key_args
			else
				call
			end
		end
	end
end