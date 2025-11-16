require_relative '../core-ext/smart-proc-binder'
require_relative '../core-ext/arrayfy'
require_relative '../core-ext/with'

# Combinatorial variation generator with Cartesian product.
#
# Variatio generates all possible combinations of parameter values across
# defined fields, creating comprehensive variation sets. Uses Cartesian
# product to produce exhaustive parameter combinations, then constructs
# objects and applies attribute modifications.
#
# ## Core Concepts
#
# - **Fields**: Named parameters with option sets
# - **Fieldsets**: Nested field groups with their own options
# - **Constructor**: Creates base objects from field values
# - **with_attributes**: Modifies objects with field/fieldset values
# - **Finalize**: Post-processes completed objects
# - **Variations**: All Cartesian product combinations
#
# ## Generation Process
#
# 1. **Define**: Specify fields, fieldsets, constructor, attributes, finalize
# 2. **Combine**: Calculate Cartesian product of all field options
# 3. **Construct**: Create objects using constructor with each combination
# 4. **Attribute**: Apply with_attributes blocks for each combination
# 5. **Finalize**: Run finalize block on completed objects
# 6. **Return**: Array of all generated variations
#
# ## Musical Applications
#
# - Generate all variations of a musical motif
# - Create comprehensive parameter sweeps for synthesis
# - Produce complete harmonic permutations
# - Build exhaustive rhythm pattern combinations
#
# @example Basic field variations
#   variatio = Musa::Variatio::Variatio.new :chord do
#     field :root, [60, 64, 67]     # C, E, G
#     field :type, [:major, :minor]
#
#     constructor do |root:, type:|
#       { root: root, type: type }
#     end
#   end
#
#   variations = variatio.run
#   # => [
#   #   { root: 60, type: :major },
#   #   { root: 60, type: :minor },
#   #   { root: 64, type: :major },
#   #   { root: 64, type: :minor },
#   #   { root: 67, type: :major },
#   #   { root: 67, type: :minor }
#   # ]
#   # 3 roots × 2 types = 6 variations
#
# @example Override field options at runtime
#   variatio = Musa::Variatio::Variatio.new :object do
#     field :a, 1..10
#     field :b, [:alfa, :beta, :gamma]
#
#     constructor { |a:, b:| { a: a, b: b } }
#   end
#
#   # Override :a to limit variations
#   variatio.on(a: 1..3)
#   # => 3 × 3 = 9 variations instead of 10 × 3 = 30
#
# @example Nested fieldsets with attributes
#   variatio = Musa::Variatio::Variatio.new :synth do
#     field :wave, [:saw, :square]
#     field :cutoff, [500, 1000, 2000]
#
#     constructor do |wave:, cutoff:|
#       { wave: wave, cutoff: cutoff, lfo: {} }
#     end
#
#     # Nested fieldset for LFO parameters
#     fieldset :lfo, [:vibrato, :tremolo] do
#       field :rate, [4, 8]
#       field :depth, [0.1, 0.5]
#
#       with_attributes do |synth:, lfo:, rate:, depth:|
#         synth[:lfo][lfo] = { rate: rate, depth: depth }
#       end
#     end
#   end
#
#   variations = variatio.run
#   # => 2 waves × 3 cutoffs × 2 lfo types × 2 rates × 2 depths = 48 variations
#
# @example With finalize block
#   variatio = Musa::Variatio::Variatio.new :note do
#     field :pitch, [60, 62, 64]
#     field :velocity, [64, 96, 127]
#
#     constructor { |pitch:, velocity:| { pitch: pitch, velocity: velocity } }
#
#     finalize do |note:|
#       note[:loudness] = note[:velocity] / 127.0
#       note[:dynamics] = case note[:velocity]
#         when 0..48 then :pp
#         when 49..80 then :mf
#         else :ff
#       end
#     end
#   end
#
# @see https://en.wikipedia.org/wiki/Cartesian_product Cartesian product (Wikipedia)
# @see https://en.wikipedia.org/wiki/Variation_(mathematics) Variation in mathematics (Wikipedia)
#
# # TODO: permitir definir un variatio a través de llamadas a métodos y/o atributos, además de a través del block del constructor

module Musa
  # Combinatorial variation generator using Cartesian product.
  #
  # Contains the {Variatio} class for generating all possible combinations
  # of parameter values across defined fields and fieldsets. Creates objects
  # from each combination, applies attributes, and optionally finalizes.
  #
  # @see Variatio Main combinatorial variation generator class
  module Variatio
    using Musa::Extension::Arrayfy
    using Musa::Extension::ExplodeRanges

    # Combinatorial variation generator.
    #
    # Generates all combinations of field values using Cartesian product,
    # constructs objects, applies attributes, and optionally finalizes.
    class Variatio
      # Creates variation generator with field definitions.
      #
      # @param instance_name [Symbol] name for object parameter in blocks
      #
      # @yield DSL block defining fields, constructor, attributes, finalize
      # @yieldreturn [void]
      #
      # @raise [ArgumentError] if instance_name not a symbol
      # @raise [ArgumentError] if no block given
      #
      # @example
      #   variatio = Variatio.new :obj do
      #     field :x, [1, 2, 3]
      #     field :y, [:a, :b]
      #     constructor { |x:, y:| { x: x, y: y } }
      #   end
      def initialize(instance_name, &block)
        raise ArgumentError, 'instance_name should be a symbol' unless instance_name.is_a?(Symbol)
        raise ArgumentError, 'block is needed' unless block

        @instance_name = instance_name

        main_context = MainContext.new &block

        @constructor = main_context._constructor
        @fieldset = main_context._fieldset
        @finalize = main_context._finalize
      end

      # Generates variations with runtime field value overrides.
      #
      # Allows overriding field options at generation time, useful for
      # limiting variation space or parameterizing generation.
      #
      # @param values [Hash{Symbol => Array, Range}] field overrides
      #   Keys are field names, values are option arrays or ranges
      #
      # @return [Array] all generated variation objects
      #
      # @example Override field values
      #   variatio = Variatio.new :obj do
      #     field :x, 1..10
      #     field :y, [:a, :b, :c]
      #     constructor { |x:, y:| { x: x, y: y } }
      #   end
      #
      #   # Default: 10 × 3 = 30 variations
      #   variatio.run.size  # => 30
      #
      #   # Override :x to limit variations
      #   variatio.on(x: 1..3).size  # => 3 × 3 = 9
      #   variatio.on(x: [5], y: [:a]).size  # => 1 × 1 = 1
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

      # Generates all variations with default field values.
      #
      # Equivalent to calling {#on} with no overrides.
      #
      # @return [Array] all generated variation objects
      #
      # @example
      #   variatio = Variatio.new :obj do
      #     field :x, [1, 2, 3]
      #     field :y, [:a, :b]
      #     constructor { |x:, y:| { x: x, y: y } }
      #   end
      #
      #   variations = variatio.run
      #   # => [
      #   #   { x: 1, y: :a }, { x: 1, y: :b },
      #   #   { x: 2, y: :a }, { x: 2, y: :b },
      #   #   { x: 3, y: :a }, { x: 3, y: :b }
      #   # ]
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

      # Internal tree node for attribute application phase.
      #
      # Manages execution of `with_attributes` blocks during variation generation.
      # Coordinates attribute application across field hierarchy.
      #
      # @api private
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

      # DSL context for fieldset definition.
      #
      # @api private
      class FieldsetContext
        include Musa::Extension::With

        # @return [Fieldset] defined fieldset
        attr_reader :_fieldset

        # @api private
        def initialize(name, options = nil, &block)
          @_fieldset = Fieldset.new name, options.arrayfy.explode_ranges

          with &block
        end

        # Defines a field with options.
        #
        # @param name [Symbol] field name
        # @param options [Array, Range, nil] field option values
        # @api private
        def field(name, options = nil)
          @_fieldset.components << Field.new(name, options.arrayfy.explode_ranges)
        end

        # Defines nested fieldset.
        #
        # @param name [Symbol] fieldset name
        # @param options [Array, Range, nil] fieldset option values
        # @yield fieldset DSL block
        # @api private
        def fieldset(name, options = nil, &block)
          fieldset_context = FieldsetContext.new name, options, &block
          @_fieldset.components << fieldset_context._fieldset
        end

        # Adds attribute modification block.
        #
        # @yield attribute modification block
        # @api private
        def with_attributes(&block)
          @_fieldset.with_attributes << block
        end
      end

      private_constant :FieldsetContext

      # DSL context for main Variatio configuration.
      #
      # @api private
      class MainContext < FieldsetContext
        # @return [Proc] constructor block
        # @return [Proc, nil] finalize block
        attr_reader :_constructor, :_finalize

        # @api private
        def initialize(&block)
          @_constructor = nil
          @_finalize = nil

          super :_maincontext, [nil], &block
        end

        # Defines object constructor.
        #
        # @yield constructor block receiving field values
        # @api private
        def constructor(&block)
          @_constructor = block
        end

        # Defines finalize block.
        #
        # @yield finalize block receiving completed object
        # @api private
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
