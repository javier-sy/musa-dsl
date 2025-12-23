# frozen_string_literal: true

module Musa
  module Scales
    # Bebop minor scale kind.
    #
    # BebopMinorScaleKind defines the bebop minor scale, an eight-note
    # scale that adds a chromatic passing tone (major 7th) to the Dorian
    # mode. This allows chord tones to fall on downbeats during eighth-note runs.
    #
    # ## Pitch Structure
    #
    # 8 degrees plus extended:
    #
    # **Scale Degrees** (lowercase for minor quality):
    #
    # - **i** (tonic): Root (0 semitones)
    # - **ii** (supertonic): Major second (2 semitones)
    # - **iii** (mediant): Minor third (3 semitones)
    # - **iv** (subdominant): Perfect fourth (5 semitones)
    # - **v** (dominant): Perfect fifth (7 semitones)
    # - **vi** (submediant): Major sixth (9 semitones) ← DORIAN
    # - **vii** (subtonic): Minor seventh (10 semitones)
    # - **vii#** (leading): Major seventh (11 semitones) ← PASSING TONE
    #
    # ## Bebop Principle
    #
    # The added major 7th chromatic note ensures that:
    # - Chord tones (1, b3, 5, b7) fall on strong beats
    # - Non-chord tones fall on weak beats
    # - Smooth chromatic connection from b7 to root
    #
    # ## Musical Character
    #
    # The bebop minor scale:
    #
    # - Used over minor 7th chords
    # - Based on Dorian mode (bright minor)
    # - Common in jazz ii-V-I progressions
    #
    # ## Usage
    #
    #     d_bebop_min = Scales[:et12][440.0][:bebop_minor][62]
    #     d_bebop_min[6].pitch  # C (72) - minor 7th
    #     d_bebop_min[7].pitch  # C# (73) - major 7th (passing)
    #     d_bebop_min[8].pitch  # D (74) - octave
    #
    # @see ScaleKind Abstract base class
    # @see DorianScaleKind Dorian mode (7-note parent)
    # @see BebopDominantScaleKind Bebop dominant scale
    class BebopMinorScaleKind < ScaleKind
      class << self
        @@pitches =
            [{ functions: %i[i _1 tonic first],
               pitch: 0 },
             { functions: %i[ii _2 supertonic second],
               pitch: 2 },
             { functions: %i[iii _3 mediant third],
               pitch: 3 },
             { functions: %i[iv _4 subdominant fourth],
               pitch: 5 },
             { functions: %i[v _5 dominant fifth],
               pitch: 7 },
             { functions: %i[vi _6 submediant sixth],
               pitch: 9 },
             { functions: %i[vii _7 subtonic seventh],
               pitch: 10 },
             { functions: %i[vii# _8 leading eighth],
               pitch: 11 },
             { functions: %i[viii _9 ninth],
               pitch: 12 },
             { functions: %i[ix _10 tenth],
               pitch: 12 + 2 },
             { functions: %i[x _11 eleventh],
               pitch: 12 + 3 },
             { functions: %i[xi _12 twelfth],
               pitch: 12 + 5 },
             { functions: %i[xii _13 thirteenth],
               pitch: 12 + 7 },
             { functions: %i[xiii _14 fourteenth],
               pitch: 12 + 9 },
             { functions: %i[xiv _15 fifteenth],
               pitch: 12 + 10 },
             { functions: %i[xv _16 sixteenth],
               pitch: 12 + 11 }].freeze

        def pitches
          @@pitches
        end

        def grades
          8
        end

        def id
          :bebop_minor
        end
      end

      EquallyTempered12ToneScaleSystem.register BebopMinorScaleKind
    end
  end
end
