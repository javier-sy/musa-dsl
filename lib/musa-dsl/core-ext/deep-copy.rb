require_relative 'extension'

module Musa
  module Extension
    # Module providing deep copy functionality for complex object graphs.
    #
    # DeepCopy implements recursive copying of objects, handling circular references,
    # instance variables, singleton class modules, and various Ruby data structures.
    #
    # ## Features
    #
    # - Handles circular references via object registry
    # - Preserves singleton class modules (dataset extensions) -- with `:clone`
    #   only, since `:dup` drops the singleton class, as it does in plain Ruby
    # - Supports both :dup and :clone methods
    # - Special handling for Arrays, Hashes, Ranges, Structs, Procs
    # - Recursively copies instance variables
    # - Freeze control for :clone, following Object#clone's own three rules
    #   (`true` freezes, `false` does not, `nil` preserves) at every node
    #
    # ## Use Cases
    #
    # - Deep copying musical event structures with complex nesting
    # - Duplicating series configurations without shared state
    # - Preserving dataset module extensions during copy operations
    # - Safe duplication of mutable default values
    #
    # @example Basic deep copy
    #   using Musa::Extension::DeepCopy
    #
    #   original = { items: [1, 2, 3] }
    #   copy = original.dup(deep: true)
    #   copy[:items] << 4
    #   original[:items]  # => [1, 2, 3] (unchanged)
    #
    # @example Preserving modules
    #   event = { pitch: 60 }.extend(Musa::Datasets::AbsI)
    #   event.clone(deep: true).is_a?(Musa::Datasets::AbsI)  # => true
    #   event.dup(deep: true).is_a?(Musa::Datasets::AbsI)    # => false
    #
    #   # A dataset IS a Hash carrying a module, so copying one with :dup
    #   # silently demotes it to a plain Hash. Datasets are copied with :clone.
    #
    # @see Arrayfy Uses deep_copy for preserving modules
    # @see Hashify Uses deep_copy for preserving modules
    #
    # Based on https://github.com/adamluzsi/duplicate.rb/blob/master/lib/duplicate.rb
    #
    # Modifications by Javier Sánchez Yeste
    module DeepCopy
      # Main deep copy module providing class methods.
      module DeepCopy
        extend self

        # Creates a deep copy of an object, recursively copying nested structures.
        #
        # Uses an object registry to handle circular references, ensuring each
        # object is copied only once and all references point to the same copy.
        #
        # @param object [Object] object to copy.
        # @param method [Symbol] :dup or :clone.
        # @param freeze [Boolean, nil] for :clone, whether to freeze the copy.
        #
        # @return [Object] deep copy of the object.
        #
        # @raise [ArgumentError] if method is not :dup or :clone.
        def deep_copy(object, method: :dup, freeze: nil)
          raise ArgumentError, "deep_copy method can only be :dup or :clone" unless method == :dup || method == :clone
          register = {}

          _deep_copy(register, object, method, freeze)
        end

        # Copies singleton class modules from source to target.
        #
        # This is essential for preserving dataset extensions (P, V, AbsI, etc.)
        # when copying musical data structures. Without this, copied objects
        # would lose their dataset behaviors.
        #
        # @param source [Object] object whose singleton modules to copy.
        # @param target [Object] object to receive the modules.
        #
        # @return [Object] target with modules applied.
        #
        # @example Carrying the singleton modules over
        #   source = [60, 100].extend(Musa::Datasets::V)
        #   target = [60, 100]
        #   DeepCopy.copy_singleton_class_modules(source, target)
        #   target.is_a?(Musa::Datasets::V)  # => true
        def copy_singleton_class_modules(source, target)
          source.singleton_class.included_modules.each do |m|
            target.extend m unless target.is_a?(m)
          end

          target
        end

        protected

        # Retrieves a previously registered copy from the registry.
        # @api private
        def registered(object, register)
          register[object.__id__]
        end

        def register(register, object, duplicate)
          register[object.__id__] = duplicate
          duplicate
        end

        def _deep_copy(register, object, method, freeze)
          return registered(object, register) if registered(object, register)
          return register(register, object, object) unless identifiable?(object)

          case object

          when Array
            deep_copy_array(register, object, method, freeze)

          when Hash
            deep_copy_hash(register, object, method, freeze)

          when Range
            deep_copy_range(register, object, method, freeze)

          when Struct
            deep_copy_struct(register, object, method, freeze)

          when Proc
            deep_copy_proc(register, object, method, freeze)

          when NilClass, Symbol, Numeric, TrueClass, FalseClass, Method
            register(register, object, object)

          else
            deep_copy_object(register, object, method, freeze)

          end
        end

        def identifiable?(object)
          object.class && object.respond_to?(:is_a?)
        rescue NoMethodError
          false
        end

        def deep_copy_array(register, object, method, freeze)
          deep_copy_object(register, object, method, freeze) do |_, copy|
            copy.map! { |e| _deep_copy(register, e, method, freeze) }
          end
        end

        def deep_copy_hash(register, object, method, freeze)
          deep_copy_object(register, object, method, freeze) do |object, copy|
            object.reduce(copy) { |hash, (k, v)| hash.merge!(_deep_copy(register, k, method, freeze) => _deep_copy(register, v, method, freeze)) }
          end
        end

        # Ruby's three rules for `clone`, in one place: `true` freezes, `false`
        # does not, and `nil` -- the default -- preserves what the original was.
        # `freeze` travels down the recursion, so each node of the graph is
        # decided by its own original.
        #
        # It is applied at the END of every copier, never at creation. Every
        # copier below fills its copy after it exists -- `merge!` for a Hash,
        # `map!` for an Array, the setters for a Struct -- and a copy frozen at
        # creation cannot be filled at all. Freezing at creation is what made
        # `clone(deep: true, freeze: true)` raise FrozenError for every
        # unfrozen container, which was the whole of issue #75.
        def freeze_as_asked(copy, object, method, freeze)
          copy.freeze if method == :clone && (freeze || (freeze.nil? && object.frozen?))

          copy
        end

        # A copy that can still be written to, whatever the caller asked for.
        # The freezing comes later, through {#freeze_as_asked}.
        def unfrozen_copy(object, method, freeze)
          try_deep_copy(object, method, method == :clone ? false : freeze)
        end

        def deep_copy_range(register, range, method, freeze)
          # exclude_end? is the third thing a Range is made of, and rebuilding
          # without it turned (1...5) into (1..5) on every deep copy.
          copy = range.class.new(_deep_copy(register, range.first, method, freeze),
                                 _deep_copy(register, range.last, method, freeze),
                                 range.exclude_end?)

          # A plain Range is frozen by Ruby the moment it is built, so `false`
          # cannot be honoured for one -- there is nothing to unfreeze it with,
          # and nothing to be gained either, a Range being immutable. Subclasses
          # of Range are NOT born frozen, and for those the rule decides.
          register(register, range, freeze_as_asked(copy, range, method, freeze))
        rescue StandardError
          # Beginless ranges (whose #first raises) and subclasses with a
          # constructor of their own end up here.
          register(register, range, freeze_as_asked(unfrozen_copy(range, method, freeze), range, method, freeze))
        end

        def deep_copy_struct(register, struct, method, freeze)
          duplication = register(register, struct, unfrozen_copy(struct, method, freeze))

          struct.each_pair do |attr, value|
            duplication.__send__("#{attr}=", _deep_copy(register, value, method, freeze))
          end

          freeze_as_asked(duplication, struct, method, freeze)
        end

        def deep_copy_object(register, object, method, freeze)
          copy = unfrozen_copy(object, method, freeze)

          register(register, object, copy)
          deep_copy_instance_variables(register, object, register(register, object, copy), method, freeze)

          yield object, copy if block_given?

          freeze_as_asked(copy, object, method, freeze)
        end

        def deep_copy_proc(register, object, method, freeze)
          if (receiver_dup = registered(object.binding.receiver, register))
            register(register,
                     object,
                     proc do |*args, **kargs|
                       # when the receiver of the proc is also a duplicated object
                       # the new copy of the proc should be the new object, not the original one.
                       #
                       receiver_dup.instance_exec(object, *args, **kargs, &object)
                     end)
          else
            register(register, object, object.dup)
          end
        end

        def deep_copy_instance_variables(register, object, duplication, method, freeze)
          return duplication unless respond_to_instance_variables?(object)

          object.instance_variables.each do |instance_variable|
            value = get_instance_variable(object, instance_variable)

            set_instance_variable(duplication, instance_variable, _deep_copy(register, value, method, freeze))
          end

          duplication
        end

        def get_instance_variable(object, instance_variable_name)
          object.instance_variable_get(instance_variable_name)
        rescue NoMethodError
          object.instance_eval(instance_variable_name.to_s)
        end

        def set_instance_variable(duplicate, instance_variable_name, value_to_set)
          duplicate.instance_variable_set(instance_variable_name, value_to_set)
        rescue NoMethodError
          duplicate.instance_eval("#{instance_variable_name} = Marshal.load(#{Marshal.dump(value_to_set).inspect})")
        end

        def try_deep_copy(object, method, freeze)
          if method == :dup
            object.dup
          else
            object.clone(freeze: freeze)
          end
        rescue NoMethodError, TypeError
          object
        end

        def respond_to_instance_variables?(object)
          object.respond_to?(:instance_variables) && object.instance_variables.is_a?(Array)
        rescue NoMethodError
          false
        end
      end

      # Refinement adding deep copy support to Object#dup and Object#clone.
      #
      # Adds a `deep:` keyword parameter to both methods, enabling easy deep copying
      # without explicit calls to DeepCopy.deep_copy.
      #
      # ## Methods Added
      #
      # ### Object
      # - {Object#dup} - Enhanced dup with optional deep copy
      # - {Object#clone} - Enhanced clone with optional deep copy
      #
      # @!method dup(deep: false)
      #   Enhanced dup with optional deep copy.
      #
      #   @note This method is added to Object via refinement. Requires `using Musa::Extension::DeepCopy`.
      #
      #   @param deep [Boolean] if true, performs deep copy; if false, standard dup.
      #
      #   @return [Object] duplicated object (shallow or deep).
      #
      #   @example Shallow dup (default)
      #     using Musa::Extension::DeepCopy
      #     arr = [[1, 2]]
      #     copy = arr.dup
      #     copy[0] << 3
      #     arr  # => [[1, 2, 3]] (inner array shared)
      #
      #   @example Deep dup
      #     using Musa::Extension::DeepCopy
      #     arr = [[1, 2]]
      #     copy = arr.dup(deep: true)
      #     copy[0] << 3
      #     arr  # => [[1, 2]] (inner array independent)
      class ::Object; end

      # @!method clone(freeze: nil, deep: false)
      #   Enhanced clone with optional deep copy.
      #
      #   @note This method is added to Object via refinement. Requires `using Musa::Extension::DeepCopy`.
      #
      #   @param freeze [Boolean, nil] whether to freeze the clone.
      #   @param deep [Boolean] if true, performs deep copy; if false, standard clone.
      #
      #   @return [Object] cloned object (shallow or deep).
      #
      #   Unlike `:dup`, a deep `:clone` preserves the modules an object has been
      #   extended with, which is why datasets are copied with it.
      #
      #   Freezing follows `Object#clone`'s three rules, applied to every node of
      #   the graph rather than just the top one: `true` freezes, `false` does
      #   not, and the default `nil` gives each copy the frozen state its own
      #   original had.
      #
      #   @example Deep clone
      #     using Musa::Extension::DeepCopy
      #     hash = { nested: { value: 1 } }
      #     copy = hash.clone(deep: true)
      #     copy[:nested].equal?(hash[:nested])  # => false
      #     copy[:nested][:value] = 2
      #     hash[:nested][:value]  # => 1
      #
      #   @example freeze: true freezes the whole copy, all the way down
      #     using Musa::Extension::DeepCopy
      #     copy = { nested: { value: 1 } }.clone(deep: true, freeze: true)
      #     copy.frozen?           # => true
      #     copy[:nested].frozen?  # => true
      #
      #   @example By default each node keeps the state its own original had
      #     using Musa::Extension::DeepCopy
      #     original = { constant: { name: 'white' }.freeze, mutable: [1] }
      #     copy = original.clone(deep: true)
      #     copy.frozen?             # => false
      #     copy[:constant].frozen?  # => true
      #     copy[:mutable].frozen?   # => false
      #
      #     # Which is what `clone` means in Ruby. `dup` is the one that hands
      #     # back everything unfrozen.
      class ::Object; end

      refine Object do
        def dup(deep: false)
          if deep
            Musa::Extension::DeepCopy::DeepCopy.deep_copy(self, method: :dup)
          else
            super()
          end
        end

        def clone(freeze: nil, deep: false)
          if deep
            Musa::Extension::DeepCopy::DeepCopy.deep_copy(self, method: :clone, freeze: freeze)
          else
            super(freeze: freeze)
          end
        end
      end
    end
  end
end

