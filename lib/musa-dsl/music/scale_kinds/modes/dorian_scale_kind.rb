# frozen_string_literal: true

module Musa
  module Scales
    # Dorian mode (second mode of major scale).
    #
    # DorianScaleKind defines the Dorian mode, a minor mode with a characteristic
    # raised sixth degree. It's built on the second degree of the major scale
    # and has a brighter, more hopeful quality than natural minor.
    #
    # ## Pitch Structure
    #
    # 7 diatonic degrees plus extended harmony (8th-13th):
    #
    # **Scale Degrees** (Roman numerals, lowercase for minor):
    #
    # - **i** (tonic): Root (0 semitones)
    # - **ii** (supertonic): Major second (2 semitones)
    # - **iii** (mediant): Minor third (3 semitones)
    # - **iv** (subdominant): Perfect fourth (5 semitones)
    # - **v** (dominant): Perfect fifth (7 semitones)
    # - **vi** (submediant): **Major sixth** (9 semitones) ← CHARACTERISTIC
    # - **vii** (subtonic): Minor seventh (10 semitones)
    #
    # ## Key Difference from Natural Minor
    #
    # The **vi** degree is raised from 8 semitones (minor sixth) to
    # 9 semitones (major sixth), creating:
    #
    # - A brighter, less melancholic minor quality
    # - The characteristic "Dorian color"
    # - Common in jazz, folk, and rock music
    #
    # ## Musical Character
    #
    # The Dorian mode:
    #
    # - Maintains minor quality (minor third)
    # - Has a raised 6th that adds brightness
    # - Common in jazz improvisation (ii-V-I progressions)
    # - Used extensively in modal jazz and Celtic music
    #
    # ## Usage
    #
    #     d_dorian = Scales[:et12][440.0][:dorian][62]
    #     d_dorian.tonic   # D (62)
    #     d_dorian.vi      # B (71) - major sixth (characteristic)
    #
    # @see ScaleKind Abstract base class
    # @see MinorNaturalScaleKind Natural minor (with minor 6th)
    # @see PhrygianScaleKind Phrygian mode
    class DorianScaleKind < ScaleKind
      @base_metadata = {
        family: :greek_modes,
        brightness: -1,
        character: [:minor, :jazzy, :sophisticated],
        parent: { scale: :major, degree: 2 }
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
               pitch: 12 + 7 },
             { functions: %i[xiii _13 thirteenth],
               pitch: 12 + 9 }].freeze

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
        # @return [Symbol] :dorian
        def id
          :dorian
        end
      end

      EquallyTempered12ToneScaleSystem.register DorianScaleKind
    end
  end
end
