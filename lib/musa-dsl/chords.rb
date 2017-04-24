module Musa
	def self.Chord(*parameters)
		Chord.new *parameters
	end

	class Chord
		def initialize(base_grade, grades: 3, scale:, octave: 0, inversion: nil, duplicate: nil, move: nil, sort: false)
			@base = base_grade
			@scale = scale
			@octave = octave

			@grades = {}
			@voices = []

			if grades.is_a? Array
				grades.each do |grade|
					note = @scale.note_of(grade)
					symbol = @scale.symbol_of(note)
					
					@grades[ symbol ] = [ note ]
					@voices << { symbol: symbol, value: note }
				end
			elsif grades.is_a? Integer
				grades.times do |position|
					note = @scale.note_of(@base) + 2 * position

					symbol = @scale.symbol_of(note)
					
					@grades[ symbol ] = [ note ]
					@voices << { symbol: symbol, value: note }
				end
			else
				raise ArgumentError, 'grades is not Numeric nor Array'
			end

			@history = []

			invert! inversion if inversion

			duplicate = [duplicate] unless duplicate.is_a? Array
			duplicate.each { |d| duplicate! d if d}

			move = [move] unless move.is_a? Array
			move.each { |m| move! m if m}

			sort_voices! if sort
		end

		attr_reader :scale, :base, :inversion
		attr_accessor :octave

		def grades
			@grades.keys
		end

		def notes
			@grades.values.flatten
		end

		def voices
			@voices.collect { |h| h[:value] + @octave * @scale.number_of_grades }
		end

		def pitches
			@scale.pitch_of voices, octave: @octave if @scale.respond_to? :pitch_of
		end

		def copy
			c = Chord.new @base, grades: @grades.length, scale: @scale, octave: @octave
			
			@history.each do |command|
				if command[1]
					c.send command[0], command[1] 
				else
					c.send command[0]
				end
			end

			c
		end

		def invert!(inversion, to_voice: nil)

			raise "Chord already inverted. Cannot invert." if @inversion
			raise "Chord already with duplications. Cannot invert." if @duplications
			raise "Chord with movements. Cannot invert." if @movements

			to_voice ||= @voices.length - 1

			@history << [ :invert!, inversion, { to_voice: to_voice } ]

			@inversion = inversion

			for i in 0...inversion
				grade = @grades.keys[i]
				notes = @grades[grade]

				if notes.length == 1
					old_note = notes[0]
					new_note = old_note + @scale.number_of_grades
					old_voice = @voices.find_index {|v| v[:symbol] == grade && v[:value] == old_note }

					notes[0] = new_note

					@voices.delete_at old_voice
					@voices.insert to_voice, { symbol: grade, value: new_note }
				end
			end

			self
		end

		def duplicate!(grade: nil, position: nil, voice: nil, octaves: 1, to_voice: -1)

			@history << [ :duplicate!, { grade: grade, position: position, voice: voice, octaves: octaves, to_voice: to_voice }]

			@duplications = true

			grade = @grades.keys[position] if grade.nil? && position
			grade = @voices[voice][:symbol] if grade.nil? && voice

			notes = @grades[grade]

			octaves = [octaves] unless octaves.is_a? Array

			octaves.each do |octaves|
				note = notes[0] + octaves * @scale.number_of_grades
				
				notes << note
				@voices.insert to_voice, { symbol: grade, value: note }
			end

			self
		end

		def move!(grade: nil, position: nil, voice: nil, octaves:, to_voice: nil)

			@history << [ :move!, { grade: grade, position: position, voice: voice, octaves: octaves, to_voice: to_voice }]

			@movements = true

			grade = @grades.keys[position] if grade.nil? && position
			grade = @voices[voice][:symbol] if grade.nil? && voice

			notes = @grades[grade]

			new_note = notes[0] + octaves * @scale.number_of_grades
			notes[0] = new_note

			if !to_voice.nil?
				voice = @voices.index { |h| h[:symbol] == grade } if voice.nil?

				@voices.delete_at voice if voice
				@voices.insert to_voice, { symbol: grade, value: new_note }
			end

			self
		end

		def sort_voices!
			@history << [ :sort_voices! ]

			@voices.sort! { |a, b| a[:value] <=> b[:value] }

			self
		end

		def to_s
			# "Chord: scale=#{@scale} base=#{@base} #{"inversion=#{@inversion}" if @inversion} grades=#{@grades} voices=#{@voices}"
			"grades: #{self.grades} notes: #{self.notes} voices: #{self.voices} pitches: #{self.pitches}"
		end
	end
end

