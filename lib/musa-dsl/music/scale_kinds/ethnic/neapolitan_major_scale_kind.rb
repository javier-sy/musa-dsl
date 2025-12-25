# frozen_string_literal: true

module Musa
  module Scales
    # Neapolitan major scale kind.
    #
    # NeapolitanMajorScaleKind defines the Neapolitan major scale, a
    # major scale with a lowered second degree, combining the Neapolitan
    # coloring with a brighter major upper structure.
    #
    # ## Pitch Structure
    #
    # 7 diatonic degrees plus extended harmony:
    #
    # **Scale Degrees** (uppercase for major quality):
    #
    # - **I** (tonic): Root (0 semitones)
    # - **II** (supertonic): Minor second (1 semitone) ← NEAPOLITAN (b2)
    # - **III** (mediant): Minor third (3 semitones)
    # - **IV** (subdominant): Perfect fourth (5 semitones)
    # - **V** (dominant): Perfect fifth (7 semitones)
    # - **VI** (submediant): Major sixth (9 semitones)
    # - **VII** (leading): Major seventh (11 semitones)
    #
    # ## Relationship to Melodic Minor
    #
    # Neapolitan major = Melodic minor with lowered 2nd
    #
    # ## Musical Character
    #
    # The Neapolitan major scale:
    #
    # - Exotic but brighter than Neapolitan minor
    # - Combines Phrygian darkness with major brightness
    # - Used in classical and contemporary music
    # - Unique harmonic possibilities
    #
    # ## Usage
    #
    #     c_neap_maj = Scales[:et12][440.0][:neapolitan_major][60]
    #     c_neap_maj.tonic  # C (60)
    #     c_neap_maj.II     # Db (61) - minor second (Neapolitan)
    #     c_neap_maj.VI     # A (69) - major sixth
    #     c_neap_maj.VII    # B (71) - leading tone
    #
    # @see ScaleKind Abstract base class
    # @see MelodicMinorScaleKind Melodic minor (with major 2nd)
    # @see NeapolitanMinorScaleKind Neapolitan minor
    class NeapolitanMajorScaleKind < ScaleKind
      @base_metadata = {
        family: :ethnic,
        brightness: -1,
        character: [:neapolitan, :classical, :bright_dark],
        parent: nil
      }.freeze

      class << self
        @@pitches =
            [{ functions: %i[I _1 tonic first],
               pitch: 0 },
             { functions: %i[II _2 supertonic second],
               pitch: 1 },
             { functions: %i[III _3 mediant third],
               pitch: 3 },
             { functions: %i[IV _4 subdominant fourth],
               pitch: 5 },
             { functions: %i[V _5 dominant fifth],
               pitch: 7 },
             { functions: %i[VI _6 submediant sixth],
               pitch: 9 },
             { functions: %i[VII _7 leading seventh],
               pitch: 11 },
             { functions: %i[VIII _8 eighth],
               pitch: 12 },
             { functions: %i[IX _9 ninth],
               pitch: 12 + 1 },
             { functions: %i[X _10 tenth],
               pitch: 12 + 3 },
             { functions: %i[XI _11 eleventh],
               pitch: 12 + 5 },
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
          :neapolitan_major
        end
      end

      EquallyTempered12ToneScaleSystem.register NeapolitanMajorScaleKind
    end
  end
end
