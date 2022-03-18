require_relative 'scales'
require_relative 'chord-definition'

module Musa
  module Chords
    class Chord

      using Musa::Extension::Arrayfy

      def self.with_root(root_note_or_pitch_or_symbol, scale: nil, allow_chromatic: false, name: nil, move: nil, duplicate: nil, **features)
        root =
          case root_note_or_pitch_or_symbol
          when Scales::NoteInScale
            root_note_or_pitch_or_symbol
          when Numeric
            if scale
              scale.note_of_pitch(root_note_or_pitch_or_symbol, allow_chromatic: allow_chromatic)
            else
              scale = Musa::Scales::Scales.default_system.default_tuning[root_note_or_pitch_or_symbol].major
              scale.note_of_pitch(root_note_or_pitch_or_symbol)
            end
          when Symbol
            raise ArgumentError, "Missing scale parameter to calculate root note for #{root_note_or_pitch_or_symbol}" unless scale

            scale[root_note_or_pitch_or_symbol]
          else
            raise ArgumentError, "Unexpected #{root_note_or_pitch_or_symbol}"
          end

        scale ||= root.scale

        if name
          raise ArgumentError, "Received name parameter with value #{name}: features parameter is not allowed" if features.any?

          chord_definition = ChordDefinition[name]

        elsif features.any?
          chord_definition = Helper.find_definition_by_features(root.pitch, features, scale, allow_chromatic: allow_chromatic)

        else
          raise ArgumentError, "Don't know how to find a chord definition without name or features parameters"
        end

        unless chord_definition
          raise ArgumentError,
                "Unable to find chord definition for root #{root}" \
                "#{" with name #{name}" if name}" \
                "#{" with features #{features}" if features.any?}"
        end

        source_notes_map = Helper.compute_source_notes_map(root, chord_definition, scale)

        Chord.new(root, scale, chord_definition, move, duplicate, source_notes_map)
      end

      class Helper
        def self.compute_source_notes_map(root, chord_definition, scale)
          chord_definition.pitch_offsets.transform_values do |offset|
            pitch = root.pitch + offset
            [scale.note_of_pitch(pitch) || scale.chromatic.note_of_pitch(pitch)]
          end.tap { |_| _.values.each(&:freeze) }.freeze
        end

        def self.find_definition_by_features(root_pitch, features, scale, allow_chromatic:)
          featured_chord_definitions = ChordDefinition.find_by_features(**features)

          unless allow_chromatic
            featured_chord_definitions.reject! do |chord_definition|
              chord_definition.pitches(root_pitch).find { |chord_pitch| scale.note_of_pitch(chord_pitch).nil? }
            end
          end

          featured_chord_definitions.first
        end
      end

      private_constant :Helper

      ChordGradeNote = Struct.new(:grade, :note, keyword_init: true)

      private_constant :ChordGradeNote

      private def initialize(root, scale, chord_definition, move, duplicate, source_notes_map)
        @root = root
        @scale = scale
        @chord_definition = chord_definition
        @move = move.dup.freeze || {}
        # TODO: ojo esto implica que sólo se puede duplicar una vez cada grado! permitir múltiples?
        @duplicate = duplicate.dup.freeze || {}
        @source_notes_map = source_notes_map.dup.freeze
        @notes_map = compute_moved_and_duplicated(source_notes_map, move, duplicate)

        # Calculate sorted notes: from lower to higher notes
        #
        @sorted_notes = []
        @notes_map.each_pair do |name, array_of_notes|
          array_of_notes.each do |note|
            @sorted_notes << ChordGradeNote.new(grade: name, note: note).freeze
          end
        end

        @sorted_notes.sort_by! { |chord_grade_note| chord_grade_note.note.pitch }
        @sorted_notes.freeze

        # Add getters for grades
        #
        @notes_map.each_key do |chord_grade_name|
          define_singleton_method chord_grade_name do |all: false|
            if all
              @notes_map[chord_grade_name]
            else
              @notes_map[chord_grade_name].first
            end
          end
        end

        # Add getters for the features values
        #
        @chord_definition.features.each_key do |feature_name|
          define_singleton_method feature_name do
            @chord_definition.features[feature_name]
          end
        end

        # Add navigation methods to other chords based on changing a feature
        #
        ChordDefinition.feature_keys.each do |feature_name|
          define_singleton_method "with_#{feature_name}".to_sym do |feature_value, allow_chromatic: true|
            featuring(allow_chromatic: allow_chromatic, **{ feature_name => feature_value })
          end
        end
      end

      attr_reader :scale, :chord_definition, :move, :duplicate

      def notes
        @sorted_notes
      end

      def pitches(*grades)
        grades = @notes_map.keys if grades.empty?
        @sorted_notes.select { |_| grades.include?(_.grade) }.collect { |_| _.note.pitch }
      end

      def features
        @chord_definition.features
      end

      def featuring(*values, allow_chromatic: false, **hash)
        # create a new list of features based on current features but
        # replacing the values for the new ones and adding the new features
        #
        features = @chord_definition.features.dup
        ChordDefinition.features_from(values, hash).each { |k, v| features[k] = v }

        chord_definition = Helper.find_definition_by_features(@root.pitch, features, @scale, allow_chromatic: allow_chromatic)

        raise ArgumentError, "Unable to find a chord definition for #{features}" unless chord_definition

        source_notes_map = Helper.compute_source_notes_map(@root, chord_definition, @scale)

        Chord.new(@root,
                  (@scale if chord_definition.in_scale?(@scale, chord_root_pitch: @root.pitch)),
                  chord_definition,
                  @move, @duplicate,
                  source_notes_map)
      end

      def octave(octave)
        source_notes_map = @source_notes_map.transform_values do |notes|
          notes.collect { |note| note.octave(octave) }.freeze
        end.freeze

        Chord.new(@root.octave(octave), @scale, chord_definition, @move, @duplicate, source_notes_map)
      end

      def move(**octaves)
        Chord.new(@root, @scale, @chord_definition, @move.merge(octaves), @duplicate, @source_notes_map)
      end

      def duplicate(**octaves)
        Chord.new(@root, @scale, @chord_definition, @move, @duplicate.merge(octaves), @source_notes_map)
      end

      def ==(other)
        self.class == other.class &&
          @sorted_notes == other.notes &&
          @chord_definition == other.chord_definition
      end

      def inspect
        "<Chord #{@name} root #{@root} notes #{@sorted_notes.collect { |_| "#{_.grade}=#{_.note.grade}|#{_.note.pitch} "} }>"
      end

      alias to_s inspect

      private def compute_moved_and_duplicated(notes_map, moved, duplicated)
        notes_map = notes_map.transform_values(&:dup)

        moved&.each do |position, octave|
          notes_map[position][0] = notes_map[position][0].octave(octave)
        end

        duplicated&.each do |position, octave|
          octave.arrayfy.each do |octave|
            notes_map[position] << notes_map[position][0].octave(octave)
          end
        end

        notes_map.tap { |_| _.values.each(&:freeze) }.freeze
      end
    end
  end
end

