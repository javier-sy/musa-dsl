# frozen_string_literal: true

module Musa
  module Scales
    # Phrygian dominant scale kind (Spanish Phrygian).
    #
    # PhrygianDominantScaleKind defines the Phrygian dominant scale (also called
    # Spanish Phrygian, Freygish, or Spanish Gypsy scale), the fifth mode of
    # harmonic minor. It's the quintessential flamenco scale.
    #
    # ## Pitch Structure
    #
    # 7 diatonic degrees plus extended harmony:
    #
    # **Scale Degrees** (uppercase for major 3rd quality):
    #
    # - **I** (tonic): Root (0 semitones)
    # - **II** (supertonic): Minor second (1 semitone) ← PHRYGIAN
    # - **III** (mediant): Major third (4 semitones) ← DOMINANT
    # - **IV** (subdominant): Perfect fourth (5 semitones)
    # - **V** (dominant): Perfect fifth (7 semitones)
    # - **VI** (submediant): Minor sixth (8 semitones)
    # - **VII** (subtonic): Minor seventh (10 semitones)
    #
    # ## Key Features
    #
    # - Phrygian's minor second (exotic)
    # - Dominant's major third (strong harmonic character)
    # - Creates the characteristic flamenco sound
    #
    # ## Musical Character
    #
    # The Phrygian dominant scale:
    #
    # - The sound of flamenco and Spanish guitar
    # - Works over dominant chords resolving to minor
    # - Common in klezmer and Middle Eastern music too
    # - Intensely expressive and dramatic
    #
    # ## Usage
    #
    #     e_phry_dom = Scales[:et12][440.0][:phrygian_dominant][64]
    #     e_phry_dom.tonic  # E (64)
    #     e_phry_dom.II     # F (65) - minor second (Phrygian)
    #     e_phry_dom.III    # G# (68) - major third (Dominant)
    #
    # @see ScaleKind Abstract base class
    # @see PhrygianScaleKind Phrygian mode (with minor 3rd)
    # @see MinorHarmonicScaleKind Parent harmonic minor scale
    class PhrygianDominantScaleKind < ScaleKind
      @base_metadata = {
        family: :ethnic,
        brightness: -1,
        character: [:spanish, :flamenco, :jewish],
        parent: { scale: :minor_harmonic, degree: 5 }
      }.freeze

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
             { functions: %i[VII _7 subtonic seventh],
               pitch: 10 },
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
          :phrygian_dominant
        end
      end

      EquallyTempered12ToneScaleSystem.register PhrygianDominantScaleKind
    end
  end
end
