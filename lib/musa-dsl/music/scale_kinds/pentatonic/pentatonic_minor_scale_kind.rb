# frozen_string_literal: true

module Musa
  module Scales
    # Minor pentatonic scale kind.
    #
    # PentatonicMinorScaleKind defines the minor pentatonic scale, a five-note
    # scale derived from the natural minor scale by omitting the 2nd and 6th degrees.
    # It's the foundation of blues and rock improvisation.
    #
    # ## Pitch Structure
    #
    # 5 diatonic degrees plus extended (6th-10th):
    #
    # **Scale Degrees** (Roman numerals, lowercase for minor):
    #
    # - **i** (tonic): Root (0 semitones)
    # - **iii** (mediant): Minor third (3 semitones)
    # - **iv** (subdominant): Perfect fourth (5 semitones)
    # - **v** (dominant): Perfect fifth (7 semitones)
    # - **vii** (subtonic): Minor seventh (10 semitones)
    #
    # ## Relationship to Natural Minor
    #
    # Minor pentatonic = Natural minor minus 2nd and 6th degrees.
    # This removes all semitone intervals, creating a scale with no dissonance.
    #
    # ## Relative Major Pentatonic
    #
    # A minor pentatonic shares the same notes as C major pentatonic.
    # They are relative scales.
    #
    # ## Musical Character
    #
    # The minor pentatonic:
    #
    # - Has a bluesy, soulful quality
    # - Foundation of blues and rock guitar solos
    # - Works over both minor and dominant 7th chords
    # - Easy to improvise with (no "wrong" notes)
    #
    # ## Usage
    #
    #     a_pent = Scales[:et12][440.0][:pentatonic_minor][69]
    #     a_pent.tonic     # A (69)
    #     a_pent.dominant  # E (76)
    #
    # @see ScaleKind Abstract base class
    # @see MinorNaturalScaleKind Natural minor scale
    # @see PentatonicMajorScaleKind Major pentatonic
    # @see BluesScaleKind Blues scale (pentatonic + blue note)
    class PentatonicMinorScaleKind < ScaleKind
      class << self
        @@pitches =
            [{ functions: %i[i _1 tonic first],
               pitch: 0 },
             { functions: %i[iii _2 mediant second],
               pitch: 3 },
             { functions: %i[iv _3 subdominant third],
               pitch: 5 },
             { functions: %i[v _4 dominant fourth],
               pitch: 7 },
             { functions: %i[vii _5 subtonic fifth],
               pitch: 10 },
             { functions: %i[viii _6 sixth],
               pitch: 12 },
             { functions: %i[x _7 seventh],
               pitch: 12 + 3 },
             { functions: %i[xi _8 eighth],
               pitch: 12 + 5 },
             { functions: %i[xii _9 ninth],
               pitch: 12 + 7 },
             { functions: %i[xiv _10 tenth],
               pitch: 12 + 10 }].freeze

        def pitches
          @@pitches
        end

        def grades
          5
        end

        def id
          :pentatonic_minor
        end
      end

      EquallyTempered12ToneScaleSystem.register PentatonicMinorScaleKind
    end
  end
end
