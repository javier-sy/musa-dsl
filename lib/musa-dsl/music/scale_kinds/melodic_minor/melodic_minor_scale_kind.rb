# frozen_string_literal: true

module Musa
  module Scales
    # Melodic minor scale kind (ascending form).
    #
    # MelodicMinorScaleKind defines the melodic minor scale in its ascending
    # form (also called jazz minor). It has a minor third but major sixth and
    # seventh, creating a unique hybrid between minor and major qualities.
    #
    # ## Pitch Structure
    #
    # 7 diatonic degrees plus extended harmony:
    #
    # **Scale Degrees** (lowercase for minor quality):
    #
    # - **i** (tonic): Root (0 semitones)
    # - **ii** (supertonic): Major second (2 semitones)
    # - **iii** (mediant): Minor third (3 semitones) ← MINOR
    # - **iv** (subdominant): Perfect fourth (5 semitones)
    # - **v** (dominant): Perfect fifth (7 semitones)
    # - **vi** (submediant): Major sixth (9 semitones) ← MAJOR
    # - **vii** (leading): Major seventh (11 semitones) ← MAJOR
    #
    # ## Relationship to Other Scales
    #
    # - Minor third (like natural minor)
    # - Major 6th and 7th (like major scale)
    # - Parent scale for many jazz modes (Lydian Dominant, Altered, etc.)
    #
    # ## Musical Character
    #
    # The melodic minor scale:
    #
    # - Minor quality with major upper structure
    # - Essential in jazz harmony
    # - Less dark than harmonic minor (no augmented 2nd)
    # - Smooth melodic contour
    #
    # ## Usage
    #
    #     c_mel_min = Scales[:et12][440.0][:minor_melodic][60]
    #     c_mel_min.tonic    # C (60)
    #     c_mel_min.mediant  # Eb (63) - minor third
    #     c_mel_min.leading  # B (71) - major seventh
    #
    # @see ScaleKind Abstract base class
    # @see MinorNaturalScaleKind Natural minor
    # @see MinorHarmonicScaleKind Harmonic minor
    # @see AlteredScaleKind Altered scale (7th mode of melodic minor)
    class MelodicMinorScaleKind < ScaleKind
      @base_metadata = {
        family: :melodic_minor_modes,
        brightness: -1,
        character: [:minor, :ascending, :classical],
        parent: nil
      }.freeze

      class << self
        @@pitches =
            [{ functions: %i[i _1 tonic first],
               pitch: 0 },
             { functions: %i[ii _2 supertonic second],
               pitch: 2 },
             { functions: %i[iii _3 mediant third],
               pitch: 3 },
             { functions: %i[iv _4 subdominant fourth],
               pitch: 5 },
             { functions: %i[v _5 dominant fifth],
               pitch: 7 },
             { functions: %i[vi _6 submediant sixth],
               pitch: 9 },
             { functions: %i[vii _7 leading seventh],
               pitch: 11 },
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
               pitch: 12 + 9 }].freeze

        def pitches
          @@pitches
        end

        def grades
          7
        end

        def id
          :minor_melodic
        end
      end

      EquallyTempered12ToneScaleSystem.register MelodicMinorScaleKind
    end
  end
end
