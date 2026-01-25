require_relative 'note'

module Musa
  module MusicXML
    module Builder
      module Internal
        # Rest (silence) with specified duration or full measure.
        #
        # Rest represents musical silence. It extends {Note} with rest-specific
        # features, particularly the measure rest attribute for whole-measure silences.
        #
        # ## Types of Rests
        #
        # ### Regular Rests
        # Rests with explicit duration and type (whole, half, quarter, eighth, etc.):
        #
        #     Rest.new(duration: 4, type: 'half')
        #     Rest.new(duration: 1, type: 'sixteenth', dots: 1)
        #
        # ### Measure Rests
        # Full-measure rests that automatically fill the entire measure regardless
        # of time signature:
        #
        #     Rest.new(duration: 8, type: 'whole', measure: true)
        #
        # The `measure: true` attribute tells notation software to center the rest
        # and adjust its appearance based on the time signature.
        #
        # ## Dotted Rests
        #
        # Like notes, rests can have augmentation dots:
        #
        #     Rest.new(duration: 3, type: 'quarter', dots: 1)  # Dotted quarter
        #     Rest.new(duration: 7, type: 'half', dots: 2)     # Double-dotted half
        #
        # ## Multi-Voice Rests
        #
        # In polyphonic music, rests can be assigned to specific voices:
        #
        #     Rest.new(duration: 2, type: 'quarter', voice: 2)
        #
        # ## Usage
        #
        # Created via Measure#add_rest or Measure#rest:
        #
        #     measure.rest duration: 4, type: 'half'
        #     measure.add_rest duration: 8, type: 'whole', measure: true
        #
        # @example Quarter rest
        #   Rest.new(duration: 2, type: 'quarter')
        #
        # @example Measure rest (whole measure)
        #   Rest.new(duration: 8, type: 'whole', measure: true)
        #
        # @example Dotted eighth rest
        #   Rest.new(duration: 3, type: 'eighth', dots: 1)
        #
        # @example Rest in specific voice
        #   Rest.new(duration: 4, type: 'half', voice: 2)
        #
        # @example Rest with fermata
        #   Rest.new(duration: 8, type: 'whole', fermata: true)
        #
        # @see Note Base class with all notation attributes
        # @see PitchedNote Pitched notes
        # @see UnpitchedNote Unpitched percussion
        # @see Measure Container for adding rests
        class Rest < Note
          # Creates a rest.
          #
          # @param measure [Boolean, nil] measure rest (fills entire measure)
          # @param (see Note#initialize)
          #
          # @example Quarter rest
          #   Rest.new(duration: 2, type: 'quarter')
          #
          # @example Whole measure rest
          #   Rest.new(duration: 8, type: 'whole', measure: true)
          #
          # @example Dotted eighth rest in voice 2
          #   Rest.new(duration: 3, type: 'eighth', dots: 1, voice: 2)
          #
          # For detailed parameter documentation, see {Note#initialize}
          def initialize(pizzicato: nil, measure: nil,
                         grace: nil, cue: nil, chord: nil,
                         duration: nil, tie_start: nil, tie_stop: nil,
                         voice: nil, type: nil, dots: nil,
                         accidental: nil, time_modification: nil,
                         stem: nil, notehead: nil, staff: nil,
                         accidental_mark: nil, arpeggiate: nil,
                         tied: nil, tuplet: nil,
                         dynamics: nil, fermata: nil, glissando: nil, non_arpeggiate: nil,
                         slide: nil, slur: nil,
                         accent: nil, breath_mark: nil, caesura: nil,
                         detached_legato: nil, doit: nil, falloff: nil,
                         other_articulation: nil, plop: nil, scoop: nil,
                         spiccato: nil, staccatissimo: nil, staccato: nil,
                         stress: nil, strong_accent: nil, tenuto: nil, unstress: nil,
                         delayed_inverted_turn: nil, delayed_turn: nil,
                         inverted_mordent: nil, inverted_turn: nil,
                         mordent: nil, schleifer: nil, shake: nil,
                         tremolo: nil, trill_mark: nil, turn: nil,
                         vertical_turn: nil, wavy_line: nil,
                         other_ornament: nil, ornament_accidental_mark: nil,
                         arrow: nil, bend: nil, double_tongue: nil, down_bow: nil,
                         fingering: nil, fingernails: nil, fret: nil,
                         hammer_on: nil, handbell: nil, harmonic: nil,
                         heel: nil, hole: nil, open_string: nil,
                         other_technical: nil, pluck: nil, pull_off: nil,
                         snap_pizzicato: nil, stopped: nil, string: nil,
                         tap: nil, thumb_position: nil, toe: nil,
                         triple_tongue: nil, up_bow: nil,
                         &block)

            @measure = measure

            super
          end

          # Measure rest builder/setter.
          #
          # Indicates whether this is a full-measure rest.
          #
          # @overload measure(value)
          #   Sets measure rest via DSL
          #   @param value [Boolean] true for measure rest
          # @overload measure=(value)
          #   Sets measure rest via assignment
          #   @param value [Boolean] true for measure rest
          attr_simple_builder :measure

          private

          # Outputs the rest XML element.
          #
          # @param io [IO] output stream
          # @param indent [Integer] indentation level
          # @return [void]
          #
          # @api private
          def specific_to_xml(io, indent:)
            tabs = "\t" * indent
            io.puts "#{tabs}<rest #{"measure=\"yes\"" if @measure}/>"
          end
        end
      end
    end
  end
end