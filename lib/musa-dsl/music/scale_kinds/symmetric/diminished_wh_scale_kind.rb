# frozen_string_literal: true

module Musa
  module Scales
    # Diminished whole-half scale kind.
    #
    # DiminishedWHScaleKind defines the whole-half diminished scale (also called
    # dominant diminished), an eight-note symmetric scale alternating whole steps
    # and half steps. It's commonly used over dominant 7th chords with altered tensions.
    #
    # ## Pitch Structure
    #
    # 8 degrees plus extended:
    #
    # **Scale Degrees** (pattern: W-H-W-H-W-H-W-H):
    #
    # - **I** (_1): Root (0 semitones)
    # - **II** (_2): Major second (2 semitones)
    # - **III** (_3): Minor third (3 semitones)
    # - **IV** (_4): Perfect fourth (5 semitones)
    # - **V** (_5): Diminished fifth (6 semitones)
    # - **VI** (_6): Augmented fifth (8 semitones)
    # - **VII** (_7): Major sixth (9 semitones)
    # - **VIII** (_8): Major seventh (11 semitones)
    #
    # ## Symmetric Properties
    #
    # - Only 3 distinct diminished scales exist
    # - Repeats every minor third (3 semitones)
    # - Same notes as half-whole, but different starting point
    # - Contains natural 9, #9, #11, 13 over dominant chord
    #
    # ## Musical Character
    #
    # The whole-half diminished scale:
    #
    # - Used over dominant 7th chords (hence "dominant diminished")
    # - Provides b9, #9, #11, and natural 13 tensions
    # - Common in bebop and modern jazz
    # - Creates sophisticated altered dominant sound
    #
    # ## Usage
    #
    #     g_dom_dim = Scales[:et12][440.0][:diminished_wh][67]
    #     g_dom_dim[0].pitch  # G (67)
    #     g_dom_dim[1].pitch  # A (69)
    #
    # @see ScaleKind Abstract base class
    # @see DiminishedHWScaleKind Half-whole diminished
    # @see AlteredScaleKind Altered scale (another dominant scale)
    class DiminishedWHScaleKind < ScaleKind
      class << self
        @@pitches =
            [{ functions: %i[I _1 tonic first],
               pitch: 0 },
             { functions: %i[II _2 second],
               pitch: 2 },
             { functions: %i[III _3 third],
               pitch: 3 },
             { functions: %i[IV _4 fourth],
               pitch: 5 },
             { functions: %i[V _5 fifth],
               pitch: 6 },
             { functions: %i[VI _6 sixth],
               pitch: 8 },
             { functions: %i[VII _7 seventh],
               pitch: 9 },
             { functions: %i[VIII _8 eighth],
               pitch: 11 },
             { functions: %i[IX _9 ninth],
               pitch: 12 },
             { functions: %i[X _10 tenth],
               pitch: 12 + 2 },
             { functions: %i[XI _11 eleventh],
               pitch: 12 + 3 },
             { functions: %i[XII _12 twelfth],
               pitch: 12 + 5 },
             { functions: %i[XIII _13 thirteenth],
               pitch: 12 + 6 },
             { functions: %i[XIV _14 fourteenth],
               pitch: 12 + 8 },
             { functions: %i[XV _15 fifteenth],
               pitch: 12 + 9 },
             { functions: %i[XVI _16 sixteenth],
               pitch: 12 + 11 }].freeze

        def pitches
          @@pitches
        end

        def grades
          8
        end

        def id
          :diminished_wh
        end
      end

      EquallyTempered12ToneScaleSystem.register DiminishedWHScaleKind
    end
  end
end
