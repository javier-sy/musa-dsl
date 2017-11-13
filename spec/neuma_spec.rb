require 'spec_helper'

require 'musa-dsl'
require 'citrus'

module Musa::Neuma
end

class Processor
	def initialize start
		@last = start
	end

	def process item
		element = @last.clone

		attributes = item.split('.')

		action = parse attributes

		element = apply action, on: element

		@last = element

		element.clone
	end

	def parse attributes
		raise NotImplementedError
	end

	def apply action, on:
		raise NotImplementedError
	end
end

class X < Processor

	def initialize scale, start
		super start
		@scale = scale
	end

	def parse _attributes

		attributes = _attributes.clone

		command = {}

		pitch = attributes.shift

		if pitch && !pitch.empty?
			if pitch[0] == '+' || pitch[0] == '-'
				command[:delta_pitch] = pitch.to_i
			else
				command[:abs_pitch] = pitch.to_i
			end
		end

		velocity = attributes.find { |a| /\A (mp | mf | (\+|\-)?(p+|f+)) \Z/x.match a }


		if velocity
			if velocity[0] == '+' || velocity[0] == '-'
				command[:delta_velocity] = (velocity[1] == 'f' ? 1 : -1) * (velocity.length - 1) * (velocity[0] + '1').to_i
			elsif 
				if velocity[0] == 'm'
					command[:abs_velocity] = (velocity[1] == 'f') ? 1 : -1
				else
					command[:abs_velocity] = velocity.length * (velocity[1] == 'f' ? 1 : -1)
				end
			end
				
			attributes.delete velocity
		end

		duration = attributes.shift

		if duration
			if duration[0] == '+' || duration[0] == '-'
				command[:delta_duration] = duration.to_r
			
			elsif duration[0] == '*'
				command[:factor_duration] = duration[1..-1].to_r
			
			else
				command[:abs_duration] = duration.to_r
			end
		end

		puts "X.parse #{_attributes} = #{command}"

		command
	end

	def apply action, on:
		action
	end
end




RSpec.describe Musa::Neuma do

	context "Easy series unmarshalling" do
		it "Basic parsing" do

			source = File.read File.join(File.dirname(__FILE__), "neuma_spec.neu")


			elements = (source.split /\n/).collect { |line| line.split('#')[0] }.compact.collect { |line_nc| line_nc.split }.flatten


			p = X.new nil, [1, 1, 1]


			elements = elements.collect { |x| p.process x }



			expect(elements).to eq ["hola"]
		end


		it "Parsing with citrus" do
			Citrus.load File.join(File.dirname(__FILE__), "../lib/musa-dsl/neuma/neuma")

			puts "Neuma.parse('1.2.3 4.5.6 # comment') = #{Neuma.parse('1.2.3 4.5.6 # comment').value}"

			expect(Neuma.parse('1.2.3 4.5.6 # comment')).to eq '1.2.3 4.5.6 # comment'

			expect(Neuma.parse('1.2.3 (4 5 6) (6 7 8) # comment')).to eq '1.2.3 (4 5 6) (6 7 8) # comment'

			expect(Neuma.parse('1.2.3 (4 5 6) :hola { que tal } # comment')).to eq '1.2.3 (4 5 6) :hola { que tal } # comment'

		end

	end
end
