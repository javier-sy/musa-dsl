require 'active_support/core_ext/object/deep_dup'

module Musa

	module Scales
		@@scales = {}

		def self.get(name)
			@@scales[name.to_sym]
		end

		def self.register(name, scale)
			@@scales[name.to_sym] = scale
		end
	end

	class ScaleDef
		def initialize(name, pitch_range_in_octave, symbols:, offsets:)
			@name = name

			@pitch_range_in_octave = pitch_range_in_octave

			@symbols = symbols
			@offsets = offsets
		end

		def number_of_grades
			@offsets.length
		end

		attr_reader :pitch_range_in_octave

		def note_of(grade_or_grade_symbol)
			if grade_or_grade_symbol.is_a? Symbol
				@symbols[grade_or_grade_symbol].to_i
			else
				grade_or_grade_symbol.to_i
			end
		end

		def symbol_of(grade_or_grade_symbol)
			s = @symbols.key note_of(grade_or_grade_symbol)
			s.nil? ? grade_or_grade_symbol : s
		end

		def pitch_offset(grade_or_grade_symbol)
			grade_raw = note_of grade_or_grade_symbol
			grade = grade_raw % @offsets.length

			octaves = grade_raw / @offsets.length

			@offsets[grade] + octaves * @pitch_range_in_octave
		end

		def reduced_grade(grade_or_grade_symbol)
			grade = note_of grade_or_grade_symbol

			grade % number_of_grades
		end

		def octave_of_grade(grade_or_grade_symbol)
			grade = note_of grade_or_grade_symbol

			grade / number_of_grades
		end

		def grade_of_pitch_offset(pitch)
			@offsets.index(pitch.to_i)
		end

		def based_on_pitch(pitch)
			Scale.new self, based_on: pitch
		end

		def to_s
			"ScaleDef: #{@name}"
		end

		alias inspect to_s
	end

	Scales.register :major, 
		ScaleDef.new("Major", 12,
			symbols: { I: 0, II: 1, III: 2, IV: 3, V: 4, VI: 5, VII: 6, VIII: 7, IX: 8, X: 9, XI: 10 },
			offsets: [ 0, 2, 4, 5, 7, 9, 11 ])

	Scales.register :minor, 
		ScaleDef.new("Minor", 12,
			symbols: { I: 0, II: 1, III: 2, IV: 3, V: 4, VI: 5, VII: 6, VIII: 7, IX: 8, X: 9, XI: 10 },
			offsets: [ 0, 2, 3, 5, 7, 8, 10 ])

	class Scale
		extend Forwardable

		attr_reader :def

		def initialize(deff, based_on:)
			@def = deff
			@base_pitch = based_on
		end

		def base
			@base_pitch
		end

		delegate number_of_grades: :@def
		delegate note_of: :@def
		delegate symbol_of: :@def

		def based_on(grade, octave: 0)
			@def.based_on_pitch @base_pitch + @def.pitch_offset(grade) + octave * @def.pitch_range_in_octave
		end

		def pitch_of(grade_or_grades, reduce: false, octave: 0) # => (number, Rational?) note
			if grade_or_grades.is_a? Array
				grade_or_grades.collect { |v| pitch_of_grade v, reduce: reduce, octave: octave }
			else
				pitch_of_grade grade_or_grades, reduce: reduce, octave: octave
			end
		end

		def pitch_of_grade(grade, reduce: false, octave: 0)
			grade = @def.reduced_grade(grade) if reduce
			@base_pitch + @def.pitch_offset(grade) + octave * @def.pitch_range_in_octave
		end

		def grade_of(pitch_or_pitches, reduced: false) # => number - entero o decimal, si hay alteraciones (grade)
			if pitch_or_pitches.is_a? Array
				pitch_or_pitches.collect { |v| grade_of_pitch v, reduced: reduced }
			else
				grade_of_pitch pitch_or_pitches, reduced: reduced
			end
		end

		def octave_of(pitch_or_pitches) # => number (octava relativa)
			if pitch_or_pitches.is_a? Array
				pitch_or_pitches.collect { |v| octave_of_pitch v }
			else
				octave_of_pitch pitch_or_pitches
			end
		end

		def grade_of_pitch(pitch, reduced: false)
			octaves = (pitch - @base_pitch) / @def.pitch_range_in_octave
			pitch %= @def.pitch_range_in_octave

			grade = @def.grade_of_pitch_offset pitch

			grade += octaves * @def.number_of_grades if !reduced
		end

		def octave_of_pitch(pitch)
			(pitch - @base_pitch) / @def.pitch_range_in_octave
		end

		# TODO to_s inspect

		private :grade_of_pitch, :octave_of_pitch
	end
end

