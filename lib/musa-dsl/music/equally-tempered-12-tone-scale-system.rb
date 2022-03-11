require_relative 'scales'

module Musa
  module Scales
    class TwelveSemitonesScaleSystem < ScaleSystem
      class << self
        @@intervals = { P0: 0, m2: 1, M2: 2, m3: 3, M3: 4, P4: 5, TT: 6, P5: 7, m6: 8, M6: 9, m7: 10, M7: 11, P8: 12 }

        def id
          :et12
        end

        def notes_in_octave
          12
        end

        def part_of_tone_size
          1
        end

        def intervals
          @@intervals
        end
      end
    end

    class EquallyTempered12ToneScaleSystem < TwelveSemitonesScaleSystem
      class << self
        def frequency_of_pitch(pitch, _root_pitch, a_frequency)
          (a_frequency * Rational(2)**Rational(pitch - 69, 12)).to_f
        end
      end

      Scales.register EquallyTempered12ToneScaleSystem, default: true
    end


    class ChromaticScaleKind < ScaleKind
      class << self
        @@pitches =
            [{ functions: [:_1], pitch: 0 },
             { functions: [:_2], pitch: 1 },
             { functions: [:_3], pitch: 2 },
             { functions: [:_4], pitch: 3 },
             { functions: [:_5], pitch: 4 },
             { functions: [:_6], pitch: 5 },
             { functions: [:_7], pitch: 6 },
             { functions: [:_8], pitch: 7 },
             { functions: [:_9], pitch: 8 },
             { functions: [:_10], pitch: 9 },
             { functions: [:_11], pitch: 10 },
             { functions: [:_12], pitch: 11 }].freeze

        def pitches
          @@pitches
        end

        def id
          :chromatic
        end

        def chromatic?
          true
        end
      end

      EquallyTempered12ToneScaleSystem.register ChromaticScaleKind
    end

    class MajorScaleKind < ScaleKind
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

        def pitches
          @@pitches
        end

        def grades
          7
        end

        def id
          :major
        end
      end

      EquallyTempered12ToneScaleSystem.register MajorScaleKind
    end

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

        def pitches
          @@pitches
        end

        def grades
          7
        end

        def id
          :minor
        end
      end

      EquallyTempered12ToneScaleSystem.register MinorNaturalScaleKind
    end

    class MinorHarmonicScaleKind < ScaleKind
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

        def pitches
          @@pitches
        end

        def grades
          7
        end

        def id
          :minor_harmonic
        end
      end

      EquallyTempered12ToneScaleSystem.register MinorHarmonicScaleKind
    end
  end
end
