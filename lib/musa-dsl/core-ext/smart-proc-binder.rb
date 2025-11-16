module Musa
  module Extension
    # Module providing smart parameter binding for Proc objects.
    #
    # SmartProcBinder analyzes a Proc's parameter signature and intelligently
    # matches provided arguments to expected parameters, handling both positional
    # and keyword arguments with proper rest parameter support.
    #
    # @see Musa::Extension::With Uses SmartProcBinder for parameter management
    module SmartProcBinder
      # Wrapper for Proc objects that provides intelligent parameter matching and binding.
      #
      # This class introspects a Proc's parameter list and provides methods to:
      # - Determine which parameters the Proc accepts
      # - Filter provided arguments to match the Proc's signature
      # - Call the Proc with properly matched arguments
      # - Optionally rescue and handle exceptions
      #
      # ## Parameter Types Handled
      #
      # - **:req, :opt**: Required and optional positional parameters
      # - **:rest**: Splat parameter (*args)
      # - **:key, :keyreq**: Optional and required keyword parameters
      # - **:keyrest**: Double splat parameter (**kwargs)
      #
      # ## Use Cases
      #
      # - DSL methods that need flexible parameter passing
      # - Builder patterns with variable block signatures
      # - Wrapper methods that forward arguments intelligently
      # - Error handling for DSL block execution
      #
      # @example Basic usage
      #   block = proc { |a, b, c:| [a, b, c] }
      #   binder = SmartProcBinder.new(block)
      #
      #   binder.call(1, 2, 3, 4, c: 5, d: 6)
      #   # => [1, 2, 5]
      #   # Only passes parameters that match signature
      #
      # @example With rescue handling
      #   error_handler = proc { |e| puts "Error: #{e.message}" }
      #   binder = SmartProcBinder.new(block, on_rescue: error_handler)
      #
      #   binder.call(invalid_args)  # Calls error_handler instead of raising
      #
      # @example Checking parameter support
      #   binder.key?(:pitch)  # => true/false
      #   binder.has_key?(:velocity)  # => true/false
      class SmartProcBinder
        # Creates a new SmartProcBinder wrapping the given block.
        #
        # Introspects the block's parameters and categorizes them for later matching.
        #
        # @param block [Proc] the proc/block to wrap.
        # @param on_rescue [Proc, nil] optional error handler called with exception
        #   if block execution fails.
        def initialize(block, on_rescue: nil)
          @block = block
          @on_rescue = on_rescue

          # Track keyword parameters by name
          @key_parameters = {}
          @has_key_rest = false

          # Track positional parameter count
          @value_parameters_count = 0
          @has_value_rest = false

          # Introspect block's parameter signature
          block.parameters.each do |parameter|
            @key_parameters[parameter[1]] = nil if parameter[0] == :key || parameter[0] == :keyreq
            @has_key_rest = true if parameter[0] == :keyrest

            @value_parameters_count += 1 if parameter[0] == :req || parameter[0] == :opt
            @has_value_rest = true if parameter[0] == :rest
          end
        end

        # Returns the wrapped Proc.
        #
        # @return [Proc] the original block.
        def proc
          @block
        end

        # Returns the parameter signature of the wrapped Proc.
        #
        # @return [Array<Array>] array of [type, name] pairs describing parameters.
        # @example
        #   proc { |a, b, c:| }.parameters  # => [[:req, :a], [:req, :b], [:key, :c]]
        def parameters
          @block.parameters
        end

        # Calls the wrapped Proc with smart parameter matching.
        #
        # @param value_parameters [Array] positional arguments.
        # @param key_parameters [Hash] keyword arguments.
        # @param block [Proc, nil] block to pass to wrapped Proc.
        #
        # @return [Object] result of calling the wrapped Proc.
        def call(*value_parameters, **key_parameters, &block)
          _call value_parameters, key_parameters, block
        end

        # Internal call implementation with error handling.
        #
        # @api private
        def _call(value_parameters, key_parameters = {}, block = nil)
          if @on_rescue
            begin
              __call value_parameters, key_parameters, block
            rescue StandardError, ScriptError => e
              @on_rescue.call e
            end
          else
            __call value_parameters, key_parameters, block
          end
        end

        private def __call(value_parameters, key_parameters = {}, block = nil)
          effective_value_parameters, effective_key_parameters = apply(*value_parameters, **key_parameters)

          if effective_key_parameters.empty?
            if effective_value_parameters.empty?
              @block.call(&block)
            else
              @block.call(*effective_value_parameters, &block)
            end
          else
            if effective_value_parameters.empty?
              @block.call(**effective_key_parameters, &block)
            else
              @block.call(*effective_value_parameters, **effective_key_parameters, &block)
            end
          end
        end

        # Checks if the wrapped Proc accepts a specific keyword parameter.
        #
        # Returns true if the Proc has a keyword parameter with the given name,
        # or if it has a **kwargs rest parameter that accepts any keyword.
        #
        # @param key [Symbol] keyword parameter name to check.
        #
        # @return [Boolean] true if key is accepted, false otherwise.
        #
        # @example
        #   proc { |a:, b:, **rest| }.key?(:a)       # => true
        #   proc { |a:, b:, **rest| }.key?(:unknown) # => true (has **rest)
        #   proc { |a:, b:| }.key?(:unknown)         # => false
        def key?(key)
          @has_key_rest || @key_parameters.include?(key)
        end

        alias_method :has_key?, :key?

        # Filters arguments to match the Proc's signature.
        #
        # @param value_parameters [Array] positional arguments to filter.
        # @param key_parameters [Hash] keyword arguments to filter.
        #
        # @return [Array<Array, Hash>] tuple of [filtered_positionals, filtered_keywords].
        def apply(*value_parameters, **key_parameters)
          _apply(value_parameters, key_parameters)
        end

        # Internal implementation of argument filtering.
        #
        # Logic:
        # - Positional: takes first N values (or all if *rest present)
        # - Keywords: includes only expected keys (or all if **rest present)
        # - Pads positional with nils if needed
        #
        # @api private
        def _apply(value_parameters, key_parameters)
          value_parameters ||= []
          key_parameters ||= {}

          if @has_value_rest
            values_result = value_parameters.clone
          else
            values_result = value_parameters.first(@value_parameters_count)
            values_result += Array.new(@value_parameters_count - values_result.size)
          end

          hash_result = @key_parameters.clone

          @key_parameters.each_key do |parameter_name|
            hash_result[parameter_name] = key_parameters[parameter_name]
          end

          if @has_key_rest
            key_parameters.each do |key, value|
              hash_result[key] = value unless hash_result.key?(key)
            end
          end

          return values_result, hash_result
        end

        def inspect
          "SmartProcBinder: parameters = #{parameters} key_parameters = #{@key_parameters} has_rest = #{@has_key_rest}"
        end

        alias to_s inspect
      end
    end
  end
end
