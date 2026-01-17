# frozen_string_literal: true

module Musa
  module Scales
    # Lydian dominant scale kind (fourth mode of melodic minor).
    #
    # LydianDominantScaleKind defines the Lydian dominant scale (also called
    # Lydian b7, Overtone scale, or Bartók scale), the fourth mode of the
    # melodic minor scale. It combines the Lydian's raised fourth with a
    # dominant seventh.
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
    # - **IV** (subdominant): Augmented fourth (6 semitones) ← LYDIAN (#4)
    # - **V** (dominant): Perfect fifth (7 semitones)
    # - **VI** (submediant): Major sixth (9 semitones)
    # - **VII** (subtonic): Minor seventh (10 semitones) ← DOMINANT (b7)
    #
    # ## Relationship to Other Modes
    #
    # - Lydian with lowered 7th
    # - Mixolydian with raised 4th
    # - 4th mode of melodic minor
    # - Matches the harmonic series closely
    #
    # ## Musical Character
    #
    # The Lydian dominant scale:
    #
    # - Bright but with dominant tension
    # - Used over 7#11 chords
    # - Common in jazz, Béla Bartók's music
    # - Creates sophisticated dominant sound
    #
    # ## Usage
    #
    #     f_lyd_dom = Scales[:et12][440.0][:lydian_dominant][65]
    #     f_lyd_dom.tonic  # F (65)
    #     f_lyd_dom.IV     # B (71) - augmented fourth
    #     f_lyd_dom.VII    # Eb (75) - minor seventh
    #
    # @see ScaleKind Abstract base class
    # @see LydianScaleKind Lydian mode (with major 7th)
    # @see MixolydianScaleKind Mixolydian mode (with perfect 4th)
    # @see MelodicMinorScaleKind Parent melodic minor scale
    class LydianDominantScaleKind < ScaleKind
      @base_metadata = {
        family: :melodic_minor_modes,
        brightness: 1,
        character: [:bright, :dominant, :fusion],
        parent: { scale: :minor_melodic, degree: 4 }
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
               pitch: 6 },
             { functions: %i[V _5 dominant fifth],
               pitch: 7 },
             { functions: %i[VI _6 submediant sixth],
               pitch: 9 },
             { functions: %i[VII _7 subtonic seventh],
               pitch: 10 },
             { functions: %i[VIII _8 eighth],
               pitch: 12 },
             { functions: %i[IX _9 ninth],
               pitch: 12 + 2 },
             { functions: %i[X _10 tenth],
               pitch: 12 + 4 },
             { functions: %i[XI _11 eleventh],
               pitch: 12 + 6 },
             { functions: %i[XII _12 twelfth],
               pitch: 12 + 7 },
             { functions: %i[XIII _13 thirteenth],
               pitch: 12 + 9 }].freeze

        def pitches
          @@pitches
        end

        def grades
          7
        end

        def id
          :lydian_dominant
        end
      end

      EquallyTempered12ToneScaleSystem.register LydianDominantScaleKind
    end
  end
end
