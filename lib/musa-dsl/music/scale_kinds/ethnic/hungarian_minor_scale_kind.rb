# frozen_string_literal: true

module Musa
  module Scales
    # Hungarian minor scale kind.
    #
    # HungarianMinorScaleKind defines the Hungarian minor scale (also called
    # Gypsy minor or Double Harmonic Minor), a minor scale with two
    # augmented seconds creating an exotic, Eastern European sound.
    #
    # ## Pitch Structure
    #
    # 7 diatonic degrees plus extended harmony:
    #
    # **Scale Degrees** (lowercase for minor quality):
    #
    # - **i** (tonic): Root (0 semitones)
    # - **ii** (supertonic): Major second (2 semitones)
    # - **iii** (mediant): Minor third (3 semitones)
    # - **iv** (subdominant): Augmented fourth (6 semitones) ← CHARACTERISTIC (#4)
    # - **v** (dominant): Perfect fifth (7 semitones)
    # - **vi** (submediant): Minor sixth (8 semitones)
    # - **vii** (leading): Major seventh (11 semitones)
    #
    # ## Two Augmented Seconds
    #
    # - Between III and IV (b3 to #4): 3 semitones
    # - Between VI and VII (b6 to 7): 3 semitones
    #
    # ## Musical Character
    #
    # The Hungarian minor scale:
    #
    # - Dramatic, passionate, exotic
    # - Common in Hungarian and Romani music
    # - Used by Liszt, Brahms, and other Romantic composers
    # - Creates a distinctive "gypsy" sound
    #
    # ## Usage
    #
    #     a_hung_min = Scales[:et12][440.0][:hungarian_minor][69]
    #     a_hung_min.tonic  # A (69)
    #     a_hung_min.iv     # D# (75) - augmented fourth
    #     a_hung_min.vii    # G# (80) - major seventh
    #
    # @see ScaleKind Abstract base class
    # @see MinorHarmonicScaleKind Harmonic minor (one augmented second)
    # @see DoubleHarmonicScaleKind Double harmonic (Byzantine)
    class HungarianMinorScaleKind < ScaleKind
      class << self
        @@pitches =
            [{ functions: %i[i _1 tonic first],
               pitch: 0 },
             { functions: %i[ii _2 supertonic second],
               pitch: 2 },
             { functions: %i[iii _3 mediant third],
               pitch: 3 },
             { functions: %i[iv _4 subdominant fourth],
               pitch: 6 },
             { functions: %i[v _5 dominant fifth],
               pitch: 7 },
             { functions: %i[vi _6 submediant sixth],
               pitch: 8 },
             { functions: %i[vii _7 leading seventh],
               pitch: 11 },
             { functions: %i[viii _8 eighth],
               pitch: 12 },
             { functions: %i[ix _9 ninth],
               pitch: 12 + 2 },
             { functions: %i[x _10 tenth],
               pitch: 12 + 3 },
             { functions: %i[xi _11 eleventh],
               pitch: 12 + 6 },
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
          :hungarian_minor
        end
      end

      EquallyTempered12ToneScaleSystem.register HungarianMinorScaleKind
    end
  end
end
