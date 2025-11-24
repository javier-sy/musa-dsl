require_relative 'extension'
require_relative 'deep-copy'

module Musa
  module Extension
    # Refinement that converts any object to an array, with optional repetition and defaults.
    #
    # This refinement is essential for normalizing parameters in the DSL, allowing users
    # to provide either single values or arrays and have them processed uniformly.
    #
    # ## Core Behavior
    #
    # - **Object**: Wraps in array; nil becomes []
    # - **Array**: Returns clone or cycles to requested size
    # - **size parameter**: Repeats/cycles to achieve target length
    # - **default parameter**: Replaces nil values
    #
    # ## Use Cases
    #
    # - Normalizing velocity parameters (single value or per-note array)
    # - Ensuring consistent array handling in DSL methods
    # - Cycling patterns to fill required lengths
    # - Providing default values for missing data
    #
    # @example Basic object wrapping
    #   using Musa::Extension::Arrayfy
    #
    #   5.arrayfy           # => [5]
    #   nil.arrayfy         # => []
    #   [1, 2, 3].arrayfy   # => [1, 2, 3]
    #
    # @example Repetition with size
    #   using Musa::Extension::Arrayfy
    #
    #   5.arrayfy(size: 3)        # => [5, 5, 5]
    #   [1, 2].arrayfy(size: 5)   # => [1, 2, 1, 2, 1]
    #   [1, 2, 3].arrayfy(size: 2) # => [1, 2]
    #
    # @example Default values for nil
    #   using Musa::Extension::Arrayfy
    #
    #   nil.arrayfy(size: 3, default: 0)           # => [0, 0, 0]
    #   [1, nil, 3].arrayfy(size: 5, default: -1)  # => [1, -1, 3, 1, -1]
    #
    # @example Musical application - velocity normalization
    #   using Musa::Extension::Arrayfy
    #
    #   # User provides single velocity for chord
    #   velocities = 90.arrayfy(size: 3)  # => [90, 90, 90]
    #
    #   # User provides array of velocities that cycles
    #   velocities = [80, 100].arrayfy(size: 5)  # => [80, 100, 80, 100, 80]
    #
    # @see Musa::MIDIVoices::MIDIVoice#note Uses arrayfy for velocity normalization
    # @note This refinement must be activated with `using Musa::Extension::Arrayfy`
    # @note Arrays are cloned and singleton class modules are preserved
    #
    # ## Methods Added
    #
    # ### Object
    # - {Object#arrayfy} - Converts any object into an array, optionally repeated to a target size
    #
    # ### Array
    # - {Array#arrayfy} - Clones or cycles the array to achieve the target size, with nil replacement
    module Arrayfy
      # @!method arrayfy(size: nil, default: nil)
      #   Converts any object into an array, optionally repeated to a target size.
      #
      #   @note This method is added to Object via refinement. Requires `using Musa::Extension::Arrayfy`.
      #
      #   @param size [Integer, nil] target array length. If nil, returns single-element array.
      #   @param default [Object, nil] value to use instead of nil.
      #
      #   @return [Array] single element repeated size times, or wrapped in array if size is nil.
      #
      #   @example With size
      #     using Musa::Extension::Arrayfy
      #     "hello".arrayfy(size: 3)  # => ["hello", "hello", "hello"]
      #
      #   @example Nil handling
      #     using Musa::Extension::Arrayfy
      #     nil.arrayfy(size: 2, default: :empty)  # => [:empty, :empty]
      class ::Object; end

      refine Object do
        def arrayfy(size: nil, default: nil)
          if size
            size.times.collect do
              nil? ? default : self
            end
          else
            nil? ? [] : [self]
          end
        end
      end

      # TODO add a refinement for Hash? Should receive a list parameter with the ordered keys

      # @!method arrayfy(size: nil, default: nil)
      #   Clones or cycles the array to achieve the target size, with nil replacement.
      #
      #   The cycling behavior multiplies the array enough times to reach or exceed
      #   the target size, then takes exactly the requested number of elements.
      #   Singleton class modules (like P, V dataset extensions) are preserved.
      #
      #   @note This method is added to Array via refinement. Requires `using Musa::Extension::Arrayfy`.
      #
      #   @param size [Integer, nil] target length. If nil, returns clone of array.
      #   @param default [Object, nil] value to replace nil elements with.
      #
      #   @return [Array] processed array of exactly the requested size.
      #
      #   @example Cycling shorter array
      #     using Musa::Extension::Arrayfy
      #     [1, 2].arrayfy(size: 5)  # => [1, 2, 1, 2, 1]
      #
      #   @example Truncating longer array
      #     using Musa::Extension::Arrayfy
      #     [1, 2, 3, 4, 5].arrayfy(size: 3)  # => [1, 2, 3]
      #
      #   @example Preserving dataset modules
      #     using Musa::Extension::Arrayfy
      #     p_sequence = [60, 1, 62].extend(Musa::Datasets::P)
      #     p_sequence.arrayfy(size: 6)  # Result also extended with P
      #
      #   @note The cycling formula: array * (size / array.size + (size % array.size).zero? ? 0 : 1)
      #     ensures enough repetitions to reach target size.
      class ::Array; end

      refine Array do
        def arrayfy(size: nil, default: nil)
          if size
            DeepCopy::DeepCopy.copy_singleton_class_modules(
                self,
                (self * (size / self.size + ((size % self.size).zero? ? 0 : 1) )).take(size))
          else
            self.clone
          end.map! { |value| value.nil? ? default : value }
        end
      end
    end
  end
end
