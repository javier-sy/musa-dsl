require_relative 'dataset'
require_relative 'packed-v'

module Musa::Datasets
  # Array-based dataset with named key conversion.
  #
  # V (Value) represents datasets stored as arrays (indexed values).
  # Extends {AbsI} for absolute indexed events.
  #
  # ## Purpose
  #
  # V provides efficient array-based storage for ordered values and conversion
  # to named key-value pairs ({PackedV}). This is useful for:
  #
  # - Compact storage of sequential values
  # - Converting between array and hash representations
  # - Filtering default values during conversion
  #
  # ## Conversion to PackedV
  #
  # The {#to_packed_V} method converts arrays to hashes using a mapper that
  # defines the correspondence between array indices and hash keys.
  #
  # ### Array Mapper
  #
  # Array mapper defines key names for each position. Position i maps to mapper[i].
  #
  #     v = [3, 2, 1].extend(Musa::Datasets::V)
  #     pv = v.to_packed_V([:c, :b, :a])
  #     # => { c: 3, b: 2, a: 1 }
  #
  # - `nil` mapper entries skip that position
  # - `nil` values skip that position
  #
  # ### Hash Mapper
  #
  # Hash mapper defines both key names (keys) and default values (values).
  # Position i maps to key mapper.keys[i] with default mapper.values[i].
  #
  #     v = [3, 2, 1, 400].extend(Musa::Datasets::V)
  #     pv = v.to_packed_V({ c: 100, b: 200, a: 300, d: 400 })
  #     # => { c: 3, b: 2, a: 1 }
  #     # d: 400 omitted because it equals default
  #
  # Values matching their defaults are omitted for compression.
  #
  # @example Basic array to hash conversion
  #   v = [60, 1.0, 64].extend(Musa::Datasets::V)
  #   pv = v.to_packed_V([:pitch, :duration, :velocity])
  #   # => { pitch: 60, duration: 1.0, velocity: 64 }
  #
  # @example With nil mapper (skip position)
  #   v = [3, 2, 1].extend(Musa::Datasets::V)
  #   pv = v.to_packed_V([:c, nil, :a])
  #   # => { c: 3, a: 1 }
  #   # Position 1 (value 2) skipped
  #
  # @example With nil value (skip position)
  #   v = [3, nil, 1].extend(Musa::Datasets::V)
  #   pv = v.to_packed_V([:c, :b, :a])
  #   # => { c: 3, a: 1 }
  #   # Position 1 (nil value) skipped
  #
  # @example Hash mapper with defaults (compression)
  #   v = [3, 2, 1, 400].extend(Musa::Datasets::V)
  #   pv = v.to_packed_V({ c: 100, b: 200, a: 300, d: 400 })
  #   # => { c: 3, b: 2, a: 1 }
  #   # d omitted because value 400 equals default 400
  #
  # @example Partial mapper (fewer keys than values)
  #   v = [3, 2, 1].extend(Musa::Datasets::V)
  #   pv = v.to_packed_V([:c, :b])
  #   # => { c: 3, b: 2 }
  #   # Position 2 (value 1) skipped - no mapper
  #
  # @see PackedV Hash-based dataset (inverse)
  # @see AbsI Parent absolute indexed module
  module V
    include AbsI

    # Converts array to packed hash (PackedV).
    #
    # @param mapper [Array<Symbol>, Hash{Symbol => Object}] key mapping
    #   - Array: maps indices to keys (nil skips)
    #   - Hash: maps indices to keys (keys) with defaults (values)
    #
    # @return [PackedV] packed hash dataset
    #
    # @raise [ArgumentError] if mapper is not Array or Hash
    #
    # @example Array mapper
    #   v.to_packed_V([:pitch, :duration])
    #
    # @example Hash mapper with defaults
    #   v.to_packed_V({ pitch: 60, duration: 1.0 })
    def to_packed_V(mapper)
      case mapper
      when Hash
        pv = {}.extend(PackedV)
        each_index { |i| pv[mapper.keys[i]] = self[i] unless self[i] == mapper.values[i] }
        pv
      when Array
        pv = {}.extend(PackedV)
        each_index { |i| pv[mapper[i]] = self[i] if mapper[i] && self[i] }
        pv
      else
        raise ArgumentError, "Expected Hash or Array as mapper but got a #{mapper.class.name}"
      end
    end
  end
end
