require 'citrus'

module Musa::Neuma
	def self.register grammar_path
		Citrus.load grammar_path
	end

	def self.parse string_or_file, language: nil, decode_with: nil

		language ||= Neuma

		match = nil

		if string_or_file.is_a? String
			match = language.parse string_or_file

		elsif string_or_file.is_a? File
			match = language.parse string_or_file.read

		else
			raise ArgumentError, 'Only String or File allowed to be parsed'
		end

		if decode_with
			match.value.collect { |v| decode_with.decode v }
		else
			match.value
		end
	end

	def self.parse_file filename, decode_with: nil
		File.open filename do |file|
			parse file, decode_with: decode_with
		end
	end

	register File.join(File.dirname(__FILE__), "neuma")

	class NeumaDecoder
		def decode attributes
			parse attributes
		end

		def parse attributes
			raise NotImplementedError
		end
	end

	class DifferentialNeumaDecoder < NeumaDecoder
		def initialize start
			@last = start
		end

		def decode attributes
			element = @last.clone

			action = parse attributes

			element = apply action, on: element

			@last = element

			element.clone
		end

		def apply action, on:
			raise NotImplementedError
		end
	end
end