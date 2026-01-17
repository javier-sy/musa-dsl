# frozen_string_literal: true

module Musa
  module Scales
    # Bebop major scale kind.
    #
    # BebopMajorScaleKind defines the bebop major scale, an eight-note
    # scale that adds a chromatic passing tone (#5) to the major scale.
    # This allows chord tones to fall on downbeats during eighth-note runs.
    #
    # ## Pitch Structure
    #
    # 8 degrees plus extended:
    #
    # **Scale Degrees** (uppercase for major quality):
    #
    # - **I** (tonic): Root (0 semitones)
    # - **II** (supertonic): Major second (2 semitones)
    # - **III** (mediant): Major third (4 semitones)
    # - **IV** (subdominant): Perfect fourth (5 semitones)
    # - **V** (dominant): Perfect fifth (7 semitones)
    # - **V#** (passing): Augmented fifth (8 semitones) ← PASSING TONE
    # - **VI** (submediant): Major sixth (9 semitones)
    # - **VII** (leading): Major seventh (11 semitones)
    #
    # ## Bebop Principle
    #
    # The added #5 chromatic note ensures that:
    # - Chord tones (1, 3, 5, 7) fall on strong beats
    # - Non-chord tones fall on weak beats
    # - Smooth chromatic connection between 5 and 6
    #
    # ## Musical Character
    #
    # The bebop major scale:
    #
    # - Used over major 7th and major 6th chords
    # - Creates flowing eighth-note lines
    # - Common in bebop and jazz standards
    #
    # ## Usage
    #
    #     c_bebop_maj = Scales[:et12][440.0][:bebop_major][60]
    #     c_bebop_maj[4].pitch  # G (67) - perfect 5th
    #     c_bebop_maj[5].pitch  # G# (68) - augmented 5th (passing)
    #     c_bebop_maj[6].pitch  # A (69) - major 6th
    #
    # @see ScaleKind Abstract base class
    # @see MajorScaleKind Major scale (7-note parent)
    # @see BebopDominantScaleKind Bebop dominant scale
    class BebopMajorScaleKind < ScaleKind
      @base_metadata = {
        family: :bebop,
        brightness: 0,
        character: [:jazz, :chromatic_passing, :major],
        parent: nil
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
             { functions: %i[V# _6 sixth],
               pitch: 8 },
             { functions: %i[VI _7 submediant seventh],
               pitch: 9 },
             { functions: %i[VII _8 leading eighth],
               pitch: 11 },
             { functions: %i[VIII _9 ninth],
               pitch: 12 },
             { functions: %i[IX _10 tenth],
               pitch: 12 + 2 },
             { functions: %i[X _11 eleventh],
               pitch: 12 + 4 },
             { functions: %i[XI _12 twelfth],
               pitch: 12 + 5 },
             { functions: %i[XII _13 thirteenth],
               pitch: 12 + 7 },
             { functions: %i[XII# _14 fourteenth],
               pitch: 12 + 8 },
             { functions: %i[XIII _15 fifteenth],
               pitch: 12 + 9 },
             { functions: %i[XIV _16 sixteenth],
               pitch: 12 + 11 }].freeze

        def pitches
          @@pitches
        end

        def grades
          8
        end

        def id
          :bebop_major
        end
      end

      EquallyTempered12ToneScaleSystem.register BebopMajorScaleKind
    end
  end
end
