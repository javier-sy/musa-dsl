require_relative 'note'

module Musa
  module MusicXML
    module Builder
      module Internal
        # Unpitched note for percussion and rhythm-only notation.
        #
        # UnpitchedNote represents notes without specific pitch, primarily used
        # for percussion instruments in drum notation. It extends {Note} with
        # simplified pitch handling—no step, alter, or octave needed.
        #
        # ## Use Cases
        #
        # ### Percussion Notation
        # Drum kits, percussion ensembles, and rhythm sections use unpitched notes
        # where vertical position on the staff indicates the instrument (not pitch):
        #
        # - Snare drum
        # - Bass drum
        # - Hi-hat
        # - Cymbals
        # - Toms
        # - Auxiliary percussion
        #
        # ### Rhythm-Only Notation
        # Teaching materials and rhythm exercises where pitch is irrelevant.
        #
        # ### Tablature
        # Some tablature systems use unpitched notes with fret/string indications.
        #
        # ## Staff Position
        #
        # Unlike pitched notes, staff line position doesn't represent pitch but rather
        # identifies the percussion instrument. This mapping is defined by the clef
        # (typically percussion clef) and is instrument-specific.
        #
        # ## Combining with Technical Markings
        #
        # Unpitched notes support all standard notations (dynamics, articulations, etc.)
        # but often use percussion-specific technicals like sticking patterns.
        #
        # ## Usage
        #
        # Created via {Measure#add_unpitched} or {Measure#unpitched}:
        #
        #     measure.unpitched duration: 2, type: 'quarter'
        #     measure.add_unpitched duration: 1, type: 'eighth', accent: true
        #
        # @example Basic unpitched quarter note
        #   UnpitchedNote.new(duration: 2, type: 'quarter')
        #
        # @example Snare drum hit with accent
        #   UnpitchedNote.new(duration: 2, type: 'quarter', accent: true)
        #
        # @example Hi-hat with staccato
        #   UnpitchedNote.new(duration: 1, type: 'eighth', staccato: true)
        #
        # @example Bass drum with forte dynamic
        #   UnpitchedNote.new(duration: 4, type: 'half', dynamics: 'f')
        #
        # @example Cymbal crash with fermata
        #   UnpitchedNote.new(duration: 8, type: 'whole', fermata: true)
        #
        # @see Note Base class with all notation attributes
        # @see PitchedNote Pitched notes
        # @see Rest Rests
        # @see Measure Container for adding notes
        class UnpitchedNote < Note
          # Creates an unpitched note.
          #
          # @param (see Note#initialize) All Note parameters are supported
          #
          # @example Percussion quarter note
          #   UnpitchedNote.new(duration: 2, type: 'quarter')
          #
          # @example Eighth note with accent
          #   UnpitchedNote.new(duration: 1, type: 'eighth', accent: true)
          #
          # @example Dotted half with forte
          #   UnpitchedNote.new(duration: 6, type: 'half', dots: 1, dynamics: 'f')
          def initialize( pizzicato: nil, # true
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

            super
          end

          private

          # Outputs the unpitched XML element.
          #
          # @param io [IO] output stream
          # @param indent [Integer] indentation level
          # @return [void]
          #
          # @api private
          def specific_to_xml(io, indent:)
            tabs = "\t" * indent
            io.puts "#{tabs}<unpitched />"
          end
        end
      end
    end
  end
end