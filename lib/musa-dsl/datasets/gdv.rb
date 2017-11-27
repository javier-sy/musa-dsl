require 'musa-dsl/neuma/neuma'

module Musa::Dataset

	module GDVd # abs_grade abs_octave delta_grade abs_duration delta_duration factor_duration abs_velocity delta_velocity event command

		def to_gdv scale, previous:

			r = previous.clone.extend GDV

			if self[:abs_grade]
				r[:grade] = scale.note_of self[:abs_grade]
			elsif self[:delta_grade]
				r[:grade] = scale.note_of r[:grade] + self[:delta_grade]
			end

			if self[:abs_octave]
				r[:octave] = self[:abs_octave]
			elsif self[:delta_octave]
				r[:octave] += self[:delta_octave]
			end

			if self[:abs_duration]
				r[:duration] = self[:abs_duration]
			elsif self[:delta_duration]
				r[:duration] += self[:delta_duration]
			elsif self[:factor_duration]
				r[:duration] *= self[:factor_duration]
			end

			if self[:abs_velocity]
				r[:velocity] = self[:abs_velocity]
			elsif self[:delta_velocity]
				r[:velocity] += self[:delta_velocity]
			end

			if self[:event]
				r = { duration: 0, event: self[:event] }
			elsif self[:command]
				r = { duration: 0, command: self[:command] }
			end

			r
		end

		def to_neuma mode = nil
			mode ||= :dotted # :parenthesis

			if self[:event]
				':' + self[:event].to_s

			elsif self[:command]
				'{ ' + self[:command] + ' }'

			else
				attributes = []

				c = 0

				if self[:abs_grade]
					attributes[c] = self[:abs_grade].to_s
				elsif self[:delta_grade] && self[:delta_grade] != 0
					attributes[c] = positive_sign_of(self[:delta_grade]) + self[:delta_grade].to_s
				end

				if self[:abs_octave]
					attributes[c+=1] = 'o' + self[:abs_octave].to_s
				elsif self[:delta_octave] && self[:delta_octave] != 0
					attributes[c+=1] = sign_of(self[:delta_octave]) + 'o' + self[:delta_octave].abs.to_s
				end

				if self[:abs_duration]
					attributes[c+=1] = self[:abs_duration].to_s
				elsif self[:delta_duration]
					attributes[c+=1] = positive_sign_of(self[:delta_duration]) + self[:delta_duration].to_s
				elsif self[:factor_duration]
					attributes[c+=1] = '*' + self[:factor_duration].to_s
				end

				if self[:abs_velocity]
					attributes[c+=1] = velocity_of(self[:abs_velocity])
				elsif self[:delta_velocity]
					attributes[c+=1] = sign_of(self[:delta_velocity]) + 'f' * self[:delta_velocity].abs
				end

				if mode == :dotted
					if attributes.size > 0
						attributes.join '.'
					else
						'.'
					end

				elsif mode == :parenthesis
					'(' + attributes.join(', ') + ')'
				else
					attributes
				end
			end
		end

		private 

		def positive_sign_of x
			x > 0 ? '+' : ''
		end

		def sign_of x
			"++-"[x <=> 0]
		end

		def velocity_of x
			['ppp', 'pp', 'p', 'mp', 'mf', 'f', 'ff', 'fff'][x + 3]
		end
	end

	module GDV # grade duration velocity event command
		def to_pdv scale
			r = {}

			if self[:grade]
				r[:pitch] = scale.pitch_of self[:grade], octave: self[:octave]
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

			if self[:command]
				r[:command] = self[:command]
			end

			r.extend Musa::Dataset::PDV
		end

		def to_neuma mode = nil
			mode ||= :dotted # :parenthesis

			attributes = []

			c = 0

			attributes[c] = self[:grade].to_s if self[:grade]
			attributes[c+=1] = 'o' + self[:octave].to_s if self[:octave]
			attributes[c+=1] = self[:duration].to_s if self[:duration]
			attributes[c+=1] = velocity_of(self[:velocity]) if self[:velocity]
				
			if mode == :dotted
				attributes.join '.'

			elsif mode == :parenthesis
				'(' + attributes.join(', ') + ')'
			else
				attributes
			end
		end

		def velocity_of x
			['ppp', 'pp', 'p', 'mp', 'mf', 'f', 'ff', 'fff'][x + 3]
		end

		private :velocity_of

		def to_gdvd scale, previous: nil

			r = {}

			if previous
				current_note = scale.reduced_grade(self[:grade]) + scale.number_of_grades * (scale.octave_of_grade(self[:grade]) + self[:octave])
				previous_note = scale.reduced_grade(previous[:grade]) + scale.number_of_grades * (scale.octave_of_grade(previous[:grade]) + previous[:octave])
				
				note_diff = current_note - previous_note
				
				if note_diff < 0
					r[:delta_grade] = -(note_diff.abs % scale.number_of_grades)
					r[:delta_octave] = -(note_diff.abs / scale.number_of_grades)
				else
					r[:delta_grade] = note_diff % scale.number_of_grades
					r[:delta_octave] = note_diff / scale.number_of_grades
				end
			else
				r[:abs_grade] = self[:grade] if self[:grade]
				r[:abs_octave] = self[:octave] if self[:octave] && self[:octave] != 0
			end

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

			elsif self[:command]
				r[:command] = self[:command]
			end

			r.extend Musa::Dataset::GDVd
		end

		module Parser
			def parse _attributes
				case
				when _attributes.key?(:attributes)

					attributes = _attributes[:attributes].clone 

					command = {}.extend GDVd

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

					octave = attributes.find { |a| /\A [+-]?o[-]?[0-9]+ \Z/x.match a }

					if octave
						if (octave[0] == '+' || octave[0] == '-') && octave[1] == 'o'
							command[:delta_octave] = (octave[0] + octave[2..-1]).to_i
						elsif octave[0] == 'o'
							command[:abs_octave] = octave[1..-1].to_i
						end

						attributes.delete octave
					end

					velocity = attributes.find { |a| /\A (mp | mf | (\+|\-)?(p+|f+)) \Z/x.match a }

					if velocity
						if velocity[0] == '+' || velocity[0] == '-'
							command[:delta_velocity] = (velocity[1] == 'f' ? 1 : -1) * (velocity.length - 1) * (velocity[0] + '1').to_i
						elsif velocity[0] == 'm'
							command[:abs_velocity] = (velocity[1] == 'f') ? 1 : 0
						else
							command[:abs_velocity] = velocity.length * (velocity[0] == 'f' ? 1 : -1) + (velocity[0] == 'f' ? 1 : 0)
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
					{ event: _attributes[:event] }.extend GDVd

				when _attributes.key?(:command)
					{ command: _attributes[:command] }.extend GDVd

				else
					raise RuntimeError, "Not processable data #{_attributes}. Keys allowed are :attributes, :event and :command"
				end
			end
		end

		private_constant :Parser

		class NeumaDifferentialDecoder < Musa::Neuma::DifferentialDecoder
			include Parser
		end

		class NeumaDecoder < Musa::Neuma::Decoder
			include Parser

			def initialize scale, base = nil
				base ||= { grade: 0, octave: 0, duration: Rational(1,4), velocity: 1 }

				@scale = scale

				super base
			end

			def apply action, on:
				action.to_gdv @scale, previous: on
			end
		end
	end
end	

