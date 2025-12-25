# frozen_string_literal: true

module Musa
  module Scales
    # Locrian mode (seventh mode of major scale).
    #
    # LocrianScaleKind defines the Locrian mode, a diminished mode with a
    # characteristic lowered second and fifth degrees. It's built on the
    # seventh degree of the major scale and has an unstable, dissonant quality.
    #
    # ## Pitch Structure
    #
    # 7 diatonic degrees plus extended harmony (8th-13th):
    #
    # **Scale Degrees** (Roman numerals, lowercase for diminished):
    #
    # - **i** (tonic): Root (0 semitones)
    # - **ii** (supertonic): **Minor second** (1 semitone) ← CHARACTERISTIC
    # - **iii** (mediant): Minor third (3 semitones)
    # - **iv** (subdominant): Perfect fourth (5 semitones)
    # - **v** (dominant): **Diminished fifth** (6 semitones) ← CHARACTERISTIC
    # - **vi** (submediant): Minor sixth (8 semitones)
    # - **vii** (subtonic): Minor seventh (10 semitones)
    #
    # ## Key Differences from Natural Minor
    #
    # Two degrees are altered:
    # - **ii** lowered from 2 to 1 semitone (minor second)
    # - **v** lowered from 7 to 6 semitones (diminished fifth/tritone)
    #
    # This creates:
    # - A highly unstable, dissonant quality
    # - No stable perfect fifth above the tonic
    # - Rarely used as a tonal center
    #
    # ## Musical Character
    #
    # The Locrian mode:
    #
    # - Has diminished quality (minor third + diminished fifth)
    # - The most unstable of the seven modes
    # - Used sparingly, often for tension or dissonance
    # - Common over half-diminished (m7b5) chords in jazz
    #
    # ## Usage
    #
    #     b_locrian = Scales[:et12][440.0][:locrian][71]
    #     b_locrian.tonic  # B (71)
    #     b_locrian.ii     # C (72) - minor second (characteristic)
    #     b_locrian.v      # F (77) - diminished fifth (characteristic)
    #
    # @see ScaleKind Abstract base class
    # @see MinorNaturalScaleKind Natural minor
    # @see PhrygianScaleKind Phrygian mode (also has minor 2nd)
    class LocrianScaleKind < ScaleKind
      @base_metadata = {
        family: :greek_modes,
        brightness: -3,
        character: [:unstable, :diminished, :tense],
        parent: { scale: :major, degree: 7 }
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
               pitch: 12 + 5 },
             { functions: %i[xii _12 twelfth],
               pitch: 12 + 6 },
             { functions: %i[xiii _13 thirteenth],
               pitch: 12 + 8 }].freeze

        # Pitch structure.
        # @return [Array<Hash>] pitch definitions with functions and offsets
        def pitches
          @@pitches
        end

        # Number of diatonic degrees.
        # @return [Integer] 7
        def grades
          7
        end

        # Scale kind identifier.
        # @return [Symbol] :locrian
        def id
          :locrian
        end
      end

      EquallyTempered12ToneScaleSystem.register LocrianScaleKind
    end
  end
end
