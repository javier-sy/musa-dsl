require 'musa-dsl/transport/clock'
require 'nibbler'

module Musa
	class DummyClock < Clock
		def initialize ticks
			super()

			@ticks = ticks
		end

		def run
			@run = true

			while @run && @ticks > 0
				yield if block_given?
				@ticks -= 1

				Thread.pass
			end
		end

		def terminate
			@run = false
		end
	end
end