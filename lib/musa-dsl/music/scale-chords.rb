module Musa
  class ScaleChord
    attr_reader :root_grade, :scale, :duplicated, :moved

    def initialize(root_grade, grades: nil, octave: nil, scale:, duplicate: nil, move: nil)
      grades ||= 3
      octave ||= 0
      duplicate ||= []
      move ||= []

      @scale = scale
      @root_grade = root_grade
      @octave = octave

      @grades = []
      @voices = []

      if grades.is_a? Numeric

        grades.times do |index|
          scale_note = @scale.note_of(@root_grade) + 2 * index
          grade = @scale.symbol_of(scale_note)

          @grades << grade
          @voices << ScaleChordNote.new(self, grade, index, @octave)
        end

      elsif grades.is_a? Array

        grades = [root_grade, *grades]
        index = 0

        grades.each do |grade_or_note|
          if grade_or_note.is_a? Symbol #  grade
            grade = grade_or_note

          elsif grade_or_note.is_a? Numeric # note
            grade = @scale.symbol_of(grade_or_note)

          else
            raise ArgumentError, 'grades array contains elements that are not Numeric nor grade Symbols'
          end

          @grades << grade
          @voices << ScaleChordNote.new(self, grade, index)

          index += 1
        end

      else
        raise ArgumentError, 'grades is not a Numeric nor an Array'
      end

      duplicate = [duplicate] unless duplicate.is_a? Array
      duplicate.each { |d| self.duplicate d[:position], octave: d[:octave], to_voice: d[:to_voice] if d.is_a? Hash }

      move = [move] unless move.is_a? Array
      move.each { |m| self.move m[:voice], octave: m[:octave] if m.is_a? Hash }

      sort_voices!
    end

    def voices
      @voices.clone
    end

    def grade(grade_or_grade_index) # -> Array de ScaleChordNote
      if grade_or_grade_index.is_a? Symbol
        @voices.select { |note| note.grade == grade_or_grade_index }
      else
        @voices.select { |note| note.grade_index == grade_or_grade_index }
      end
    end

    def pitches
      @voices.collect(&:pitch)
    end

    def duplicate(grade_or_grade_index, octave: nil, to_voice: nil) # -> ScaleChordNote
      octave ||= 0

      note = ScaleChordNote.new self, grade_of(grade_or_grade_index), grade_index_of(grade_or_grade_index), @octave + octave

      if to_voice
        @voices.insert to_voice, note
      else
        @voices << note
      end

      self
    end

    def move(voice, octave: nil)
      octave ||= 0

      @voices[voice].octave = octave + @octave

      self
    end

    def sort_voices!
      @voices.sort! { |a, b| a.pitch <=> b.pitch }

      self
    end

    def inversion
      @voices.min_by(&:pitch).grade_index
     end

    def position
      @voices.max_by(&:pitch).grade_index
     end

    def distance
      sorted = @voices.sort_by(&:pitch)

      sorted.last.pitch - sorted.first.pitch
    end

    def to_s
      "Chord root: #{@root_grade} voices: #{@voices}"
    end

    alias inspect to_s

    private

    def grade_of(grade_or_grade_index)
      if grade_or_grade_index.is_a? Symbol
        grade_or_grade_index
      else
        @grades[grade_or_grade_index]
      end
    end

    def grade_index_of(grade_or_grade_index)
      if grade_or_grade_index.is_a? Symbol
        @grades.index(grade_or_grade_index)
      else
        grade_or_grade_index
      end
    end

    class ScaleChordNote
      attr_reader :grade, :grade_index
      attr_accessor :octave

      def initialize(chord, grade, grade_index, octave)
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
        "ScaleChordNote \##{voice} #{@grade} octave: #{@octave}"
      end

      alias inspect to_s
    end

    private_constant :ScaleChordNote
  end
end
