# frozen_string_literal: true

module Musa
  module Scales
    # Natural minor scale kind (Aeolian mode).
    #
    # MinorNaturalScaleKind defines the natural minor scale, parallel to the
    # major scale but with a darker, melancholic character. It follows the
    # pattern: W-H-W-W-H-W-W or intervals: M2-m2-M2-M2-m2-M2-M2 from the root.
    #
    # ## Pitch Structure
    #
    # 7 diatonic degrees plus extended harmony (8th-13th):
    #
    # **Scale Degrees** (Roman numerals, lowercase for minor):
    #
    # - **i** (tonic): Root (0 semitones)
    # - **ii** (supertonic): Major second (2 semitones)
    # - **iii** (mediant): Minor third (3 semitones, relative major)
    # - **iv** (subdominant): Perfect fourth (5 semitones)
    # - **v** (dominant): Perfect fifth (7 semitones)
    # - **vi** (submediant): Minor sixth (8 semitones)
    # - **vii** (subtonic): Minor seventh (10 semitones, NOT leading tone)
    #
    # **Extended degrees**: viii-xiii (compound intervals)
    #
    # ## Differences from Major
    #
    # Compared to major scale (same tonic):
    #
    # - **iii**: Flatted third (minor third instead of major)
    # - **vi**: Flatted sixth (minor sixth instead of major)
    # - **vii**: Flatted seventh (minor seventh instead of major)
    #
    # ## Relative Major
    #
    # The **iii** degree is the root of the relative major scale (shares same
    # notes but different tonic). For example:
    #
    # - A minor (natural) relative major: C major
    # - C major relative minor: A minor
    #
    # ## Function Aliases
    #
    # Similar to major but with lowercase Roman numerals:
    #
    # - **Numeric**: _1, _2, _3, _4, _5, _6, _7
    # - **Roman**: i, ii, iii, iv, v, vi, vii
    # - **Function**: tonic, supertonic, mediant, subdominant, dominant, submediant
    # - **Ordinal**: first, second, third, fourth, fifth, sixth, seventh
    # - **Special**: relative/relative_major for iii
    #
    # ## Usage
    #
    #     a_minor = Scales[:et12][440.0][:minor][69]
    #     a_minor.tonic        # A (69)
    #     a_minor.dominant     # E (76)
    #     a_minor.iii          # C (72) - relative major root
    #     a_minor.relative_major.scale(:major)  # C major scale
    #
    # @see ScaleKind Abstract base class
    # @see MajorScaleKind Major scale
    # @see MinorHarmonicScaleKind Harmonic minor (with raised 7th)
    class MinorNaturalScaleKind < ScaleKind
      class << self
        @@pitches =
            [{ functions: %i[i _1 tonic first],
               pitch: 0 },
             { functions: %i[ii _2 supertonic second],
               pitch: 2 },
             { functions: %i[iii _3 mediant relative relative_major third],
               pitch: 3 },
             { functions: %i[iv _4 subdominant fourth],
               pitch: 5 },
             { functions: %i[v _5 dominant fifth],
               pitch: 7 },
             { functions: %i[vi _6 submediant sixth],
               pitch: 8 },
             { functions: %i[vii _7 seventh],
               pitch: 10 },
             { functions: %i[viii _8 eighth],
               pitch: 12 },
             { functions: %i[ix _9 ninth],
               pitch: 12 + 2 },
             { functions: %i[x _10 tenth],
               pitch: 12 + 3 },
             { functions: %i[xi _11 eleventh],
               pitch: 12 + 5 },
             { functions: %i[xii _12 twelfth],
               pitch: 12 + 7 },
             { functions: %i[xiii _13 thirteenth],
               pitch: 12 + 8 }].freeze

        # Pitch structure.
        # @return [Array<Hash>] pitch definitions with functions and offsets
        def pitches
          @@pitches
        end

        # Number of diatonic degrees.
        # @return [Integer] 7
        def grades
          7
        end

        # Scale kind identifier.
        # @return [Symbol] :minor
        def id
          :minor
        end
      end

      EquallyTempered12ToneScaleSystem.register MinorNaturalScaleKind
    end
  end
end
