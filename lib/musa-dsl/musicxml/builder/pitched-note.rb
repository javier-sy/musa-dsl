require_relative 'note'

module Musa
  module MusicXML
    module Builder
      module Internal
        # Pitched note with specific step, octave, and optional alteration.
        #
        # PitchedNote represents notes with defined pitches (as opposed to rests or
        # unpitched percussion). It extends {Note} with pitch information: step (C-G),
        # octave (scientific pitch notation), and optional chromatic alteration.
        #
        # ## Pitch Components
        #
        # ### Step
        # The diatonic pitch class: 'C', 'D', 'E', 'F', 'G', 'A', 'B'
        #
        # ### Octave
        # Scientific pitch notation (middle C = C4):
        # - Octave 0: C0 to B0 (subcontra octave)
        # - Octave 4: C4 to B4 (one-line octave, middle C)
        # - Octave 8: C8 to B8 (five-line octave)
        #
        # ### Alter
        # Chromatic alteration in semitones:
        # - **-2**: Double flat
        # - **-1**: Flat
        # - **0**: Natural (can be omitted)
        # - **+1**: Sharp
        # - **+2**: Double sharp
        #
        # ## Accidentals
        #
        # The `alter` parameter changes the sounding pitch, while the `accidental`
        # parameter controls visual display:
        #
        # - **alter**: Affects playback (actual pitch)
        # - **accidental**: Visual symbol (sharp, flat, natural, etc.)
        #
        # Usually both are specified together, but you can have:
        # - alter without accidental (implied by key signature)
        # - accidental without alter (cautionary accidental)
        #
        # ## Usage
        #
        # Created via Measure#add_pitch or Measure#pitch:
        #
        #     measure.pitch 'C', octave: 5, duration: 4, type: 'quarter'
        #     measure.add_pitch step: 'F', alter: 1, octave: 4, duration: 2, type: 'eighth'
        #
        # @example Middle C quarter note
        #   PitchedNote.new('C', octave: 4, duration: 4, type: 'quarter')
        #
        # @example F# with sharp symbol
        #   PitchedNote.new('F', alter: 1, octave: 5, duration: 2, type: 'eighth',
        #                   accidental: 'sharp')
        #
        # @example Bb dotted half note with staccato
        #   PitchedNote.new('B', alter: -1, octave: 4, duration: 6, type: 'half',
        #                   dots: 1, accidental: 'flat', staccato: true)
        #
        # @example High A with trill
        #   PitchedNote.new('A', octave: 6, duration: 8, type: 'whole',
        #                   trill_mark: true)
        #
        # @example Chord notes (C major triad)
        #   measure.pitch 'C', octave: 4, duration: 4, type: 'quarter'
        #   measure.pitch 'E', octave: 4, duration: 4, type: 'quarter', chord: true
        #   measure.pitch 'G', octave: 4, duration: 4, type: 'quarter', chord: true
        #
        # @example Grace note with slur
        #   PitchedNote.new('D', octave: 5, grace: true, type: 'eighth',
        #                   slur: 'start')
        #
        # @see Note Base class with all notation attributes
        # @see Rest Rest notes
        # @see UnpitchedNote Unpitched percussion
        # @see Measure Container for adding notes
        class PitchedNote < Note
          # Creates a pitched note.
          #
          # @param positional_step [String, nil] step as positional parameter (alternative to keyword)
          # @param step [String, nil] diatonic step: 'C', 'D', 'E', 'F', 'G', 'A', 'B'
          # @param alter [Integer, nil] semitone alteration: -2 (double flat), -1 (flat),
          #   0 (natural), +1 (sharp), +2 (double sharp)
          # @param octave [Integer] octave number (scientific pitch notation, middle C = 4)
          # @param (see Note#initialize)
          #
          # @example C natural in octave 4, quarter note
          #   PitchedNote.new('C', octave: 4, duration: 4, type: 'quarter')
          #
          # @example F sharp in octave 5, eighth note
          #   PitchedNote.new('F', alter: 1, octave: 5, duration: 2, type: 'eighth',
          #                   accidental: 'sharp')
          #
          # @example B flat with keyword syntax
          #   PitchedNote.new(step: 'B', alter: -1, octave: 4, duration: 4,
          #                   type: 'quarter', accidental: 'flat')
          #
          # For detailed parameter documentation, see {Note#initialize}
          def initialize(positional_step = nil, step: nil, alter: nil, octave:,
                         pizzicato: nil,
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

            @step = step || positional_step
            @alter = alter
            @octave = octave

            super
          end

          # Step builder/setter.
          # @overload step(value)
          #   Sets step via DSL
          #   @param value [String] diatonic step ('C'-'G')
          # @overload step=(value)
          #   Sets step via assignment
          #   @param value [String] diatonic step ('C'-'G')
          attr_simple_builder :step

          # Alter builder/setter.
          # @overload alter(value)
          #   Sets alteration via DSL
          #   @param value [Integer] semitone alteration (-2 to +2)
          # @overload alter=(value)
          #   Sets alteration via assignment
          #   @param value [Integer] semitone alteration (-2 to +2)
          attr_simple_builder :alter

          # Octave builder/setter.
          # @overload octave(value)
          #   Sets octave via DSL
          #   @param value [Integer] octave number
          # @overload octave=(value)
          #   Sets octave via assignment
          #   @param value [Integer] octave number
          attr_simple_builder :octave

          private

          # Outputs the pitch XML element.
          #
          # @param io [IO] output stream
          # @param indent [Integer] indentation level
          # @return [void]
          #
          # @api private
          def specific_to_xml(io, indent:)
            tabs = "\t" * indent

            io.puts "#{tabs}<pitch>"
            io.puts "#{tabs}\t<step>#{@step}</step>"
            io.puts "#{tabs}\t<alter>#{@alter}</alter>" if @alter
            io.puts "#{tabs}\t<octave>#{@octave.to_i}</octave>"
            io.puts "#{tabs}</pitch>"
          end
        end
      end
    end
  end
end