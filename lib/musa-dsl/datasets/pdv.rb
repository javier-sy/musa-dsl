require 'musa-dsl/neuma/neuma'

module Musa::Dataset
	module PDV
		def to_gdve scale
			r = {}

			if self[:pitch]
				r[:grade] = scale.grade_of self[:pitch]
			end

			if self[:duration]
				r[:duration] = self[:duration]
			end

			if self[:velocity]
				# ppp = 16 ... fff = 127
				r[:velocity] = [0..16, 17..32, 33..48, 49..64, 65..80, 81..96, 97..112, 113..127].index { |r| r.cover? self[:velocity] } - 3
			end

			if self[:event]
				r[:event] = self[:event]
			end

			r.extend Musa::Dataset::GDV
		end
	end
end	

