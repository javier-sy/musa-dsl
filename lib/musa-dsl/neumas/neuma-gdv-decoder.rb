require_relative 'neuma-decoder'

module Musa::Neumas
  module Decoders
    # GDV neuma decoder for converting neumas to Grade-Duration-Velocity events.
    #
    # Converts neuma notation (GDVD - differential format) to GDV (absolute format)
    # using scale information. This decoder is the primary way to transform text-based
    # neuma notation into playable musical events.
    #
    # ## GDVD vs GDV
    #
    # - **GDVD** (differential): Relative changes `+2 _2` (up 2 steps, double duration)
    # - **GDV** (absolute): Absolute values `{grade: 2, duration: 1/2r}` ready for playback
    #
    # ## Conversion Process
    #
    # ```ruby
    # Neuma String → Parser → GDVD → NeumaDecoder → GDV → Transcriptor → MIDI/MusicXML
    # "0 +2 +2 -1"              ↓                      ↓
    #                   {grade_diff: +2}    {grade: 2, duration: 1/4r}
    # ```
    #
    # ## Scale Integration
    #
    # The decoder uses a scale to interpret grade values:
    # ```ruby
    # scale = Musa::Scales::Scales.et12[440.0].major[60]
    # decoder = NeumaDecoder.new(scale)
    #
    # # Grade 2 in C major = E (C=0, D=1, E=2)
    # ```
    #
    # ## Appogiatura Handling
    #
    # Grace notes (appogiatura) are processed recursively:
    # ```ruby
    # "(+1_/4)+2_"  # Grace note +1 with duration 1/4, main note +2
    # ```
    #
    # Both the grace note and main note are converted from GDVD to GDV.
    #
    # @example Using with transcriptor
    #   scale = Musa::Scales::Scales.et12[440.0].major[60]
    #
    #   # Create mock transcriptor
    #   transcriptor = Object.new
    #   def transcriptor.transcript(gdv); [gdv]; end
    #
    #   decoder = Musa::Neumas::Decoders::NeumaDecoder.new(
    #     scale,
    #     base_duration: 1/4r,
    #     transcriptor: transcriptor
    #   )
    #
    #   # Transcriptor will process decoded events
    #   decoder.transcriptor  # => transcriptor object
    #
    # @see Musa::Neumas::Decoders::Decoder
    # @see Musa::Scales
    # @see Musa::Transcription
    #
    # @api public
    class NeumaDecoder < Decoder # to get a GDV
      # Creates GDV neuma decoder.
      #
      # @param scale [Scale] scale for interpreting grade values
      # @param base_duration [Rational, nil] base duration unit (default: 1/4)
      # @param transcriptor [Transcriptor, nil] optional transcriptor for ornaments
      # @param base [Hash, nil] initial state (auto-created if nil)
      #
      # @example Create decoder with scale
      #   scale = Object.new
      #   decoder = Musa::Neumas::Decoders::NeumaDecoder.new(
      #     scale,
      #     base_duration: 1/4r
      #   )
      #
      #   # Check initial state
      #   decoder.base[:grade]      # => 0
      #   decoder.base[:duration]   # => 1/4r
      #
      # @example Custom initial state
      #   scale = Object.new
      #   decoder = Musa::Neumas::Decoders::NeumaDecoder.new(
      #     scale,
      #     base: { grade: 2, octave: 1, duration: 1/8r, velocity: 0.8 }
      #   )
      #
      #   # Verify custom state
      #   decoder.base[:grade]   # => 2
      #   decoder.base[:octave]  # => 1
      #
      # @api public
      def initialize(scale, base_duration: nil, transcriptor: nil, base: nil)
        @base_duration = base_duration
        @base_duration ||= base[:duration] if base
        @base_duration ||= Rational(1, 4)

        base ||= { grade: 0, octave: 0, duration: @base_duration, velocity: 1 }

        @scale = scale

        super base, transcriptor: transcriptor
      end

      # Scale for interpreting grade values.
      #
      # @return [Scale] scale object
      #
      # @api public
      attr_accessor :scale

      # Base duration unit for duration calculations.
      #
      # @return [Rational] base duration (e.g., 1/4 for quarter note)
      #
      # @api public
      attr_accessor :base_duration

      # Processes GDVD attributes before conversion.
      #
      # Sets base_duration on GDVD object for duration calculations.
      # Handles appogiatura (grace note) modifiers recursively.
      #
      # @param gdvd [Hash] GDVD attributes
      #
      # @return [Hash] processed GDVD with base_duration set
      #
      # @api public
      def process(gdvd)
        gdvd = gdvd.clone

        gdvd.base_duration = @base_duration

        appogiatura_gdvd = gdvd[:modifiers]&.delete :appogiatura

        if appogiatura_gdvd
          appogiatura_gdvd = appogiatura_gdvd.clone
          appogiatura_gdvd.base_duration = @base_duration

          gdvd[:modifiers][:appogiatura] = appogiatura_gdvd
        end

        gdvd
      end

      # Creates independent subcontext decoder.
      #
      # Returns new decoder with current `@last` state as base, enabling
      # independent processing of nested structures (grace notes, etc.).
      #
      # @return [NeumaDecoder] subcontext decoder with current state
      #
      # @api public
      def subcontext
        NeumaDecoder.new @scale, base_duration: @base_duration, transcriptor: @transcriptor, base: @last
      end

      # Applies GDVD to previous state, producing absolute GDV.
      #
      # Converts differential GDVD to absolute GDV using scale. Processes
      # appogiatura modifiers recursively.
      #
      # @param gdvd [Hash] processed GDVD attributes
      # @param on [Hash] previous GDV state
      #
      # @return [Hash] absolute GDV event
      #
      # @example Convert differential to absolute
      #   # Previous: { grade: 0, duration: 1/4r }
      #   # GDVD: { grade_diff: +2, duration_factor: 2 }
      #   # Result: { grade: 2, duration: 1/2r, ... }
      #
      # @api public
      def apply(gdvd, on:)
        gdv = gdvd.to_gdv @scale, previous: on

        appogiatura_action = gdvd.dig(:modifiers, :appogiatura)
        gdv[:appogiatura] = appogiatura_action.to_gdv @scale, previous: on if appogiatura_action

        gdv
      end

      # Returns debug representation.
      #
      # @return [String] debug string with last state
      #
      # @api public
      def inspect
        "GDV NeumaDecoder: @last = #{@last}"
      end

      alias to_s inspect
    end
  end
end
