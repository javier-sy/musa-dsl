require_relative 'e'

module Musa::Datasets
  # Delta events with flexible duration encoding.
  #
  # DeltaD (Delta Duration) extends {Delta} events with three different ways to
  # specify duration changes in delta-encoded sequences. This provides flexibility
  # for efficient encoding of musical sequences.
  #
  # ## Duration Encoding Modes
  #
  # **:abs_duration** - Absolute duration override
  #
  # Sets duration to an absolute value, regardless of previous duration.
  # Use when duration changes to a completely different value.
  #
  #     { abs_duration: 2.0 }
  #     # Sets duration to 2.0, ignoring previous
  #
  # **:delta_duration** - Incremental duration change
  #
  # Adds or subtracts from the previous duration value.
  # Use for small adjustments to duration.
  #
  #     { delta_duration: 0.5 }   # Add 0.5 to previous
  #     { delta_duration: -0.25 } # Subtract 0.25 from previous
  #
  # **:factor_duration** - Multiplicative duration factor
  #
  # Multiplies previous duration by a factor.
  # Use for proportional changes (doubling, halving, etc.).
  #
  #     { factor_duration: 2 }    # Double previous duration
  #     { factor_duration: 0.5 }  # Half previous duration
  #
  # ## Natural Keys
  #
  # - **:abs_duration**: Absolute duration value
  # - **:delta_duration**: Duration increment/decrement
  # - **:factor_duration**: Duration multiplication factor
  #
  # Only one duration key should be present at a time.
  #
  # ## Usage in Delta Encoding
  #
  # Used by {GDVd} for efficient delta encoding of musical sequences:
  #
  # @example Different duration encoding modes
  #   previous = { duration: 1.0 }
  #
  #   # Absolute: set to specific value
  #   delta1 = { abs_duration: 2.0 }.extend(DeltaD)
  #   # Result: duration becomes 2.0
  #
  #   # Delta: add to previous
  #   delta2 = { delta_duration: 0.5 }.extend(DeltaD)
  #   # Result: duration becomes 1.5 (was 1.0)
  #
  #   # Factor: multiply previous
  #   delta3 = { factor_duration: 2 }.extend(DeltaD)
  #   # Result: duration becomes 2.0 (was 1.0)
  #
  # @example Neuma notation representation
  #   # Absolute duration
  #   { abs_duration: 1.5 } => "1.5"
  #
  #   # Delta duration
  #   { delta_duration: 0.5 }  => "+0.5"
  #   { delta_duration: -0.5 } => "-0.5"
  #
  #   # Factor duration
  #   { factor_duration: 2 } => "*2"
  #
  # @see Delta Parent delta module
  # @see GDVd Grade/Duration/Velocity delta encoding
  # @see AbsD Absolute duration events
  module DeltaD
    include Delta

    # Natural keys for delta duration encoding.
    #
    # Only one of these keys should be present in a delta event.
    #
    # @return [Array<Symbol>] natural duration keys
    NaturalKeys = [:abs_duration, # absolute duration
                   :delta_duration, # incremental duration
                   :factor_duration # multiplicative factor duration
    ].freeze
  end
end