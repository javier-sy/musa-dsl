require 'musa-dsl/neuma/neuma'

module Musa::Neuma
	module GDV
		module Implementation
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

		private_constant :Implementation

		class Decoder < Musa::Neuma::Decoder
			include Implementation
		end

		class DifferentialDecoder < Musa::Neuma::DifferentialDecoder
			include Implementation

			def initialize scale, base = nil
				base ||= { grade: 0, duration: Rational(1,4), velocity: 1 }

				@scale = scale

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
					r = { duration: 0, event: action[:event] }
				end

				r
			end

			def to_midi_note_on_or_event **gdv
				r = {}

				if gdv[:grade]
					r[:pitch] = @scale.pitch_of gdv[:grade]
				end

				if gdv[:duration]
					r[:duration] = gdv[:duration]
				end

				if gdv[:velocity]
					# ppp = 16 ... fff = 127
					r[:velocity] = [16, 32, 48, 64, 80, 96, 112, 127][gdv[:velocity] + 3]
				end

				if gdv[:event]
					r[:event] = gdv[:event]
				end

				r
			end
		end

	end
end	

