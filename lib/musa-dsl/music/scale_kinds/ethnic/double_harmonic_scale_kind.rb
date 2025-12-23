# frozen_string_literal: true

module Musa
  module Scales
    # Double harmonic scale kind (Byzantine scale).
    #
    # DoubleHarmonicScaleKind defines the double harmonic scale (also called
    # Byzantine scale, Arabic scale, or Gypsy Major), characterized by two
    # augmented seconds that create an exotic, Middle Eastern sound.
    #
    # ## Pitch Structure
    #
    # 7 diatonic degrees plus extended harmony:
    #
    # **Scale Degrees** (uppercase for major quality):
    #
    # - **I** (tonic): Root (0 semitones)
    # - **II** (supertonic): Minor second (1 semitone) ← CHARACTERISTIC
    # - **III** (mediant): Major third (4 semitones)
    # - **IV** (subdominant): Perfect fourth (5 semitones)
    # - **V** (dominant): Perfect fifth (7 semitones)
    # - **VI** (submediant): Minor sixth (8 semitones) ← CHARACTERISTIC
    # - **VII** (leading): Major seventh (11 semitones)
    #
    # ## Two Augmented Seconds
    #
    # - Between II and III (b2 to 3): 3 semitones
    # - Between VI and VII (b6 to 7): 3 semitones
    #
    # ## Musical Character
    #
    # The double harmonic scale:
    #
    # - Strongly Middle Eastern/Byzantine sound
    # - Two exotic augmented second intervals
    # - Major quality with dramatic colorations
    # - Used in Arabic, Turkish, Greek, and Indian music
    #
    # ## Usage
    #
    #     c_dbl_harm = Scales[:et12][440.0][:double_harmonic][60]
    #     c_dbl_harm.tonic  # C (60)
    #     c_dbl_harm.II     # Db (61) - minor second
    #     c_dbl_harm.III    # E (64) - major third (augmented second above)
    #
    # @see ScaleKind Abstract base class
    # @see PhrygianDominantScaleKind Spanish Phrygian (similar exotic quality)
    # @see HungarianMinorScaleKind Hungarian minor
    class DoubleHarmonicScaleKind < ScaleKind
      class << self
        @@pitches =
            [{ functions: %i[I _1 tonic first],
               pitch: 0 },
             { functions: %i[II _2 supertonic second],
               pitch: 1 },
             { functions: %i[III _3 mediant third],
               pitch: 4 },
             { functions: %i[IV _4 subdominant fourth],
               pitch: 5 },
             { functions: %i[V _5 dominant fifth],
               pitch: 7 },
             { functions: %i[VI _6 submediant sixth],
               pitch: 8 },
             { functions: %i[VII _7 leading seventh],
               pitch: 11 },
             { functions: %i[VIII _8 eighth],
               pitch: 12 },
             { functions: %i[IX _9 ninth],
               pitch: 12 + 1 },
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
          :double_harmonic
        end
      end

      EquallyTempered12ToneScaleSystem.register DoubleHarmonicScaleKind
    end
  end
end
