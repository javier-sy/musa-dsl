# TODO no resulta reconstruible vía inspect si se utiliza grade(x).octave = y o si se llama a move tras un sort_voices! revisar reconstruccionabilidad del chord

module Musa
	def self.Chord(*parameters)
		Chord.new *parameters
	end

	class Chord

		attr_reader :root_grade, :scale, :duplicated, :moved

		def initialize(root_grade, grades: nil, scale:, duplicate: nil, move: nil)
			@constructor_grades = grades
			@duplicates = []
			@moves = []

			grades ||= 3
			duplicate ||= []
			move ||= []

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

			duplicate = [duplicate] unless duplicate.is_a? Array
			duplicate.each { |d| self.duplicate d[:position], octave: d[:octave], to_voice: d[:to_voice] if d.is_a? Hash}

			move = [move] unless move.is_a? Array
			move.each { |m| self.move m[:voice], octave: m[:octave] if m.is_a? Hash }
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

		def duplicate(grade_or_grade_index, octave: nil, to_voice: nil) # -> ChordNote

			cmd = { position: grade_or_grade_index }
			cmd[:octave] = octave if octave
			cmd[:to_voice] = to_voice if to_voice

			@duplicates << cmd

			octave ||= 0

			note = ChordNote.new chord: self, grade: grade_of(grade_or_grade_index), grade_index: grade_index_of(grade_or_grade_index), octave: octave

			if to_voice
				@voices.insert to_voice, note
			else
				@voices << note
			end

			self
		end

		def move(voice, octave: nil)
			cmd = { voice: voice }
			cmd[:octave] = octave if octave

			@moves << cmd

			octave ||= 0

			@voices[voice].octave += octave

			self
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

 		def inspect
 			grades = "grades: #{@constructor_grades}" if @constructor_grades
 			duplicates =  "duplicate: #{ @duplicates.size == 1 ? @duplicates.first.inspect : @duplicates.inspect }" unless @duplicates.empty?
 			moves = "move: #{ @moves.size == 1 ? @moves.first.inspect : @moves.inspect }" unless @moves.empty?

 			%{ Musa::Chord #{@root_grade.inspect}#{", #{grades}" if grades}#{", #{duplicates}" if duplicates}#{", #{moves}" if moves} }.strip
 		end

 		def to_s
 			"Chord root: #{@root_grade} voices: #{@voices}"
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

			def initialize(chord:, grade:, grade_index:, octave: nil)
				octave ||= 0

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

			def to_s
				"ChordNote \##{voice} #{@grade} octave: #{@octave}"
			end

			alias inspect to_s 
		end

		private_constant :ChordNote
	end
end
