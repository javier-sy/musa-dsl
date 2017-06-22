class Array
	def apply method_name, source
	
		source = [source] unless source.is_a? Array
		
		self.each_with_index do |o, i|
			o.send method_name, source[i % source.length]
		end
	end

	def get method_name
		self.collect { |o| o.send method_name }
	end
end

class Rational
	def inspect
		d = self - self.to_i
		if d != 0
			"#{self.to_i}(#{d.numerator}/#{d.denominator})"
		else
			"#{self.to_i}"
		end
	end

	alias to_s inspect
end

class Object
	def instance_exec_nice value_or_key_args = nil, key_args = nil, &block

		if !value_or_key_args.nil? && value_or_key_args.is_a?(Hash)
			key_args ||= {}
			key_args = key_args.merge value_or_key_args
			value_or_key_args = nil
		end

		if block.lambda?
			if !value_or_key_args.nil? && !value_or_key_args.empty?
				if !key_args.nil? && !key_args.empty?
					block.call *value_or_key_args, **key_args
				else
					block.call *value_or_key_args
				end
			else
				if !key_args.nil? && !key_args.empty?
					block.call **key_args
				else
					block.call
				end
			end
		else
			if !value_or_key_args.nil? && !value_or_key_args.empty?
				if !key_args.nil? && !key_args.empty?
					instance_exec *value_or_key_args, **key_args, &block
				else
					instance_exec *value_or_key_args, &block
				end
			else
				if !key_args.nil? && !key_args.empty?
					instance_exec **key_args, &block
				else
					instance_eval &block
				end
			end
		end
	end

	def send_nice method_name, *args, **key_args, &block
		if args && args.size > 0
			if key_args && key_args.size > 0
				send method_name, *args, **key_args, &block
			else
				send method_name, *args, &block
			end
		else
			if key_args && key_args.size > 0
				send method_name, **key_args, &block
			else
				send method_name, &block
			end
		end
	end
end