# frozen_string_literal: true

module Musa
  module Scales
    # Major scale kind (Ionian mode).
    #
    # MajorScaleKind defines the major scale, the fundamental scale of Western
    # tonal music. It follows the pattern: W-W-H-W-W-W-H (whole-half steps)
    # or intervals: M2-M2-m2-M2-M2-M2-m2 from the root.
    #
    # ## Pitch Structure
    #
    # 7 diatonic degrees plus extended harmony (8th-13th):
    #
    # **Scale Degrees** (Roman numerals, uppercase for major):
    #
    # - **I** (tonic): Root (0 semitones)
    # - **II** (supertonic): Major second (2 semitones)
    # - **III** (mediant): Major third (4 semitones)
    # - **IV** (subdominant): Perfect fourth (5 semitones)
    # - **V** (dominant): Perfect fifth (7 semitones)
    # - **VI** (submediant): Major sixth (9 semitones, relative minor)
    # - **VII** (leading): Major seventh (11 semitones)
    #
    # **Extended degrees** (for extended harmony):
    #
    # - VIII-XIII: Compound intervals (8th, 9th, 10th, 11th, 12th, 13th)
    #
    # ## Function Aliases
    #
    # Each degree has multiple function names:
    #
    # - **Numeric**: _1, _2, _3, _4, _5, _6, _7 (ordinal)
    # - **Roman**: I, II, III, IV, V, VI, VII (harmonic analysis)
    # - **Function**: tonic, supertonic, mediant, subdominant, dominant,
    #                 submediant, leading
    # - **Ordinal**: first, second, third, fourth, fifth, sixth, seventh
    # - **Special**: relative/relative_minor for VI (relative minor root)
    #
    # ## Usage
    #
    #     c_major = Scales[:et12][440.0][:major][60]
    #     c_major.tonic      # C (60)
    #     c_major.dominant   # G (67)
    #     c_major.VI         # A (69) - relative minor root
    #     c_major.relative_minor.as_root_of(:minor)  # A minor scale
    #
    # @see ScaleKind Abstract base class
    # @see MinorNaturalScaleKind Natural minor scale
    # @see ChromaticScaleKind Chromatic scale
    class MajorScaleKind < ScaleKind
      @base_metadata = {
        family: :diatonic,
        brightness: 0,
        character: [:bright, :stable, :resolved],
        parent: nil
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
             { functions: %i[VI _6 submediant relative relative_minor sixth],
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
               pitch: 12 + 5 },
             { functions: %i[XII _12 twelfth],
               pitch: 12 + 7 },
             { functions: %i[XIII _13 thirteenth],
               pitch: 12 + 9 }].freeze

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
        # @return [Symbol] :major
        def id
          :major
        end
      end

      EquallyTempered12ToneScaleSystem.register MajorScaleKind
    end
  end
end
