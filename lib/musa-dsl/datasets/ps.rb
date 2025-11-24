require_relative 'e'
require_relative 'score'

require_relative '../sequencer'

module Musa::Datasets
  # Parameter segments for continuous changes between multidimensional points.
  #
  # PS (Parameter Segment) represents a continuous change from one point
  # to another over a duration. Extends {AbsD} for duration support.
  #
  # ## Purpose
  #
  # PS is used to represent:
  #
  # - **Glissandi**: Continuous pitch slides (portamento)
  # - **Parameter sweeps**: Gradual changes in any sonic parameter
  # - **Interpolations**: Smooth transitions between multidimensional states
  #
  # Unlike discrete events that jump from one value to another, PS represents
  # the continuous path between values.
  #
  # ## Natural Keys
  #
  # - **:from**: Starting value (number, array, or hash)
  # - **:to**: Ending value (must match :from type and structure)
  # - **:right_open**: Whether endpoint is included (true = open interval)
  # - **:duration**: Duration of the change (from {AbsD})
  # - **:note_duration**, **:forward_duration**: Additional duration keys (from {AbsD})
  #
  # ## Value Types
  #
  # ### Single Values
  #
  #     { from: 60, to: 72, duration: 1.0 }
  #     # Single value glissando
  #
  # ### Arrays (parallel interpolation)
  #
  #     { from: [60, 64], to: [72, 76], duration: 1.0 }
  #     # Both values interpolate in parallel
  #     # Arrays must be same size
  #
  # ### Hashes (named parameters)
  #
  #     { from: { pitch: 60, velocity: 64 },
  #       to: { pitch: 72, velocity: 80 },
  #       duration: 1.0 }
  #     # Multiple parameters interpolate together
  #     # Hashes must have same keys
  #
  # ## Right Open Intervals
  #
  # The :right_open flag determines if the ending value is reached:
  #
  # - **false** (closed): Interpolation reaches :to value
  # - **true** (open): Interpolation stops just before :to value
  #
  # This is important for consecutive segments where you don't want
  # discontinuities at the boundaries.
  #
  # @example Basic parameter segment (pitch glissando)
  #   ps = { from: 60, to: 72, duration: 2.0 }.extend(Musa::Datasets::PS)
  #   # Continuous slide from C4 to C5 over 2 beats
  #
  # @example Parallel interpolation (multidimensional)
  #   ps = {
  #     from: [60, 64],  # C4 and E4
  #     to: [72, 76],    # C5 and E5
  #     duration: 1.0
  #   }.extend(PS)
  #   # Both parameters move in parallel
  #
  # @example Multiple parameters (sonic gesture)
  #   ps = {
  #     from: { pitch: 60, velocity: 64, pan: -1.0 },
  #     to: { pitch: 72, velocity: 80, pan: 1.0 },
  #     duration: 2.0
  #   }.extend(PS)
  #   # Pitch, velocity, and pan all change smoothly
  #
  # @example Right open interval
  #   ps1 = { from: 60, to: 64, duration: 1.0, right_open: true }.extend(PS)
  #   ps2 = { from: 64, to: 67, duration: 1.0, right_open: false }.extend(PS)
  #   # ps1 stops just before 64, ps2 starts at 64 - no discontinuity
  #
  # @example Created from P point series
  #   p = [60, 4, 64, 8, 67].extend(P)
  #   serie = p.to_ps_serie
  #   ps1 = serie.next_value
  #   # => { from: 60, to: 64, duration: 1.0, right_open: true }
  #
  # @see AbsD Parent absolute duration module
  # @see P Point series (source of PS)
  # @see Helper String formatting utilities
  module PS
    include AbsD

    include Helper

    # Natural keys including segment endpoints.
    # @return [Array<Symbol>]
    NaturalKeys = (NaturalKeys + [:from, :to, :right_open]).freeze

    # Base duration for time calculations.
    # @return [Rational]
    attr_accessor :base_duration

    # Converts to Neuma notation string.
    #
    # @return [String] Neuma notation
    # @todo Not yet implemented
    def to_neuma
      raise NotImplementedError, 'PS to_neuma conversion is not yet implemented'
    end

    # Converts to PDV (Pitch/Duration/Velocity).
    #
    # @return [PDV] PDV dataset
    # @todo Not yet implemented
    def to_pdv
      raise NotImplementedError, 'PS to_pdv conversion is not yet implemented'
    end

    # Converts to GDV (Grade/Duration/Velocity).
    #
    # @return [GDV] GDV dataset
    # @todo Not yet implemented
    def to_gdv
      raise NotImplementedError, 'PS to_gdv conversion is not yet implemented'
    end

    # Converts to absolute indexed format.
    #
    # @return [AbsI] indexed dataset
    # @todo Not yet implemented
    def to_absI
      raise NotImplementedError, 'PS to_absI conversion is not yet implemented'
    end

    # Validates PS structure.
    #
    # Checks that:
    # - :from and :to have compatible types
    # - Arrays have same size
    # - Hashes have same keys
    # - Duration is positive numeric
    #
    # @return [Boolean] true if valid
    #
    # @example Valid array segment
    #   ps = { from: [60, 64], to: [72, 76], duration: 1.0 }.extend(PS)
    #   ps.valid?  # => true
    #
    # @example Invalid - mismatched array sizes
    #   ps = { from: [60, 64], to: [72], duration: 1.0 }.extend(PS)
    #   ps.valid?  # => false
    #
    # @example Invalid - mismatched hash keys
    #   ps = { from: { a: 1 }, to: { b: 2 }, duration: 1.0 }.extend(PS)
    #   ps.valid?  # => false
    def valid?
      case self[:from]
      when Array
        self[:to].is_a?(Array) &&
            self[:from].size == self[:to].size
      when Hash
        self[:to].is_a?(Hash) &&
            self[:from].keys == self[:to].keys
      else
        false
      end && self[:duration].is_a?(Numeric) && self[:duration] > 0
    end
  end
end
