require 'musa-dsl/neuma'

module Musa::Dataset
	module PDV # pitch duration velocity
		def to_gdv scale
			r = {}

			if self[:pitch]
				if self[:pitch] == :silence
					r[:grade] = :silence
				else
					r[:grade] = scale.grade_of self[:pitch], reduced: true
					r[:octave] = scale.octave_of self[:pitch]
				end
			end

			if self[:duration]
				r[:duration] = self[:duration]
			end

			if self[:velocity]
				# ppp = 16 ... fff = 127
				r[:velocity] = [0..16, 17..32, 33..48, 49..64, 65..80, 81..96, 97..112, 113..127].index { |r| r.cover? self[:velocity] } - 3
			end

			r.extend Musa::Dataset::GDV
		end
	end
end	

