require 'citrus'

module Musa::Neuma
	Citrus.load File.join(File.dirname(__FILE__), "neuma")

	def self.parse string_or_file
		match = nil

		if string_or_file.is_a? String
			match = Neuma.parse string_or_file
		elsif string_or_file.is_a? File
			match = Neuma.parse string_or_file.read
		else
			raise ArgumentError, 'Only String or File allowed to be parsed'
		end

		match.value
	end

	def self.load filename
		File.open filename do |file|
			parse file
		end
	end
end

