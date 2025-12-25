# frozen_string_literal: true

module Musa
  module Scales
    # Locrian #2 scale kind (sixth mode of melodic minor).
    #
    # LocrianSharp2ScaleKind defines the Locrian #2 scale (also called
    # Aeolian b5 or Half-Diminished scale), the sixth mode of the
    # melodic minor scale. It's the primary scale for half-diminished chords.
    #
    # ## Pitch Structure
    #
    # 7 diatonic degrees plus extended harmony:
    #
    # **Scale Degrees** (lowercase for diminished quality):
    #
    # - **i** (tonic): Root (0 semitones)
    # - **ii** (supertonic): Major second (2 semitones) ← #2 vs Locrian
    # - **iii** (mediant): Minor third (3 semitones)
    # - **iv** (subdominant): Perfect fourth (5 semitones)
    # - **v** (dominant): Diminished fifth (6 semitones) ← DIMINISHED
    # - **vi** (submediant): Minor sixth (8 semitones)
    # - **vii** (subtonic): Minor seventh (10 semitones)
    #
    # ## Relationship to Other Modes
    #
    # - Locrian with raised 2nd (natural 9)
    # - Aeolian with lowered 5th
    # - 6th mode of melodic minor
    #
    # ## Musical Character
    #
    # The Locrian #2 scale:
    #
    # - Primary scale for m7b5 (half-diminished) chords
    # - More usable than pure Locrian (has natural 9)
    # - Essential in jazz ii-V-I in minor keys
    # - Dark but functional
    #
    # ## Usage
    #
    #     a_loc2 = Scales[:et12][440.0][:locrian_sharp2][69]
    #     a_loc2.tonic  # A (69)
    #     a_loc2.ii     # B (71) - major second (raised)
    #     a_loc2.v      # Eb (75) - diminished fifth
    #
    # @see ScaleKind Abstract base class
    # @see LocrianScaleKind Locrian mode (with minor 2nd)
    # @see MelodicMinorScaleKind Parent melodic minor scale
    class LocrianSharp2ScaleKind < ScaleKind
      @base_metadata = {
        family: :melodic_minor_modes,
        brightness: -2,
        character: [:half_diminished, :jazz],
        parent: { scale: :minor_melodic, degree: 6 }
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
               pitch: 6 },
             { functions: %i[vi _6 submediant sixth],
               pitch: 8 },
             { functions: %i[vii _7 subtonic seventh],
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
          :locrian_sharp2
        end
      end

      EquallyTempered12ToneScaleSystem.register LocrianSharp2ScaleKind
    end
  end
end
