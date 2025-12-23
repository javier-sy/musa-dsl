# frozen_string_literal: true

module Musa
  module Scales
    # Harmonic major scale kind.
    #
    # HarmonicMajorScaleKind defines the harmonic major scale, a major scale
    # with a lowered sixth degree. It creates an augmented second between
    # the sixth and seventh degrees, similar to harmonic minor but in a
    # major context.
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
    # - **VII** (leading): Major seventh (11 semitones)
    #
    # ## Key Feature
    #
    # The augmented second between b6 and natural 7 creates an exotic
    # interval similar to harmonic minor, but in a major key context.
    #
    # ## Musical Character
    #
    # The harmonic major scale:
    #
    # - Major quality with exotic coloring
    # - Augmented second (b6 to 7) adds drama
    # - Used in classical, jazz, and film music
    # - Creates unique diminished chord on bVI
    #
    # ## Usage
    #
    #     c_harm_maj = Scales[:et12][440.0][:major_harmonic][60]
    #     c_harm_maj.tonic    # C (60)
    #     c_harm_maj.VI       # Ab (68) - minor sixth
    #     c_harm_maj.leading  # B (71) - major seventh
    #     # Ab to B = augmented second (3 semitones)
    #
    # @see ScaleKind Abstract base class
    # @see MajorScaleKind Major scale (with major 6th)
    # @see MinorHarmonicScaleKind Harmonic minor (similar augmented second)
    class HarmonicMajorScaleKind < ScaleKind
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
             { functions: %i[VII _7 leading seventh],
               pitch: 11 },
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
          :major_harmonic
        end
      end

      EquallyTempered12ToneScaleSystem.register HarmonicMajorScaleKind
    end
  end
end
