# frozen_string_literal: true

module Musa
  module Scales
    # Lydian mode (fourth mode of major scale).
    #
    # LydianScaleKind defines the Lydian mode, a major mode with a characteristic
    # raised fourth degree. It's built on the fourth degree of the major scale
    # and has a bright, dreamy, floating quality.
    #
    # ## Pitch Structure
    #
    # 7 diatonic degrees plus extended harmony (8th-13th):
    #
    # **Scale Degrees** (Roman numerals, uppercase for major):
    #
    # - **I** (tonic): Root (0 semitones)
    # - **II** (supertonic): Major second (2 semitones)
    # - **III** (mediant): Major third (4 semitones)
    # - **IV** (subdominant): **Augmented fourth** (6 semitones) ← CHARACTERISTIC
    # - **V** (dominant): Perfect fifth (7 semitones)
    # - **VI** (submediant): Major sixth (9 semitones)
    # - **VII** (leading): Major seventh (11 semitones)
    #
    # ## Key Difference from Major
    #
    # The **IV** degree is raised from 5 semitones (perfect fourth) to
    # 6 semitones (augmented fourth/tritone), creating:
    #
    # - A bright, ethereal quality
    # - The characteristic "Lydian color"
    # - A sense of floating or suspension
    #
    # ## Musical Character
    #
    # The Lydian mode:
    #
    # - Maintains major quality (major third)
    # - Has a raised 4th that adds brightness and tension
    # - Common in film scores and jazz (especially over maj7#11 chords)
    # - Creates a dreamy, otherworldly atmosphere
    #
    # ## Usage
    #
    #     f_lydian = Scales[:et12][440.0][:lydian][65]
    #     f_lydian.tonic  # F (65)
    #     f_lydian.IV     # B (71) - augmented fourth (characteristic)
    #
    # @see ScaleKind Abstract base class
    # @see MajorScaleKind Major scale (with perfect 4th)
    # @see MixolydianScaleKind Mixolydian mode
    class LydianScaleKind < ScaleKind
      @base_metadata = {
        family: :greek_modes,
        brightness: 2,
        character: [:bright, :dreamy, :floating],
        parent: { scale: :major, degree: 4 }
      }.freeze

      class << self
        @@pitches =
            [{ functions: %i[I _1 tonic first],
               pitch: 0 },
             { functions: %i[II _2 supertonic second],
               pitch: 2 },
             { functions: %i[III _3 mediant third],
               pitch: 4 },
             { functions: %i[IV _4 subdominant fourth],
               pitch: 6 },
             { functions: %i[V _5 dominant fifth],
               pitch: 7 },
             { functions: %i[VI _6 submediant sixth],
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
               pitch: 12 + 6 },
             { functions: %i[XII _12 twelfth],
               pitch: 12 + 7 },
             { functions: %i[XIII _13 thirteenth],
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
        # @return [Symbol] :lydian
        def id
          :lydian
        end
      end

      EquallyTempered12ToneScaleSystem.register LydianScaleKind
    end
  end
end
