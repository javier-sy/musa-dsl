# frozen_string_literal: true

module Musa
  module Scales
    # Base class for 12-semitone scale systems.
    #
    # TwelveSemitonesScaleSystem provides the foundation for any scale system
    # using 12 semitones per octave. It defines intervals and structure but
    # doesn't specify tuning (frequency calculation).
    #
    # Concrete subclasses must implement frequency calculation:
    #
    # - {EquallyTempered12ToneScaleSystem}: Equal temperament (12-TET)
    # - Other temperaments could be added (e.g., meantone, just intonation)
    #
    # ## Intervals
    #
    # Defines standard interval names using semitone distances:
    #
    #     { P0: 0, m2: 1, M2: 2, m3: 3, M3: 4, P4: 5, TT: 6,
    #       P5: 7, m6: 8, M6: 9, m7: 10, M7: 11, P8: 12 }
    #
    # @abstract Subclasses must implement {frequency_of_pitch}
    # @see EquallyTempered12ToneScaleSystem Concrete equal temperament implementation
    class TwelveSemitonesScaleSystem < ScaleSystem
      class << self
        @@intervals = { P0: 0, m2: 1, M2: 2, m3: 3, M3: 4, P4: 5, TT: 6, P5: 7, m6: 8, M6: 9, m7: 10, M7: 11, P8: 12 }

        # System identifier.
        # @return [Symbol] :et12
        def id
          :et12
        end

        # Number of distinct notes per octave.
        # @return [Integer] 12
        def notes_in_octave
          12
        end

        # Size of smallest pitch division.
        # @return [Integer] 1 (semitone)
        def part_of_tone_size
          1
        end

        # Interval definitions.
        #
        # @return [Hash{Symbol => Integer}] interval name to semitones mapping
        #
        # @example
        #   intervals[:P5]  # => 7 (perfect fifth)
        #   intervals[:M3]  # => 4 (major third)
        def intervals
          @@intervals
        end
      end
    end
  end
end
