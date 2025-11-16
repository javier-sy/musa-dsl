require_relative 'smart-proc-binder'

module Musa
  module Extension
    # Module providing the `with` method for flexible DSL block execution.
    #
    # The `with` method is a cornerstone of Musa DSL's builder pattern, allowing
    # objects to execute blocks in either the object's context (for DSL-style
    # configuration) or the caller's context (for traditional Ruby blocks).
    #
    # ## Context Switching Logic
    #
    # The method intelligently determines which context to use based on:
    # 1. The `keep_block_context` parameter (explicit control)
    # 2. Block parameters (implicit control via `_` parameter)
    # 3. Whether parameters are passed to the block
    #
    # ## Modes of Operation
    #
    # - **DSL mode** (`instance_eval`): Block executes in object's context
    #   - Used when: no parameters, no `keep_block_context`, no `_` parameter
    #   - Enables: direct access to object's instance variables and methods
    #
    # - **Caller context mode** (`call` with self as `_`): Block keeps its context
    #   - Used when: block has `_` parameter, or `keep_block_context: true`
    #   - Enables: access to both contexts (object via `_`, caller's scope naturally)
    #
    # - **Hybrid mode** (`instance_exec`): Block in object context with parameters
    #   - Used when: parameters provided but `keep_block_context` not set
    #   - Enables: DSL-style access plus explicit parameters
    #
    # ## Use Cases
    #
    # - Builder pattern DSL methods
    # - Configuration blocks that need object context
    # - Flexible API supporting both DSL and traditional Ruby styles
    # - Initializers that configure objects via blocks
    #
    # @example DSL mode (instance_eval)
    #   class Builder
    #     include Musa::Extension::With
    #
    #     def initialize(&block)
    #       @items = []
    #       with(&block) if block
    #     end
    #
    #     def add(item)
    #       @items << item
    #     end
    #   end
    #
    #   builder = Builder.new do
    #     add :foo
    #     add :bar
    #   end
    #   # Block has direct access to #add method
    #
    # @example Caller context with _ parameter
    #   external_var = 42
    #
    #   Builder.new do |_|
    #     _.add :foo
    #     puts external_var  # Can access caller's variables
    #   end
    #   # Block keeps caller's context, object accessed via _
    #
    # @example With parameters
    #   class Builder
    #     def initialize(name, &block)
    #       @name = name
    #       with(name, &block) if block
    #     end
    #   end
    #
    #   Builder.new('test') do |name|
    #     # Has access to object's context AND receives name parameter
    #     puts @name  # Works
    #     puts name   # Also works
    #   end
    #
    # @example Explicit keep_block_context
    #   Builder.new do |obj|
    #     obj.add :item
    #     # Block explicitly keeps caller's context
    #   end
    #
    # @see SmartProcBinder Used internally for parameter management
    # @see Musa::Datasets DSL builder methods use this extensively
    module With
      # Executes a block with flexible context and parameter handling.
      #
      # @param value_parameters [Array] positional parameters to pass to block.
      # @param keep_block_context [Boolean, nil] explicit control of context switching:
      #   - `true`: always keep caller's context
      #   - `false`: always use object's context
      #   - `nil`: auto-detect based on `_` parameter
      # @param key_parameters [Hash] keyword parameters to pass to block.
      # @param block [Proc] block to execute.
      #
      # @return [Object] result of block execution.
      #
      # @note The `_` parameter is special: when present, it signals "keep caller's context"
      #   and receives `self` (the object) as its value.
      # @note Uses SmartProcBinder internally to handle parameter matching.
      def with(*value_parameters, keep_block_context: nil, **key_parameters, &block)
        # Wrap block in SmartProcBinder for parameter introspection and management
        smart_block = Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)

        # Check if first parameter is _ (underscore), which signals "keep caller's context"
        send_self_as_underscore_parameter = smart_block.parameters[0][1] == :_ unless smart_block.parameters.empty?

        # Determine effective context mode:
        # 1. Use explicit keep_block_context if provided
        # 2. Otherwise, use _ parameter presence as signal
        # 3. Default to false (use object's context)
        effective_keep_block_context = keep_block_context
        effective_keep_block_context = send_self_as_underscore_parameter if effective_keep_block_context.nil?
        effective_keep_block_context = false if effective_keep_block_context.nil?

        # Match provided parameters to block's expected parameters
        effective_value_parameters, effective_key_parameters = smart_block._apply(value_parameters, key_parameters)

        # Execute block in appropriate context
        if effective_keep_block_context
          # Keep caller's context: call block normally
          if send_self_as_underscore_parameter
            # Pass self as first parameter (the _ parameter)
            smart_block.call(self, *effective_value_parameters, **effective_key_parameters)
          else
            # Just pass the effective parameters
            smart_block.call(*effective_value_parameters, **effective_key_parameters)
          end
        elsif effective_value_parameters.empty? && effective_key_parameters.empty?
          # DSL mode: no parameters, execute in object's context
          instance_eval &block
        else
          # Hybrid mode: execute in object's context with parameters
          instance_exec *effective_value_parameters, **effective_key_parameters, &block
        end
      end
    end
  end
end
