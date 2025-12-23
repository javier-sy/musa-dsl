# frozen_string_literal: true

module Musa
  module Scales
    # Neapolitan minor scale kind.
    #
    # NeapolitanMinorScaleKind defines the Neapolitan minor scale, a
    # harmonic minor scale with a lowered second degree, named after
    # the Neapolitan school of opera in the 18th century.
    #
    # ## Pitch Structure
    #
    # 7 diatonic degrees plus extended harmony:
    #
    # **Scale Degrees** (lowercase for minor quality):
    #
    # - **i** (tonic): Root (0 semitones)
    # - **ii** (supertonic): Minor second (1 semitone) ← NEAPOLITAN (b2)
    # - **iii** (mediant): Minor third (3 semitones)
    # - **iv** (subdominant): Perfect fourth (5 semitones)
    # - **v** (dominant): Perfect fifth (7 semitones)
    # - **vi** (submediant): Minor sixth (8 semitones)
    # - **vii** (leading): Major seventh (11 semitones)
    #
    # ## Relationship to Harmonic Minor
    #
    # Neapolitan minor = Harmonic minor with lowered 2nd
    #
    # ## Musical Character
    #
    # The Neapolitan minor scale:
    #
    # - Dark, dramatic, operatic
    # - The Neapolitan sixth chord (bII) is characteristic
    # - Used in classical and film music
    # - Strong resolution tendency to tonic
    #
    # ## Usage
    #
    #     a_neap_min = Scales[:et12][440.0][:neapolitan_minor][69]
    #     a_neap_min.tonic  # A (69)
    #     a_neap_min.ii     # Bb (70) - minor second (Neapolitan)
    #     a_neap_min.vii    # G# (80) - leading tone
    #
    # @see ScaleKind Abstract base class
    # @see MinorHarmonicScaleKind Harmonic minor (with major 2nd)
    # @see NeapolitanMajorScaleKind Neapolitan major
    class NeapolitanMinorScaleKind < ScaleKind
      class << self
        @@pitches =
            [{ functions: %i[i _1 tonic first],
               pitch: 0 },
             { functions: %i[ii _2 supertonic second],
               pitch: 1 },
             { functions: %i[iii _3 mediant third],
               pitch: 3 },
             { functions: %i[iv _4 subdominant fourth],
               pitch: 5 },
             { functions: %i[v _5 dominant fifth],
               pitch: 7 },
             { functions: %i[vi _6 submediant sixth],
               pitch: 8 },
             { functions: %i[vii _7 leading seventh],
               pitch: 11 },
             { functions: %i[viii _8 eighth],
               pitch: 12 },
             { functions: %i[ix _9 ninth],
               pitch: 12 + 1 },
             { functions: %i[x _10 tenth],
               pitch: 12 + 3 },
             { functions: %i[xi _11 eleventh],
               pitch: 12 + 5 },
             { functions: %i[xii _12 twelfth],
               pitch: 12 + 7 },
             { functions: %i[xiii _13 thirteenth],
               pitch: 12 + 8 }].freeze

        def pitches
          @@pitches
        end

        def grades
          7
        end

        def id
          :neapolitan_minor
        end
      end

      EquallyTempered12ToneScaleSystem.register NeapolitanMinorScaleKind
    end
  end
end
