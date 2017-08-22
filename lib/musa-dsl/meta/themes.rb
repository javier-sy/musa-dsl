require 'musa-dsl/mods/nice-send'
require 'musa-dsl/sequencer/sequencer'

module Musa
	class Theme
		def initialize(context)
			@_context = context
		end

		def at_position(p, **parameters)
			p
		end

		def run
		end

		private

		def method_missing(method_name, *args, **key_args, &block)
			if @_context.respond_to? method_name

				# TODO optimizar esta búsqueda / cachearla
				if Sequencer.method_defined?(method_name) && Sequencer.instance_method(method_name).parameters.find {|a| a[1] == :context }
					@_context.send_nice method_name, *args, context: self, **key_args, &block
				else
					@_context.send_nice method_name, *args, **key_args, &block
				end
			else
				super
			end
		end

		def respond_to_missing?(method_name, include_private)
			@_context.respond_to?(method_name, include_private) || super
		end
	end
end