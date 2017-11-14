require 'spec_helper'

require 'musa-dsl'

module Impl
	def parse _attributes
		case
		when _attributes.key?(:attributes)

			attributes = _attributes[:attributes].clone 

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

			command

		when _attributes.key?(:event)

			nil

		when _attributes.key?(:comment)

			nil
		else
			raise RuntimeError, "Not processable data #{_attributes}. Keys allowed are :attributes, :event and :comment"
		end
	end
end	

class X < Musa::Neuma::NeumaDecoder
	include Impl
end

class Y < Musa::Neuma::DifferentialNeumaDecoder
	include Impl

	def initialize 
		super nil
	end

	def apply action, on:
		action
	end
end

RSpec.describe Musa::Neuma do

	context "Neuma parsing" do
		p = X.new 

		it "Basic neuma inline parsing" do
			expect(Musa::Neuma.parse('2.3.4 5.6.7 :evento # comentario 1')).to eq(
				[{ attributes: ["2", "3", "4"] }, { attributes: ["5", "6", "7"] }, { event: "evento" }])

			expect(Musa::Neuma.parse('(2 3 4) (7 8 9) { esto es un comando complejo { con { xxx } subcomando  }  { y otro } } # comentario 2')).to eq(
				[{ attributes: ["2", "3", "4"] }, { attributes: ["7", "8", "9"] }, { command: "esto es un comando complejo { con { xxx } subcomando  }  { y otro } " }])
		end

		it "Basic neuma inline parsing with comment" do
			expect(Musa::Neuma.parse("# comentario (con parentesis) \n 2.3.4")).to eq([{ attributes: ["2", "3", "4"] }])
		end	

		it "Basic neuma inline parsing with decoder" do

			result = Musa::Neuma.parse '0 . +1 2.p 2.1/2.p # comentario 1', decode_with: p

			expect(result[0]).to eq({ abs_pitch: 0 })
			expect(result[1]).to eq({ })
			expect(result[2]).to eq({ delta_pitch: 1 })
			expect(result[3]).to eq({ abs_pitch: 2, abs_velocity: -1 })
			expect(result[4]).to eq({ abs_pitch: 2, abs_duration: Rational(1,2), abs_velocity: -1 })
			expect(result[5]).to eq(nil)
		end

		it "Basic neuma file parsing with decoder" do

			result = Musa::Neuma.parse_file File.join(File.dirname(__FILE__), "neuma_spec.neu"), decode_with: p

			expect(result[0]).to eq({ })
			expect(result[1]).to eq({ abs_pitch: 'II' })
			expect(result[2]).to eq({ delta_pitch: 1 })
			expect(result[3]).to eq({ abs_pitch: 2, abs_velocity: -1 })
			expect(result[4]).to eq({ abs_pitch: 2, abs_duration: Rational(1,2), abs_velocity: -1 })
			expect(result[5]).to eq(nil)
		end
	end
end
