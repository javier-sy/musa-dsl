# frozen_string_literal: true

module Musa
  module Scales
    # Bebop dominant scale kind.
    #
    # BebopDominantScaleKind defines the bebop dominant scale, an eight-note
    # scale that adds a chromatic passing tone (major 7th) to the Mixolydian
    # mode. This allows chord tones to fall on downbeats during eighth-note runs.
    #
    # ## Pitch Structure
    #
    # 8 degrees plus extended:
    #
    # **Scale Degrees** (uppercase for major quality):
    #
    # - **I** (tonic): Root (0 semitones)
    # - **II** (supertonic): Major second (2 semitones)
    # - **III** (mediant): Major third (4 semitones)
    # - **IV** (subdominant): Perfect fourth (5 semitones)
    # - **V** (dominant): Perfect fifth (7 semitones)
    # - **VI** (submediant): Major sixth (9 semitones)
    # - **VII** (subtonic): Minor seventh (10 semitones)
    # - **VII#** (leading): Major seventh (11 semitones) ← PASSING TONE
    #
    # ## Bebop Principle
    #
    # The added chromatic note ensures that:
    # - Chord tones (1, 3, 5, b7) fall on strong beats
    # - Non-chord tones fall on weak beats
    # - Creates smooth voice leading at tempo
    #
    # ## Musical Character
    #
    # The bebop dominant scale:
    #
    # - Essential for jazz improvisation over dominant 7th chords
    # - Creates characteristic bebop sound at fast tempos
    # - Used by Charlie Parker, Dizzy Gillespie, and bebop masters
    #
    # ## Usage
    #
    #     g_bebop = Scales[:et12][440.0][:bebop_dominant][67]
    #     g_bebop[0].pitch  # G (67) - root
    #     g_bebop[6].pitch  # F (77) - minor 7th
    #     g_bebop[7].pitch  # F# (78) - major 7th (chromatic passing)
    #
    # @see ScaleKind Abstract base class
    # @see MixolydianScaleKind Mixolydian (7-note parent)
    # @see BebopMajorScaleKind Bebop major scale
    class BebopDominantScaleKind < ScaleKind
      @base_metadata = {
        family: :bebop,
        brightness: 1,
        character: [:jazz, :chromatic_passing, :dominant],
        parent: nil
      }.freeze

      class << self
        @@pitches =
            [{ functions: %i[I _1 tonic first],
               pitch: 0 },
             { functions: %i[II _2 supertonic second],
               pitch: 2 },
             { functions: %i[III _3 mediant third],
               pitch: 4 },
             { functions: %i[IV _4 subdominant fourth],
               pitch: 5 },
             { functions: %i[V _5 dominant fifth],
               pitch: 7 },
             { functions: %i[VI _6 submediant sixth],
               pitch: 9 },
             { functions: %i[VII _7 subtonic seventh],
               pitch: 10 },
             { functions: %i[VII# _8 leading eighth],
               pitch: 11 },
             { functions: %i[VIII _9 ninth],
               pitch: 12 },
             { functions: %i[IX _10 tenth],
               pitch: 12 + 2 },
             { functions: %i[X _11 eleventh],
               pitch: 12 + 4 },
             { functions: %i[XI _12 twelfth],
               pitch: 12 + 5 },
             { functions: %i[XII _13 thirteenth],
               pitch: 12 + 7 },
             { functions: %i[XIII _14 fourteenth],
               pitch: 12 + 9 },
             { functions: %i[XIV _15 fifteenth],
               pitch: 12 + 10 },
             { functions: %i[XV _16 sixteenth],
               pitch: 12 + 11 }].freeze

        def pitches
          @@pitches
        end

        def grades
          8
        end

        def id
          :bebop_dominant
        end
      end

      EquallyTempered12ToneScaleSystem.register BebopDominantScaleKind
    end
  end
end
