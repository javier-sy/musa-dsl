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
        # Created via Measure#add_unpitched or Measure#unpitched:
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
          # @param (see Note#initialize)
          #
          # @example Percussion quarter note
          #   UnpitchedNote.new(duration: 2, type: 'quarter')
          #
          # @example Eighth note with accent
          #   UnpitchedNote.new(duration: 1, type: 'eighth', accent: true)
          #
          # @example Dotted half with forte
          #   UnpitchedNote.new(duration: 6, type: 'half', dots: 1, dynamics: 'f')
          #
          # For detailed parameter documentation, see {Note#initialize}
          def initialize(pizzicato: nil,
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