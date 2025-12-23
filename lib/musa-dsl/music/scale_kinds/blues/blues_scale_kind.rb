# frozen_string_literal: true

module Musa
  module Scales
    # Blues scale kind (minor blues).
    #
    # BluesScaleKind defines the blues scale, a six-note scale that adds
    # the "blue note" (b5) to the minor pentatonic scale. This is the
    # quintessential scale for blues, rock, and jazz improvisation.
    #
    # ## Pitch Structure
    #
    # 6 degrees plus extended:
    #
    # **Scale Degrees** (lowercase for minor quality):
    #
    # - **i** (tonic): Root (0 semitones)
    # - **iii** (mediant): Minor third (3 semitones)
    # - **iv** (subdominant): Perfect fourth (5 semitones)
    # - **blue** (blue note): Diminished fifth (6 semitones) ← CHARACTERISTIC
    # - **v** (dominant): Perfect fifth (7 semitones)
    # - **vii** (subtonic): Minor seventh (10 semitones)
    #
    # ## The Blue Note
    #
    # The b5 (diminished fifth) is the defining characteristic of the blues
    # scale. It creates tension that resolves either up to the 5th or down
    # to the 4th, giving the scale its distinctive "bluesy" sound.
    #
    # ## Musical Character
    #
    # The blues scale:
    #
    # - Foundation of blues improvisation
    # - Works over minor, dominant 7th, and even major chords
    # - The blue note adds expressive tension
    # - Common in blues, rock, jazz, and funk
    #
    # ## Usage
    #
    #     a_blues = Scales[:et12][440.0][:blues][69]
    #     a_blues.tonic  # A (69)
    #     a_blues.blue   # Eb (75) - the blue note
    #
    # @see ScaleKind Abstract base class
    # @see PentatonicMinorScaleKind Minor pentatonic (without blue note)
    # @see BluesMajorScaleKind Major blues scale
    class BluesScaleKind < ScaleKind
      class << self
        @@pitches =
            [{ functions: %i[i _1 tonic first],
               pitch: 0 },
             { functions: %i[iii _2 mediant second],
               pitch: 3 },
             { functions: %i[iv _3 subdominant third],
               pitch: 5 },
             { functions: %i[blue _4 fourth],
               pitch: 6 },
             { functions: %i[v _5 dominant fifth],
               pitch: 7 },
             { functions: %i[vii _6 subtonic sixth],
               pitch: 10 },
             { functions: %i[viii _7 seventh],
               pitch: 12 },
             { functions: %i[x _8 eighth],
               pitch: 12 + 3 },
             { functions: %i[xi _9 ninth],
               pitch: 12 + 5 },
             { functions: %i[blue2 _10 tenth],
               pitch: 12 + 6 },
             { functions: %i[xii _11 eleventh],
               pitch: 12 + 7 },
             { functions: %i[xiv _12 twelfth],
               pitch: 12 + 10 }].freeze

        def pitches
          @@pitches
        end

        def grades
          6
        end

        def id
          :blues
        end
      end

      EquallyTempered12ToneScaleSystem.register BluesScaleKind
    end
  end
end
