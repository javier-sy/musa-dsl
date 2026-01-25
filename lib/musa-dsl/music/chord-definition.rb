module Musa
  # Chord construction and manipulation framework.
  #
  # The Chords module provides a comprehensive system for defining, creating, and
  # manipulating musical chords. It supports standard chord types (triads, sevenths,
  # ninths, etc.) with various qualities (major, minor, diminished, augmented, dominant).
  #
  # ## Architecture
  #
  # - **ChordDefinition**: Template defining chord structure (intervals and features)
  # - **Chord**: Actual chord instance with specific root and scale context
  #
  # ## Basic Usage
  #
  #     # Create chord from scale note
  #     scale = Scales::Scales.default_system.default_tuning.major[60]
  #     chord = scale.tonic.chord         # C major triad
  #     chord = scale.tonic.chord :triad  # Explicitly specify size
  #
  # ## Features
  #
  # Chords are defined by features:
  #
  # - **quality**: :major, :minor, :diminished, :augmented, :dominant
  # - **size**: :triad, :seventh, :ninth, :eleventh, :thirteenth
  #
  # # Registered chord definitions.
  #
  # ## Triads
  #
  # Basic three-note chords:
  #
  # - **:maj** - Major triad (1-3-5): root, major third, perfect fifth
  # - **:min** - Minor triad (1-♭3-5): root, minor third, perfect fifth
  # - **:dim** - Diminished triad (1-♭3-♭5): root, minor third, diminished fifth
  # - **:aug** - Augmented triad (1-3-♯5): root, major third, augmented fifth
  #
  # ## Seventh Chords
  #
  # Four-note chords with added seventh:
  #
  # - **:maj7** - Major seventh (1-3-5-7): major triad + major seventh
  # - **:min7** - Minor seventh (1-♭3-5-♭7): minor triad + minor seventh
  # - **:dom7** - Dominant seventh (1-3-5-♭7): major triad + minor seventh
  #
  # ## Extended Chords
  #
  # Chords with ninths, elevenths, and thirteenths:
  #
  # - **:maj9, :min9, :dom9** - Ninth chords
  # - **:maj11, :min11** - Eleventh chords
  # - **:maj13, :min13** - Thirteenth chords
  #
  # @see ChordDefinition Chord template/definition
  # @see Chord Instantiated chord
  module Chords
    # Chord template defining structure and features.
    #
    # ChordDefinition is a template that specifies the intervals and characteristics
    # of a chord type. It's defined once and used to create many chord instances.
    #
    # ## Components
    #
    # - **Name**: Unique identifier (:maj, :min, :dom7, etc.)
    # - **Offsets**: Semitone intervals from root ({ root: 0, third: 4, fifth: 7 })
    # - **Features**: Characteristics (quality: :major, size: :triad)
    #
    # ## Registration
    #
    # Chord definitions are registered globally:
    #
    #     ChordDefinition.register :maj,
    #       quality: :major,
    #       size: :triad,
    #       offsets: { root: 0, third: 4, fifth: 7 }
    #
    # ## Finding Definitions
    #
    # **By name**:
    #
    #     ChordDefinition[:maj]  # => <ChordDefinition :maj>
    #
    # **By features**:
    #
    #     ChordDefinition.find_by_features(quality: :major, size: :triad)
    #     # => [<ChordDefinition :maj>]
    #
    # **By pitches**:
    #
    #     ChordDefinition.find_by_pitches([60, 64, 67])  # C E G
    #     # => <ChordDefinition :maj>
    #
    # @example Defining a major triad
    #   ChordDefinition.register :maj,
    #     quality: :major,
    #     size: :triad,
    #     offsets: { root: 0, third: 4, fifth: 7 }
    #
    # @example Defining a dominant seventh
    #   ChordDefinition.register :dom7,
    #     quality: :dominant,
    #     size: :seventh,
    #     offsets: { root: 0, third: 4, fifth: 7, seventh: 10 }
    #
    # @see Chord Instantiated chord using this definition
    # @see chord-definitions.rb Standard chord definitions
    class ChordDefinition
      # Retrieves a registered chord definition by name.
      #
      # @param name [Symbol] chord definition name
      # @return [ChordDefinition, nil] definition or nil if not found
      #
      # @example
      #   ChordDefinition[:maj]   # => <ChordDefinition :maj>
      #   ChordDefinition[:min7]  # => <ChordDefinition :min7>
      def self.get(name)
        @definitions[name]
      end

      class << self
        alias_method :[], :get
      end

      # Registers a new chord definition.
      #
      # Creates and registers a chord definition with specified intervals and features.
      # The definition becomes available globally for chord creation.
      #
      # @param name [Symbol] unique chord identifier
      # @param offsets [Hash{Symbol => Integer}] semitone intervals from root
      # @param features [Hash] chord characteristics (quality, size, etc.)
      # @return [self]
      #
      # @example Major triad
      #   ChordDefinition.register :maj,
      #     quality: :major,
      #     size: :triad,
      #     offsets: { root: 0, third: 4, fifth: 7 }
      #
      # @example Minor seventh
      #   ChordDefinition.register :min7,
      #     quality: :minor,
      #     size: :seventh,
      #     offsets: { root: 0, third: 3, fifth: 7, seventh: 11 }
      def self.register(name, offsets:, **features)
        definition = ChordDefinition.new(name, offsets: offsets, **features)

        @definitions ||= {}
        @definitions[definition.name] = definition

        @features_by_value ||= {}
        definition.features.each { |k, v| @features_by_value[v] = k }

        @feature_keys ||= Set[]
        features.each_key { |feature_name| @feature_keys << feature_name }

        self
      end

      # Finds chord definition matching a set of pitches.
      #
      # Identifies chord by comparing pitch intervals, accounting for octave reduction.
      #
      # @param pitches [Array<Integer>] MIDI pitch numbers
      # @return [ChordDefinition, nil] matching definition or nil
      #
      # @example
      #   ChordDefinition.find_by_pitches([60, 64, 67])  # => :maj
      def self.find_by_pitches(pitches)
        @definitions.values.find { |d| d.matches(pitches) }
      end

      # Converts feature values to feature hash.
      #
      # @param values [Array<Symbol>] feature values
      # @param hash [Hash] feature key-value pairs
      # @return [Hash] combined features
      #
      # @example
      #   features_from([:major, :triad])
      #   # => { quality: :major, size: :triad }
      def self.features_from(values = nil, hash = nil)
        values ||= []
        hash ||= {}

        features = hash.dup
        values.each { |v| features[@features_by_value[v]] = v }

        features
      end

      # Finds definitions matching specified features.
      #
      # @param values [Array<Symbol>] feature values
      # @param hash [Hash] feature key-value pairs
      # @return [Array<ChordDefinition>] matching definitions
      #
      # @example
      #   find_by_features(quality: :major, size: :triad)
      #   # => [<ChordDefinition :maj>]
      def self.find_by_features(*values, **hash)
        features = features_from(values, hash)
        @definitions.values.select { |d| features <= d.features }
      end

      # Returns feature key for a feature value.
      #
      # @param feature_value [Symbol] feature value
      # @return [Symbol] feature key
      def self.feature_key_of(feature_value)
        @features_by_value[feature_value]
      end

      # Returns all registered feature values.
      #
      # @return [Array<Symbol>] feature values
      def self.feature_values
        @features_by_value.keys
      end

      # Returns all registered feature keys.
      #
      # @return [Set<Symbol>] feature keys
      def self.feature_keys
        @feature_keys
      end

      # Creates a chord definition.
      #
      # @param name [Symbol] chord name
      # @param offsets [Hash{Symbol => Integer}] semitone offsets
      # @param features [Hash] chord features
      #
      # @api private
      def initialize(name, offsets:, **features)
        @name = name.freeze
        @features = features.transform_values(&:dup).transform_values(&:freeze).freeze
        @pitch_offsets = offsets.dup.freeze
        @pitch_names = offsets.collect { |k, v| [v, k] }.to_h.freeze
        freeze
      end

      # Chord name.
      # @return [Symbol]
      attr_reader :name

      # Chord features (quality, size, etc.).
      # @return [Hash{Symbol => Symbol}]
      attr_reader :features

      # Semitone offsets by position name.
      # @return [Hash{Symbol => Integer}]
      attr_reader :pitch_offsets

      # Position names by semitone offset.
      # @return [Hash{Integer => Symbol}]
      attr_reader :pitch_names

      # Calculates chord pitches from root pitch.
      #
      # @param root_pitch [Integer] MIDI root pitch
      # @return [Array<Integer>] chord pitches
      #
      # @example
      #   chord_def.pitches(60)  # => [60, 64, 67] for C major
      def pitches(root_pitch)
        @pitch_offsets.values.collect { |offset| root_pitch + offset }
      end

      # Checks if chord fits within a scale.
      #
      # @param scale [Scale] scale to check against
      # @param chord_root_pitch [Integer] chord root pitch
      # @return [Boolean] true if all chord notes are in scale
      #
      # @example
      #   maj_def.in_scale?(c_major, chord_root_pitch: 60)  # => true
      def in_scale?(scale, chord_root_pitch:)
        !pitches(chord_root_pitch).find { |chord_pitch| scale.note_of_pitch(chord_pitch).nil? }
      end

      # Maps elements to named chord positions.
      #
      # @param elements_or_pitches [Array] elements to map
      # @yield [element] block to extract pitch from element
      # @return [Hash{Symbol => Array}] position names to elements
      #
      # @api private
      def named_pitches(elements_or_pitches, &block)
        pitches = elements_or_pitches.collect do |element_or_pitch|
          [if block_given?
             yield element_or_pitch
           else
             element_or_pitch
           end,
           element_or_pitch]
        end.to_h

        root_pitch = pitches.keys.find do |candidate_root_pitch|
          candidate_pitches = pitches.keys.collect { |p| p - candidate_root_pitch }
          octave_reduce(candidate_pitches).uniq == octave_reduce(@pitch_offsets.values).uniq
        end

        # TODO: OJO: problema con las notas duplicadas, con la identificación de inversiones y con las notas a distancias de más de una octava

        pitches.collect do |pitch, element|
          [@pitch_names[pitch - root_pitch], [element]]
        end.to_h
      end

      # Checks if pitches match this chord definition.
      #
      # Compares octave-reduced pitch sets to determine if they form this chord.
      #
      # @param pitches [Array<Integer>] MIDI pitches to check
      # @return [Boolean] true if pitches match this chord
      #
      # @example
      #   maj_def.matches([60, 64, 67])  # => true (C major)
      #   maj_def.matches([60, 63, 67])  # => false (C minor)
      def matches(pitches)
        reduced_pitches = octave_reduce(pitches).uniq

        !!reduced_pitches.find do |candidate_root_pitch|
          reduced_pitches.sort == octave_reduce(pitches(candidate_root_pitch)).uniq.sort
        end
      end

      # Returns string representation.
      #
      # @return [String]
      def inspect
        "<ChordDefinition: name = #{@name} features = #{@features} pitch_offsets = #{@pitch_offsets}>"
      end

      alias to_s inspect

      private

      # Reduces pitches to within one octave (0-11).
      #
      # @param pitches [Array<Integer>] MIDI pitches
      # @return [Array<Integer>] octave-reduced pitches
      #
      # @api private
      def octave_reduce(pitches)
        pitches.collect { |p| p % 12 }
      end
    end
  end
end
