require_relative '../core-ext/smart-proc-binder'
require_relative '../core-ext/arrayfy'
require_relative '../core-ext/with'

# TODO: permitir definir un variatio a través de llamadas a métodos y/o atributos, además de a través del block del constructor

module Musa
  module Variatio
    using Musa::Extension::Arrayfy
    using Musa::Extension::ExplodeRanges

    class Variatio
      def initialize(instance_name, &block)
        raise ArgumentError, 'instance_name should be a symbol' unless instance_name.is_a?(Symbol)
        raise ArgumentError, 'block is needed' unless block

        @instance_name = instance_name

        main_context = MainContext.new &block

        @constructor = main_context._constructor
        @fieldset = main_context._fieldset
        @finalize = main_context._finalize
      end

      def on(**values)
        constructor_binder = Musa::Extension::SmartProcBinder::SmartProcBinder.new @constructor
        finalize_binder = Musa::Extension::SmartProcBinder::SmartProcBinder.new @finalize if @finalize

        run_fieldset = @fieldset.clone # TODO: verificar que esto no da problemas

        run_fieldset.components.each do |component|
          if values.key? component.name
            component.options = values[component.name].arrayfy.explode_ranges
          end
        end

        tree_A = generate_eval_tree_A run_fieldset
        tree_B = generate_eval_tree_B run_fieldset

        parameters_set = tree_A.calc_parameters

        combinations = []

        parameters_set.each do |parameters_with_depth|
          instance = @constructor.call **(constructor_binder._apply(nil, parameters_with_depth).last)

          tree_B.run parameters_with_depth, @instance_name => instance

          if @finalize
            finalize_parameters = finalize_binder._apply(nil, parameters_with_depth).last
            finalize_parameters[@instance_name] = instance

            @finalize.call **finalize_parameters
          end

          combinations << instance
        end

        combinations
      end

      def run
        on
      end

      module Helper
        module_function

        def list_of_hashes_product(list_of_hashes_1, list_of_hashes_2)
          result = []

          list_of_hashes_1.each do |hash1|
            list_of_hashes_2.each do |hash2|
              result << hash1.merge(hash2)
            end
          end

          result
        end
      end

      private_constant :Helper

      private

      def generate_eval_tree_A(fieldset)
        root = nil
        current = nil

        fieldset.components.each do |component|
          if component.is_a? Field
            a = A1.new component.name, component.options
          elsif component.is_a? Fieldset
            a = A2.new component.name, component.options, generate_eval_tree_A(component)
          end

          current.inner = a if current
          root ||= a

          current = a
        end

        root
      end

      def generate_eval_tree_B(fieldset)
        affected_field_names = []
        inner = []

        fieldset.components.each do |component|
          if component.is_a? Fieldset
            inner << generate_eval_tree_B(component)
          elsif component.is_a? Field
            affected_field_names << component.name
          end
        end

        B.new fieldset.name, fieldset.options, affected_field_names, inner, fieldset.with_attributes
      end

      class A
        attr_reader :parameter_name, :options
        attr_accessor :inner

        def initialize(parameter_name, options)
          @parameter_name = parameter_name
          @options = options
          @inner = nil
        end

        def calc_parameters
          unless @calc_parameters
            if inner
              @calc_parameters = Helper.list_of_hashes_product(calc_own_parameters, @inner.calc_parameters)
            else
              @calc_parameters = calc_own_parameters
            end
          end

          @calc_parameters
        end
      end

      private_constant :A

      class A1 < A
        def initialize(parameter_name, options)
          super parameter_name, options

          @own_parameters = @options.collect { |option| { @parameter_name => option } }
        end

        def calc_own_parameters
          @own_parameters
        end

        def inspect
          "A1 name: #{@parameter_name}, options: #{@options}, inner: #{@inner || 'nil'}"
        end

        alias to_s inspect
      end

      private_constant :A1

      class A2 < A
        def initialize(parameter_name, options, subcomponent)
          super parameter_name, options

          @subcomponent = subcomponent

          sub_parameters_set = @subcomponent.calc_parameters
          result = nil

          @options.each do |option|
            if result.nil?
              result = sub_parameters_set.collect { |v| { option => v } }
            else
              result = Helper.list_of_hashes_product result, sub_parameters_set.collect { |v| { option => v } }
            end
          end

          result = result.collect { |v| { @parameter_name => v } }

          @own_parameters = result
        end

        def calc_own_parameters
          @own_parameters
        end

        def inspect
          "A2 name: #{@parameter_name}, options: #{@options}, subcomponent: #{@subcomponent}, inner: #{@inner || 'nil'}"
        end

        alias to_s inspect
      end

      private_constant :A2

      class B
        attr_reader :parameter_name, :options, :affected_field_names, :blocks, :inner

        def initialize(parameter_name, options, affected_field_names, inner, blocks)
          @parameter_name = parameter_name
          @options = options
          @affected_field_names = affected_field_names
          @inner = inner

          @procedures = blocks.collect { |proc| Musa::Extension::SmartProcBinder::SmartProcBinder.new proc }
        end

        def run(parameters_with_depth, parent_parameters = nil)
          parent_parameters ||= {}

          @options.each do |option|
            base = @parameter_name == :_maincontext ? parameters_with_depth : parameters_with_depth[@parameter_name][option]

            parameters = base.select { |k, _v| @affected_field_names.include? k }.merge(parent_parameters)
            parameters[@parameter_name] = option

            @procedures.each do |procedure_binder|
              procedure_binder.call **parameters
            end

            if @parameter_name == :_maincontext
              @inner.each do |inner|
                inner.run parameters_with_depth, parameters
              end
            else
              @inner.each do |inner|
                inner.run parameters_with_depth[@parameter_name][option], parameters
              end
            end
          end
        end

        def inspect
          "B name: #{@parameter_name}, options: #{@options}, affected_field_names: #{@affected_field_names}, blocks_size: #{@blocks.size}, inner: #{@inner}"
        end

        alias to_s inspect

        private
      end

      class FieldsetContext
        include Musa::Extension::With

        attr_reader :_fieldset

        def initialize(name, options = nil, &block)
          @_fieldset = Fieldset.new name, options.arrayfy.explode_ranges

          with &block
        end

        def field(name, options = nil)
          @_fieldset.components << Field.new(name, options.arrayfy.explode_ranges)
        end

        def fieldset(name, options = nil, &block)
          fieldset_context = FieldsetContext.new name, options, &block
          @_fieldset.components << fieldset_context._fieldset
        end

        def with_attributes(&block)
          @_fieldset.with_attributes << block
        end
      end

      private_constant :FieldsetContext

      class MainContext < FieldsetContext
        attr_reader :_constructor, :_finalize

        def initialize(&block)
          @_constructor = nil
          @_finalize = nil

          super :_maincontext, [nil], &block
        end

        def constructor(&block)
          @_constructor = block
        end

        def finalize(&block)
          @_finalize = block
        end
      end

      private_constant :MainContext

      class Field
        attr_reader :name
        attr_accessor :options

        def inspect
          "Field #{@name} options: #{@options}"
        end

        alias to_s inspect

        private

        def initialize(name, options)
          @name = name
          @options = options
        end
      end

      private_constant :Field

      class Fieldset
        attr_reader :name, :with_attributes, :components
        attr_accessor :options

        def inspect
          "Fieldset #{@name} options: #{@options} components: #{@components}"
        end

        alias to_s inspect

        private

        def initialize(name, options)
          @name = name
          @options = options || [nil]
          @components = []
          @with_attributes = []
        end
      end

      private_constant :Fieldset
    end
  end
end
