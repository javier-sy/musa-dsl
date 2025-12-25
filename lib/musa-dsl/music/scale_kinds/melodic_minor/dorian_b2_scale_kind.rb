# frozen_string_literal: true

module Musa
  module Scales
    # Dorian b2 scale kind (second mode of melodic minor).
    #
    # DorianB2ScaleKind defines the Dorian b2 scale (also called Phrygian #6
    # or Javanese scale), the second mode of the melodic minor scale.
    # It combines the Phrygian's lowered second with the Dorian's raised sixth.
    #
    # ## Pitch Structure
    #
    # 7 diatonic degrees plus extended harmony:
    #
    # **Scale Degrees** (lowercase for minor quality):
    #
    # - **i** (tonic): Root (0 semitones)
    # - **ii** (supertonic): Minor second (1 semitone) ← CHARACTERISTIC (b2)
    # - **iii** (mediant): Minor third (3 semitones)
    # - **iv** (subdominant): Perfect fourth (5 semitones)
    # - **v** (dominant): Perfect fifth (7 semitones)
    # - **vi** (submediant): Major sixth (9 semitones) ← CHARACTERISTIC (#6)
    # - **vii** (subtonic): Minor seventh (10 semitones)
    #
    # ## Relationship to Other Modes
    #
    # - Dorian with lowered 2nd
    # - Phrygian with raised 6th
    # - 2nd mode of melodic minor
    #
    # ## Musical Character
    #
    # The Dorian b2 scale:
    #
    # - Exotic, Eastern quality
    # - Minor with both Phrygian darkness and Dorian brightness
    # - Used over sus4(b9) chords in jazz
    # - Common in contemporary jazz and fusion
    #
    # ## Usage
    #
    #     d_dor_b2 = Scales[:et12][440.0][:dorian_b2][62]
    #     d_dor_b2.tonic  # D (62)
    #     d_dor_b2.ii     # Eb (63) - minor second
    #     d_dor_b2.vi     # B (71) - major sixth
    #
    # @see ScaleKind Abstract base class
    # @see DorianScaleKind Dorian mode
    # @see PhrygianScaleKind Phrygian mode
    # @see MelodicMinorScaleKind Parent melodic minor scale
    class DorianB2ScaleKind < ScaleKind
      @base_metadata = {
        family: :melodic_minor_modes,
        brightness: -2,
        character: [:exotic, :phrygian_dorian],
        parent: { scale: :minor_melodic, degree: 2 }
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
               pitch: 5 },
             { functions: %i[v _5 dominant fifth],
               pitch: 7 },
             { functions: %i[vi _6 submediant sixth],
               pitch: 9 },
             { functions: %i[vii _7 subtonic seventh],
               pitch: 10 },
             { functions: %i[viii _8 eighth],
               pitch: 12 },
             { functions: %i[ix _9 ninth],
               pitch: 12 + 1 },
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
          :dorian_b2
        end
      end

      EquallyTempered12ToneScaleSystem.register DorianB2ScaleKind
    end
  end
end
