require_relative 'attributes'
require_relative 'pitched-note'
require_relative 'rest'
require_relative 'unpitched-note'
require_relative 'backup-forward'
require_relative 'direction'

require_relative 'helper'

module Musa
  module MusicXML
    class Measure
      include Helper::ToXML

      def initialize(number, divisions: nil,
                     key_cancel: nil, key_fifths: nil, key_mode: nil,
                     time_senza_misura: nil, time_beats: nil, time_beat_type: nil,
                     clef_sign: nil, clef_line: nil, clef_octave_change: nil)
        @number = number
        @elements = []
        @last_attributes = nil

        if divisions ||
            key_cancel || key_fifths || key_mode ||
            time_senza_misura || time_beats || time_beat_type ||
            clef_sign || clef_line || clef_octave_change

          add_attributes divisions: divisions,
                         key_cancel: key_cancel, key_fifths: key_fifths, key_mode: key_mode,
                         time_senza_misura: time_senza_misura, time_beats: time_beats, time_beat_type: time_beat_type,
                         clef_sign: clef_sign, clef_line: clef_line, clef_octave_change: clef_octave_change
        end
      end

      attr_accessor :number
      attr_reader :elements

      attr_reader :last_attributes

      def add_attributes(divisions: nil,
                         key_cancel: nil, key_fifths: nil, key_mode: nil,
                         time_senza_misura: nil, time_beats: nil, time_beat_type: nil,
                         clef_sign: nil, clef_line: nil, clef_octave_change: nil)

        Attributes.new(divisions: divisions,
                       key_cancel: key_cancel, key_fifths: key_fifths, key_mode: key_mode,
                       time_senza_misura: time_senza_misura, time_beats: time_beats, time_beat_type: time_beat_type,
                       clef_sign: clef_sign, clef_line: clef_line, clef_octave_change: clef_octave_change) \
                  .tap do |attributes|
          @elements << attributes
          @last_attributes = attributes
        end
      end

      def add_pitch(step: nil, octave: nil, alter: nil,
                    # note
                    pizzicato: nil,
                    # main content
                    grace: nil,
                    cue: nil,
                    chord: nil,
                    duration: nil,
                    tie_start: nil, tie_stop: nil,
                    voice: nil,
                    type: nil,
                    dots: nil,
                    accidental: nil,
                    time_modification: nil,
                    stem: nil,
                    notehead: nil,
                    staff: nil,

                    # notations
                    accidental_mark: nil,
                    arpeggiate: nil,

                    tied: nil,
                    tuplet: nil,

                    dynamics: nil,
                    fermata: nil,
                    glissando: nil,
                    non_arpeggiate: nil,

                    slide: nil,
                    slur: nil,

                    ## articulations
                    accent: nil,
                    breath_mark: nil,
                    caesura: nil,
                    detached_legato:nil,
                    doit: nil,
                    falloff: nil,
                    other_articulation: nil,
                    plop: nil,
                    scoop: nil,
                    spiccato: nil,
                    staccatissimo: nil,
                    staccato: nil,
                    stress: nil,
                    strong_accent: nil,
                    tenuto: nil,
                    unstress: nil,

                    ## ornaments
                    delayed_inverted_turn: nil,
                    delayed_turn: nil,
                    inverted_mordent: nil,
                    inverted_turn: nil,
                    mordent: nil,
                    schleifer: nil,
                    shake: nil,
                    tremolo: nil,
                    trill_mark: nil,
                    turn: nil,
                    vertical_turn: nil,
                    wavy_line: nil,
                    other_ornament: nil,
                    ornament_accidental_mark: nil,

                    ## technical
                    arrow: nil,
                    bend: nil,
                    double_tongue: nil,
                    down_bow: nil,
                    fingering: nil,
                    fingernails: nil,
                    fret: nil,
                    hammer_on: nil,
                    handbell: nil,
                    harmonic: nil,
                    heel: nil,
                    hole: nil,
                    open_string: nil,
                    other_technical: nil,
                    pluck: nil,
                    pull_off: nil,
                    snap_pizzicato: nil,
                    stopped: nil,
                    string: nil,
                    tap: nil,
                    thumb_position: nil,
                    toe: nil,
                    triple_tongue: nil,
                    up_bow: nil)

        PitchedNote.new(step: step, octave: octave, alter: alter,
                        pizzicato: pizzicato,

                        grace: grace,
                        cue: cue,
                        chord: chord,
                        duration: duration,
                        tie_start: tie_start,
                        tie_stop: tie_stop,
                        voice: voice,
                        type: type,
                        dots: dots,
                        accidental: accidental,
                        time_modification: time_modification,
                        stem: stem,
                        notehead: notehead,
                        staff: staff,

                        # notations
                        accidental_mark: accidental_mark,
                        arpeggiate: arpeggiate,
                        tied: tied,
                        tuplet: tuplet,
                        dynamics: dynamics,
                        fermata: fermata,
                        glissando: glissando,
                        non_arpeggiate: non_arpeggiate,
                        slide: slide,
                        slur: slur,

                        ## articulations
                        accent: accent,
                        breath_mark: breath_mark,
                        caesura: caesura,
                        detached_legato: detached_legato,
                        doit: doit,
                        falloff: falloff,
                        other_articulation: other_articulation,
                        plop: plop,
                        scoop: scoop,
                        spiccato: spiccato,
                        staccatissimo: staccatissimo,
                        staccato: staccato,
                        stress: stress,
                        strong_accent: strong_accent,
                        tenuto: tenuto,
                        unstress: unstress,

                        ## ornaments
                        delayed_inverted_turn: delayed_inverted_turn,
                        delayed_turn: delayed_turn,
                        inverted_mordent: inverted_mordent,
                        inverted_turn: inverted_turn,
                        mordent: mordent,
                        schleifer: schleifer,
                        shake: shake,
                        tremolo: tremolo,
                        trill_mark: trill_mark,
                        turn: turn,
                        vertical_turn: vertical_turn,
                        wavy_line: wavy_line,
                        other_ornament: other_ornament,
                        ornament_accidental_mark: ornament_accidental_mark,

                        ## technical
                        arrow: arrow,
                        bend: bend,
                        double_tongue: double_tongue,
                        down_bow: down_bow,
                        fingering: fingering,
                        fingernails: fingernails,
                        fret: fret,
                        hammer_on: hammer_on,
                        handbell: handbell,
                        harmonic: harmonic,
                        heel: heel,
                        hole: hole,
                        open_string: open_string,
                        other_technical: other_technical,
                        pluck: pluck,
                        pull_off: pull_off,
                        snap_pizzicato: snap_pizzicato,
                        stopped: stopped,
                        string: string,
                        tap: tap,
                        thumb_position: thumb_position,
                        toe: toe,
                        triple_tongue: triple_tongue,
                        up_bow: up_bow).tap { |note| @elements << note }
      end

      def add_rest(measure: nil,
                   # note
                   pizzicato: nil,
                   # main content
                   grace: nil,
                   cue: nil,
                   chord: nil,
                   duration: nil,
                   tie_start: nil, tie_stop: nil,
                   voice: nil,
                   type: nil,
                   dots: nil,
                   accidental: nil,
                   time_modification: nil,
                   stem: nil,
                   notehead: nil,
                   staff: nil,

                   # notations
                   accidental_mark: nil,
                   arpeggiate: nil,

                   tied: nil,
                   tuplet: nil,

                   dynamics: nil,
                   fermata: nil,
                   glissando: nil,
                   non_arpeggiate: nil,

                   slide: nil,
                   slur: nil,

                   ## articulations
                   accent: nil,
                   breath_mark: nil,
                   caesura: nil,
                   detached_legato:nil,
                   doit: nil,
                   falloff: nil,
                   other_articulation: nil,
                   plop: nil,
                   scoop: nil,
                   spiccato: nil,
                   staccatissimo: nil,
                   staccato: nil,
                   stress: nil,
                   strong_accent: nil,
                   tenuto: nil,
                   unstress: nil,

                   ## ornaments
                   delayed_inverted_turn: nil,
                   delayed_turn: nil,
                   inverted_mordent: nil,
                   inverted_turn: nil,
                   mordent: nil,
                   schleifer: nil,
                   shake: nil,
                   tremolo: nil,
                   trill_mark: nil,
                   turn: nil,
                   vertical_turn: nil,
                   wavy_line: nil,
                   other_ornament: nil,
                   ornament_accidental_mark: nil,

                   ## technical
                   arrow: nil,
                   bend: nil,
                   double_tongue: nil,
                   down_bow: nil,
                   fingering: nil,
                   fingernails: nil,
                   fret: nil,
                   hammer_on: nil,
                   handbell: nil,
                   harmonic: nil,
                   heel: nil,
                   hole: nil,
                   open_string: nil,
                   other_technical: nil,
                   pluck: nil,
                   pull_off: nil,
                   snap_pizzicato: nil,
                   stopped: nil,
                   string: nil,
                   tap: nil,
                   thumb_position: nil,
                   toe: nil,
                   triple_tongue: nil,
                   up_bow: nil)

        Rest.new(measure: measure,

                 pizzicato: pizzicato,

                 grace: grace,
                 cue: cue,
                 chord: chord,
                 duration: duration,
                 tie_start: tie_start,
                 tie_stop: tie_stop,
                 voice: voice,
                 type: type,
                 dots: dots,
                 accidental: accidental,
                 time_modification: time_modification,
                 stem: stem,
                 notehead: notehead,
                 staff: staff,

                 # notations
                 accidental_mark: accidental_mark,
                 arpeggiate: arpeggiate,
                 tied: tied,
                 tuplet: tuplet,
                 dynamics: dynamics,
                 fermata: fermata,
                 glissando: glissando,
                 non_arpeggiate: non_arpeggiate,
                 slide: slide,
                 slur: slur,

                 ## articulations
                 accent: accent,
                 breath_mark: breath_mark,
                 caesura: caesura,
                 detached_legato: detached_legato,
                 doit: doit,
                 falloff: falloff,
                 other_articulation: other_articulation,
                 plop: plop,
                 scoop: scoop,
                 spiccato: spiccato,
                 staccatissimo: staccatissimo,
                 staccato: staccato,
                 stress: stress,
                 strong_accent: strong_accent,
                 tenuto: tenuto,
                 unstress: unstress,

                 ## ornaments
                 delayed_inverted_turn: delayed_inverted_turn,
                 delayed_turn: delayed_turn,
                 inverted_mordent: inverted_mordent,
                 inverted_turn: inverted_turn,
                 mordent: mordent,
                 schleifer: schleifer,
                 shake: shake,
                 tremolo: tremolo,
                 trill_mark: trill_mark,
                 turn: turn,
                 vertical_turn: vertical_turn,
                 wavy_line: wavy_line,
                 other_ornament: other_ornament,
                 ornament_accidental_mark: ornament_accidental_mark,

                 ## technical
                 arrow: arrow,
                 bend: bend,
                 double_tongue: double_tongue,
                 down_bow: down_bow,
                 fingering: fingering,
                 fingernails: fingernails,
                 fret: fret,
                 hammer_on: hammer_on,
                 handbell: handbell,
                 harmonic: harmonic,
                 heel: heel,
                 hole: hole,
                 open_string: open_string,
                 other_technical: other_technical,
                 pluck: pluck,
                 pull_off: pull_off,
                 snap_pizzicato: snap_pizzicato,
                 stopped: stopped,
                 string: string,
                 tap: tap,
                 thumb_position: thumb_position,
                 toe: toe,
                 triple_tongue: triple_tongue,
                 up_bow: up_bow).tap { |rest| @elements << rest }
      end

      def add_unpitched(pizzicato: nil,
                        # main content
                        grace: nil,
                        cue: nil,
                        chord: nil,
                        duration: nil,
                        tie_start: nil, tie_stop: nil,
                        voice: nil,
                        type: nil,
                        dots: nil,
                        accidental: nil,
                        time_modification: nil,
                        stem: nil,
                        notehead: nil,
                        staff: nil,

                        # notations
                        accidental_mark: nil,
                        arpeggiate: nil,

                        tied: nil,
                        tuplet: nil,

                        dynamics: nil,
                        fermata: nil,
                        glissando: nil,
                        non_arpeggiate: nil,

                        slide: nil,
                        slur: nil,

                        ## articulations
                        accent: nil,
                        breath_mark: nil,
                        caesura: nil,
                        detached_legato:nil,
                        doit: nil,
                        falloff: nil,
                        other_articulation: nil,
                        plop: nil,
                        scoop: nil,
                        spiccato: nil,
                        staccatissimo: nil,
                        staccato: nil,
                        stress: nil,
                        strong_accent: nil,
                        tenuto: nil,
                        unstress: nil,

                        ## ornaments
                        delayed_inverted_turn: nil,
                        delayed_turn: nil,
                        inverted_mordent: nil,
                        inverted_turn: nil,
                        mordent: nil,
                        schleifer: nil,
                        shake: nil,
                        tremolo: nil,
                        trill_mark: nil,
                        turn: nil,
                        vertical_turn: nil,
                        wavy_line: nil,
                        other_ornament: nil,
                        ornament_accidental_mark: nil,

                        ## technical
                        arrow: nil,
                        bend: nil,
                        double_tongue: nil,
                        down_bow: nil,
                        fingering: nil,
                        fingernails: nil,
                        fret: nil,
                        hammer_on: nil,
                        handbell: nil,
                        harmonic: nil,
                        heel: nil,
                        hole: nil,
                        open_string: nil,
                        other_technical: nil,
                        pluck: nil,
                        pull_off: nil,
                        snap_pizzicato: nil,
                        stopped: nil,
                        string: nil,
                        tap: nil,
                        thumb_position: nil,
                        toe: nil,
                        triple_tongue: nil,
                        up_bow: nil)

        UnpitchedNote.new(pizzicato: pizzicato,

                          grace: grace,
                          cue: cue,
                          chord: chord,
                          duration: duration,
                          tie_start: tie_start,
                          tie_stop: tie_stop,
                          voice: voice,
                          type: type,
                          dots: dots,
                          accidental: accidental,
                          time_modification: time_modification,
                          stem: stem,
                          notehead: notehead,
                          staff: staff,

                          # notations
                          accidental_mark: accidental_mark,
                          arpeggiate: arpeggiate,
                          tied: tied,
                          tuplet: tuplet,
                          dynamics: dynamics,
                          fermata: fermata,
                          glissando: glissando,
                          non_arpeggiate: non_arpeggiate,
                          slide: slide,
                          slur: slur,

                          ## articulations
                          accent: accent,
                          breath_mark: breath_mark,
                          caesura: caesura,
                          detached_legato: detached_legato,
                          doit: doit,
                          falloff: falloff,
                          other_articulation: other_articulation,
                          plop: plop,
                          scoop: scoop,
                          spiccato: spiccato,
                          staccatissimo: staccatissimo,
                          staccato: staccato,
                          stress: stress,
                          strong_accent: strong_accent,
                          tenuto: tenuto,
                          unstress: unstress,

                          ## ornaments
                          delayed_inverted_turn: delayed_inverted_turn,
                          delayed_turn: delayed_turn,
                          inverted_mordent: inverted_mordent,
                          inverted_turn: inverted_turn,
                          mordent: mordent,
                          schleifer: schleifer,
                          shake: shake,
                          tremolo: tremolo,
                          trill_mark: trill_mark,
                          turn: turn,
                          vertical_turn: vertical_turn,
                          wavy_line: wavy_line,
                          other_ornament: other_ornament,
                          ornament_accidental_mark: ornament_accidental_mark,

                          ## technical
                          arrow: arrow,
                          bend: bend,
                          double_tongue: double_tongue,
                          down_bow: down_bow,
                          fingering: fingering,
                          fingernails: fingernails,
                          fret: fret,
                          hammer_on: hammer_on,
                          handbell: handbell,
                          harmonic: harmonic,
                          heel: heel,
                          hole: hole,
                          open_string: open_string,
                          other_technical: other_technical,
                          pluck: pluck,
                          pull_off: pull_off,
                          snap_pizzicato: snap_pizzicato,
                          stopped: stopped,
                          string: string,
                          tap: tap,
                          thumb_position: thumb_position,
                          toe: toe,
                          triple_tongue: triple_tongue,
                          up_bow: up_bow).tap { |unpitched| @elements << unpitched }
      end

      def add_backup(duration:)
        Backup.new(duration: duration).tap { |backup| @elements << backup }
      end

      def add_forward(duration:, voice: nil, staff: nil)
        Forward.new(duration: duration, voice: voice, staff: staff).tap { |forward| @elements << forward }
      end

      def add_direction(type, # [ DirectionType | Hash ] | Array of (DirectionType | Hash)
                        voice: nil, # number
                        staff: nil, # number
                        offset: nil) # number (divisions)

        Direction.new(type, voice: voice, staff: staff).tap { |direction| @elements << direction }
      end

      def add_wedge(type, niente: nil, voice: nil, staff: nil)
        add_direction({ kind: :wedge, type: type, niente: niente }, voice: voice, staff: staff)
      end

      def add_dynamics(value, voice: nil, staff: nil)
        add_direction({ kind: :dynamics, value: value }, voice: voice, staff: staff)
      end

      def add_pedal(type, line: nil, voice: nil, staff: nil)
        add_direction({ kind: :pedal, type: type, line: line }, voice: voice, staff: staff)
      end

      def add_bracket(type, line_end:, line_type: nil, voice: nil, staff: nil)
        add_direction({ kind: :bracket, type: type, line_end: line_end, line_type: line_type }, voice: voice, staff: staff)
      end

      def add_dashes(type, voice: nil, staff: nil)
        add_direction({ kind: :dashes, type: type }, voice: voice, staff: staff)
      end

      def add_words(words, voice: nil, staff: nil)
        add_direction({ kind: :words, value: words }, voice: voice, staff: staff)
      end

      def add_octave_shift(type, size: nil, voice: nil, staff: nil)
        add_direction({ kind: :octave_shift, type: type, size: size }, voice: voice, staff: staff)
      end

      def add_metronome(beat_unit:, beat_unit_dots: nil, per_minute:, voice: nil, staff: nil)
        add_direction({ kind: :metronome, beat_unit: beat_unit, beat_unit_dots: beat_unit_dots, per_minute: per_minute }, voice: voice, staff: staff)
      end

      def _to_xml(io, indent:, tabs:)
        io.puts "#{tabs}<measure number=\"#{@number}\">"

        @elements.each do |element|
          element.to_xml(io, indent: indent + 1)
        end

        io.puts "#{tabs}</measure>"
      end
    end
  end
end