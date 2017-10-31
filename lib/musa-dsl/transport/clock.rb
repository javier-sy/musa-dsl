require 'nibbler'

module Musa
	class Clock
		def initialize
			@on_start = []
			@on_stop = []
			@on_song_position_pointer = []
		end

		def on_start &block
			@on_start << block
		end

		def on_stop &block
			@on_stop << block
		end

		def on_song_position_pointer &block
			@on_song_position_pointer << block
		end

		def run
			raise NotImplementedError
		end

		def terminate
			raise NotImplementedError
		end
	end
end