require_relative 'chords'

module Musa
  # Musical scale system framework.
  #
  # The Scales module provides a comprehensive framework for working with musical scales,
  # supporting multiple scale systems (equal temperament, just intonation, etc.), scale
  # types (major, minor, chromatic, etc.), and musical operations (transposition, interval
  # calculation, frequency generation, etc.).
  #
  # ## Architecture
  #
  # The framework has a hierarchical structure:
  #
  # 1. **ScaleSystem**: Defines the tuning system (e.g., 12-tone equal temperament)
  # 2. **ScaleSystemTuning**: A scale system with specific A frequency (e.g., A=440Hz)
  # 3. **ScaleKind**: Type of scale (major, minor, chromatic, etc.)
  # 4. **Scale**: A scale kind rooted on a specific pitch (e.g., C major, A minor)
  # 5. **NoteInScale**: A specific note within a scale
  #
  # ## Basic Usage
  #
  #     # Access the default system (12-tone equal temperament at A=440Hz)
  #     tuning = Scales::Scales.default_system.default_tuning
  #
  #     # Get a C major scale (root pitch 60 = middle C)
  #     c_major = tuning.major[60]
  #
  #     # Access notes by grade or function
  #     c_major[0]          # => Tonic (C)
  #     c_major.tonic       # => Tonic (C)
  #     c_major.dominant    # => Dominant (G)
  #     c_major[:V]         # => Dominant (G)
  #
  # ## Advanced Features
  #
  # - **Multiple tuning systems**: Support for different A frequencies
  # - **Interval calculations**: Named intervals (M3, P5, etc.) and numeric offsets
  # - **Chromatic operations**: Sharp, flat, and chromatic movements
  # - **Scale navigation**: Move between related scales
  # - **Frequency calculation**: Convert pitches to frequencies
  # - **Chord generation**: Build chords from scale degrees
  #
  # @see Scales Module for registering scale systems
  # @see ScaleSystem Abstract base for scale systems
  # @see EquallyTempered12ToneScaleSystem The default 12-tone equal temperament system
  module Scales
    # Scale system registry.
    #
    # The Scales module provides a central registry for scale systems, allowing access
    # by symbol ID or method name.
    #
    # ## Registration
    #
    # Scale systems register themselves using {register}:
    #
    #     Scales.register EquallyTempered12ToneScaleSystem, default: true
    #
    # ## Access Methods
    #
    # **By symbol**:
    #
    #     Scales[:et12]              # => EquallyTempered12ToneScaleSystem
    #     Scales[:et12][440.0]       # => ScaleSystemTuning with A=440Hz
    #
    # **By method name**:
    #
    #     Scales.et12                # => EquallyTempered12ToneScaleSystem
    #     Scales.et12[440.0]         # => ScaleSystemTuning with A=440Hz
    #
    # **Default system**:
    #
    #     Scales.default_system                      # => The default scale system
    #     Scales.default_system.default_tuning       # => Default tuning (A=440Hz)
    #
    # @example Accessing scale systems
    #   # Get system by symbol
    #   system = Scales::Scales[:et12]
    #
    #   # Get system by method
    #   system = Scales::Scales.et12
    #
    #   # Get default system
    #   system = Scales::Scales.default_system
    #
    # @example Working with tunings
    #   # Get tuning with A=440Hz (default)
    #   tuning = Scales::Scales[:et12][440.0]
    #
    #   # Get tuning with baroque pitch A=415Hz
    #   baroque = Scales::Scales[:et12][415.0]
    #
    # @example Building scales
    #   tuning = Scales::Scales.default_system.default_tuning
    #
    #   # C major scale
    #   c_major = tuning.major[60]
    #
    #   # A minor scale
    #   a_minor = tuning.minor[69]
    module Scales
      # Registers a scale system.
      #
      # Makes the scale system available via symbol lookup and dynamic method.
      # Optionally marks it as the default system.
      #
      # @param scale_system [Class] the ScaleSystem subclass to register
      # @param default [Boolean] whether to set as default system
      # @return [self]
      #
      # @example
      #   Scales.register EquallyTempered12ToneScaleSystem, default: true
      def self.register(scale_system, default: nil)
        @scale_systems ||= {}
        @scale_systems[scale_system.id] = scale_system

        @default_scale_system = scale_system if default

        self.class.define_method scale_system.id do
          scale_system
        end

        self
      end

      # Retrieves a registered scale system by ID.
      #
      # @param id [Symbol] the scale system identifier
      # @return [Class] the ScaleSystem subclass
      # @raise [KeyError] if scale system not found
      #
      # @example
      #   Scales[:et12]  # => EquallyTempered12ToneScaleSystem
      def self.[](id)
        raise KeyError, "Scale system :#{id} not found" unless @scale_systems.key?(id)

        @scale_systems[id]
      end

      # Returns the default scale system.
      #
      # @return [Class] the default ScaleSystem subclass
      #
      # @example
      #   Scales.default_system  # => EquallyTempered12ToneScaleSystem
      def self.default_system
        @default_scale_system
      end
    end

    # Abstract base class for musical scale systems.
    #
    # ScaleSystem defines the foundation of a tuning system, including:
    #
    # - Number of notes per octave
    # - Available intervals
    # - Frequency calculation method
    # - Registered scale kinds (major, minor, etc.)
    #
    # ## Subclass Requirements
    #
    # Subclasses must implement:
    #
    # - {.id}: Unique symbol identifier
    # - {.notes_in_octave}: Number of notes in an octave
    # - {.part_of_tone_size}: Size of smallest pitch unit (for sharps/flats)
    # - {.intervals}: Hash of named intervals to semitone offsets
    # - {.frequency_of_pitch}: Pitch to frequency conversion
    #
    # Optionally override:
    #
    # - {.default_a_frequency}: Reference A frequency (defaults to 440.0 Hz)
    #
    # ## Usage
    #
    # ScaleSystem is accessed via {Scales} module, not instantiated directly:
    #
    #     system = Scales[:et12]           # Get system
    #     tuning = system[440.0]           # Get tuning
    #     scale = tuning.major[60]         # Get scale
    #
    # @abstract Subclass and implement abstract methods
    # @see EquallyTempered12ToneScaleSystem Concrete 12-tone implementation
    # @see ScaleSystemTuning Tuning with specific A frequency
    class ScaleSystem
      # Returns the unique identifier for this scale system.
      #
      # @abstract Subclass must implement
      # @return [Symbol] the scale system ID (e.g., :et12)
      # @raise [RuntimeError] if not implemented in subclass
      #
      # @example
      #   EquallyTempered12ToneScaleSystem.id  # => :et12
      def self.id
        raise 'Method not implemented. Should be implemented in subclass.'
      end

      # Returns the number of notes in one octave.
      #
      # @abstract Subclass must implement
      # @return [Integer] notes per octave (e.g., 12 for chromatic)
      # @raise [RuntimeError] if not implemented in subclass
      #
      # @example
      #   EquallyTempered12ToneScaleSystem.notes_in_octave  # => 12
      def self.notes_in_octave
        raise 'Method not implemented. Should be implemented in subclass.'
      end

      # Returns the size of the smallest pitch unit.
      #
      # Used for calculating sharp (#) and flat (♭) alterations.
      # In equal temperament, this is 1 semitone.
      #
      # @abstract Subclass must implement
      # @return [Integer] smallest unit size
      # @raise [RuntimeError] if not implemented in subclass
      #
      # @example
      #   EquallyTempered12ToneScaleSystem.part_of_tone_size  # => 1
      def self.part_of_tone_size
        raise 'Method not implemented. Should be implemented in subclass.'
      end

      # Returns available intervals as name-to-offset mapping.
      #
      # Intervals are named using standard music theory notation:
      #
      # - **P** (Perfect): P1, P4, P5, P8
      # - **M** (Major): M2, M3, M6, M7
      # - **m** (minor): m2, m3, m6, m7
      # - **TT**: Tritone
      #
      # @abstract Subclass must implement
      # @return [Hash{Symbol => Integer}] interval names to semitone offsets
      # @raise [RuntimeError] if not implemented in subclass
      #
      # @example
      #   intervals[:M3]   # => 4  (major third = 4 semitones)
      #   intervals[:P5]   # => 7  (perfect fifth = 7 semitones)
      #   intervals[:m7]   # => 10 (minor seventh = 10 semitones)
      def self.intervals
        # TODO: implementar intérvalos sinónimos (p.ej, m3 = A2)
        # TODO: implementar identificación de intérvalos, teniendo en cuenta no sólo los semitonos sino los grados de separación
        # TODO: implementar inversión de intérvalos
        raise 'Method not implemented. Should be implemented in subclass.'
      end

      # Calculates frequency for a given pitch.
      #
      # Converts MIDI pitch numbers to frequencies in Hz. The calculation method
      # depends on the tuning system (equal temperament, just intonation, etc.).
      #
      # @abstract Subclass must implement
      # @param pitch [Numeric] MIDI pitch number (60 = middle C, 69 = A440)
      # @param root_pitch [Numeric] root pitch of scale (for non-equal temperaments)
      # @param a_frequency [Numeric] reference A frequency in Hz
      # @return [Float] frequency in Hz
      # @raise [RuntimeError] if not implemented in subclass
      #
      # @example Equal temperament
      #   # A440 (MIDI 69)
      #   frequency_of_pitch(69, 60, 440.0)  # => 440.0
      #
      #   # Middle C (MIDI 60)
      #   frequency_of_pitch(60, 60, 440.0)  # => ~261.63 Hz
      def self.frequency_of_pitch(pitch, root_pitch, a_frequency)
        raise 'Method not implemented. Should be implemented in subclass.'
      end

      # Returns the default A frequency.
      #
      # @return [Float] default A frequency in Hz (440.0 standard concert pitch)
      #
      # @example
      #   ScaleSystem.default_a_frequency  # => 440.0
      def self.default_a_frequency
        440.0
      end

      # Creates or retrieves a tuning for this scale system.
      #
      # Returns a {ScaleSystemTuning} instance for the specified A frequency.
      # Tunings are cached—repeated calls with same frequency return same instance.
      #
      # @param a_frequency [Numeric] reference A frequency in Hz
      # @return [ScaleSystemTuning] tuning instance
      #
      # @example Standard pitch
      #   tuning = ScaleSystem[440.0]
      #
      # @example Baroque pitch
      #   baroque = ScaleSystem[415.0]
      #
      # @example Modern high pitch
      #   modern = ScaleSystem[442.0]
      def self.[](a_frequency)
        a_frequency = a_frequency.to_f

        @a_tunings ||= {}
        @a_tunings[a_frequency] = ScaleSystemTuning.new self, a_frequency unless @a_tunings.key?(a_frequency)

        @a_tunings[a_frequency]
      end

      # Returns semitone offset for a named interval.
      #
      # @param name [Symbol] interval name (e.g., :M3, :P5)
      # @return [Integer] semitone offset
      #
      # @example
      #   offset_of_interval(:P5)  # => 7
      def self.offset_of_interval(name)
        intervals[name]
      end

      # Returns the default tuning (A=440Hz).
      #
      # @return [ScaleSystemTuning] default tuning instance
      #
      # @example
      #   tuning = ScaleSystem.default_tuning
      def self.default_tuning
        self[default_a_frequency]
      end

      # Registers a scale kind (major, minor, etc.) with this system.
      #
      # @param scale_kind_class [Class] ScaleKind subclass to register
      # @return [self]
      #
      # @example
      #   EquallyTempered12ToneScaleSystem.register MajorScaleKind
      def self.register(scale_kind_class)
        @scale_kind_classes ||= {}
        @scale_kind_classes[scale_kind_class.id] = scale_kind_class
        if scale_kind_class.chromatic?
          @chromatic_scale_kind_class = scale_kind_class
        end
        self
      end

      # Retrieves a registered scale kind by ID.
      #
      # @param id [Symbol] scale kind identifier
      # @return [Class] ScaleKind subclass
      # @raise [KeyError] if not found
      def self.scale_kind_class(id)
        raise KeyError, "Scale kind class [#{id}] not found in scale system [#{self.id}]" unless @scale_kind_classes.key? id

        @scale_kind_classes[id]
      end

      # Checks if a scale kind is registered.
      #
      # @param id [Symbol] scale kind identifier
      # @return [Boolean]
      def self.scale_kind_class?(id)
        @scale_kind_classes.key? id
      end

      # Returns all registered scale kinds.
      #
      # @return [Hash{Symbol => Class}] scale kind classes
      def self.scale_kind_classes
        @scale_kind_classes
      end

      # Returns the chromatic scale kind class.
      #
      # @return [Class] chromatic ScaleKind subclass
      # @raise [RuntimeError] if chromatic scale not defined
      def self.chromatic_class
        raise "Chromatic scale kind class for [#{self.id}] scale system undefined" if @chromatic_scale_kind_class.nil?

        @chromatic_scale_kind_class
      end

      # Compares scale systems for equality.
      #
      # @param other [ScaleSystem]
      # @return [Boolean]
      def ==(other)
        self.class == other.class
      end
    end

    # Scale system with specific A frequency tuning.
    #
    # ScaleSystemTuning combines a {ScaleSystem} with a specific reference A frequency,
    # providing access to scale kinds (major, minor, chromatic, etc.) tuned to that
    # frequency.
    #
    # ## Usage
    #
    # Tunings are created via {ScaleSystem.[]}:
    #
    #     tuning = Scales[:et12][440.0]     # Standard pitch
    #     baroque = Scales[:et12][415.0]    # Baroque pitch
    #
    # ## Accessing Scales
    #
    # **By symbol**:
    #
    #     tuning[:major][60]     # C major scale
    #
    # **By method name**:
    #
    #     tuning.major[60]       # C major scale
    #     tuning.minor[69]       # A minor scale
    #
    # **Chromatic scale**:
    #
    #     tuning.chromatic[60]   # C chromatic scale
    #
    # @example Standard usage
    #   tuning = Scales::Scales.default_system.default_tuning
    #   c_major = tuning.major[60]
    #   a_minor = tuning.minor[69]
    #
    # @example Historical pitch
    #   baroque = Scales[:et12][415.0]
    #   scale = baroque.major[60]  # C major at A=415Hz
    #
    # @see ScaleSystem Parent scale system
    # @see ScaleKind Scale types (major, minor, etc.)
    class ScaleSystemTuning
      extend Forwardable

      def initialize(scale_system, a_frequency)
        @scale_system = scale_system
        @a_frequency = a_frequency
        @scale_kinds = {}

        @chromatic_scale_kind = self[@scale_system.chromatic_class.id]

        @scale_system.scale_kind_classes.each_key do |name|
          define_singleton_method name do
            self[name]
          end
        end
      end

      # TODO: allow scales not based in octaves but in other intervals (like fifths or other ratios). Possibly based on intervals definition of ScaleSystem plus a "generator interval" attribute

      def_delegators :@scale_system, :notes_in_octave, :offset_of_interval

      attr_reader :a_frequency, :scale_system

      def [](scale_kind_class_id)
        @scale_kinds[scale_kind_class_id] ||= @scale_system.scale_kind_class(scale_kind_class_id).new self
      end

      def chromatic
        @chromatic_scale_kind
      end

      def frequency_of_pitch(pitch, root)
        @scale_system.frequency_of_pitch(pitch, root, @a_frequency)
      end

      def ==(other)
        self.class == other.class &&
            @scale_system == other.scale_system &&
            @a_frequency == other.a_frequency
      end

      def inspect
        "<ScaleSystemTuning: scale_system = #{@scale_system} a_frequency = #{@a_frequency}>"
      end

      alias to_s inspect
    end

    # Abstract base class for scale types (major, minor, chromatic, etc.).
    #
    # ScaleKind defines a type of scale (major, minor, chromatic, etc.) independent
    # of root pitch or tuning. It specifies:
    #
    # - Scale degrees and their pitch offsets
    # - Function names for each degree (tonic, dominant, etc.)
    # - Number of grades per octave
    # - Whether the scale is chromatic (contains all pitches)
    #
    # ## Subclass Requirements
    #
    # Subclasses must implement:
    #
    # - {.id}: Unique symbol identifier (:major, :minor, :chromatic, etc.)
    # - {.pitches}: Array defining scale structure
    # - {.chromatic?}: Whether this is the chromatic scale (default: false)
    # - {.grades}: Number of grades per octave (if different from pitches.length)
    #
    # ## Pitch Structure
    #
    # The {.pitches} array defines the scale structure:
    #
    #     [{ functions: [:I, :tonic, :_1], pitch: 0 },
    #      { functions: [:II, :supertonic, :_2], pitch: 2 },
    #      ...]
    #
    # - **functions**: Array of symbols that can access this degree
    # - **pitch**: Semitone offset from root
    #
    # ## Dynamic Method Creation
    #
    # Each scale instance gets methods for all registered scale kinds:
    #
    #     note.major     # Get major scale rooted on this note
    #     note.minor     # Get minor scale rooted on this note
    #
    # ## Usage
    #
    # ScaleKind instances are accessed via tuning:
    #
    #     tuning = Scales[:et12][440.0]
    #     major_kind = tuning[:major]        # ScaleKind instance
    #     c_major = major_kind[60]           # Scale instance
    #
    # Or directly via convenience methods:
    #
    #     c_major = tuning.major[60]
    #
    # @abstract Subclass and implement abstract methods
    # @see MajorScaleKind Concrete major scale implementation
    # @see MinorNaturalScaleKind Concrete minor scale implementation
    # @see ChromaticScaleKind Concrete chromatic scale implementation
    # @see Scale Instantiated scale with root pitch
    class ScaleKind
      # Creates a scale kind instance.
      #
      # @param tuning [ScaleSystemTuning] the tuning context
      #
      # @api private
      def initialize(tuning)
        @tuning = tuning
        @scales = {}
      end

      # The tuning context.
      # @return [ScaleSystemTuning]
      attr_reader :tuning

      # Creates or retrieves a scale rooted on specific pitch.
      #
      # Scales are cached—repeated calls with same pitch return same instance.
      #
      # @param root_pitch [Integer] MIDI root pitch (60 = middle C)
      # @return [Scale] scale instance
      #
      # @example
      #   major_kind = tuning[:major]
      #   c_major = major_kind[60]     # C major
      #   g_major = major_kind[67]     # G major
      def [](root_pitch)
        @scales[root_pitch] = Scale.new(self, root_pitch: root_pitch) unless @scales.key?(root_pitch)
        @scales[root_pitch]
      end

      # Returns scale with default root (middle C, MIDI 60).
      #
      # @return [Scale] scale rooted on middle C
      #
      # @example
      #   tuning.major.default_root  # C major
      def default_root
        self[60]
      end

      # Returns scale with absolute root (MIDI 0).
      #
      # @return [Scale] scale rooted on MIDI 0
      #
      # @example
      #   tuning.major.absolut  # Scale rooted at MIDI 0
      def absolut
        self[0]
      end

      # Checks scale kind equality.
      #
      # @param other [ScaleKind]
      # @return [Boolean]
      def ==(other)
        self.class == other.class && @tuning == other.tuning
      end

      # Returns string representation.
      #
      # @return [String]
      def inspect
        "<#{self.class.name}: tuning = #{@tuning}>"
      end

      alias to_s inspect

      # Returns the unique identifier for this scale kind.
      #
      # @abstract Subclass must implement
      # @return [Symbol] scale kind ID (e.g., :major, :minor, :chromatic)
      # @raise [RuntimeError] if not implemented in subclass
      #
      # @example
      #   MajorScaleKind.id  # => :major
      def self.id
        raise 'Method not implemented. Should be implemented in subclass.'
      end

      # Returns the pitch structure definition.
      #
      # Defines the scale degrees and their pitch offsets from the root.
      # Each entry specifies function names and semitone offset.
      #
      # @abstract Subclass must implement
      # @return [Array<Hash>] array of pitch definitions with:
      #   - **:functions** [Array<Symbol>]: function names for this degree
      #   - **:pitch** [Integer]: semitone offset from root
      # @raise [RuntimeError] if not implemented in subclass
      #
      # @example Major scale structure (partial)
      #   [{ functions: [:I, :tonic, :_1], pitch: 0 },
      #    { functions: [:II, :supertonic, :_2], pitch: 2 },
      #    { functions: [:III, :mediant, :_3], pitch: 4 },
      #    ...]
      def self.pitches
        raise 'Method not implemented. Should be implemented in subclass.'
      end

      # Indicates whether this is the chromatic scale.
      #
      # Only one scale kind per system should return true. The chromatic scale
      # contains all notes in the scale system and is used as a fallback for
      # non-diatonic notes.
      #
      # @return [Boolean] true if chromatic scale (default: false)
      #
      # @example
      #   ChromaticScaleKind.chromatic?  # => true
      #   MajorScaleKind.chromatic?      # => false
      def self.chromatic?
        false
      end

      # Returns the number of grades per octave.
      #
      # For scales defining extended harmony (8th, 9th, etc.), this returns
      # the number of diatonic degrees within one octave. Defaults to the
      # number of pitch definitions.
      #
      # @return [Integer] number of grades per octave
      #
      # @example
      #   MajorScaleKind.grades  # => 7 (not 13, even with extended degrees)
      def self.grades
        pitches.length
      end

      # Returns grade index for a function symbol.
      #
      # @param symbol [Symbol] function name (e.g., :tonic, :dominant, :V)
      # @return [Integer, nil] grade index or nil if not found
      #
      # @example
      #   MajorScaleKind.grade_of_function(:tonic)     # => 0
      #   MajorScaleKind.grade_of_function(:dominant)  # => 4
      #   MajorScaleKind.grade_of_function(:V)         # => 4
      #
      # @api private
      def self.grade_of_function(symbol)
        create_grade_functions_index unless @grade_names_index
        @grade_names_index[symbol]
      end

      # Returns all function symbols for accessing scale degrees.
      #
      # @return [Array<Symbol>] all function names
      #
      # @example
      #   MajorScaleKind.grades_functions
      #   # => [:I, :_1, :tonic, :first, :II, :_2, :supertonic, :second, ...]
      #
      # @api private
      def self.grades_functions
        create_grade_functions_index unless @grade_names_index
        @grade_names_index.keys
      end

      private

      # Creates internal index mapping function names to grade indices.
      #
      # @return [self]
      #
      # @api private
      def self.create_grade_functions_index
        @grade_names_index = {}
        pitches.each_index do |i|
          pitches[i][:functions].each do |function|
            @grade_names_index[function] = i
          end
        end

        self
      end
    end

    # Instantiated scale with specific root pitch.
    #
    # Scale represents a concrete scale (major, minor, etc.) rooted on a specific
    # pitch. It provides access to scale degrees, interval calculations, frequency
    # generation, and chord construction.
    #
    # ## Creation
    #
    # Scales are created via {ScaleKind}:
    #
    #     tuning = Scales[:et12][440.0]
    #     c_major = tuning.major[60]        # Via convenience method
    #     a_minor = tuning[:minor][69]      # Via bracket notation
    #
    # ## Accessing Notes
    #
    # **By numeric grade** (0-based):
    #
    #     scale[0]    # First degree (tonic)
    #     scale[1]    # Second degree
    #     scale[4]    # Fifth degree
    #
    # **By function name** (dynamic methods):
    #
    #     scale.tonic       # First degree
    #     scale.dominant    # Fifth degree
    #     scale.mediant     # Third degree
    #
    # **By Roman numeral**:
    #
    #     scale[:I]     # First degree
    #     scale[:V]     # Fifth degree
    #     scale[:IV]    # Fourth degree
    #
    # **With accidentals** (sharp # or flat _):
    #
    #     scale[:I#]    # Raised tonic
    #     scale[:V_]    # Flatted dominant
    #     scale['II##'] # Double-raised second
    #
    # ## Note Operations
    #
    # Each note is a {NoteInScale} instance with full capabilities:
    #
    #     note = scale.tonic
    #     note.pitch              # MIDI pitch number
    #     note.frequency          # Frequency in Hz
    #     note.chord              # Build chord from note
    #     note.up(:P5)            # Navigate by interval
    #     note.sharp              # Raise by semitone
    #
    # ## Special Methods
    #
    # - **chromatic**: Access chromatic scale at same root
    # - **octave**: Transpose scale to different octave
    # - **note_of_pitch**: Find note for specific MIDI pitch
    #
    # @example Basic scale access
    #   c_major = tuning.major[60]
    #   c_major.tonic.pitch      # => 60 (C)
    #   c_major.dominant.pitch   # => 67 (G)
    #   c_major[:III].pitch      # => 64 (E)
    #
    # @example Chromatic alterations
    #   c_major[:I#].pitch       # => 61 (C#)
    #   c_major[:V_].pitch       # => 66 (F#/Gb)
    #
    # @example Building chords
    #   c_major.tonic.chord              # C major triad
    #   c_major.dominant.chord :seventh  # G dominant 7th
    #
    # @see ScaleKind Scale type definition
    # @see NoteInScale Individual note in scale
    class Scale
      extend Forwardable

      # Creates a scale instance.
      #
      # @param kind [ScaleKind] the scale kind
      # @param root_pitch [Integer] MIDI root pitch
      #
      # @api private
      def initialize(kind, root_pitch:)
        @notes_by_grade = {}
        @notes_by_pitch = {}

        @kind = kind

        @root_pitch = root_pitch

        @kind.class.grades_functions.each do |name|
          define_singleton_method name do
            self[name]
          end
        end

        freeze
      end

      # Delegates tuning access to kind.
      def_delegators :@kind, :tuning

      # Scale kind (major, minor, etc.).
      # @return [ScaleKind]
      attr_reader :kind

      # Root pitch (MIDI number).
      # @return [Integer]
      attr_reader :root_pitch

      # Returns the root note (first degree).
      #
      # Equivalent to scale[0] or scale.tonic.
      #
      # @return [NoteInScale] root note
      #
      # @example
      #   c_major.root.pitch  # => 60
      def root
        self[0]
      end

      # Returns the chromatic scale at the same root.
      #
      # @return [Scale] chromatic scale rooted at same pitch
      #
      # @example
      #   c_major.chromatic  # Chromatic scale starting at C
      def chromatic
        @kind.tuning.chromatic[@root_pitch]
      end

      # Returns the scale rooted at absolute pitch 0.
      #
      # @return [Scale] scale of same kind at MIDI 0
      #
      # @example
      #   c_major.absolut  # Major scale at MIDI 0
      def absolut
        @kind[0]
      end

      # Transposes scale by octaves.
      #
      # @param octave [Integer] octave offset (positive = up, negative = down)
      # @return [Scale] transposed scale
      # @raise [ArgumentError] if octave is not integer
      #
      # @example
      #   c_major.octave(1)   # C major one octave higher
      #   c_major.octave(-1)  # C major one octave lower
      def octave(octave)
        raise ArgumentError, "#{octave} is not integer" unless octave == octave.to_i

        @kind[@root_pitch + octave * @kind.class.grades]
      end

      # Accesses scale degree by grade, symbol, or function name.
      #
      # Supports multiple access patterns:
      # - **Integer**: Numeric grade (0-based)
      # - **Symbol/String**: Function name or Roman numeral
      # - **With accidentals**: Add '#' for sharp, '_' for flat
      #
      # Notes are cached—repeated access returns same instance.
      #
      # @param grade_or_symbol [Integer, Symbol, String] degree specifier
      # @return [NoteInScale] note at specified degree
      # @raise [ArgumentError] if grade_or_symbol is invalid type
      #
      # @example Numeric access
      #   scale[0]    # Tonic
      #   scale[4]    # Dominant (in major/minor)
      #
      # @example Function name access
      #   scale[:tonic]
      #   scale[:dominant]
      #   scale[:mediant]
      #
      # @example Roman numeral access
      #   scale[:I]     # Tonic
      #   scale[:V]     # Dominant
      #   scale[:IV]    # Subdominant
      #
      # @example With accidentals
      #   scale[:I#]     # Raised tonic
      #   scale[:V_]     # Flatted dominant
      #   scale['II##']  # Double-raised second
      def [](grade_or_symbol)

        raise ArgumentError, "grade_or_symbol '#{grade_or_symbol}' should be a Integer, String or Symbol" unless grade_or_symbol.is_a?(Symbol) || grade_or_symbol.is_a?(String) || grade_or_symbol.is_a?(Integer)

        wide_grade, sharps = grade_of(grade_or_symbol)

        unless @notes_by_grade.key?(wide_grade)

          octave = wide_grade / @kind.class.grades
          grade = wide_grade % @kind.class.grades

          pitch = @root_pitch +
              octave * @kind.tuning.notes_in_octave +
              @kind.class.pitches[grade][:pitch]

          note = NoteInScale.new self, grade, octave, pitch

          @notes_by_grade[wide_grade] = @notes_by_pitch[pitch] = note
        end


        @notes_by_grade[wide_grade].sharp(sharps)
      end

      # Converts grade specifier to numeric grade and accidentals.
      #
      # @param grade_or_string_or_symbol [Integer, Symbol, String] grade specifier
      # @return [Array(Integer, Integer)] wide grade and accidentals count
      #
      # @api private
      def grade_of(grade_or_string_or_symbol)
        name, wide_grade, accidentals = parse_grade(grade_or_string_or_symbol)

        grade = @kind.class.grade_of_function name if name

        octave = wide_grade / @kind.class.grades if wide_grade
        grade = wide_grade % @kind.class.grades if wide_grade

        octave ||= 0

        return octave * @kind.class.grades + grade, accidentals
      end

      # Parses grade string/symbol into components.
      #
      # Handles formats like "I#", ":V_", "7##", extracting function name,
      # numeric grade, and accidentals.
      #
      # @param neuma_grade [Integer, Symbol, String] grade to parse
      # @return [Array(Symbol, Integer, Integer)] name, wide_grade, accidentals
      #
      # @api private
      def parse_grade(neuma_grade)
        name = wide_grade = nil
        accidentals = 0

        case neuma_grade
        when Symbol, String
          match = /\A(?<name>[^[#|_]]*)(?<accidental_sharps>#*)(?<accidental_flats>_*)\Z/.match neuma_grade.to_s

          if match
            if match[:name] == match[:name].to_i.to_s
              wide_grade = match[:name].to_i
            else
              name = match[:name].to_sym unless match[:name].empty?
            end
            accidentals = match[:accidental_sharps].length - match[:accidental_flats].length
          else
            name = neuma_grade.to_sym unless (neuma_grade.nil? || neuma_grade.empty?)
          end
        when Numeric
          wide_grade = neuma_grade.to_i

        else
          raise ArgumentError, "Cannot eval #{neuma_grade} as name or grade position."
        end

        return name, wide_grade, accidentals
      end

      # Finds note for a specific MIDI pitch.
      #
      # Searches for a note in the scale matching the given pitch. Options control
      # behavior when pitch is not in scale.
      #
      # @param pitch [Integer] MIDI pitch number
      # @param allow_chromatic [Boolean] if true, return chromatic note when not in scale
      # @param allow_nearest [Boolean] if true, return nearest scale note
      # @return [NoteInScale, nil] matching note or nil
      #
      # @example Diatonic note
      #   c_major.note_of_pitch(64)  # => E (in scale)
      #
      # @example Chromatic note
      #   c_major.note_of_pitch(63, allow_chromatic: true)  # => Eb (chromatic)
      #
      # @example Nearest note
      #   c_major.note_of_pitch(63, allow_nearest: true)  # => E or D (nearest)
      def note_of_pitch(pitch, allow_chromatic: nil, allow_nearest: nil)
        allow_chromatic ||= false
        allow_nearest ||= false

        note = @notes_by_pitch[pitch]

        unless note
          pitch_offset = pitch - @root_pitch

          pitch_offset_in_octave = pitch_offset % @kind.tuning.scale_system.notes_in_octave
          pitch_offset_octave = pitch_offset / @kind.tuning.scale_system.notes_in_octave

          grade = @kind.class.pitches.find_index { |pitch_definition| pitch_definition[:pitch] == pitch_offset_in_octave }

          if grade
            wide_grade = pitch_offset_octave * @kind.class.grades + grade
            note = self[wide_grade]

          elsif allow_nearest
            sharps = 0

            until note
              note = note_of_pitch(pitch - (sharps += 1) * @kind.tuning.scale_system.part_of_tone_size)
              note ||= note_of_pitch(pitch + sharps * @kind.tuning.scale_system.part_of_tone_size)
            end

          elsif allow_chromatic
            nearest = note_of_pitch(pitch, allow_nearest: true)

            note = chromatic.note_of_pitch(pitch).with_background(scale: self, grade: nearest.grade, octave: nearest.octave, sharps: (pitch - nearest.pitch) / @kind.tuning.scale_system.part_of_tone_size)
          end
        end

        note
      end

      # Returns semitone offset for a named interval.
      #
      # @param interval_name [Symbol] interval name (e.g., :M3, :P5)
      # @return [Integer] semitone offset
      #
      # @example
      #   scale.offset_of_interval(:P5)  # => 7
      #   scale.offset_of_interval(:M3)  # => 4
      def offset_of_interval(interval_name)
        @kind.tuning.offset_of_interval(interval_name)
      end

      # Checks scale equality.
      #
      # Scales are equal if they have same kind and root pitch.
      #
      # @param other [Scale]
      # @return [Boolean]
      def ==(other)
        self.class == other.class &&
            @kind == other.kind &&
            @root_pitch == other.root_pitch
      end

      # Returns string representation.
      #
      # @return [String]
      def inspect
        "<Scale: kind = #{@kind} root_pitch = #{@root_pitch}>"
      end

      alias to_s inspect
    end

    # Note within a scale context.
    #
    # NoteInScale represents a specific note within a scale, providing rich musical
    # functionality including:
    # - Pitch and frequency information
    # - Interval navigation (up, down, by named intervals)
    # - Chromatic alterations (sharp, flat)
    # - Scale navigation (change scales while keeping pitch)
    # - Chord construction
    # - Octave transposition
    #
    # ## Creation
    #
    # Notes are created via scale access, not directly:
    #
    #     scale = tuning.major[60]
    #     note = scale.tonic           # NoteInScale instance
    #     note = scale[:V]             # Another NoteInScale
    #
    # ## Basic Properties
    #
    #     note.pitch       # MIDI pitch number
    #     note.grade       # Scale degree (0-based)
    #     note.octave      # Octave relative to scale root
    #     note.frequency   # Frequency in Hz
    #     note.functions   # Function names for this degree
    #
    # ## Interval Navigation
    #
    # **Natural intervals** (diatonic, within scale):
    #
    #     note.up(2)        # Up 2 scale degrees
    #     note.down(1)      # Down 1 scale degree
    #
    # **Chromatic intervals** (by semitones or named intervals):
    #
    #     note.up(:P5)      # Up perfect fifth
    #     note.up(7)        # Up 7 semitones (if chromatic specified)
    #     note.down(:M3)    # Down major third
    #
    # ## Chromatic Alterations
    #
    #     note.sharp        # Raise by 1 semitone
    #     note.sharp(2)     # Raise by 2 semitones
    #     note.flat         # Lower by 1 semitone
    #     note.flat(2)      # Lower by 2 semitones
    #
    # ## Scale Navigation
    #
    #     note.scale(:minor)     # Same pitch in minor scale
    #     note.major             # Same pitch in major scale
    #     note.chromatic         # Same pitch in chromatic scale
    #
    # ## Chord Construction
    #
    #     note.chord                      # Build triad
    #     note.chord :seventh             # Build seventh chord
    #     note.chord quality: :minor      # Build with features
    #
    # ## Background Scale Context
    #
    # Chromatic notes remember their diatonic context:
    #
    #     c# = c_major.tonic.sharp        # C# in C major context
    #     c#.background_scale             # => c_major
    #     c#.background_note              # => C (natural)
    #     c#.background_sharps            # => 1
    #
    # @example Basic usage
    #   c_major = tuning.major[60]
    #   tonic = c_major.tonic
    #   tonic.pitch       # => 60
    #   tonic.frequency   # => ~261.63 Hz
    #
    # @example Interval navigation
    #   tonic.up(:P5).pitch        # => 67 (G)
    #   tonic.up(4, :natural).pitch # => 71 (4 scale degrees = B)
    #
    # @example Chromatic alterations
    #   tonic.sharp.pitch  # => 61 (C#)
    #   tonic.flat.pitch   # => 59 (B)
    #
    # @example Chord building
    #   tonic.chord              # C major triad
    #   tonic.chord :seventh     # C major 7th
    #
    # @see Scale Parent scale
    # @see Chord Chord construction
    class NoteInScale

      # Creates a note within a scale.
      #
      # @param scale [Scale] parent scale
      # @param grade [Integer] scale degree (0-based)
      # @param octave [Integer] octave relative to scale root
      # @param pitch [Numeric] MIDI pitch (Integer, Rational, or Float for microtones)
      # @param background_scale [Scale, nil] diatonic context for chromatic notes
      # @param background_grade [Integer, nil] diatonic grade for chromatic notes
      # @param background_octave [Integer, nil] diatonic octave for chromatic notes
      # @param background_sharps [Integer, nil] sharps/flats from diatonic note
      #
      # @api private
      def initialize(scale, grade, octave, pitch, background_scale: nil, background_grade: nil, background_octave: nil, background_sharps: nil)
        @scale = scale
        @grade = grade
        @octave = octave
        @pitch = pitch

        @background_scale = background_scale
        @background_grade = background_grade
        @background_octave = background_octave
        @background_sharps = background_sharps

        @scale.kind.tuning.scale_system.scale_kind_classes.each_key do |name|
          define_singleton_method name do
            scale(name)
          end
        end
      end

      # Scale degree (0-based).
      # @return [Integer]
      attr_reader :grade

      # MIDI pitch number.
      # @return [Numeric]
      attr_reader :pitch

      # Returns function names for this scale degree.
      #
      # @return [Array<Symbol>] function symbols
      #
      # @example
      #   c_major.tonic.functions  # => [:I, :_1, :tonic, :first]
      def functions
        @scale.kind.class.pitches[grade][:functions]
      end

      # Transposes note or returns current octave.
      #
      # **Without argument**: Returns current octave relative to scale root.
      #
      # **With argument**: Returns note transposed by octave offset.
      #
      # @param octave [Integer, nil] octave offset (nil to query current)
      # @param absolute [Boolean] if true, ignore current octave
      # @return [Integer, NoteInScale] current octave or transposed note
      # @raise [ArgumentError] if octave is not integer
      #
      # @example Query octave
      #   note.octave  # => 0 (at scale root octave)
      #
      # @example Transpose relative
      #   note.octave(1).pitch   # Up one octave from current
      #   note.octave(-1).pitch  # Down one octave from current
      #
      # @example Transpose absolute
      #   note.octave(2, absolute: true).pitch  # At octave 2, regardless of current
      def octave(octave = nil, absolute: false)
        if octave.nil?
          @octave
        else
          raise ArgumentError, "#{octave} is not integer" unless octave == octave.to_i

          @scale[@grade + ((absolute ? 0 : @octave) + octave) * @scale.kind.class.grades]
        end
      end

      # Creates a copy with background scale context.
      #
      # Used internally when creating chromatic notes to remember their
      # diatonic context.
      #
      # @param scale [Scale] background diatonic scale
      # @param grade [Integer, nil] background grade
      # @param octave [Integer, nil] background octave
      # @param sharps [Integer, nil] accidentals from background note
      # @return [NoteInScale] new note with background context
      #
      # @api private
      def with_background(scale:, grade: nil, octave: nil, sharps: nil)
        NoteInScale.new(@scale, @grade, @octave, @pitch,
                        background_scale: scale,
                        background_grade: grade,
                        background_octave: octave,
                        background_sharps: sharps)
      end

      # Background diatonic scale (for chromatic notes).
      # @return [Scale, nil]
      attr_reader :background_scale

      # Returns the diatonic note this chromatic note is based on.
      #
      # @return [NoteInScale, nil] background note or nil
      #
      # @example
      #   c# = c_major.tonic.sharp
      #   c#.background_note.pitch  # => 60 (C natural)
      def background_note
        @background_scale[@background_grade + (@background_octave || 0) * @background_scale.kind.class.grades] if @background_grade
      end

      # Sharps/flats from background note.
      # @return [Integer, nil]
      attr_reader :background_sharps

      # Returns wide grade (grade + octave * grades_per_octave).
      #
      # @return [Integer]
      #
      # @example
      #   note.wide_grade  # => 7 (second octave, first degree)
      #
      # @api private
      def wide_grade
        @grade + @octave * @scale.kind.class.grades
      end

      # Navigates upward by interval.
      #
      # Supports both natural (diatonic) and chromatic (semitone) intervals.
      #
      # - **Numeric interval + :natural**: Move by scale degrees
      # - **Symbol or numeric interval + :chromatic**: Move by semitones or named interval
      #
      # @param interval_name_or_interval [Symbol, Integer] interval
      # @param natural_or_chromatic [Symbol, nil] :natural or :chromatic
      # @param sign [Integer] direction multiplier (internal use)
      # @return [NoteInScale] note at interval above
      #
      # @example Natural interval (scale degrees)
      #   note.up(2, :natural)  # Up 2 scale degrees
      #
      # @example Chromatic interval (semitones)
      #   note.up(:P5)  # Up perfect fifth (7 semitones)
      #   note.up(7)    # Up 7 semitones (if chromatic)
      def up(interval_name_or_interval, natural_or_chromatic = nil, sign: nil)

        sign ||= 1

        if interval_name_or_interval.is_a?(Numeric)
          natural_or_chromatic ||= :natural
        else
          natural_or_chromatic = :chromatic
        end

        if natural_or_chromatic == :chromatic
          interval = if interval_name_or_interval.is_a?(Symbol)
                       @scale.kind.tuning.offset_of_interval(interval_name_or_interval)
                     else
                       interval_name_or_interval
                     end

          calculate_note_of_pitch(@pitch, sign * interval)
        else
          @scale[@grade + sign * interval_name_or_interval]
        end
      end

      def calculate_note_of_pitch(in_scale_pitch, sharps)
        pitch = in_scale_pitch + sharps * @scale.kind.tuning.scale_system.part_of_tone_size

        if pitch == @pitch
          self
        else
          note = @scale.note_of_pitch(pitch, allow_chromatic: true)
          if @background_scale
            note.on(@background_scale) || note
          else
            note
          end
        end
      end

      private :calculate_note_of_pitch

      # Navigates downward by interval.
      #
      # Same as {#up} but in reverse direction.
      #
      # @param interval_name_or_interval [Symbol, Integer] interval
      # @param natural_or_chromatic [Symbol, nil] :natural or :chromatic
      # @return [NoteInScale] note at interval below
      #
      # @example
      #   note.down(2, :natural)  # Down 2 scale degrees
      #   note.down(:P5)          # Down perfect fifth
      def down(interval_name_or_interval, natural_or_chromatic = nil)
        up(interval_name_or_interval, natural_or_chromatic, sign: -1)
      end

      # Raises note by semitones (adds sharps).
      #
      # @param count [Integer, nil] number of semitones (default 1)
      # @return [NoteInScale] raised note
      #
      # @example
      #   note.sharp.pitch     # Up 1 semitone
      #   note.sharp(2).pitch  # Up 2 semitones
      def sharp(count = nil)
        count ||= 1
        calculate_note_of_pitch(@pitch, count)
      end

      # Lowers note by semitones (adds flats).
      #
      # @param count [Integer, nil] number of semitones (default 1)
      # @return [NoteInScale] lowered note
      #
      # @example
      #   note.flat.pitch     # Down 1 semitone
      #   note.flat(2).pitch  # Down 2 semitones
      def flat(count = nil)
        count ||= 1
        sharp(-count)
      end

      # Calculates frequency in Hz.
      #
      # Uses the scale system's frequency calculation (equal temperament,
      # just intonation, etc.) and the tuning's A frequency.
      #
      # @return [Float] frequency in Hz
      #
      # @example
      #   c_major.tonic.frequency  # => ~261.63 Hz (middle C at A=440)
      def frequency
        @scale.kind.tuning.frequency_of_pitch(@pitch, @scale.root_pitch)
      end

      # Changes scale while keeping pitch, or returns current scale.
      #
      # **Without argument**: Returns current scale.
      #
      # **With argument**: Returns note at same pitch in different scale kind.
      #
      # @param kind_id_or_kind [Symbol, ScaleKind, nil] scale kind or ID
      # @return [Scale, NoteInScale] current scale or note in new scale
      #
      # @example Query current scale
      #   note.scale  # => <Scale: kind = MajorScaleKind ...>
      #
      # @example Change to minor
      #   note.scale(:minor)  # Same pitch in minor scale
      #
      # @example Dynamic method
      #   note.minor   # Same as note.scale(:minor)
      #   note.major   # Same as note.scale(:major)
      def scale(kind_id_or_kind = nil)
        if kind_id_or_kind.nil?
          @scale
        else
          if kind_id_or_kind.is_a? ScaleKind
            kind_id_or_kind[@pitch]
          else
            @scale.kind.tuning[kind_id_or_kind][@pitch]
          end
        end
      end

      # Finds this note in another scale.
      #
      # Searches for a note with the same pitch in the target scale.
      #
      # @param scale [Scale] target scale to search
      # @return [NoteInScale, nil] note in target scale or nil
      #
      # @example
      #   c_major_tonic = c_major.tonic
      #   c_minor = tuning.minor[60]
      #   c_major_tonic.on(c_minor)  # C in C minor scale
      def on(scale)
        scale.note_of_pitch @pitch
      end

      # Builds a chord rooted on this note.
      #
      # Creates a chord using this note as the root. Chord can be specified by:
      # - Feature values (:triad, :seventh, :major, :minor, etc.)
      # - Feature hash (quality:, size:)
      # - Chord definition name (not shown here, see Chord.with_root)
      #
      # If no features specified, defaults to major triad.
      #
      # @param feature_values [Array<Symbol>] feature values (size, quality, etc.)
      # @param allow_chromatic [Boolean] allow non-diatonic chord notes
      # @param move [Hash{Symbol => Integer}] initial octave moves
      # @param duplicate [Hash{Symbol => Integer, Array<Integer>}] initial duplications
      # @param features_hash [Hash] feature key-value pairs
      # @return [Chord] chord rooted on this note
      #
      # @example Default triad
      #   note.chord  # Major triad
      #
      # @example Specified size
      #   note.chord :seventh   # Seventh chord matching scale
      #   note.chord :ninth     # Ninth chord
      #
      # @example With features
      #   note.chord quality: :minor, size: :seventh
      #   note.chord :minor, :seventh  # Same as above
      #
      # @example With voicing
      #   note.chord :seventh, move: {root: -1}, duplicate: {fifth: 1}
      #
      # @see Chord Chord class
      def chord(*feature_values,
                allow_chromatic: nil,
                move: nil,
                duplicate: nil,
                **features_hash)

        features = { size: :triad } if feature_values.empty? && features_hash.empty?
        features ||= Musa::Chords::ChordDefinition.features_from(feature_values, features_hash)

        Musa::Chords::Chord.with_root(self,
                                      allow_chromatic: allow_chromatic,
                                      move: move,
                                      duplicate: duplicate,
                                      **features)
      end

      # Checks note equality.
      #
      # Notes are equal if they have same scale, grade, octave, and pitch.
      #
      # @param other [NoteInScale]
      # @return [Boolean]
      def ==(other)
        self.class == other.class &&
            @scale == other.scale &&
            @grade == other.grade &&
            @octave == other.octave &&
            @pitch == other.pitch
      end

      # Returns string representation.
      #
      # @return [String]
      def inspect
        "<NoteInScale: grade = #{@grade} octave = #{@octave} pitch = #{@pitch} scale = (#{@scale.kind.class.name} on #{scale.root_pitch})>"
      end

      alias to_s inspect
    end
  end
end
