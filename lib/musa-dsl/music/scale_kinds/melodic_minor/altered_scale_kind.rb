# frozen_string_literal: true

module Musa
  module Scales
    # Altered scale kind (seventh mode of melodic minor).
    #
    # AlteredScaleKind defines the Altered scale (also called Super Locrian,
    # Diminished Whole Tone, or Altered Dominant), the seventh mode of the
    # melodic minor scale. It's the quintessential scale for altered dominant
    # chords in jazz.
    #
    # ## Pitch Structure
    #
    # 7 diatonic degrees plus extended harmony:
    #
    # **Scale Degrees** (lowercase for diminished quality):
    #
    # - **i** (tonic): Root (0 semitones)
    # - **ii** (supertonic): Minor second (1 semitone) ← b9
    # - **iii** (mediant): Minor third (3 semitones) ← #9 (enharmonic)
    # - **iv** (subdominant): Major third (4 semitones) ← b11 (3rd of chord)
    # - **v** (dominant): Diminished fifth (6 semitones) ← b5/#11
    # - **vi** (submediant): Minor sixth (8 semitones) ← #5/b13
    # - **vii** (subtonic): Minor seventh (10 semitones) ← b7
    #
    # ## All Alterations Present
    #
    # Contains all possible alterations of a dominant chord:
    # - b9, #9 (altered 9ths)
    # - #11/b5 (altered 11th/5th)
    # - b13/#5 (altered 13th/5th)
    #
    # ## Musical Character
    #
    # The Altered scale:
    #
    # - Maximum tension for dominant chords
    # - Used over 7alt, 7#9, 7b9#11, etc.
    # - Essential in bebop and modern jazz
    # - Creates strong resolution to tonic
    #
    # ## Usage
    #
    #     g_alt = Scales[:et12][440.0][:altered][67]
    #     g_alt.tonic  # G (67)
    #     g_alt.ii     # Ab (68) - b9
    #     g_alt.iii    # Bb (70) - #9
    #     g_alt.v      # Db (73) - b5
    #
    # @see ScaleKind Abstract base class
    # @see MelodicMinorScaleKind Parent melodic minor scale
    # @see DiminishedWHScaleKind Another altered dominant scale option
    class AlteredScaleKind < ScaleKind
      @base_metadata = {
        family: :melodic_minor_modes,
        brightness: -3,
        character: [:altered_dominant, :jazz, :tension],
        parent: { scale: :minor_melodic, degree: 7 }
      }.freeze

      class << self
        @@pitches =
            [{ functions: %i[i _1 tonic first],
               pitch: 0 },
             { functions: %i[ii _2 supertonic second],
               pitch: 1 },
             { functions: %i[iii _3 mediant third],
               pitch: 3 },
             { functions: %i[iv _4 subdominant fourth],
               pitch: 4 },
             { functions: %i[v _5 dominant fifth],
               pitch: 6 },
             { functions: %i[vi _6 submediant sixth],
               pitch: 8 },
             { functions: %i[vii _7 subtonic seventh],
               pitch: 10 },
             { functions: %i[viii _8 eighth],
               pitch: 12 },
             { functions: %i[ix _9 ninth],
               pitch: 12 + 1 },
             { functions: %i[x _10 tenth],
               pitch: 12 + 3 },
             { functions: %i[xi _11 eleventh],
               pitch: 12 + 4 },
             { functions: %i[xii _12 twelfth],
               pitch: 12 + 6 },
             { functions: %i[xiii _13 thirteenth],
               pitch: 12 + 8 }].freeze

        def pitches
          @@pitches
        end

        def grades
          7
        end

        def id
          :altered
        end
      end

      EquallyTempered12ToneScaleSystem.register AlteredScaleKind
    end
  end
end
