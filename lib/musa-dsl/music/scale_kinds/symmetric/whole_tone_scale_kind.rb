# frozen_string_literal: true

module Musa
  module Scales
    # Whole tone scale kind.
    #
    # WholeToneScaleKind defines the whole tone scale, a six-note symmetric
    # scale where every interval is a whole step (major second). It has a
    # dreamy, ambiguous quality with no clear tonal center.
    #
    # ## Pitch Structure
    #
    # 6 degrees plus extended:
    #
    # **Scale Degrees**:
    #
    # - **I** (_1): Root (0 semitones)
    # - **II** (_2): Major second (2 semitones)
    # - **III** (_3): Major third (4 semitones)
    # - **IV#** (_4): Augmented fourth (6 semitones)
    # - **V#** (_5): Augmented fifth (8 semitones)
    # - **VII** (_6): Minor seventh (10 semitones)
    #
    # ## Symmetric Properties
    #
    # - Only 2 distinct whole tone scales exist (C and C#)
    # - Every note can function as the root
    # - Divides the octave into 6 equal parts
    # - No perfect fifths = no strong harmonic function
    #
    # ## Musical Character
    #
    # The whole tone scale:
    #
    # - Dreamy, floating, ambiguous quality
    # - No leading tones or tendency tones
    # - Associated with impressionism (Debussy)
    # - Used over augmented and dominant 7#5 chords
    #
    # ## Usage
    #
    #     c_whole = Scales[:et12][440.0][:whole_tone][60]
    #     c_whole[0].pitch  # C (60)
    #     c_whole[3].pitch  # F# (66)
    #
    # @see ScaleKind Abstract base class
    # @see DiminishedHWScaleKind Diminished scale (another symmetric scale)
    class WholeToneScaleKind < ScaleKind
      class << self
        @@pitches =
            [{ functions: %i[I _1 tonic first],
               pitch: 0 },
             { functions: %i[II _2 second],
               pitch: 2 },
             { functions: %i[III _3 third],
               pitch: 4 },
             { functions: %i[IV _4 fourth],
               pitch: 6 },
             { functions: %i[V _5 fifth],
               pitch: 8 },
             { functions: %i[VI _6 sixth],
               pitch: 10 },
             { functions: %i[VII _7 seventh],
               pitch: 12 },
             { functions: %i[VIII _8 eighth],
               pitch: 12 + 2 },
             { functions: %i[IX _9 ninth],
               pitch: 12 + 4 },
             { functions: %i[X _10 tenth],
               pitch: 12 + 6 },
             { functions: %i[XI _11 eleventh],
               pitch: 12 + 8 },
             { functions: %i[XII _12 twelfth],
               pitch: 12 + 10 }].freeze

        def pitches
          @@pitches
        end

        def grades
          6
        end

        def id
          :whole_tone
        end
      end

      EquallyTempered12ToneScaleSystem.register WholeToneScaleKind
    end
  end
end
