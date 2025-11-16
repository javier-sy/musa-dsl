require_relative 'e'
require_relative 'v'

module Musa::Datasets
  # Hash-based dataset with array conversion.
  #
  # PackedV (Packed Value) represents datasets stored as hashes (named key-value pairs).
  # Extends {AbsI} for absolute indexed events.
  #
  # ## Purpose
  #
  # PackedV provides named key-value storage for musical data and conversion
  # to indexed arrays ({V}). This is useful for:
  #
  # - Semantic naming of values (pitch, duration, velocity)
  # - Sparse data (only store non-default values)
  # - Converting between hash and array representations
  # - Serialization to readable formats
  #
  # ## Conversion to V
  #
  # The {#to_V} method converts hashes to arrays using a mapper that
  # defines the correspondence between hash keys and array positions.
  #
  # ### Array Mapper
  #
  # Array mapper defines the order of keys in resulting array.
  # Position i contains value for key mapper[i].
  #
  #     pv = { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PackedV)
  #     v = pv.to_V([:pitch, :duration, :velocity])
  #     # => [60, 1.0, nil]
  #     # velocity missing, becomes nil
  #
  # - Missing keys become `nil` in array
  #
  # ### Hash Mapper
  #
  # Hash mapper defines both key order (keys) and default values (values).
  # Position i contains value for key mapper.keys[i], using mapper.values[i]
  # as default if key is missing or value is nil.
  #
  #     pv = { pitch: 60 }.extend(Musa::Datasets::PackedV)
  #     v = pv.to_V({ pitch: 60, duration: 1.0, velocity: 64 })
  #     # => [60, 1.0, 64]
  #     # duration and velocity use defaults
  #
  # Defaults fill in missing or nil values.
  #
  # @example Basic hash to array conversion
  #   pv = { pitch: 60, duration: 1.0, velocity: 64 }.extend(Musa::Datasets::PackedV)
  #   v = pv.to_V([:pitch, :duration, :velocity])
  #   # => [60, 1.0, 64]
  #
  # @example Missing keys become nil (array mapper)
  #   pv = { a: 1, c: 3 }.extend(Musa::Datasets::PackedV)
  #   v = pv.to_V([:c, :b, :a])
  #   # => [3, nil, 1]
  #   # b missing, becomes nil
  #
  # @example Hash mapper with defaults
  #   pv = { a: 1, b: nil, c: 3 }.extend(Musa::Datasets::PackedV)
  #   v = pv.to_V({ c: 100, b: 200, a: 300, d: 400 })
  #   # => [3, 200, 1, 400]
  #   # b nil → uses default 200
  #   # d missing → uses default 400
  #
  # @example Partial mapper (fewer keys in mapper)
  #   pv = { a: 1, b: 2, c: 3 }.extend(Musa::Datasets::PackedV)
  #   v = pv.to_V([:c, :b])
  #   # => [3, 2]
  #   # Only c and b extracted
  #
  # @example Key order matters
  #   pv = { a: 1, b: 2, c: 3 }.extend(Musa::Datasets::PackedV)
  #   v = pv.to_V([:c, :b, :a])
  #   # => [3, 2, 1]
  #
  # @see V Array-based dataset (inverse)
  # @see AbsI Parent absolute indexed module
  module PackedV
    include AbsI

    # Converts packed hash to array (V).
    #
    # @param mapper [Array<Symbol>, Hash{Symbol => Object}] key mapping
    #   - Array: maps keys to indices (order matters)
    #   - Hash: maps keys (keys) to indices with defaults (values)
    #
    # @return [V] array dataset
    #
    # @raise [ArgumentError] if mapper is not Array or Hash
    #
    # @example Array mapper
    #   pv.to_V([:pitch, :duration, :velocity])
    #
    # @example Hash mapper with defaults
    #   pv.to_V({ pitch: 60, duration: 1.0, velocity: 64 })
    def to_V(mapper)
      case mapper
      when Hash
        mapper.collect { |key, default| self[key] || default }.extend(V)
      when Array
        mapper.collect { |key| self[key] }.extend(V)
      else
        raise ArgumentError, "Expected Hash or Array as mapper but got a #{mapper.class.name}"
      end
    end
  end
end
