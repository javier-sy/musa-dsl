require_relative 'extension'
require_relative 'deep-copy'

module Musa
  module Extension
    # Refinement that converts objects, arrays, and hashes into hashes with specified keys.
    #
    # This refinement is crucial for normalizing parameters in the DSL, especially when
    # dealing with musical events that can be specified in multiple formats (positional,
    # hash-based, or mixed).
    #
    # ## Core Behavior
    #
    # - **Object**: Creates hash mapping all keys to the same value
    # - **Array**: Maps keys to array elements in order (consuming array)
    # - **Hash**: Filters and reorders according to specified keys
    # - **Preserves singleton class modules** on hash results
    #
    # ## Use Cases
    #
    # - Converting positional parameters to named parameters
    # - Normalizing mixed parameter formats in musical events
    # - Extracting specific keys from larger hashes
    # - Providing defaults for missing event attributes
    #
    # @example Basic object hashification
    #   using Musa::Extension::Hashify
    #
    #   100.hashify(keys: [:velocity, :duration])
    #   # => { velocity: 100, duration: 100 }
    #
    # @example Array to hash
    #   using Musa::Extension::Hashify
    #
    #   [60, 100, 0.5].hashify(keys: [:pitch, :velocity, :duration])
    #   # => { pitch: 60, velocity: 100, duration: 0.5 }
    #
    # @example Hash filtering and reordering
    #   using Musa::Extension::Hashify
    #
    #   { pitch: 60, velocity: 100, channel: 0, duration: 1 }
    #     .hashify(keys: [:pitch, :velocity])
    #   # => { pitch: 60, velocity: 100 }
    #
    # @example With defaults
    #   using Musa::Extension::Hashify
    #
    #   [60].hashify(keys: [:pitch, :velocity, :duration], default: nil)
    #   # => { pitch: 60, velocity: nil, duration: nil }
    #
    # @example Musical event normalization
    #   using Musa::Extension::Hashify
    #
    #   # User provides just a pitch
    #   60.hashify(keys: [:pitch, :velocity], default: 64)
    #   # => { pitch: 60, velocity: 64 }
    #
    #   # User provides array [pitch, velocity, duration]
    #   [62, 90, 0.5].hashify(keys: [:pitch, :velocity, :duration])
    #   # => { pitch: 62, velocity: 90, duration: 0.5 }
    #
    # @see Musa::Datasets Hash-based event structures
    # @note This refinement must be activated with `using Musa::Extension::Hashify`
    # @note Singleton class modules (dataset extensions) are preserved on hash results
    #
    # ## Methods Added
    #
    # ### Object
    # - {Object#hashify} - Creates a hash mapping all specified keys to this object's value
    #
    # ### Array
    # - {Array#hashify} - Maps array elements to hash keys in order, consuming the array
    #
    # ### Hash
    # - {Hash#hashify} - Filters and reorders hash to include only specified keys, preserving modules
    module Hashify
      # @!method hashify(keys:, default: nil)
      #   Creates a hash mapping all specified keys to this object's value.
      #
      #   Useful for broadcasting a single value across multiple attributes.
      #   Nil objects can be replaced with a default value.
      #
      #   @note This method is added to Object via refinement. Requires `using Musa::Extension::Hashify`.
      #
      #   @param keys [Array<Symbol>] keys for the resulting hash.
      #   @param default [Object, nil] value to use if self is nil.
      #
      #   @return [Hash] hash with all keys mapped to self (or default if nil).
      #
      #   @example Single value to multiple keys
      #     using Musa::Extension::Hashify
      #     127.hashify(keys: [:velocity, :pressure])
      #     # => { velocity: 127, pressure: 127 }
      class ::Object; end

      refine Object do
        def hashify(keys:, default: nil)
          keys.collect do |key|
            [ key,
              if nil?
                default
              else
                self
              end ]
          end.to_h
        end
      end

      # @!method hashify(keys:, default: nil)
      #   Maps array elements to hash keys in order, consuming the array.
      #
      #   Elements are assigned to keys sequentially. If the array has fewer elements
      #   than keys, remaining keys get nil (or default). The array is cloned before
      #   consumption, so the original is unchanged.
      #
      #   @note This method is added to Array via refinement. Requires `using Musa::Extension::Hashify`.
      #
      #   @param keys [Array<Symbol>] keys for the resulting hash (in order).
      #   @param default [Object, nil] value for keys without corresponding array elements.
      #
      #   @return [Hash] hash with keys mapped to array elements in order.
      #
      #   @example Basic array mapping
      #     using Musa::Extension::Hashify
      #     [60, 100, 0.25].hashify(keys: [:pitch, :velocity, :duration])
      #     # => { pitch: 60, velocity: 100, duration: 0.25 }
      #
      #   @example Fewer elements than keys
      #     using Musa::Extension::Hashify
      #     [60, 100].hashify(keys: [:pitch, :velocity, :duration], default: nil)
      #     # => { pitch: 60, velocity: 100, duration: nil }
      #
      #   @example More elements than keys (extras ignored)
      #     using Musa::Extension::Hashify
      #     [60, 100, 0.5, :ignored].hashify(keys: [:pitch, :velocity])
      #     # => { pitch: 60, velocity: 100 }
      class ::Array; end

      refine Array do
        def hashify(keys:, default: nil)
          values = clone
          keys.collect do |key|
            value = values.shift
            [ key,
              value.nil? ? default : value ]
          end.to_h
        end
      end

      # @!method hashify(keys:, default: nil)
      #   Filters and reorders hash to include only specified keys, preserving modules.
      #
      #   Creates a new hash with only the requested keys, in the order specified.
      #   Missing keys get nil (or default). Singleton class modules (like dataset
      #   extensions) are copied to the result.
      #
      #   @note This method is added to Hash via refinement. Requires `using Musa::Extension::Hashify`.
      #
      #   @param keys [Array<Symbol>] keys to include in result (order matters).
      #   @param default [Object, nil] value for keys not present in source hash.
      #
      #   @return [Hash] new hash with specified keys, preserving singleton modules.
      #
      #   @example Filtering keys
      #     using Musa::Extension::Hashify
      #     { pitch: 60, velocity: 100, channel: 0 }
      #       .hashify(keys: [:pitch, :velocity])
      #     # => { pitch: 60, velocity: 100 }
      #
      #   @example Reordering keys
      #     using Musa::Extension::Hashify
      #     { velocity: 100, pitch: 60 }
      #       .hashify(keys: [:pitch, :velocity])
      #     # => { pitch: 60, velocity: 100 }
      #
      #   @example Adding missing keys with default
      #     using Musa::Extension::Hashify
      #     { pitch: 60 }
      #       .hashify(keys: [:pitch, :velocity], default: 80)
      #     # => { pitch: 60, velocity: 80 }
      #
      #   @example Preserving dataset modules
      #     using Musa::Extension::Hashify
      #     event = { pitch: 60, velocity: 100 }.extend(Musa::Datasets::AbsI)
      #     event.hashify(keys: [:pitch, :velocity])
      #     # Result also extended with AbsI
      #
      #   @note Singleton class modules are preserved via DeepCopy.copy_singleton_class_modules
      class ::Hash; end

      refine Hash do
        def hashify(keys:, default: nil)
          keys.collect do |key|
            value = self[key]
            [ key,
              value.nil? ? default : value ]
          end.to_h
              .tap {|_| DeepCopy::DeepCopy.copy_singleton_class_modules(self, _) }
        end
      end
    end
  end
end
