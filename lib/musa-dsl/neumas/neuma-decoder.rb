require_relative 'neumas'

module Musa::Neumas
  # Neuma decoder infrastructure for converting neuma notation to musical events.
  #
  # Provides base classes for decoding neuma notation (a musical representation format)
  # into GDV (Grade-Duration-Velocity) events. The decoder system supports differential
  # decoding where each event is interpreted relative to the previous event.
  #
  # ## Architecture Overview
  #
  # ### Decoder Hierarchy
  #
  # ```
  # ProtoDecoder (abstract)
  #   └── DifferentialDecoder (abstract)
  #         └── Decoder (stateful base)
  #               ├── NeumaDecoder (GDV output)
  #               └── NeumaDifferentialDecoder (GDVD output)
  # ```
  #
  # ### Key Concepts
  #
  # 1. **Differential Decoding**: Each neuma is interpreted relative to previous state
  #
  #    - Grade: `+2` means "2 steps up from last note"
  #    - Duration: `_2` means "double the base duration"
  #
  # 2. **Stateful Processing**: Decoders maintain `@last` state for differential interpretation
  #
  # 3. **Subcontexts**: Create independent decoder contexts for nested structures
  #
  # 4. **Transcription Integration**: Optional transcriptor for post-processing (ornaments, etc.)
  #
  # ## Processing Pipeline
  #
  # ```ruby
  # Neuma Input → process() → apply() → Transcriptor → GDV Output
  #                  ↓           ↓
  #              Prepare     Apply to
  #              attributes   last state
  # ```
  #
  # ## Neuma Notation
  #
  # Neumas are text-based musical notation:
  # ```ruby
  # "0 +2 +2 -1"        # Grade sequence (scale degrees)
  # "_ _2 _/2"          # Duration modifiers
  # ".st .tr .mor"      # Articulation/ornament modifiers
  # "(+1_/4)+2_"        # Appogiatura (grace note) + main note
  # ```
  #
  # @example Basic usage
  #
  # Decoders are used by the neuma parsing system:
  # ```ruby
  # decoder = Musa::Neumas::Decoders::NeumaDecoder.new(
  #   scale,
  #   base_duration: 1/4r,
  #   transcriptor: transcriptor
  # )
  #
  # # Parse and decode neuma string
  # neumas = "0 +2 +2 -1 0".to_neumas
  # neumas.each { |neuma| decoder.decode(neuma) }
  # ```
  #
  # @see Musa::Neumas Neuma notation system
  # @see Musa::Datasets::GDV Absolute GDV format
  # @see Musa::Datasets::GDVd Differential GDVD format
  # @see Musa::Neumas::Decoders::NeumaDecoder
  # @see Musa::Neumas::Decoders::NeumaDifferentialDecoder
  # @see Musa::Transcription
  #
  # @api public
  module Decoders
    # Abstract base decoder class.
    #
    # Defines the basic decoder interface. All decoders must implement:
    #
    # - `decode(element)` - Main decoding method
    # - `subcontext` - Create independent decoder context
    #
    # ## Subcontexts
    #
    # Subcontexts allow creating independent decoder instances for nested
    # structures (like grace notes) that need their own state tracking.
    #
    # @api public
    class ProtoDecoder
      # Creates subcontext decoder.
      #
      # Returns independent decoder instance for nested decoding.
      # Default implementation returns self (stateless).
      #
      # @return [ProtoDecoder] subcontext decoder instance
      #
      # @api public
      def subcontext
        self
      end

      # Decodes element to musical event.
      #
      # Abstract method - must be implemented by subclasses.
      #
      # @param _element [Object] element to decode
      #
      # @return [Hash] decoded musical event
      #
      # @raise [NotImplementedError] if not overridden
      #
      # @api public
      def decode(_element)
        raise NotImplementedError
      end
    end

    # Differential decoder base class.
    #
    # Adds `process` step to decoding pipeline for preparing/transforming
    # input before final decoding. Useful for setting default values,
    # normalizing formats, etc.
    #
    # ## Pipeline
    #
    # ```ruby
    # input → process(input) → decode(processed)
    # ```
    #
    # @api public
    class DifferentialDecoder < ProtoDecoder
      # Decodes element after processing.
      #
      # Calls `process` to prepare element, then returns processed result.
      #
      # @param gdvd [Hash] GDVD (Grade-Duration-Velocity-Differential) attributes
      #
      # @return [Hash] processed attributes
      #
      # @api public
      def decode(gdvd)
        process gdvd
      end

      # Processes/prepares attributes for decoding.
      #
      # Abstract method - must be implemented by subclasses to transform
      # input attributes (set defaults, normalize, etc.).
      #
      # @param _gdvd [Hash] GDVD attributes
      #
      # @return [Hash] processed attributes
      #
      # @raise [NotImplementedError] if not overridden
      #
      # @api public
      def process(_gdvd)
        raise NotImplementedError
      end
    end

    # Stateful decoder with differential interpretation and transcription.
    #
    # Maintains state (`@base`, `@last`) to interpret each neuma relative to
    # the previous one. Supports optional transcriptor for post-processing
    # (expanding ornaments, applying articulations, etc.).
    #
    # ## Differential Interpretation
    #
    # Each decoded event is interpreted relative to `@last`:
    #
    # - Grade changes: `+2` = last_grade + 2
    # - Duration changes: `_2` = base_duration * 2
    #
    # After decoding, `@last` is updated for next event.
    #
    # ## Processing Pipeline
    #
    # ```ruby
    # Input → process() → apply(on: @last) → update @last → transcriptor → Output
    # ```
    #
    # @example Stateful decoding
    #   decoder = Musa::Neumas::Decoders::NeumaDifferentialDecoder.new(
    #     base_duration: 1/4r
    #   )
    #
    #   # Create mock GDVD object
    #   gdvd1 = Object.new
    #   def gdvd1.clone; self; end
    #   def gdvd1.base_duration=(val); @bd = val; end
    #
    #   result = decoder.decode(gdvd1)
    #   # Returns processed GDVD with base_duration set
    #
    # @api public
    class Decoder < DifferentialDecoder
      # Creates stateful decoder.
      #
      # @param base [Hash] base/initial state for differential decoding
      # @param transcriptor [Transcriptor, nil] optional transcriptor for post-processing
      #
      # @example Create decoder with base state
      #   base_state = { grade: 0, octave: 0, duration: 1/4r, velocity: 1 }
      #   decoder = Musa::Neumas::Decoders::Decoder.new(base_state)
      #
      #   # Decoder maintains state
      #   decoder.base[:grade]     # => 0
      #   decoder.base[:duration]  # => 1/4r
      #
      # @api public
      def initialize(base, transcriptor: nil)
        @base = base
        @last = base.clone

        @transcriptor = transcriptor
      end

      # Transcriptor for post-processing decoded events.
      #
      # @return [Transcriptor, nil] transcriptor instance or nil
      #
      # @api public
      attr_accessor :transcriptor

      # Base state for decoder.
      #
      # @return [Hash] base state
      #
      # @api public
      attr_reader :base

      # Sets base state and resets last state.
      #
      # @param base [Hash] new base state
      #
      # @api public
      def base=(base)
        @base = base
        @last = base.clone
      end

      # Creates independent subcontext decoder.
      #
      # Returns new decoder with same base state but independent `@last` tracking.
      # Used for nested structures like grace notes.
      #
      # @return [Decoder] independent decoder instance
      #
      # @api public
      def subcontext
        Decoder.new @base
      end

      # Decodes attributes with differential interpretation and transcription.
      #
      # Pipeline:
      # 1. Process attributes
      # 2. Apply to last state
      # 3. Update last state
      # 4. Optional transcription
      #
      # @param attributes [Hash] neuma attributes to decode
      #
      # @return [Hash, Array<Hash>] decoded event(s), possibly transcribed
      #
      # @example Create decoder with transcriptor
      #   base_state = { grade: 0, octave: 0, duration: 1/4r, velocity: 1 }
      #
      #   # Create mock transcriptor
      #   transcriptor = Object.new
      #   def transcriptor.transcript(gdv); [gdv, gdv.clone]; end
      #
      #   decoder = Musa::Neumas::Decoders::Decoder.new(
      #     base_state,
      #     transcriptor: transcriptor
      #   )
      #
      #   # Transcriptor can expand events (e.g., ornaments)
      #   decoder.transcriptor  # => transcriptor object
      #
      # @api public
      def decode(attributes)
        result = apply process(attributes), on: @last

        @last = result.clone

        if @transcriptor
          @transcriptor.transcript(result)
        else
          result
        end
      end

      # Applies processed attributes to previous state.
      #
      # Abstract method - must be implemented by subclasses to define how
      # differential attributes are applied to produce absolute values.
      #
      # @param _action [Hash] processed attributes
      # @param on [Hash] previous state to apply attributes to
      #
      # @return [Hash] resulting absolute event
      #
      # @raise [NotImplementedError] if not overridden
      #
      # @api public
      def apply(_action, on:)
        raise NotImplementedError
      end
    end
  end
end

