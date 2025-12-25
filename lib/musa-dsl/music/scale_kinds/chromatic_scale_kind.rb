# frozen_string_literal: true

module Musa
  module Scales
    # Chromatic scale kind (all 12 semitones).
    #
    # ChromaticScaleKind defines the chromatic scale containing all 12 semitones
    # of the octave. It's used as a fallback for chromatic (non-diatonic) notes
    # and for atonal or twelve-tone compositions.
    #
    # ## Pitch Structure
    #
    # Contains 12 pitch classes, one for each semitone:
    #
    # - Degrees: _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12
    # - Pitches: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 (semitones from root)
    #
    # ## Special Properties
    #
    # - **chromatic?**: Returns true (only scale kind with this property)
    # - Used automatically when accessing non-diatonic notes in diatonic scales
    #
    # ## Usage
    #
    #     chromatic = Scales[:et12][440.0][:chromatic][60]
    #     chromatic._1   # C
    #     chromatic._2   # C#/Db
    #     chromatic._3   # D
    #     # ... all 12 semitones
    #
    # @see ScaleKind Abstract base class
    # @see MajorScaleKind Major scale (7 notes)
    # @see MinorNaturalScaleKind Minor scale (7 notes)
    class ChromaticScaleKind < ScaleKind
      @base_metadata = {
        family: :chromatic,
        brightness: nil,
        character: [:atonal, :all_notes],
        parent: nil
      }.freeze

      class << self
        @@pitches =
            [{ functions: [:_1], pitch: 0 },
             { functions: [:_2], pitch: 1 },
             { functions: [:_3], pitch: 2 },
             { functions: [:_4], pitch: 3 },
             { functions: [:_5], pitch: 4 },
             { functions: [:_6], pitch: 5 },
             { functions: [:_7], pitch: 6 },
             { functions: [:_8], pitch: 7 },
             { functions: [:_9], pitch: 8 },
             { functions: [:_10], pitch: 9 },
             { functions: [:_11], pitch: 10 },
             { functions: [:_12], pitch: 11 }].freeze

        # Pitch structure.
        # @return [Array<Hash>] pitch definitions with functions and offsets
        def pitches
          @@pitches
        end

        # Scale kind identifier.
        # @return [Symbol] :chromatic
        def id
          :chromatic
        end

        # Indicates if this is a chromatic scale.
        # @return [Boolean] true
        def chromatic?
          true
        end
      end

      EquallyTempered12ToneScaleSystem.register ChromaticScaleKind
    end
  end
end
