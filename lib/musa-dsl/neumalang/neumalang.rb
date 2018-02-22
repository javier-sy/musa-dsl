require 'citrus'

module Musa::Neumalang
	def self.register grammar_path
		Citrus.load grammar_path
	end

	def self.parse string_or_file, language: nil, decode_with: nil, debug: nil

		language ||= Neumalang

		match = nil

		if string_or_file.is_a? String
			match = language.parse string_or_file

		elsif string_or_file.is_a? File
			match = language.parse string_or_file.read

		else
			raise ArgumentError, 'Only String or File allowed to be parsed'
		end

		match.dump if debug

		list = match.value

		if decode_with
			plan = []

			until list.empty?
				plan << decode_with.decode(list.shift, list)
			end

			plan

		else
			list
		end
	end

	def self.parse_file filename, decode_with: nil, debug: nil
		File.open filename do |file|
			parse file, decode_with: decode_with, debug: debug
		end
	end

	register File.join(File.dirname(__FILE__), "neumalang")

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