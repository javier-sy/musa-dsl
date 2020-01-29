require_relative 'note'

module Musa
  module MusicXML
    class PitchedNote < Note
      def initialize(step:, alter: nil, octave:,
                     pizzicato: nil, # true
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
                     **_rest)
        super

        @step = step
        @alter = alter
        @octave = octave
      end

      attr_accessor :step, :alter, :octave

      private

      def specific_to_xml(io, indent:)
        tabs = "\t" * indent

        io.puts "#{tabs}<pitch>"
        io.puts "#{tabs}\t<step>#{@step}</step>"
        io.puts "#{tabs}\t<alter>#{@alter}</alter>" if @alter
        io.puts "#{tabs}\t<octave>#{@octave}</octave>"
        io.puts "#{tabs}</pitch>"
      end
    end
  end
end