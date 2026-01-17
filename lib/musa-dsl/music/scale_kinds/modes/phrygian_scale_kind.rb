# frozen_string_literal: true

module Musa
  module Scales
    # Phrygian mode (third mode of major scale).
    #
    # PhrygianScaleKind defines the Phrygian mode, a minor mode with a characteristic
    # lowered second degree. It's built on the third degree of the major scale
    # and has a dark, exotic, Spanish/Middle Eastern quality.
    #
    # ## Pitch Structure
    #
    # 7 diatonic degrees plus extended harmony (8th-13th):
    #
    # **Scale Degrees** (Roman numerals, lowercase for minor):
    #
    # - **i** (tonic): Root (0 semitones)
    # - **ii** (supertonic): **Minor second** (1 semitone) ← CHARACTERISTIC
    # - **iii** (mediant): Minor third (3 semitones)
    # - **iv** (subdominant): Perfect fourth (5 semitones)
    # - **v** (dominant): Perfect fifth (7 semitones)
    # - **vi** (submediant): Minor sixth (8 semitones)
    # - **vii** (subtonic): Minor seventh (10 semitones)
    #
    # ## Key Difference from Natural Minor
    #
    # The **ii** degree is lowered from 2 semitones (major second) to
    # 1 semitone (minor second), creating:
    #
    # - A dark, exotic quality
    # - The characteristic "Phrygian color"
    # - Strong association with Spanish/Flamenco music
    #
    # ## Musical Character
    #
    # The Phrygian mode:
    #
    # - Maintains minor quality (minor third)
    # - Has a lowered 2nd that creates tension
    # - Common in flamenco, metal, and Middle Eastern music
    # - The half-step from ii to i creates strong resolution
    #
    # ## Usage
    #
    #     e_phrygian = Scales[:et12][440.0][:phrygian][64]
    #     e_phrygian.tonic  # E (64)
    #     e_phrygian.ii     # F (65) - minor second (characteristic)
    #
    # @see ScaleKind Abstract base class
    # @see MinorNaturalScaleKind Natural minor (with major 2nd)
    # @see DorianScaleKind Dorian mode
    class PhrygianScaleKind < ScaleKind
      @base_metadata = {
        family: :greek_modes,
        brightness: -2,
        character: [:dark, :spanish, :exotic],
        parent: { scale: :major, degree: 3 }
      }.freeze

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
             { functions: %i[vii _7 subtonic seventh],
               pitch: 10 },
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
        # @return [Symbol] :phrygian
        def id
          :phrygian
        end
      end

      EquallyTempered12ToneScaleSystem.register PhrygianScaleKind
    end
  end
end
