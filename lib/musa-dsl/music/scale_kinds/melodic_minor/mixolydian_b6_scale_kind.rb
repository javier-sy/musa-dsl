# frozen_string_literal: true

module Musa
  module Scales
    # Mixolydian b6 scale kind (fifth mode of melodic minor).
    #
    # MixolydianB6ScaleKind defines the Mixolydian b6 scale (also called
    # Melodic Major, Hindu scale, or Aeolian Dominant), the fifth mode of
    # the melodic minor scale. It combines the Mixolydian's major quality
    # with a minor sixth.
    #
    # ## Pitch Structure
    #
    # 7 diatonic degrees plus extended harmony:
    #
    # **Scale Degrees** (uppercase for major quality):
    #
    # - **I** (tonic): Root (0 semitones)
    # - **II** (supertonic): Major second (2 semitones)
    # - **III** (mediant): Major third (4 semitones)
    # - **IV** (subdominant): Perfect fourth (5 semitones)
    # - **V** (dominant): Perfect fifth (7 semitones)
    # - **VI** (submediant): Minor sixth (8 semitones) ← CHARACTERISTIC (b6)
    # - **VII** (subtonic): Minor seventh (10 semitones)
    #
    # ## Relationship to Other Modes
    #
    # - Mixolydian with lowered 6th
    # - Major scale with b6 and b7
    # - 5th mode of melodic minor
    #
    # ## Musical Character
    #
    # The Mixolydian b6 scale:
    #
    # - Melancholic major quality
    # - Used over dominant 7th with b13 (V7b13)
    # - Creates a beautiful tension in the upper structure
    # - Common in jazz and contemporary music
    #
    # ## Usage
    #
    #     g_mix_b6 = Scales[:et12][440.0][:mixolydian_b6][67]
    #     g_mix_b6.tonic  # G (67)
    #     g_mix_b6.VI     # Eb (75) - minor sixth
    #
    # @see ScaleKind Abstract base class
    # @see MixolydianScaleKind Mixolydian mode (with major 6th)
    # @see MelodicMinorScaleKind Parent melodic minor scale
    class MixolydianB6ScaleKind < ScaleKind
      @base_metadata = {
        family: :melodic_minor_modes,
        brightness: 0,
        character: [:hindu, :dominant, :melodic],
        parent: { scale: :minor_melodic, degree: 5 }
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
               pitch: 8 },
             { functions: %i[VII _7 subtonic seventh],
               pitch: 10 },
             { functions: %i[VIII _8 eighth],
               pitch: 12 },
             { functions: %i[IX _9 ninth],
               pitch: 12 + 2 },
             { functions: %i[X _10 tenth],
               pitch: 12 + 4 },
             { functions: %i[XI _11 eleventh],
               pitch: 12 + 5 },
             { functions: %i[XII _12 twelfth],
               pitch: 12 + 7 },
             { functions: %i[XIII _13 thirteenth],
               pitch: 12 + 8 }].freeze

        def pitches
          @@pitches
        end

        def grades
          7
        end

        def id
          :mixolydian_b6
        end
      end

      EquallyTempered12ToneScaleSystem.register MixolydianB6ScaleKind
    end
  end
end
