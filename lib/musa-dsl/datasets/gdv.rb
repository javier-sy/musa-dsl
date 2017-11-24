require 'musa-dsl/neuma/neuma'

module Musa::Dataset
	module GDVd
		def to_neuma
			attributes = []

			if self[:abs_grade]
				attributes[0] = self[:abs_grade].to_s

			elsif self[:delta_grade]
				attributes[0] = self[:abs_grade].to_s
			end

			

		end
	end

	module GDV
		include GDVd

		def to_pdve scale
			r = {}

			if self[:grade]
				r[:pitch] = scale.pitch_of self[:grade]
			end

			if self[:duration]
				r[:duration] = self[:duration]
			end

			if self[:velocity]
				# ppp = 16 ... fff = 127
				r[:velocity] = [16, 32, 48, 64, 80, 96, 112, 127][self[:velocity] + 3]
			end

			if self[:event]
				r[:event] = self[:event]
			end

			r.extend Musa::Dataset::PDV
		end

		def diff_to previous = nil, scale:

			r = {}

			if previous
				if self[:grade] && previous[:grade] && (self[:grade] != previous[:grade])
					r[:delta_grade] = scale.note_of(self[:grade]) - scale.note_of(previous[:grade])
				end
			else
				r[:abs_grade] = self[:grade] if self[:grade]
			end

			if previous
				if self[:duration] && previous[:duration] && (self[:duration] != previous[:duration])
					r[:delta_duration] = self[:duration] - previous[:duration]
				end
			else
				r[:abs_duration] = self[:duration] if self[:duration]
			end

			if previous
				if self[:velocity] && previous[:velocity] && (self[:velocity] != previous[:velocity])
					r[:delta_velocity] = self[:velocity] - previous[:velocity]
				end
			else
				r[:abs_velocity] = self[:velocity] if self[:velocity]
			end

			if self[:event]
				r[:event] = self[:event]
			end

			r.extend Musa::Dataset::GDVd
		end

		module Parser
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

		private_constant :Parser

		class NeumaDecoder < Musa::Neuma::Decoder
			include Parser
		end

		class NeumaDifferentialDecoder < Musa::Neuma::DifferentialDecoder
			include Parser

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
		end
	end
end	

