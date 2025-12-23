# frozen_string_literal: true

module Musa
  module Scales
    # Lydian augmented scale kind (third mode of melodic minor).
    #
    # LydianAugmentedScaleKind defines the Lydian augmented scale, the third
    # mode of the melodic minor scale. It combines the Lydian's raised fourth
    # with an augmented (raised) fifth.
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
    # - **IV** (subdominant): Augmented fourth (6 semitones) ← LYDIAN
    # - **V** (dominant): Augmented fifth (8 semitones) ← AUGMENTED
    # - **VI** (submediant): Major sixth (9 semitones)
    # - **VII** (leading): Major seventh (11 semitones)
    #
    # ## Relationship to Other Modes
    #
    # - Lydian with augmented 5th
    # - 3rd mode of melodic minor
    # - Contains both #4 and #5
    #
    # ## Musical Character
    #
    # The Lydian augmented scale:
    #
    # - Extremely bright and ethereal
    # - Used over maj7#5 and maj7#11 chords
    # - Dreamy, floating quality
    # - Common in contemporary jazz and film music
    #
    # ## Usage
    #
    #     eb_lyd_aug = Scales[:et12][440.0][:lydian_augmented][63]
    #     eb_lyd_aug.tonic  # Eb (63)
    #     eb_lyd_aug.IV     # A (69) - augmented fourth
    #     eb_lyd_aug.V      # B (71) - augmented fifth
    #
    # @see ScaleKind Abstract base class
    # @see LydianScaleKind Lydian mode
    # @see MelodicMinorScaleKind Parent melodic minor scale
    class LydianAugmentedScaleKind < ScaleKind
      class << self
        @@pitches =
            [{ functions: %i[I _1 tonic first],
               pitch: 0 },
             { functions: %i[II _2 supertonic second],
               pitch: 2 },
             { functions: %i[III _3 mediant third],
               pitch: 4 },
             { functions: %i[IV _4 subdominant fourth],
               pitch: 6 },
             { functions: %i[V _5 dominant fifth],
               pitch: 8 },
             { functions: %i[VI _6 submediant sixth],
               pitch: 9 },
             { functions: %i[VII _7 leading seventh],
               pitch: 11 },
             { functions: %i[VIII _8 eighth],
               pitch: 12 },
             { functions: %i[IX _9 ninth],
               pitch: 12 + 2 },
             { functions: %i[X _10 tenth],
               pitch: 12 + 4 },
             { functions: %i[XI _11 eleventh],
               pitch: 12 + 6 },
             { functions: %i[XII _12 twelfth],
               pitch: 12 + 8 },
             { functions: %i[XIII _13 thirteenth],
               pitch: 12 + 9 }].freeze

        def pitches
          @@pitches
        end

        def grades
          7
        end

        def id
          :lydian_augmented
        end
      end

      EquallyTempered12ToneScaleSystem.register LydianAugmentedScaleKind
    end
  end
end
