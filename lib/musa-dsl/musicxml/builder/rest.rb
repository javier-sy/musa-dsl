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
          # @param (see Note#initialize) All Note parameters are supported
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
          def initialize(pizzicato: nil, # true
                         measure: nil, # true
                         grace: nil, # true
                         cue: nil, # true
                         chord: nil, # true
                         duration: nil, # number positive divisions
                         tie_start: nil, tie_stop: nil, # true
                         voice: nil, # number
                         type: nil, # whole / half / quarter / ...
                         dots: nil, # number
                         accidental: nil, # sharp / flat / ...
                         time_modification: nil, # TimeModification class instance
                         stem: nil, # up / down / double
                         notehead: nil, # Notehead class instance
                         staff: nil, # number

                         # notations
                         accidental_mark: nil, # sharp / natural / flat / ...
                         arpeggiate: nil, # true / up / down

                         tied: nil, # start / stop / continue
                         tuplet: nil, # Tuplet class instance

                         dynamics: nil, # pppp...ffff (single or array of)
                         fermata: nil, # true / upright / inverted
                         glissando: nil, # start / stop
                         non_arpeggiate: nil, # top / bottom

                         slide: nil, # start / stop
                         slur: nil, # start / stop / continue

                         ## articulations
                         accent: nil, # true
                         breath_mark: nil, # comma / tick
                         caesura: nil, # true
                         detached_legato:nil, # true
                         doit: nil, # true
                         falloff: nil, # true
                         other_articulation: nil, # text
                         plop: nil, # true
                         scoop: nil, # true
                         spiccato: nil, # true
                         staccatissimo: nil, # true
                         staccato: nil, # true
                         stress: nil, # true
                         strong_accent: nil, # true / up / down
                         tenuto: nil, # true
                         unstress: nil, # true

                         ## ornaments
                         delayed_inverted_turn: nil, # true
                         delayed_turn: nil, # true
                         inverted_mordent: nil, # true
                         inverted_turn: nil, # true
                         mordent: nil, # true
                         schleifer: nil, # true
                         shake: nil, # true
                         tremolo: nil, # start / stop / single,
                         trill_mark: nil, # true
                         turn: nil, # true
                         vertical_turn: nil, # true
                         wavy_line: nil, # true
                         other_ornament: nil, # true
                         ornament_accidental_mark: nil, # sharp / natural / flat / ...

                         ## technical
                         arrow: nil, # Arrow class instance
                         bend: nil, # Bend class instance
                         double_tongue: nil, # true
                         down_bow: nil, # true
                         fingering: nil,  # Fingering class instance
                         fingernails: nil, # true
                         fret: nil, # number
                         hammer_on: nil, # HammerOnPullOff class instance
                         handbell: nil, # damp / echo / ...
                         harmonic: nil, # Harmonic class instance
                         heel: nil, # true
                         hole: nil, # Hole class instance
                         open_string: nil, # true
                         other_technical: nil, # text
                         pluck: nil, # text
                         pull_off: nil, # HammerOnPullOff class insstance
                         snap_pizzicato: nil, # true
                         stopped: nil, # true
                         string: nil, # number (string number)
                         tap: nil, # text
                         thumb_position: nil, # true
                         toe: nil, # true
                         triple_tongue: nil, # true
                         up_bow: nil,  # true
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