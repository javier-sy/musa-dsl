require_relative 'scales'
require_relative 'chord-definition'

module Musa
  module Chords
    # Instantiated chord with specific root and scale context.
    #
    # Chord represents an actual chord instance with a root note, scale context,
    # and chord definition. It provides access to chord tones, voicing modifications,
    # and navigation between related chords.
    #
    # ## Creation
    #
    # Chords are typically created from scale notes rather than directly:
    #
    #     scale = Scales::Scales.default_system.default_tuning.major[60]
    #     chord = scale.tonic.chord              # C major triad
    #     chord = scale.tonic.chord :seventh     # C major seventh
    #     chord = scale.dominant.chord :ninth    # G ninth chord
    #
    # ## Accessing Chord Tones
    #
    # Chord tones are accessed by their position name (root, third, fifth, etc.):
    #
    #     chord.root      # Returns NoteInScale for root
    #     chord.third     # Returns NoteInScale for third
    #     chord.fifth     # Returns NoteInScale for fifth
    #     chord.seventh   # Returns NoteInScale for seventh (if exists)
    #
    # When notes are duplicated, use `all: true` to get all instances:
    #
    #     chord.root(all: true)  # Returns array of all root notes
    #
    # ## Features and Navigation
    #
    # Chords have features (quality, size) and can navigate to related chords:
    #
    #     chord.features          # => { quality: :major, size: :triad }
    #     chord.quality           # => :major (dynamic method)
    #     chord.size              # => :triad (dynamic method)
    #
    #     chord.with_quality(:minor)     # Change to minor
    #     chord.with_size(:seventh)      # Add seventh
    #     chord.featuring(size: :ninth)  # Change multiple features
    #
    # ## Voicing Modifications
    #
    # ### Move - Relocate specific chord tones to different octaves:
    #
    #     chord.with_move(root: -1, seventh: 1)
    #     # Root down one octave, seventh up one octave
    #     chord.move  # => { root: -1, seventh: 1 } (current settings)
    #
    # ### Duplicate - Add copies of chord tones in other octaves:
    #
    #     chord.with_duplicate(root: -2, third: [-1, 1])
    #     # Add root 2 octaves down, third 1 octave down and 1 up
    #     chord.duplicate  # => { root: -2, third: [-1, 1] } (current settings)
    #
    # ### Octave - Transpose entire chord:
    #
    #     chord.octave(-1)  # Move entire chord down one octave
    #
    # ## Pitch Extraction
    #
    #     chord.pitches                    # All pitches sorted by pitch
    #     chord.pitches(:root, :third)     # Only specified chord tones
    #     chord.notes                      # Sorted ChordGradeNote structs
    #
    # ## Scale Context
    #
    # Chords maintain their scale context. When navigating to chords with
    # non-diatonic notes (e.g., major to minor), the scale may become nil:
    #
    #     major_chord = c_major.tonic.chord
    #     major_chord.scale  # => C major scale
    #
    #     minor_chord = major_chord.with_quality(:minor)
    #     minor_chord.scale  # => nil (Eb not in C major)
    #
    # @example Basic triad creation
    #   scale = Scales::Scales.default_system.default_tuning.major[60]
    #   chord = scale.tonic.chord
    #   chord.root.pitch   # => 60 (C)
    #   chord.third.pitch  # => 64 (E)
    #   chord.fifth.pitch  # => 67 (G)
    #
    # @example Seventh chord
    #   chord = scale.tonic.chord :seventh
    #   chord.seventh.pitch  # => 71 (B)
    #
    # @example Voicing with move and duplicate
    #   scale = Scales::Scales.default_system.default_tuning.major[60]
    #   chord = scale.dominant.chord(:seventh)
    #     .with_move(root: -1, third: -1)
    #     .with_duplicate(fifth: [0, 1])
    #
    # @example Feature navigation
    #   scale = Scales::Scales.default_system.default_tuning.major[60]
    #   maj_triad = scale.tonic.chord
    #   min_triad = maj_triad.with_quality(:minor)
    #   maj_seventh = maj_triad.with_size(:seventh)
    #
    # @see ChordDefinition Chord template/definition
    # @see NoteInScale Note within scale
    # @see chord-definitions.rb Standard chord types
    class Chord

      using Musa::Extension::Arrayfy

      # Creates a chord with specified root.
      #
      # Factory method for creating chords by specifying the root note and either
      # a chord definition name or features. The root can be a NoteInScale, pitch
      # number, or scale degree symbol.
      #
      # @param root_note_or_pitch_or_symbol [NoteInScale, Integer, Symbol] chord root
      #   - NoteInScale: use note directly
      #   - Integer (MIDI pitch): find note in scale, or create C major if no scale
      #   - Symbol (scale degree): requires scale parameter (e.g., :tonic, :dominant)
      # @param scale [Scale, nil] scale context for finding notes
      # @param allow_chromatic [Boolean] allow non-diatonic notes
      # @param name [Symbol, nil] chord definition name (:maj, :min7, etc.)
      # @param move [Hash{Symbol => Integer}, nil] initial octave moves (e.g., `{root: -1}`)
      # @param duplicate [Hash{Symbol => Integer, Array<Integer>}, nil] initial duplications
      # @param features [Hash] chord features if not using name (quality:, size:, etc.)
      # @return [Chord] new chord instance
      #
      # @example With note from scale
      #   Chord.with_root(scale.tonic, name: :maj7)
      #
      # @example With MIDI pitch and scale
      #   Chord.with_root(60, scale: c_major, name: :min)
      #
      # @example With scale degree
      #   Chord.with_root(:dominant, scale: c_major, quality: :dominant, size: :seventh)
      #
      # @example With features instead of name
      #   Chord.with_root(60, scale: c_major, quality: :major, size: :triad)
      #
      # @example With voicing parameters
      #   Chord.with_root(60, scale: c_major, name: :maj7,
      #                   move: {root: -1}, duplicate: {fifth: 1})
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

      # Internal helper methods for chord construction.
      #
      # @api private
      class Helper
        # Computes the source notes map for a chord.
        #
        # Maps each chord position (root, third, fifth, etc.) to its corresponding
        # note in the scale or chromatic scale.
        #
        # @param root [NoteInScale] chord root note
        # @param chord_definition [ChordDefinition] chord structure
        # @param scale [Scale] scale context
        # @return [Hash{Symbol => Array<NoteInScale>}] position to notes mapping
        #
        # @api private
        def self.compute_source_notes_map(root, chord_definition, scale)
          chord_definition.pitch_offsets.transform_values do |offset|
            pitch = root.pitch + offset
            [scale.note_of_pitch(pitch) || scale.chromatic.note_of_pitch(pitch)]
          end.tap { |_| _.values.each(&:freeze) }.freeze
        end

        # Finds a chord definition matching features and scale constraints.
        #
        # Searches for chord definitions with specified features, filtering out
        # those that don't fit in the scale unless allow_chromatic is true.
        #
        # @param root_pitch [Integer] MIDI pitch of chord root
        # @param features [Hash] desired chord features (quality:, size:, etc.)
        # @param scale [Scale] scale context for diatonic filtering
        # @param allow_chromatic [Boolean] allow non-diatonic chords
        # @return [ChordDefinition, nil] matching definition or nil
        #
        # @api private
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

      # Container for chord tone with its position name.
      #
      # Associates a chord position (grade) with its corresponding note.
      # Used internally for sorting and organizing chord notes.
      #
      # @!attribute grade
      #   @return [Symbol] position name (:root, :third, :fifth, etc.)
      # @!attribute note
      #   @return [NoteInScale] the note at this position
      #
      # @api private
      ChordGradeNote = Struct.new(:grade, :note, keyword_init: true)

      private_constant :ChordGradeNote

      # Creates a chord (private constructor).
      #
      # Use {with_root} or create chords from scale notes instead.
      #
      # @param root [NoteInScale] chord root note
      # @param scale [Scale, nil] scale context (nil if chromatic notes present)
      # @param chord_definition [ChordDefinition] chord structure
      # @param move [Hash, nil] octave moves for positions
      # @param duplicate [Hash, nil] octave duplications for positions
      # @param source_notes_map [Hash] position to notes mapping
      #
      # @api private
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

      # Scale context (nil if chord contains non-diatonic notes).
      # @return [Scale, nil]
      attr_reader :scale

      # Chord definition template.
      # @return [ChordDefinition]
      attr_reader :chord_definition

      # Octave moves applied to positions.
      # @return [Hash{Symbol => Integer}]
      attr_reader :move

      # Octave duplications applied to positions.
      # @return [Hash{Symbol => Integer, Array<Integer>}]
      attr_reader :duplicate

      # Returns chord notes sorted by pitch.
      #
      # @return [Array<ChordGradeNote>] sorted array of grade-note pairs
      #
      # @example
      #   chord.notes.each do |chord_grade_note|
      #     puts "#{chord_grade_note.grade}: #{chord_grade_note.note.pitch}"
      #   end
      def notes
        @sorted_notes
      end

      # Returns MIDI pitches of chord notes.
      #
      # Without arguments, returns all pitches sorted from low to high.
      # With grade arguments, returns only pitches for those positions.
      #
      # @param grades [Array<Symbol>] optional position names to filter
      # @return [Array<Integer>] MIDI pitches sorted by pitch
      #
      # @example All pitches
      #   chord.pitches  # => [60, 64, 67]
      #
      # @example Specific positions
      #   chord.pitches(:root, :third)  # => [60, 64]
      def pitches(*grades)
        grades = @notes_map.keys if grades.empty?
        @sorted_notes.select { |_| grades.include?(_.grade) }.collect { |_| _.note.pitch }
      end

      # Returns chord features.
      #
      # @return [Hash{Symbol => Symbol}] features hash (quality:, size:, etc.)
      #
      # @example
      #   chord.features  # => { quality: :major, size: :triad }
      def features
        @chord_definition.features
      end

      # Creates new chord with modified features.
      #
      # Returns a new chord with the same root but different features.
      # Features can be specified as values (converted to feature hash) or
      # as keyword arguments.
      #
      # @param values [Array<Symbol>] feature values to change
      # @param allow_chromatic [Boolean] allow non-diatonic result
      # @param hash [Hash] feature key-value pairs to change
      # @return [Chord] new chord with modified features
      # @raise [ArgumentError] if no matching chord definition found
      #
      # @example Change size
      #   chord.featuring(size: :seventh)
      #
      # @example Change quality
      #   chord.featuring(quality: :minor)
      #
      # @example Change multiple features
      #   chord.featuring(quality: :dominant, size: :ninth)
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

      # Transposes entire chord to a different octave.
      #
      # Moves all chord notes by the specified octave offset, preserving
      # internal voicing structure (moves and duplications).
      #
      # @param octave [Integer] octave offset (positive = up, negative = down)
      # @return [Chord] new chord in different octave
      #
      # @example Move chord down one octave
      #   chord.octave(-1)
      #
      # @example Move chord up two octaves
      #   chord.octave(2)
      def octave(octave)
        source_notes_map = @source_notes_map.transform_values do |notes|
          notes.collect { |note| note.at_octave(octave) }.freeze
        end.freeze

        Chord.new(@root.at_octave(octave), @scale, chord_definition, @move, @duplicate, source_notes_map)
      end

      # Current move settings (position to octave offset mapping).
      # @return [Hash{Symbol => Integer}]
      attr_reader :move

      # Creates new chord with positions moved to different octaves.
      #
      # Relocates specific chord positions to different octaves while keeping
      # other positions unchanged. Multiple positions can be moved at once.
      # Merges with existing moves.
      #
      # @param octaves [Hash{Symbol => Integer}] position to octave offset mapping
      # @return [Chord] new chord with moved positions
      #
      # @example Move root down, seventh up
      #   chord.with_move(root: -1, seventh: 1)
      #
      # @example Drop voicing (move third and seventh down)
      #   chord.with_move(third: -1, seventh: -1)
      def with_move(**octaves)
        Chord.new(@root, @scale, @chord_definition, @move.merge(octaves), @duplicate, @source_notes_map)
      end

      # Current duplicate settings (position to octave(s) mapping).
      # @return [Hash{Symbol => Integer, Array<Integer>}]
      attr_reader :duplicate

      # Creates new chord with positions duplicated in other octaves.
      #
      # Adds copies of specific chord positions in different octaves.
      # Original positions remain at their current octave.
      # Merges with existing duplications.
      #
      # @param octaves [Hash{Symbol => Integer, Array<Integer>}] position to octave(s)
      # @return [Chord] new chord with duplicated positions
      #
      # @example Duplicate root two octaves down
      #   chord.with_duplicate(root: -2)
      #
      # @example Duplicate third in multiple octaves
      #   chord.with_duplicate(third: [-1, 1])
      #
      # @example Duplicate multiple positions
      #   chord.with_duplicate(root: -1, fifth: 1)
      def with_duplicate(**octaves)
        Chord.new(@root, @scale, @chord_definition, @move, @duplicate.merge(octaves), @source_notes_map)
      end

      # Finds this chord in other scales.
      #
      # Searches through scale kinds matching the given metadata criteria to find
      # all scales that contain this chord. Returns new chord instances, each with
      # its containing scale as context.
      #
      # @param roots [Range, Array, nil] pitch offsets to search (default: full octave)
      # @param metadata [Hash] metadata filters for scale kinds (family:, brightness:, etc.)
      # @return [Array<Chord>] this chord in different scale contexts
      #
      # @example Find G major triad in diatonic scales
      #   g_triad = c_major.dominant.chord
      #   g_triad.in_scales(family: :diatonic)
      #
      # @example Find chord in scales with specific brightness
      #   g7.in_scales(brightness: -1..1)
      #
      # @example Iterate over results
      #   g7.in_scales(family: :greek_modes).each do |chord|
      #     scale = chord.scale
      #     degree = scale.degree_of_chord(chord)
      #     puts "#{scale.kind.class.id} on #{scale.root_pitch}: degree #{degree}"
      #   end
      #
      # @see Musa::Scales::Scale#chord_on
      # @see Musa::Scales::ScaleSystemTuning#chords_of
      def in_scales(roots: nil, **metadata)
        tuning = @scale&.kind&.tuning || @root.scale.kind.tuning
        tuning.chords_of(self, roots: roots, **metadata)
      end

      # Checks chord equality.
      #
      # Chords are equal if they have the same notes and chord definition.
      #
      # @param other [Chord] chord to compare
      # @return [Boolean] true if chords are equal
      def ==(other)
        self.class == other.class &&
          @sorted_notes == other.notes &&
          @chord_definition == other.chord_definition
      end

      # Returns string representation.
      #
      # @return [String]
      def inspect
        "<Chord #{@name} root #{@root} notes #{@sorted_notes.collect { |_| "#{_.grade}=#{_.note.grade}|#{_.note.pitch} "} }>"
      end

      alias to_s inspect

      # Applies move and duplicate operations to notes map.
      #
      # Computes the final notes map after applying octave moves and duplications
      # to the source notes.
      #
      # @param notes_map [Hash] source notes map
      # @param moved [Hash, nil] octave moves for positions
      # @param duplicated [Hash, nil] octave duplications for positions
      # @return [Hash{Symbol => Array<NoteInScale>}] final notes map
      #
      # @api private
      private def compute_moved_and_duplicated(notes_map, moved, duplicated)
        notes_map = notes_map.transform_values(&:dup)

        moved&.each do |position, octave|
          notes_map[position][0] = notes_map[position][0].at_octave(octave)
        end

        duplicated&.each do |position, octave|
          octave.arrayfy.each do |octave|
            notes_map[position] << notes_map[position][0].at_octave(octave)
          end
        end

        notes_map.tap { |_| _.values.each(&:freeze) }.freeze
      end
    end
  end
end

