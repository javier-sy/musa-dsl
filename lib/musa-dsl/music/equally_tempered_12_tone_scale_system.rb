module Musa
  class EquallyTempered12ToneScaleSystem < ScaleSystem
    class << self
      def id
        :et12
      end

      def notes_in_octave
        12
      end
    end

    Scales.register EquallyTempered12ToneScaleSystem
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

      def full_canonical?
        true
      end
    end

    EquallyTempered12ToneScaleSystem.register ChromaticScaleKind
  end

  class MajorScaleKind < ScaleKind
    class << self
      @@pitches =
        [{ functions: %i[I _1 tonic],
           pitch: 0 },
         { functions: %i[II _2 supertonic],
           pitch: 2 },
         { functions: %i[III _3 mediant],
           pitch: 4 },
         { functions: %i[IV _4 subdominant],
           pitch: 5 },
         { functions: %i[V _5 dominant],
           pitch: 7 },
         { functions: %i[VI _6 submediant relative relative_minor],
           pitch: 9 },
         { functions: %i[VII _7 leading],
           pitch: 11 }].freeze

      def pitches
        @@pitches
      end

      def id
        :major
      end
    end

    EquallyTempered12ToneScaleSystem.register MajorScaleKind
  end

  class MinorScaleKind < ScaleKind
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
         { functions: %i[vii _7],
           pitch: 10 }].freeze

      def pitches
        @@pitches
      end

      def id
        :minor
      end
    end

    EquallyTempered12ToneScaleSystem.register MinorScaleKind
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
           pitch: 11 }].freeze

      def pitches
        @@pitches
      end

      def id
        :minor_harmonic
      end
    end

    EquallyTempered12ToneScaleSystem.register MinorHarmonicScaleKind
  end
end
