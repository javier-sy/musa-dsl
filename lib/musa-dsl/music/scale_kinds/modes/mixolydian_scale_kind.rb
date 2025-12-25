# frozen_string_literal: true

module Musa
  module Scales
    # Mixolydian mode (fifth mode of major scale).
    #
    # MixolydianScaleKind defines the Mixolydian mode, a major mode with a
    # characteristic lowered seventh degree. It's built on the fifth degree
    # of the major scale and has a bluesy, rock quality.
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
    # - **IV** (subdominant): Perfect fourth (5 semitones)
    # - **V** (dominant): Perfect fifth (7 semitones)
    # - **VI** (submediant): Major sixth (9 semitones)
    # - **VII** (subtonic): **Minor seventh** (10 semitones) ← CHARACTERISTIC
    #
    # ## Key Difference from Major
    #
    # The **VII** degree is lowered from 11 semitones (major seventh) to
    # 10 semitones (minor seventh), creating:
    #
    # - A bluesy, rock quality
    # - The characteristic "Mixolydian color"
    # - Natural dominant seventh sound
    #
    # ## Musical Character
    #
    # The Mixolydian mode:
    #
    # - Maintains major quality (major third)
    # - Has a lowered 7th that removes the leading tone tension
    # - Common in rock, blues, funk, and folk music
    # - Natural mode for dominant seventh chords
    #
    # ## Usage
    #
    #     g_mixolydian = Scales[:et12][440.0][:mixolydian][67]
    #     g_mixolydian.tonic  # G (67)
    #     g_mixolydian.VII    # F (77) - minor seventh (characteristic)
    #
    # @see ScaleKind Abstract base class
    # @see MajorScaleKind Major scale (with major 7th)
    # @see LydianScaleKind Lydian mode
    class MixolydianScaleKind < ScaleKind
      @base_metadata = {
        family: :greek_modes,
        brightness: 1,
        character: [:bluesy, :rock, :dominant],
        parent: { scale: :major, degree: 5 }
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
               pitch: 5 },
             { functions: %i[V _5 dominant fifth],
               pitch: 7 },
             { functions: %i[VI _6 submediant sixth],
               pitch: 9 },
             { functions: %i[VII _7 subtonic seventh],
               pitch: 10 },
             { functions: %i[VIII _8 eighth],
               pitch: 12 },
             { functions: %i[IX _9 ninth],
               pitch: 12 + 2 },
             { functions: %i[X _10 tenth],
               pitch: 12 + 4 },
             { functions: %i[XI _11 eleventh],
               pitch: 12 + 5 },
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
        # @return [Symbol] :mixolydian
        def id
          :mixolydian
        end
      end

      EquallyTempered12ToneScaleSystem.register MixolydianScaleKind
    end
  end
end
