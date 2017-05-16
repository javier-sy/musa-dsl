module Musa
	def self.Chord2(*parameters)
		Chord2.new *parameters
	end

	class Chord2

		attr_reader :root_grade, :scale

		def initialize(root_grade, grades: 3, scale:)
			@scale = scale
			@root_grade = root_grade

			@grades = []
			@voices = []

			if grades.is_a? Numeric

				grades.times do |index|
					scale_note = @scale.note_of(@root_grade) + 2 * index
					grade = @scale.symbol_of(scale_note)

					@grades << grade
					@voices << ChordNote.new(chord: self, grade: grade, grade_index: index)
				end

			elsif grades.is_a? Array

				grades = [root_grade, *grades]
				index = 0

				grades.each do |grade_or_note|
					if grade_or_note.is_a? Symbol # grade
						grade = grade_or_note

					elsif grade_or_note.is_a? Numeric # note
						grade = @scale.symbol_of(grade_or_note)

					else
						raise ArgumentError, 'grades array contains elements that are not Numeric nor grade Symbols'
					end

					@grades << grade
					@voices << ChordNote.new(chord: self, grade: grade, grade_index: index)

					index += 1
				end

			else
				raise ArgumentError, 'grades is not a Numeric nor an Array'
			end
		end

		def voices
			@voices.clone
		end

		def grade(grade_or_grade_index) # -> Array de ChordNote
			if grade_or_grade_index.is_a? Symbol
				return @voices.select { |note| note.grade == grade_or_grade_index }
			else
				return @voices.select { |note| note.grade_index == grade_or_grade_index }
			end
		end

		def pitches
			@voices.collect { |v| v.pitch }
		end

		def duplicate(grade_or_grade_index, octave: 0, to_voice: nil) # -> ChordNote
			chord = ChordNote.new chord: self, grade: grade_of(grade_or_grade_index), grade_index: grade_index_of(grade_or_grade_index), octave: octave

			if to_voice
				@voices.insert to_voice, chord
			else
				@voices << chord
			end
		end

		def sort_voices!
			@voices.sort! { |a, b| a.pitch <=> b.pitch }

			self
		end

		def inversion
			@voices.sort_by { |note| note.pitch }.first.grade_index
 		end

		def position
			@voices.sort_by { |note| note.pitch }.last.grade_index
 		end

 		def distance
 			sorted = @voices.sort_by { |note| note.pitch }

 			sorted.last.pitch - sorted.first.pitch
 		end

		private

		def grade_of(grade_or_grade_index)
			if grade_or_grade_index.is_a? Symbol
				return grade_or_grade_index
			else
				return @grades[grade_or_grade_index]
			end
		end

		def grade_index_of(grade_or_grade_index)
			if grade_or_grade_index.is_a? Symbol
				return @grades.index(grade_or_grade_index)
			else
				return grade_or_grade_index
			end
		end

		class ChordNote
			attr_reader :grade, :grade_index
			attr_accessor :octave

			def initialize(chord:, grade:, grade_index:, octave: 0)
				@chord = chord

				@grade = grade
				@grade_index = grade_index
				@octave = octave
			end

			def pitch
				@chord.scale.pitch_of @grade, octave: @octave
			end

			def voice
				@chord.voices.index self
			end
		end

		private_constant :ChordNote
	end
end


