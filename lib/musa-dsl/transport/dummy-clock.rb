require 'musa-dsl/transport/clock'
require 'nibbler'

module Musa
	class DummyClock < Clock
		def initialize ticks = nil, &block
			super()

			raise ArgumentError, 'Cannot initialize with ticks and block. You can only use one of the parameters.' if ticks && block

			@ticks = ticks
			@block = block
		end

		def run
			@run = true

			while @run && eval_condition
				yield if block_given?

				Thread.pass
			end
		end

		def terminate
			@run = false
		end
		
		private
		
		def eval_condition
			if @ticks
				@ticks -= 1
				@ticks > 0
			else
				@block.call
			end
		end
	end
end