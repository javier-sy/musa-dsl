module Musa::Neuma
	class ProtoDecoder
		
		def subcontext
			self
		end
		
		def decode element, following = nil
			raise NotImplementedError
		end
	end

	class DifferentialDecoder < ProtoDecoder
		def decode attributes, following = nil
			parse attributes
		end

		def parse attributes
			raise NotImplementedError
		end
	end

	class Decoder < DifferentialDecoder
		def initialize start
			@start = start.clone
			@last = start.clone
		end
		
		def subcontext
			Decoder.new @start
		end

		def decode attributes, following = nil
			result = apply parse(attributes), on: @last

			@last = result.clone unless result[:event] || result[:command]

			result
		end

		def apply action, on:
			raise NotImplementedError
		end
	end
end