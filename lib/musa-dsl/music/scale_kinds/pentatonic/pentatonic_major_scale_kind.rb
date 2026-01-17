# frozen_string_literal: true

module Musa
  module Scales
    # Major pentatonic scale kind.
    #
    # PentatonicMajorScaleKind defines the major pentatonic scale, a five-note
    # scale derived from the major scale by omitting the 4th and 7th degrees.
    # It has a bright, open sound and is extremely common in folk, rock, and blues.
    #
    # ## Pitch Structure
    #
    # 5 diatonic degrees plus extended (6th-10th):
    #
    # **Scale Degrees** (Roman numerals, uppercase for major):
    #
    # - **I** (tonic): Root (0 semitones)
    # - **II** (supertonic): Major second (2 semitones)
    # - **III** (mediant): Major third (4 semitones)
    # - **V** (dominant): Perfect fifth (7 semitones)
    # - **VI** (submediant): Major sixth (9 semitones)
    #
    # ## Relationship to Major Scale
    #
    # Major pentatonic = Major scale minus 4th and 7th degrees.
    # This removes all semitone intervals, creating a scale with no dissonance.
    #
    # ## Musical Character
    #
    # The major pentatonic:
    #
    # - Has a bright, happy, open quality
    # - No semitones = no tension or dissonance
    # - Universal across cultures (found in music worldwide)
    # - Common in folk, country, rock, pop, and blues
    #
    # ## Usage
    #
    #     c_pent = Scales[:et12][440.0][:pentatonic_major][60]
    #     c_pent.tonic     # C (60)
    #     c_pent.dominant  # G (67)
    #
    # @see ScaleKind Abstract base class
    # @see MajorScaleKind Major scale
    # @see PentatonicMinorScaleKind Minor pentatonic
    class PentatonicMajorScaleKind < ScaleKind
      @base_metadata = {
        family: :pentatonic,
        brightness: 1,
        character: [:bright, :simple, :folk],
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
             { functions: %i[V _4 dominant fourth],
               pitch: 7 },
             { functions: %i[VI _5 submediant fifth],
               pitch: 9 },
             { functions: %i[VIII _6 sixth],
               pitch: 12 },
             { functions: %i[IX _7 seventh],
               pitch: 12 + 2 },
             { functions: %i[X _8 eighth],
               pitch: 12 + 4 },
             { functions: %i[XII _9 ninth],
               pitch: 12 + 7 },
             { functions: %i[XIII _10 tenth],
               pitch: 12 + 9 }].freeze

        def pitches
          @@pitches
        end

        def grades
          5
        end

        def id
          :pentatonic_major
        end
      end

      EquallyTempered12ToneScaleSystem.register PentatonicMajorScaleKind
    end
  end
end
