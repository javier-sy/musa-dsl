# frozen_string_literal: true

module Musa
  module Scales
    # Harmonic minor scale kind.
    #
    # MinorHarmonicScaleKind defines the harmonic minor scale, a variation of
    # the natural minor with a raised seventh degree. This creates a leading
    # tone (major seventh) that resolves strongly to the tonic, giving the
    # scale a more directed, dramatic character.
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
    # - **vii** (leading): **Major seventh** (11 semitones) ← RAISED from natural minor
    #
    # **Extended degrees**: viii-xiii (compound intervals)
    #
    # ## Key Difference from Natural Minor
    #
    # The **vii** degree is raised from 10 semitones (minor seventh) to
    # 11 semitones (major seventh), creating:
    #
    # - A **leading tone** that resolves strongly upward to the tonic
    # - An **augmented second** interval between vi and vii (3 semitones)
    # - A **dominant seventh chord** (v7) with strong resolution to i
    #
    # ## Musical Character
    #
    # The harmonic minor scale:
    #
    # - Maintains minor quality (minor third)
    # - Provides strong dominant-to-tonic resolution
    # - Creates exotic sound due to augmented second (vi-vii)
    # - Common in classical, jazz, and Middle Eastern music
    #
    # ## Function Aliases
    #
    # Same as natural minor:
    #
    # - **Numeric**: _1, _2, _3, _4, _5, _6, _7
    # - **Roman**: i, ii, iii, iv, v, vi, vii
    # - **Function**: tonic, supertonic, mediant, subdominant, dominant,
    #                 submediant, leading
    # - **Special**: relative/relative_major for iii
    #
    # ## Usage
    #
    #     a_harmonic_minor = Scales[:et12][440.0][:minor_harmonic][69]
    #     a_harmonic_minor.vii  # G# (80) - raised 7th, not G (79)
    #     a_harmonic_minor.vi   # F (77)
    #     # Augmented second: F to G# = 3 semitones
    #
    # @see ScaleKind Abstract base class
    # @see MinorNaturalScaleKind Natural minor (with minor 7th)
    # @see MajorScaleKind Major scale
    class MinorHarmonicScaleKind < ScaleKind
      @base_metadata = {
        family: :diatonic,
        brightness: -2,
        character: [:dark, :exotic, :dramatic],
        parent: nil
      }.freeze

      class << self
        @@pitches =
            [{ functions: %i[i _1 tonic],
               pitch: 0 },
             { functions: %i[ii _2 supertonic],
               pitch: 2 },
             { functions: %i[iii _3 mediant relative relative_major],
               pitch: 3 },
             { functions: %i[iv _4 subdominant],
               pitch: 5 },
             { functions: %i[v _5 dominant],
               pitch: 7 },
             { functions: %i[vi _6 submediant],
               pitch: 8 },
             { functions: %i[vii _7 leading],
               pitch: 11 },
             { functions: %i[viii _8],
               pitch: 12 },
             { functions: %i[ix _9],
               pitch: 12 + 2 },
             { functions: %i[x _10],
               pitch: 12 + 3 },
             { functions: %i[xi _11],
               pitch: 12 + 5 },
             { functions: %i[xii _12],
               pitch: 12 + 7 },
             { functions: %i[xiii _13],
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
        # @return [Symbol] :minor_harmonic
        def id
          :minor_harmonic
        end
      end

      EquallyTempered12ToneScaleSystem.register MinorHarmonicScaleKind
    end
  end
end
