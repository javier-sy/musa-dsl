# frozen_string_literal: true

module Musa
  module Scales
    # Diminished half-whole scale kind.
    #
    # DiminishedHWScaleKind defines the half-whole diminished scale (also called
    # octatonic scale), an eight-note symmetric scale alternating half steps and
    # whole steps. It's commonly used over diminished 7th chords.
    #
    # ## Pitch Structure
    #
    # 8 degrees plus extended:
    #
    # **Scale Degrees** (pattern: H-W-H-W-H-W-H-W):
    #
    # - **i** (_1): Root (0 semitones)
    # - **ii** (_2): Minor second (1 semitone)
    # - **iii** (_3): Minor third (3 semitones)
    # - **iv** (_4): Major third (4 semitones)
    # - **v** (_5): Diminished fifth (6 semitones)
    # - **vi** (_6): Perfect fifth (7 semitones)
    # - **vii** (_7): Major sixth (9 semitones)
    # - **viii** (_8): Minor seventh (10 semitones)
    #
    # ## Symmetric Properties
    #
    # - Only 3 distinct diminished scales exist
    # - Repeats every minor third (3 semitones)
    # - Contains 4 minor thirds, 4 major thirds, 2 tritones
    # - Every diminished 7th chord is contained within
    #
    # ## Musical Character
    #
    # The half-whole diminished scale:
    #
    # - Tense, dark, unstable quality
    # - Used over diminished 7th chords
    # - Common in jazz, film scores, classical
    # - Creates strong chromatic tension
    #
    # ## Usage
    #
    #     c_dim = Scales[:et12][440.0][:diminished_hw][60]
    #     c_dim[0].pitch  # C (60)
    #     c_dim[1].pitch  # Db (61)
    #
    # @see ScaleKind Abstract base class
    # @see DiminishedWHScaleKind Whole-half diminished (dominant diminished)
    # @see WholeToneScaleKind Whole tone scale
    class DiminishedHWScaleKind < ScaleKind
      class << self
        @@pitches =
            [{ functions: %i[i _1 tonic first],
               pitch: 0 },
             { functions: %i[ii _2 second],
               pitch: 1 },
             { functions: %i[iii _3 third],
               pitch: 3 },
             { functions: %i[iv _4 fourth],
               pitch: 4 },
             { functions: %i[v _5 fifth],
               pitch: 6 },
             { functions: %i[vi _6 sixth],
               pitch: 7 },
             { functions: %i[vii _7 seventh],
               pitch: 9 },
             { functions: %i[viii _8 eighth],
               pitch: 10 },
             { functions: %i[ix _9 ninth],
               pitch: 12 },
             { functions: %i[x _10 tenth],
               pitch: 12 + 1 },
             { functions: %i[xi _11 eleventh],
               pitch: 12 + 3 },
             { functions: %i[xii _12 twelfth],
               pitch: 12 + 4 },
             { functions: %i[xiii _13 thirteenth],
               pitch: 12 + 6 },
             { functions: %i[xiv _14 fourteenth],
               pitch: 12 + 7 },
             { functions: %i[xv _15 fifteenth],
               pitch: 12 + 9 },
             { functions: %i[xvi _16 sixteenth],
               pitch: 12 + 10 }].freeze

        def pitches
          @@pitches
        end

        def grades
          8
        end

        def id
          :diminished_hw
        end
      end

      EquallyTempered12ToneScaleSystem.register DiminishedHWScaleKind
    end
  end
end
