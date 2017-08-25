# TODO hacer que *_nice permitar recibir atributos para indicar cómo se quieren procesar los parámetros (haciendo *, **, o sin hacer nada)

class Object
	def as_context_run value_or_key_args = nil, key_args = nil, parameter: nil, &proc
		if parameter
			self.instance_exec parameter, &proc
		else
			if !value_or_key_args.nil? && value_or_key_args.is_a?(Hash)
				key_args ||= {}
				key_args = key_args.merge value_or_key_args
				value_or_key_args = nil
			end

			if proc.lambda?
				if !value_or_key_args.nil? && !value_or_key_args.empty?
					if !key_args.nil? && !key_args.empty?
						proc.call *value_or_key_args, **key_args
					else
						proc.call *value_or_key_args
					end
				else
					if !key_args.nil? && !key_args.empty?
						proc.call **key_args
					else
						proc.call
					end
				end
			else
				if !value_or_key_args.nil? && !value_or_key_args.empty?
					if !key_args.nil? && !key_args.empty?
						self.instance_exec *value_or_key_args, **key_args, &proc
					else
						self.instance_exec *value_or_key_args, &proc
					end
				else
					if !key_args.nil? && !key_args.empty?
						self.instance_exec **key_args, &proc
					else
						self.instance_eval &proc
					end
				end
			end
		end
	end

	def instance_exec_nice value_or_key_args = nil, key_args = nil, &block

		# TODO raise "DEPRECATED Object.instance_exec_nice, use Object.as_context_run"

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
					self.instance_exec *value_or_key_args, **key_args, &block
				else
					self.instance_exec *value_or_key_args, &block
				end
			else
				if !key_args.nil? && !key_args.empty?
					self.instance_exec **key_args, &block
				else
					self.instance_eval &block
				end
			end
		end
	end
end