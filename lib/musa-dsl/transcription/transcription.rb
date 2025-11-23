module Musa
  # Transcription framework for converting GDV musical events to output formats.
  #
  # Provides infrastructure for transcribing GDV (Grade-Duration-Velocity) events
  # into various output formats (MIDI, MusicXML) through a pipeline of feature
  # processors. The transcription system handles musical ornaments, articulations,
  # and notation-specific transformations.
  #
  # ## Architecture Overview
  #
  # ### Core Components
  #
  # 1. **Transcriptor** - Main orchestrator that chains feature processors
  # 2. **FeatureTranscriptor** - Base class for individual feature processors
  # 3. **Transcriptor Sets** - Pre-configured processor chains for specific formats
  #
  # ### Processing Pipeline
  #
  # ```ruby
  # GDV Event → [Transcriptor 1] → [Transcriptor 2] → ... → Output Format
  # ```
  #
  # Each transcriptor in the chain:
  #
  # - Extracts specific features (appogiatura, trill, staccato, etc.)
  # - Transforms/expands the event based on those features
  # - Passes result to next transcriptor in chain
  #
  # ## GDV Format
  #
  # GDV events are hashes representing musical notes/events:
  # ```ruby
  # {
  #   grade: 0,           # Scale degree (pitch)
  #   duration: 1r,       # Rational duration
  #   velocity: 0.8,      # Note velocity (0.0-1.0)
  #   # Plus optional ornament/articulation attributes:
  #   tr: true,           # Trill
  #   mor: :up,           # Mordent
  #   st: 2,              # Staccato
  #   appogiatura: {...}  # Grace note
  # }
  # ```
  #
  # ## Output Formats
  #
  # - **MIDI** (`FromGDV::ToMIDI`): Expands ornaments to note sequences for playback
  # - **MusicXML** (`FromGDV::ToMusicXML`): Preserves ornaments as notation symbols
  #
  # ## Usage
  #
  # ```ruby
  # # MIDI transcription (expands ornaments)
  # transcriptor = Musa::Transcription::Transcriptor.new(
  #   Musa::Transcriptors::FromGDV::ToMIDI.transcription_set(duration_factor: 1/4r),
  #   base_duration: 1/4r,
  #   tick_duration: 1/96r
  # )
  # midi_events = transcriptor.transcript(gdv_event)
  #
  # # MusicXML transcription (preserves ornaments as symbols)
  # transcriptor = Musa::Transcription::Transcriptor.new(
  #   Musa::Transcriptors::FromGDV::ToMusicXML.transcription_set,
  #   base_duration: 1/4r
  # )
  # musicxml_events = transcriptor.transcript(gdv_event)
  # ```
  #
  # ## Supported Features
  #
  # ### Ornaments
  #
  # - **Appogiatura**: Grace notes
  # - **Mordent**: Quick alternation with adjacent note
  # - **Turn**: Four-note circling figure
  # - **Trill**: Rapid alternation with upper neighbor
  #
  # ### Articulations
  #
  # - **Staccato**: Shortened note duration
  # - **Base/Rest**: Zero-duration structural markers
  #
  # ## Creating Custom Transcriptors
  #
  # Extend `FeatureTranscriptor` and implement `transcript` method:
  # ```ruby
  # class MyOrnament < Musa::Transcription::FeatureTranscriptor
  #   def transcript(gdv, base_duration:, tick_duration:)
  #     if ornament = gdv.delete(:my_ornament)
  #       # Process ornament, return modified event(s)
  #       [event1, event2, ...]
  #     else
  #       super  # Pass through unchanged
  #     end
  #   end
  # end
  # ```
  #
  # ## Integration
  #
  # The transcription system integrates with:
  #
  # - **Sequencer**: Converting generative patterns to playable events
  # - **MIDI**: Real-time MIDI output with ornament expansion
  # - **MusicXML**: Score generation with notation symbols
  # - **Datasets**: Using AbsD (absolute duration) extensions
  #
  # @example Complete transcription workflow
  #   # 1. Generate GDV events
  #   gdv_events = [
  #     { grade: 0, duration: 1r, tr: true },
  #     { grade: 2, duration: 1r, mor: :up },
  #     { grade: 4, duration: 1/2r, st: true }
  #   ]
  #
  #   # 2. Create MIDI transcriptor
  #   transcriptor = Musa::Transcription::Transcriptor.new(
  #     Musa::Transcriptors::FromGDV::ToMIDI.transcription_set,
  #     base_duration: 1/4r
  #   )
  #
  #   # 3. Transcribe to MIDI events
  #   midi_events = gdv_events.collect { |gdv| transcriptor.transcript(gdv) }.flatten
  #
  #   # 4. Send to MIDI output
  #   midi_events.each { |event| midi_output.send_event(event) }
  #
  # @see Musa::Transcriptors::FromGDV::ToMIDI
  # @see Musa::Transcriptors::FromGDV::ToMusicXML
  # @see Musa::Sequencer
  #
  # @api public
  module Transcription
    # Main transcription orchestrator.
    #
    # Chains multiple feature transcriptors to process GDV events through a
    # transformation pipeline. Each transcriptor in the chain processes specific
    # musical features (ornaments, articulations, etc.).
    #
    # ## Processing
    #
    # The transcriptor applies each feature processor in sequence:
    # 1. First transcriptor processes event
    # 2. Result passed to second transcriptor
    # 3. Continue through chain
    # 4. Final result returned
    #
    # ## Array Handling
    #
    # If a transcriptor returns an array (e.g., expanding one note to many),
    # subsequent transcriptors process each element and results are flattened.
    #
    # @example Create transcriptor chain
    #   transcriptor = Musa::Transcription::Transcriptor.new(
    #     [Appogiatura.new, Trill.new, Staccato.new],
    #     base_duration: 1/4r,
    #     tick_duration: 1/96r
    #   )
    #
    # @api public
    class Transcriptor
      # Returns the transcriptor chain.
      #
      # @return [Array<FeatureTranscriptor>] array of feature processors
      #
      # @api public
      attr_reader :transcriptors

      # Creates transcriptor with specified feature processors.
      #
      # @param transcriptors [Array<FeatureTranscriptor>] chain of feature processors
      # @param base_duration [Rational] base duration unit (e.g., quarter note = 1/4)
      # @param tick_duration [Rational] minimum tick duration (e.g., 1/96 for MIDI)
      #
      # @example Create MIDI transcriptor
      #   transcriptor = Musa::Transcription::Transcriptor.new(
      #     Musa::Transcriptors::FromGDV::ToMIDI.transcription_set,
      #     base_duration: 1/4r,
      #     tick_duration: 1/96r
      #   )
      #
      # @api public
      def initialize(transcriptors = nil, base_duration: nil, tick_duration: nil)
        @transcriptors = transcriptors || []

        @base_duration = base_duration || 1/4r
        @tick_duration = tick_duration || 1/96r
      end

      # Transcribes GDV event(s) through the processor chain.
      #
      # Applies each transcriptor in sequence. Handles both single events and
      # arrays of events, flattening results when transcriptors expand events.
      #
      # @param element [Hash, Array<Hash>] GDV event or array of events
      #
      # @return [Hash, Array<Hash>, nil] transcribed event(s)
      #
      # @example Transcribe single event
      #   gdv = { grade: 0, duration: 1r, tr: true }
      #   result = transcriptor.transcript(gdv)
      #   # => [{ grade: 1, duration: 1/16r }, { grade: 0, duration: 1/16r }, ...]
      #
      # @example Transcribe array of events
      #   gdvs = [
      #     { grade: 0, duration: 1r, mor: true },
      #     { grade: 2, duration: 1r }
      #   ]
      #   results = transcriptor.transcript(gdvs)
      #
      # @api public
      def transcript(element)
        @transcriptors.each do |transcriptor|
          if element
            if element.is_a?(Array)
              element = element.collect { |element_i| transcriptor.transcript(element_i, base_duration: @base_duration, tick_duration: @tick_duration) }.flatten(1)
            else
              element = transcriptor.transcript(element, base_duration: @base_duration, tick_duration: @tick_duration)
            end
          end
        end

        element
      end
    end

    # Base class for feature transcriptors.
    #
    # Provides common functionality for processing specific musical features
    # in GDV events. Subclasses implement `transcript` method to handle
    # their specific feature (ornament, articulation, etc.).
    #
    # ## Contract
    #
    # Transcriptor implementations should:
    #
    # 1. Extract their specific feature from GDV hash
    # 2. Process/transform the event based on that feature
    # 3. Return modified event(s) or call `super` if feature not present
    # 4. Use `delete` to remove processed feature attributes
    #
    # ## Helper Methods
    #
    # - `check(value, &block)`: Safely iterate over value or array
    #
    # @example Implement custom transcriptor
    #   class Accent < FeatureTranscriptor
    #     def transcript(gdv, base_duration:, tick_duration:)
    #       if accent = gdv.delete(:accent)
    #         gdv[:velocity] *= 1.2  # Increase velocity
    #       end
    #       super  # Clean up and pass through
    #     end
    #   end
    #
    # @api public
    class FeatureTranscriptor
      # Transcribes GDV event for this feature.
      #
      # Base implementation cleans up empty `:modifiers` attribute. Subclasses
      # should override to process their specific feature, then call `super`.
      #
      # @param element [Hash, Array<Hash>] GDV event or array of events
      # @param base_duration [Rational] base duration unit
      # @param tick_duration [Rational] minimum tick duration
      #
      # @return [Hash, Array<Hash>] transcribed event(s)
      #
      # @api public
      def transcript(element, base_duration:, tick_duration:)
        case element
        when Hash
          element.delete :modifiers if element[:modifiers]&.empty?
        when Array
          element.each { |_| _.delete :modifiers if _[:modifiers]&.empty? }
        end

        element
      end

      # Helper to safely process value or array.
      #
      # Yields each element if array, or yields single value.
      # Useful for processing feature values that may be single or multiple.
      #
      # @param value_or_array [Object, Array] value to check
      # @yield [value] block to call for each value
      #
      # @example Check ornament options
      #   check(ornament_value) do |option|
      #     case option
      #     when :up then direction = :up
      #     when :down then direction = :down
      #     end
      #   end
      #
      # @api public
      def check(value_or_array, &block)
        if block_given?
          if value_or_array.is_a?(Array)
            value_or_array.each(&block)
          else
            yield value_or_array
          end
        end
      end
    end
  end

  # Namespace for transcriptor implementations.
  #
  # Contains modules for different transcription targets:
  # - `FromGDV::ToMIDI` - MIDI playback transcriptors
  # - `FromGDV::ToMusicXML` - MusicXML notation transcriptors
  #
  # @api public
  module Transcriptors; end
end