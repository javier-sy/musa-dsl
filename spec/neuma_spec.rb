require 'spec_helper'

require 'musa-dsl'

module Musa::Neuma::GradeDurationVelocityDecoderImpl
	def parse _attributes
		case
		when _attributes.key?(:attributes)

			attributes = _attributes[:attributes].clone 

			command = {}

			grade = attributes.shift

			if grade && !grade.empty?
				if grade[0] == '+' || grade[0] == '-'
					command[:delta_grade] = grade.to_i
				else
					if grade.match /^[+-]?[0-9]+$/
						command[:abs_grade] = grade.to_i
					else 
						command[:abs_grade] = grade.to_sym
					end
				end
			end

			velocity = attributes.find { |a| /\A (mp | mf | (\+|\-)?(p+|f+)) \Z/x.match a }

			if velocity
				if velocity[0] == '+' || velocity[0] == '-'
					command[:delta_velocity] = (velocity[1] == 'f' ? 1 : -1) * (velocity.length - 1) * (velocity[0] + '1').to_i
				elsif 
					if velocity[0] == 'm'
						command[:abs_velocity] = (velocity[1] == 'f') ? 1 : 0
					else
						command[:abs_velocity] = velocity.length * (velocity[0] == 'f' ? 1 : -1) + (velocity[0] == 'f' ? 1 : 0)
					end
				end
					
				attributes.delete velocity
			end

			duration = attributes.shift

			if duration && !duration.empty?
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

			{ event: _attributes[:event] }

		else
			raise RuntimeError, "Not processable data #{_attributes}. Keys allowed are :attributes, :event and :comment"
		end
	end
end	

class GDVDecoder < Musa::Neuma::Decoder
	include Musa::Neuma::GradeDurationVelocityDecoderImpl
end

class GDVDifferentialDecoder < Musa::Neuma::DifferentialDecoder
	include Musa::Neuma::GradeDurationVelocityDecoderImpl

	def initialize scale, base = nil, &event_handler
		base ||= { grade: 0, duration: Rational(1,4), velocity: 1 }

		@scale = scale
		@event_handler = event_handler

		super base
	end

	def apply action, on:

		r = on

		if action[:abs_grade]
			on[:grade] = @scale.note_of action[:abs_grade]
		end

		if action[:delta_grade]
			on[:grade] = @scale.note_of on[:grade] + action[:delta_grade]
		end

		if action[:abs_duration]
			on[:duration] = action[:abs_duration]
		end

		if action[:delta_duration]
			on[:duration] += action[:delta_duration]
		end

		if action[:factor_duration]
			on[:duration] *= action[:factor_duration]
		end

		if action[:abs_velocity]
			on[:velocity] = action[:abs_velocity]
		end

		if action[:delta_velocity]
			on[:velocity] += action[:delta_velocity]
		end

		if action[:event]
			r = @event_handler.call action[:event] if @event_handler
		end

		r
	end
end

RSpec.describe Musa::Neuma do

	context "Neuma parsing" do

		it "Basic neuma inline parsing" do
			expect(Musa::Neuma.parse('2.3.4 5.6.7 :evento # comentario 1')).to eq(
				[{ attributes: ["2", "3", "4"] }, { attributes: ["5", "6", "7"] }, { event: :evento }])

			expect(Musa::Neuma.parse('(2 3 4) (7 8 9) { esto es un comando complejo { con { xxx } subcomando  }  { y otro } } # comentario 2')).to eq(
				[{ attributes: ["2", "3", "4"] }, { attributes: ["7", "8", "9"] }, { command: "esto es un comando complejo { con { xxx } subcomando  }  { y otro } " }])
		end

		it "Basic neuma inline parsing with comment" do
			expect(Musa::Neuma.parse("# comentario (con parentesis) \n 2.3.4")).to eq([{ attributes: ["2", "3", "4"] }])
		end	

		it "Basic neuma inline parsing only duration" do

			result = Musa::Neuma.parse '0 .1/2'

			expect(result[0]).to eq({ attributes: ["0"] })
			expect(result[1]).to eq({ attributes: [nil, "1/2"] })
		end

		decoder = GDVDecoder.new 

		it "Basic neuma inline parsing with decoder" do

			result = Musa::Neuma.parse '0 . +1 2.p 2.1/2.p # comentario 1', decode_with: decoder

			expect(result[0]).to eq({ abs_grade: 0 })
			expect(result[1]).to eq({ })
			expect(result[2]).to eq({ delta_grade: 1 })
			expect(result[3]).to eq({ abs_grade: 2, abs_velocity: -1 })
			expect(result[4]).to eq({ abs_grade: 2, abs_duration: Rational(1,2), abs_velocity: -1 })
		end

		it "Basic neuma file parsing with decoder" do

			result = Musa::Neuma.parse_file File.join(File.dirname(__FILE__), "neuma_spec.neu"), decode_with: decoder

			c = -1

			expect(result[c+=1]).to eq({ })
			expect(result[c+=1]).to eq({ abs_grade: :II })
			expect(result[c+=1]).to eq({ abs_grade: :I, abs_duration: Rational(2) })
			expect(result[c+=1]).to eq({ abs_grade: :I, abs_duration: Rational(1,2) })
			expect(result[c+=1]).to eq({ abs_grade: :I, abs_velocity: -1 })
			
			expect(result[c+=1]).to eq({ abs_grade: 0 })
			expect(result[c+=1]).to eq({ abs_grade: 0, abs_duration: Rational(1) })
			expect(result[c+=1]).to eq({ abs_grade: 0, abs_duration: Rational(1,2) })
			expect(result[c+=1]).to eq({ abs_grade: 0, abs_velocity: 4 })

			expect(result[c+=1]).to eq({ abs_grade: 0 })
			expect(result[c+=1]).to eq({ abs_grade: 1 })
			expect(result[c+=1]).to eq({ abs_grade: 2, abs_velocity: -1 })
			expect(result[c+=1]).to eq({ abs_grade: 2, abs_duration: Rational(1,2), abs_velocity: 3 })

			expect(result[c+=1]).to eq({ abs_grade: 0 })
			expect(result[c+=1]).to eq({ })
			expect(result[c+=1]).to eq({ delta_grade: 1 })
			expect(result[c+=1]).to eq({ delta_duration: Rational(1,2) })
			expect(result[c+=1]).to eq({ factor_duration: Rational(1,2) })
			expect(result[c+=1]).to eq({ abs_velocity: -1 })
			expect(result[c+=1]).to eq({ delta_velocity: 1 })

			expect(result[c+=1]).to eq({ event: :evento })

			expect(result[c+=1]).to eq({ delta_grade: -1 })
		end

		it "Basic neuma file parsing with differential decoder" do

			scale = Musa::Scales.get :major

			differential_decoder = GDVDifferentialDecoder.new(scale, { grade: 0, duration: 1, velocity: 1 }) { |event| { evento: event } }

			result = Musa::Neuma.parse_file File.join(File.dirname(__FILE__), "neuma_spec.neu"), decode_with: differential_decoder

			c = -1

			expect(result[c+=1]).to eq({ grade: 0, duration: 1, velocity: 1 })
			expect(result[c+=1]).to eq({ grade: 1, duration: 1, velocity: 1 })
			expect(result[c+=1]).to eq({ grade: 0, duration: 2, velocity: 1 })
			expect(result[c+=1]).to eq({ grade: 0, duration: Rational(1,2), velocity: 1 })
			expect(result[c+=1]).to eq({ grade: 0, duration: Rational(1,2), velocity: -1 })

			expect(result[c+=1]).to eq({ grade: 0, duration: Rational(1,2), velocity: -1 })
			expect(result[c+=1]).to eq({ grade: 0, duration: Rational(1), velocity: -1 })
			expect(result[c+=1]).to eq({ grade: 0, duration: Rational(1,2), velocity: -1 })
			expect(result[c+=1]).to eq({ grade: 0, duration: Rational(1,2), velocity: 4 })

			expect(result[c+=1]).to eq({ grade: 0, duration: Rational(1,2), velocity: 4 })
			expect(result[c+=1]).to eq({ grade: 1, duration: Rational(1,2), velocity: 4 })
			expect(result[c+=1]).to eq({ grade: 2, duration: Rational(1,2), velocity: -1 })
			expect(result[c+=1]).to eq({ grade: 2, duration: Rational(1,2), velocity: 3 })

			expect(result[c+=1]).to eq({ grade: 0, duration: Rational(1,2), velocity: 3 })
			expect(result[c+=1]).to eq({ grade: 0, duration: Rational(1,2), velocity: 3 })
			expect(result[c+=1]).to eq({ grade: 1, duration: Rational(1,2), velocity: 3 })
			expect(result[c+=1]).to eq({ grade: 1, duration: Rational(1), velocity: 3 })
			expect(result[c+=1]).to eq({ grade: 1, duration: Rational(1,2), velocity: 3 })
			expect(result[c+=1]).to eq({ grade: 1, duration: Rational(1,2), velocity: -1 })
			expect(result[c+=1]).to eq({ grade: 1, duration: Rational(1,2), velocity: 0 })
			
			expect(result[c+=1]).to eq({ evento: :evento })

			expect(result[c+=1]).to eq({ grade: 0, duration: Rational(1,2), velocity: 0 })
		end
	end
end
