class Object
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