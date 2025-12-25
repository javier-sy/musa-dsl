# frozen_string_literal: true

module Musa
  module Scales
    # Major blues scale kind.
    #
    # BluesMajorScaleKind defines the major blues scale, a six-note scale
    # that adds the "blue note" (b3) to the major pentatonic scale.
    # It provides a brighter blues sound than the minor blues scale.
    #
    # ## Pitch Structure
    #
    # 6 degrees plus extended:
    #
    # **Scale Degrees** (uppercase for major quality):
    #
    # - **I** (tonic): Root (0 semitones)
    # - **II** (supertonic): Major second (2 semitones)
    # - **blue** (blue note): Minor third (3 semitones) ← CHARACTERISTIC
    # - **III** (mediant): Major third (4 semitones)
    # - **V** (dominant): Perfect fifth (7 semitones)
    # - **VI** (submediant): Major sixth (9 semitones)
    #
    # ## The Blue Note
    #
    # The b3 (minor third) is the blue note in the major blues scale.
    # It creates tension that resolves up to the major third, providing
    # the characteristic "bend" sound in blues guitar and vocals.
    #
    # ## Musical Character
    #
    # The major blues scale:
    #
    # - Brighter alternative to minor blues
    # - Works well over major and dominant 7th chords
    # - Common in country blues and jazz
    # - The b3 to natural 3 movement is essential
    #
    # ## Usage
    #
    #     c_blues_maj = Scales[:et12][440.0][:blues_major][60]
    #     c_blues_maj.tonic    # C (60)
    #     c_blues_maj.blue     # Eb (63) - the blue note
    #     c_blues_maj.mediant  # E (64) - major third
    #
    # @see ScaleKind Abstract base class
    # @see PentatonicMajorScaleKind Major pentatonic (without blue note)
    # @see BluesScaleKind Minor blues scale
    class BluesMajorScaleKind < ScaleKind
      @base_metadata = {
        family: :blues,
        brightness: 0,
        character: [:bluesy, :gospel, :major],
        parent: nil
      }.freeze

      class << self
        @@pitches =
            [{ functions: %i[I _1 tonic first],
               pitch: 0 },
             { functions: %i[II _2 supertonic second],
               pitch: 2 },
             { functions: %i[blue _3 third],
               pitch: 3 },
             { functions: %i[III _4 mediant fourth],
               pitch: 4 },
             { functions: %i[V _5 dominant fifth],
               pitch: 7 },
             { functions: %i[VI _6 submediant sixth],
               pitch: 9 },
             { functions: %i[VIII _7 seventh],
               pitch: 12 },
             { functions: %i[IX _8 eighth],
               pitch: 12 + 2 },
             { functions: %i[blue2 _9 ninth],
               pitch: 12 + 3 },
             { functions: %i[X _10 tenth],
               pitch: 12 + 4 },
             { functions: %i[XII _11 eleventh],
               pitch: 12 + 7 },
             { functions: %i[XIII _12 twelfth],
               pitch: 12 + 9 }].freeze

        def pitches
          @@pitches
        end

        def grades
          6
        end

        def id
          :blues_major
        end
      end

      EquallyTempered12ToneScaleSystem.register BluesMajorScaleKind
    end
  end
end
