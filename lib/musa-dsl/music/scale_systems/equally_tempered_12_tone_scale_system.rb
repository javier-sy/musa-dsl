# frozen_string_literal: true

require_relative 'twelve_semitones_scale_system'

module Musa
  module Scales
    # Equal temperament 12-tone scale system.
    #
    # EquallyTempered12ToneScaleSystem implements the standard equal temperament
    # tuning where each semitone has exactly the same frequency ratio: 2^(1/12).
    # This is the most common tuning system in modern Western music.
    #
    # ## Frequency Calculation
    #
    # Uses the equal temperament formula based on A440 concert pitch:
    #
    #     frequency = a_frequency × 2^((pitch - 69) / 12)
    #
    # Where:
    #
    # - **a_frequency**: Reference A frequency (typically 440 Hz)
    # - **pitch**: MIDI pitch number (69 = A4)
    #
    # ## Historical Pitch Standards
    #
    # Different A frequencies represent different historical standards:
    #
    # - **440 Hz**: Modern concert pitch (ISO 16)
    # - **442 Hz**: Used by some orchestras (brighter sound)
    # - **415 Hz**: Baroque pitch (approximately A=415)
    # - **432 Hz**: Alternative tuning (some claim harmonic benefits)
    #
    # ## Registration
    #
    # This system is registered as the default scale system, accessible via:
    #
    #     Scales[:et12]                    # By ID
    #     Scales.default_system            # As default
    #
    # ## Usage
    #
    #     # Get system with standard A440 tuning
    #     system = Scales[:et12][440.0]
    #
    #     # Get system with baroque tuning
    #     baroque = Scales[:et12][415.0]
    #
    #     # Access scale kinds
    #     c_major = system[:major][60]
    #     a_minor = system[:minor][69]
    #
    # @see TwelveSemitonesScaleSystem Abstract base class
    # @see ScaleSystem#frequency_of_pitch Abstract method implemented here
    class EquallyTempered12ToneScaleSystem < TwelveSemitonesScaleSystem
      class << self
        # Calculates frequency for a pitch using equal temperament.
        #
        # Implements the equal temperament tuning formula where each semitone
        # has a frequency ratio of 2^(1/12) ≈ 1.059463.
        #
        # @param pitch [Integer] MIDI pitch number
        # @param _root_pitch [Integer] unused (required by interface)
        # @param a_frequency [Numeric] reference A4 frequency in Hz
        # @return [Float] frequency in Hz
        #
        # @example Standard A440 tuning
        #   frequency_of_pitch(69, nil, 440.0)  # => 440.0 (A4)
        #   frequency_of_pitch(60, nil, 440.0)  # => 261.63 (C4, middle C)
        #
        # @example Baroque tuning
        #   frequency_of_pitch(69, nil, 415.0)  # => 415.0 (A4)
        def frequency_of_pitch(pitch, _root_pitch, a_frequency)
          (a_frequency * Rational(2)**Rational(pitch - 69, 12)).to_f
        end
      end

      Scales.register EquallyTempered12ToneScaleSystem, default: true
    end
  end
end
