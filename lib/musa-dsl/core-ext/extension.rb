module Musa
  # Namespace for core Ruby extensions and utilities used throughout Musa DSL.
  #
  # This module contains fundamental extensions and helper modules that enhance
  # Ruby's capabilities for DSL construction and flexible block handling.
  #
  # ## Included Modules
  #
  # - {With} - Flexible DSL block execution with context switching
  # - {SmartProcBinder::SmartProcBinder} - Intelligent parameter binding for Procs
  # - {AttributeBuilder} - DSL-style attribute builder macros
  # - {DynamicProxy::DynamicProxy} - Dynamic method proxying
  #
  # ## Purpose
  #
  # These extensions enable Musa DSL's characteristic features:
  # - Builder pattern with flexible context switching
  # - Method-style and block-style parameter passing
  # - Dynamic method generation for DSL syntax
  # - Intelligent parameter matching and binding
  #
  # ## Design Philosophy
  #
  # The extensions in this module prioritize:
  # - **Flexibility**: Supporting multiple calling conventions
  # - **Transparency**: Minimal interference with normal Ruby behavior
  # - **Reusability**: General-purpose tools used across Musa DSL
  #
  # @example Using With for DSL blocks
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
  #     add :foo  # Executes in Builder's context
  #   end
  #
  # @see With The core DSL block execution module
  # @see SmartProcBinder Intelligent Proc parameter handling
  # @see AttributeBuilder DSL attribute builder macros
  # @see DynamicProxy Dynamic method proxying implementation
  module Extension
  end
end
