require_relative 'base-series'

require_relative '../core-ext/with'
require_relative '../core-ext/arrayfy'

module Musa
  module Series
    module Operations
      # Creates a composer transformation pipeline for complex multi-stage transformations.
      #
      # Composer provides declarative DSL for building transformation pipelines
      # with multiple inputs, outputs, and intermediate processing stages.
      #
      # ## Composer Concepts
      #
      # - **Pipelines**: Named transformation chains
      # - **Inputs**: Named input series (proxied and buffered)
      # - **Outputs**: Named output series
      # - **Operations**: Transformation steps in pipeline
      # - **Auto-commit**: Automatic finalization of pipelines
      #
      # ## DSL Structure
      #
      # ```ruby
      # composer do
      #   input_name >> operation1 >> operation2 >> :output_name
      #   :other_input >> transform >> :other_output
      # end
      # ```
      #
      # ## Musical Applications
      #
      # - Complex multi-voice processing
      # - Effect chains and routing
      # - Algorithmic composition pipelines
      # - Multi-stage transformations
      # - Modular synthesis-style routing
      #
      # @example Basic composer
      #   s = S(1, 2, 3).composer do
      #     input.map { |x| x * 2 } >> :output
      #   end
      #   s.i.to_a  # => [2, 4, 6]
      #
      # @example Multi-pipeline
      #   composer = Composer.new(input: S(1, 2, 3)) do
      #     input.map { |x| x * 2 } >> :doubled
      #     input.map { |x| x * 3 } >> :tripled
      #   end
      #   composer.output(:doubled).i.to_a  # => [2, 4, 6]
      #   composer.output(:tripled).i.to_a  # => [3, 6, 9]
      #
      # @yield composer DSL block
      #
      # @return [ComposerAsOperationSerie] composed serie
      #
      # @example Simple transformation
      #   s.composer do
      #     input.map { |x| x + 1 } >> :output
      #   end
      #
      # @api public
      def composer(&block)
        ComposerAsOperationSerie.new(self, &block)
      end

      # Wrapper that exposes Composer as a serie operation.
      #
      # Allows {Composer::Composer} pipelines to be used as standard serie
      # operations. The composer takes input from the source serie, processes
      # it through the configured pipeline, and outputs transformed values.
      #
      # This enables complex multi-input/output serie transformations to
      # be used in serie operation chains.
      #
      # @example Using composer as operation
      #   serie = FromArray.new([1, 2, 3, 4])
      #   transformed = serie.composer do
      #     # Composer pipeline configuration
      #     pipeline { |v| v * 2 }
      #   end
      #   transformed.next_value  # => 2
      #
      # @see Composer::Composer Full composer implementation
      # @api private
      class ComposerAsOperationSerie
        include Musa::Series::Serie.with(source: true)

        def initialize(serie, &block)
          self.source = serie
          @block = block

          init
        end

        attr_reader :composer

        private def _init
          @composer = Composer::Composer.new(input: @source, &@block)
          @output = @composer.output
        end

        private def _restart
          @output.restart
        end

        private def _next_value
          @output.next_value
        end
      end
    end

    # Series composition and transformation pipeline system.
    #
    # Provides infrastructure for building complex multi-input/output
    # transformation pipelines with named routes, intermediate stages,
    # and declarative DSL syntax.
    #
    # The Composer system enables modular, synthesis-style routing of
    # serie transformations with explicit input/output management.
    #
    # @see Composer::Composer Main composer implementation
    # @see ComposerAsOperationSerie Composer as serie operation
    module Composer
      # Multi-input/output serie transformation pipeline system.
      #
      # Composer enables building complex transformation graphs with multiple named
      # inputs, outputs, and intermediate processing stages. It provides a declarative
      # DSL for defining pipelines and routing data between them, similar to modular
      # synthesis patch routing.
      #
      # ## Architecture
      #
      # The Composer system consists of:
      #
      # - **Pipelines**: Named transformation stages that process series
      # - **Routes**: Connections between pipelines specifying data flow
      # - **Inputs**: Named entry points (automatically proxied and buffered)
      # - **Outputs**: Named exit points for consuming results
      # - **DSL Context**: method_missing-based interface for pipeline definition
      #
      # ## Pipeline Definition
      #
      # Pipelines are defined using method calls in the DSL block. Each pipeline
      # consists of:
      #
      # - **Constructor** (optional): Series constructor like `S`, `H`, etc.
      # - **Operations** (one or more): Transformations like `reverse`, `skip`, etc.
      #
      # @example Pipeline with constructor
      #   composer = Composer.new(inputs: nil) do
      #     my_pipeline ({ S: [1, 2, 3] }), reverse, { skip: 1 }
      #     route my_pipeline, to: output
      #   end
      #   composer.output.i.to_a  # => [2, 1]
      #   # Creates: S([1,2,3]) → reverse → skip(1)
      #
      # @example Pipeline with operations only
      #   composer = Composer.new(input: S(1, 2, 3)) do
      #     my_pipeline reverse, { skip: 1 }
      #     route input, to: my_pipeline
      #     route my_pipeline, to: output
      #   end
      #   composer.output.i.to_a  # => [2, 1]
      #   # Applies: input → reverse → skip(1)
      #
      # ## Routing System
      #
      # Routes connect pipelines using the `route` method:
      #
      # ```ruby
      # route from_pipeline, to: to_pipeline, on: :source, as: :key
      # ```
      #
      # **Routing modes:**
      #
      # 1. **Hash assignment** (when `as:` provided):
      # 
      #    - Data is assigned to: `to_pipeline.input[on][as] = from_pipeline.output`
      #    - Used by operations accepting hash inputs (e.g., `H` constructor)
      #    - Default `on` is `:sources` when `as` is provided
      #
      # 2. **Setter method** (when `as:` omitted):
      # 
      #    - Calls: `to_pipeline.input.source = from_pipeline.output`
      #    - Used by operations with explicit source setters
      #    - Default `on` is `:source` when `as` is omitted
      #
      # @example Hash routing
      #   composer = Composer.new(inputs: [:a, :b], auto_commit: false) do
      #     step1 reverse
      #     step2 reverse
      #     hash_merge ({ H: {} })
      #
      #     route a, to: step1
      #     route b, to: step2
      #     route step1, to: hash_merge, as: :x    # hash_merge.input[:sources][:x] = step1.output
      #     route step2, to: hash_merge, as: :y    # hash_merge.input[:sources][:y] = step2.output
      #     route hash_merge, to: output
      #   end
      #
      #   composer.input(:a).proxy_source = S(1, 2, 3)
      #   composer.input(:b).proxy_source = S(10, 20, 30)
      #   composer.commit!
      #   composer.output.i.to_a  # => [{x: 3, y: 30}, {x: 2, y: 20}, {x: 1, y: 10}]
      #
      # @example Setter routing
      #   composer = Composer.new(input: S(1, 2, 3)) do
      #     step1 reverse
      #     route input, to: step1            # step1.input.source = input.output
      #     route step1, to: output
      #   end
      #
      #   composer.output.i.to_a  # => [3, 2, 1]
      #
      # ## Commit System
      #
      # Composer uses two-phase initialization:
      #
      # 1. **Definition phase**: Routes and pipelines are declared
      # 2. **Commit phase**: All connections are resolved and finalized
      #
      # **Key behaviors:**
      # - Routes can be defined in any order (order-independent)
      # - Output access is blocked until `commit!` is called
      # - Commit resolves all routes and sets up buffering
      # - `auto_commit: true` (default) commits automatically after DSL block
      #
      # ## DSL Context
      #
      # The DSL uses `method_missing` to enable natural pipeline definition:
      #
      # - **Named access**: `input`, `output`, pipeline names return symbols
      # - **Pipeline creation**: `name arg1, arg2, ...` creates pipeline
      # - **Operation symbols**: Series operations return as symbols for parsing
      # - **Constructor symbols**: Series constructors return as symbols for parsing
      #
      # @example Basic pipeline
      #   composer = Composer.new(input: S(1, 2, 3)) do
      #     step1 reverse
      #     route input, to: step1
      #     route step1, to: output
      #   end
      #   composer.output.i.to_a  # => [3, 2, 1]
      #
      # @example Multiple inputs merging
      #   composer = Composer.new(inputs: { a: S(1, 2), b: S(10, 20) }) do
      #     hash_merge ({ H: {} })
      #     route a, to: hash_merge, as: :x
      #     route b, to: hash_merge, as: :y
      #     route hash_merge, to: output
      #   end
      #   composer.output.i.to_a  # => [{x: 1, y: 10}, {x: 2, y: 20}]
      #
      # @example Multiple outputs
      #   composer = Composer.new(input: S(1, 2, 3)) do
      #     doubled ({ eval: ->(v) { v * 2 } })
      #     tripled ({ eval: ->(v) { v * 3 } })
      #
      #     route input, to: doubled
      #     route input, to: tripled
      #     route doubled, to: output
      #   end
      #   composer.output.i.to_a  # => [2, 4, 6]
      #
      # @example Complex routing
      #   composer = Composer.new(inputs: [:a, :b], auto_commit: false) do
      #     step1 reverse
      #     step2 ({ skip: 1 })
      #     hash_merge ({ H: {} })
      #
      #     route a, to: step1
      #     route b, to: step2
      #     route step1, to: hash_merge, as: :x
      #     route step2, to: hash_merge, as: :y
      #     route hash_merge, to: output
      #   end
      #
      #   composer.input(:a).proxy_source = S(1, 2, 3)
      #   composer.input(:b).proxy_source = S(10, 20, 30)
      #   composer.commit!
      #
      #   composer.output.i.to_a  # => [{x: 3, y: 20}, {x: 2, y: 30}]
      class Composer
        using Musa::Extension::Arrayfy

        def initialize(input: nil, inputs: [:input], outputs: [:output], auto_commit: nil, &block)
          auto_commit = true if auto_commit.nil?

          inputs = case inputs
                   when Array
                     inputs.collect { |_| [_, nil] }.to_h
                   when nil
                     {}
                   when Hash
                     inputs
                   else
                     raise ArgumentError, "inputs: expected a Hash with input names and source series { name: serie, ... } or an Array with names [name, ...] but received #{inputs}"
                   end

          inputs[:input] = input if input

          @pipelines = {}

          def @pipelines.[]=(name, pipeline)
            pipeline_to_add = @commited ? pipeline.commit! : pipeline
            super(name, pipeline_to_add)
          end

          @dsl = DSLContext.new(@pipelines)
          @inputs = {}
          @outputs = {}

          inputs.keys&.each do |input|
            p = Musa::Series::Constructors.PROXY(inputs[input])

            @inputs[input] = @pipelines[input] = Pipeline.new(input, input: p, output: p.buffered, pipelines: @pipelines)

            @dsl.define_singleton_method(input) { input }
          end

          outputs&.each do |output|
            p = Musa::Series::Constructors.PROXY()
            @outputs[output] = @pipelines[output] = Pipeline.new(output, is_output: true, input: p, output: p, pipelines: @pipelines)

            @dsl.define_singleton_method(output) { output }
          end

          @dsl.with &block if block
          commit! if auto_commit
        end

        # Accesses named input proxy for dynamic source assignment.
        #
        # Returns the proxy series for the specified input, allowing dynamic
        # assignment of source series after composer creation. Used with
        # `auto_commit: false` to set sources before manual commit.
        #
        # @param name [Symbol, nil] input name (defaults to :input)
        #
        # @return [ProxySerie] proxy series for source assignment
        #
        # @example Set input source dynamically
        #   composer = Composer.new(auto_commit: false) do
        #     step reverse
        #     route input, to: step
        #     route step, to: output
        #   end
        #
        #   composer.input.proxy_source = S(1, 2, 3)
        #   composer.commit!
        #
        # @api public
        def input(name = nil)
          name ||= :input
          @inputs[name].input
        end

        # Accesses named output series for consumption.
        #
        # Returns the output series for the specified output. Can only be
        # called after `commit!` has been invoked. Raises error if composer
        # is not committed.
        #
        # @param name [Symbol, nil] output name (defaults to :output)
        #
        # @return [Serie] output series
        #
        # @raise [RuntimeError] if composer not yet committed
        #
        # @example Access output
        #   composer.output.i.to_a  # => [3, 2, 1]
        #
        # @example Multiple outputs
        #   composer.output(:doubled).i.to_a  # => [2, 4, 6]
        #   composer.output(:tripled).i.to_a  # => [3, 6, 9]
        #
        # @api public
        def output(name = nil)
          raise "Can't access output if the Composer is uncommited. Call '.commit' first." unless @commited

          name ||= :output
          @outputs[name].output
        end

        # Defines routing connection between pipelines.
        #
        # Creates data flow route from source pipeline to destination pipeline.
        # The routing behavior depends on whether `as:` parameter is provided.
        #
        # **With `as:` parameter (Hash routing):**
        # - Assigns to hash: `to_pipeline.input[on][as] = from_pipeline.output`
        # - Default `on` is `:sources`
        # - Used by operations accepting hash inputs (e.g., `H` constructor)
        #
        # **Without `as:` parameter (Setter routing):**
        # - Calls setter: `to_pipeline.input.source = from_pipeline.output`
        # - Default `on` is `:source`
        # - Used by operations with explicit source setter methods
        #
        # @param from [Symbol] source pipeline name
        # @param to [Symbol] destination pipeline name
        # @param on [Symbol, nil] attribute name (:source or :sources)
        # @param as [Symbol, nil] hash key for assignment
        #
        # @return [void]
        #
        # @raise [ArgumentError] if pipeline names not found
        # @raise [ArgumentError] if route already exists
        #
        # @example Hash routing (inside DSL block)
        #   composer = Composer.new(inputs: [:a, :b], auto_commit: false) do
        #     step1 reverse
        #     step2 reverse
        #     hash_merge ({ H: {} })
        #
        #     route a, to: step1
        #     route b, to: step2
        #     route step1, to: hash_merge, as: :x    # hash_merge.input[:sources][:x] = step1
        #     route step2, to: hash_merge, as: :y    # hash_merge.input[:sources][:y] = step2
        #     route hash_merge, to: output
        #   end
        #
        #   composer.input(:a).proxy_source = S(1, 2)
        #   composer.input(:b).proxy_source = S(10, 20)
        #   composer.commit!
        #   composer.output.i.to_a  # => [{x: 2, y: 20}, {x: 1, y: 10}]
        #
        # @example Setter routing (inside DSL block)
        #   composer = Composer.new(input: S(1, 2, 3)) do
        #     step reverse
        #     route input, to: step             # step.input.source = input
        #     route step, to: output
        #   end
        #
        #   composer.output.i.to_a  # => [3, 2, 1]
        #
        # @example Custom on parameter (inside DSL block)
        #   composer = Composer.new(input: S(1, 2, 3), auto_commit: false) do
        #     step reverse
        #     hash_merge ({ H: {} })
        #     route input, to: step
        #     route step, to: hash_merge, on: :sources, as: :x
        #     route hash_merge, to: output
        #   end
        #
        #   composer.commit!
        #   composer.output.i.to_a  # => [{x: 3}, {x: 2}, {x: 1}]
        #
        # @api public
        def route(from, to:, on: nil, as: nil)
          @dsl.route(from, to: to, on: on, as: as)
        end

        # Defines named pipeline with transformation operations.
        #
        # Creates a pipeline from constructor and/or operations. This method
        # is typically called implicitly through the DSL's method_missing, but
        # can be called directly for dynamic pipeline creation.
        #
        # @param name [Symbol] pipeline name
        # @param elements [Array] constructor and operations
        #
        # @return [void]
        #
        # @example Direct call (inside DSL block)
        #   composer = Composer.new(inputs: nil) do
        #     pipeline(:my_step, [{ S: [1, 2, 3] }, :reverse])
        #     route my_step, to: output
        #   end
        #
        #   composer.output.i.to_a  # => [3, 2, 1]
        #
        # @example DSL equivalent (method_missing)
        #   composer = Composer.new(inputs: nil) do
        #     my_step ({ S: [1, 2, 3] }), reverse
        #     route my_step, to: output
        #   end
        #
        #   composer.output.i.to_a  # => [3, 2, 1]
        #
        # @api public
        def pipeline(name, *elements)
          @dsl.pipeline(name, elements)
        end

        # Updates composer with additional DSL block.
        #
        # Allows dynamic modification of composer after creation by executing
        # additional DSL block in the composer's DSL context. Useful for
        # progressive pipeline construction.
        #
        # @yield DSL block with additional pipeline definitions
        #
        # @return [void]
        #
        # @example Add routes dynamically
        #   composer.update do
        #     route step3, to: output
        #   end
        #
        # @api public
        def update(&block)
          @dsl.with &block
        end

        # Finalizes composer by resolving all routes and connections.
        #
        # Commits the composer, resolving all route connections and setting up
        # buffering. Must be called before accessing outputs. Cannot be called
        # twice on same composer instance.
        #
        # The commit process:
        # 1. Recursively commits all output pipelines
        # 2. Each pipeline commits its input routes
        # 3. Connects all sources through buffers
        # 4. Sets committed flag enabling output access
        #
        # @return [void]
        #
        # @raise [RuntimeError] if already committed
        #
        # @example Manual commit
        #   composer = Composer.new(auto_commit: false) do
        #     # ... pipeline definitions ...
        #   end
        #   composer.input.proxy_source = S(1, 2, 3)
        #   composer.commit!
        #   result = composer.output.i.to_a
        #
        # @api public
        def commit!
          raise 'Already commited' if @commited

          @outputs.each_value do |pipeline|
            pipeline.commit!
          end

          @commited = true
        end

        # Internal representation of a transformation pipeline stage.
        #
        # Pipeline encapsulates a single named stage in the composer graph,
        # storing its input/output series, routes, and transformation logic.
        #
        # ## Pipeline Types
        #
        # - **Input pipelines**: Created from `inputs:` parameter, wrap proxy series
        # - **Output pipelines**: Created from `outputs:` parameter, wrap proxy series
        # - **Transformation pipelines**: Created by DSL, contain transformation logic
        #
        # ## Pipeline Components
        #
        # - `@first_proc`: Proc creating initial series from UNDEFINED (constructors)
        # - `@chain_proc`: Proc applying operations to existing series
        # - `@routes`: Hash of incoming route connections
        # - `@input`: Input series (set during commit)
        # - `@output`: Output series (set during commit)
        #
        # @api private
        class Pipeline
          # Creates new pipeline stage.
          #
          # @param name [Symbol] pipeline name
          # @param is_output [Boolean] whether this is an output pipeline
          # @param input [Serie, nil] input series
          # @param output [Serie, nil] output series
          # @param first_proc [Proc, nil] constructor proc
          # @param chain_proc [Proc, nil] operations proc
          # @param pipelines [Hash] reference to all pipelines
          #
          # @api private
          def initialize(name, is_output: false, input: nil, output: nil, first_proc: nil, chain_proc: nil, pipelines:)
            @name = name
            @is_output = is_output
            @input = input
            @output = output
            @first_proc = first_proc
            @chain_proc = chain_proc
            @routes = {}
            @pipelines = pipelines
          end

          attr_reader :name, :is_output
          attr_accessor :input, :output, :proc

          # Retrieves route at specified connection point.
          #
          # @param on [Symbol] connection attribute name
          # @param as [Symbol, nil] hash key for assignment
          #
          # @return [Route, nil] route at connection point
          #
          # @api private
          def [](on, as)
            @routes[[on, as]]
          end

          # Stores route at specified connection point.
          #
          # @param on [Symbol] connection attribute name
          # @param as [Symbol, nil] hash key for assignment
          # @param source [Pipeline] source pipeline
          #
          # @return [Route] created route
          #
          # @api private
          def []=(on, as, source)
            @routes[[on, as]] = Route.new(on, as, source)
          end

          # Finalizes pipeline by resolving routes and connecting series.
          #
          # The commit process:
          # 1. Calls `@first_proc` with UNDEFINED to create initial series (if present)
          # 2. Recursively commits all source pipelines
          # 3. Connects input routes:
          #    - For output pipelines: assigns to proxy_source
          #    - For hash routes (with `as`): assigns to input[on][as]
          #    - For setter routes (without `as`): calls input.on=
          # 4. Applies `@chain_proc` to transform input series (if present)
          # 5. Sets output series (buffered)
          #
          # @return [self]
          #
          # @api private
          def commit!
            first_serie_operation = @first_proc&.call(Musa::Series::Constructors.UNDEFINED())

            @input ||= first_serie_operation

            @routes.each_value do |route|
              route.source.commit!

              if @is_output
                @input.proxy_source = route.source.output.buffer
              elsif route.as
                @input.send(route.on)[route.as] = route.source.output.buffer
              else
                @input.send("#{route.on.to_s}=".to_sym, route.source.output.buffer)
              end
            end

            chain_serie_operation = @chain_proc&.call(@input) || @input
            @output ||= chain_serie_operation.buffered

            self
          end
        end

        # Route connection between two pipelines.
        #
        # Stores the metadata for a single route connection, including the
        # connection point (on), hash key (as), and source pipeline.
        #
        # @api private
        class Route
          # Creates new route.
          #
          # @param on [Symbol] connection attribute name
          # @param as [Symbol, nil] hash key for assignment
          # @param source [Pipeline] source pipeline
          #
          # @api private
          def initialize(on, as, source)
            @on = on
            @as = as
            @source = source
          end
          attr_accessor :on, :as, :source
        end

        # DSL execution context for pipeline definition.
        #
        # DSLContext provides the execution environment for the composer DSL block.
        # It uses `method_missing` to enable natural syntax for pipeline definition
        # and routing operations.
        #
        # ## Method Resolution
        #
        # - **Series operations** (`reverse`, `skip`, etc.): Return symbol for parsing
        # - **Series constructors** (`S`, `H`, etc.): Return symbol for parsing
        # - **Pipeline names**: Return symbol for routing
        # - **With arguments**: Create pipeline with those arguments
        #
        # ## Key Responsibilities
        #
        # - Parse pipeline definitions into first/chain procs
        # - Validate and store route connections
        # - Distinguish between constructors and operations
        # - Handle dynamic parameter passing
        #
        # @api private
        class DSLContext
          include Musa::Extension::With

          # Creates DSL context.
          #
          # @param pipelines [Hash] reference to all pipelines
          #
          # @api private
          def initialize(pipelines)
            @pipelines = pipelines
          end

          # Defines route connection in DSL context.
          #
          # Validates pipeline existence, determines default `on` parameter,
          # checks for duplicate routes, and stores route in destination pipeline.
          #
          # @param from [Symbol] source pipeline name
          # @param to [Symbol] destination pipeline name
          # @param on [Symbol, nil] connection attribute
          # @param as [Symbol, nil] hash key
          #
          # @return [void]
          #
          # @raise [ArgumentError] if pipelines not found
          # @raise [ArgumentError] if route already exists
          # @raise [ArgumentError] if output pipeline with on/as parameters
          #
          # @api private
          def route(from, to:, on: nil, as: nil)
            from_pipeline = @pipelines[from]
            to_pipeline = @pipelines[to]

            raise ArgumentError, "Pipeline '#{from}' not found." unless from_pipeline
            raise ArgumentError, "Pipeline '#{to}' not found." unless to_pipeline

            if to_pipeline.is_output && (on || as)
              raise ArgumentError, "Output pipeline #{to_pipeline.name} only allows default routing"
            end

            # Default on logic: :sources when as provided, :source otherwise
            on ||= (as ? :sources : :source)

            raise ArgumentError,
                  "Source of pipeline #{to} on #{on} as #{as} already connected to #{to_pipeline[on, as].source.name}" \
                  unless to_pipeline[on, as].nil?


            to_pipeline[on, as] = from_pipeline
          end

          # Creates pipeline from elements in DSL context.
          #
          # Parses elements into first/chain procs, creates Pipeline instance,
          # and defines DSL accessor method for pipeline name.
          #
          # @param name [Symbol] pipeline name
          # @param elements [Array] constructor and/or operations
          #
          # @return [void]
          #
          # @api private
          def pipeline(name, elements)
            first, chain = parse(elements)
            @pipelines[name] = Pipeline.new(name, first_proc: first, chain_proc: chain, pipelines: @pipelines)

            define_singleton_method(name) { name }
          end

          # Parses pipeline elements into first/chain proc pair.
          #
          # The parser transforms DSL syntax into executable procs. It splits
          # pipeline definition into:
          # - `first`: Proc creating initial series from UNDEFINED (constructors)
          # - `chain`: Proc applying operations to existing series
          #
          # **Parsing modes:**
          #
          # - **Array**: Sequence of operations/constructors
          # - **Hash**: Single operation/constructor with parameters
          # - **Symbol**: Operation/constructor name without parameters
          # - **Proc**: Direct transformation function
          #
          # **First vs Chain logic:**
          # - First element (if constructor) becomes `first`
          # - Remaining elements compose into `chain`
          # - Operations only: `first` is nil, all become `chain`
          #
          # @param thing [Array, Hash, Symbol, Proc, Object] element(s) to parse
          #
          # @return [Array(Proc, Proc), Proc, Object] [first, chain] pair or single proc
          #
          # @example Array with constructor + operations
          #   parse([{ S: [1, 2, 3] }, :reverse, { skip: 1 }])
          #   # => [first_proc, chain_proc]
          #   # first_proc: creates S([1,2,3])
          #   # chain_proc: applies reverse >> skip(1)
          #
          # @example Operations only
          #   parse([:reverse, { skip: 1 }])
          #   # => [nil, chain_proc]
          #   # chain_proc: applies reverse >> skip(1)
          #
          # @api private
          private def parse(thing)
            case thing
            when Array
              first = chain = nil

              thing.each do |element|
                case element
                when Hash
                  new_chain = parse(element)
                when Symbol
                  new_chain = operation_as_chained_proc(element, nil)
                when Proc
                  new_chain = operation_as_chained_proc(:map, element)
                else
                  raise ArgumentError, "Syntax error: don't know how to handle #{element}"
                end

                if first.nil?
                  first = new_chain unless first
                else
                  chain = chain ? chain >> new_chain : new_chain
                end
              end

              [first, chain]

            when Hash
              if thing.size == 1
                operation = thing.first[0] # key
                parameter = thing.first[1] # value

                if is_a_series_constructor?(operation)
                  operation_as_chained_proc(operation, parameter)
                else
                  operation_as_chained_proc(operation, parse(parameter))
                end
              else
                raise ArgumentError, "Syntax error: don't know how to handle #{element}"
              end

            when Symbol
              operation_as_chained_proc(operation)

            when Proc
              thing

            else
              thing
            end
          end

          # Wraps operation/constructor as chainable proc.
          #
          # Creates proc that accepts previous result (`last`) and applies
          # operation/constructor with parameters. Distinguishes between
          # constructors (create series) and operations (transform series).
          #
          # @param operation [Symbol] operation or constructor name
          # @param parameter [Object, nil] operation parameters
          #
          # @return [Proc] chainable proc accepting `last` argument
          #
          # @api private
          private def operation_as_chained_proc(operation, parameter = nil)
            if is_a_series_constructor?(operation)
              proc do |last|
                call_constructor_according_to_last_and_parameter(last, operation, parameter)
              end

            elsif is_a_series_operation?(operation)
              proc { |last| call_operation_according_to_parameter(last, operation, parameter) }

            else
              # non-series operation
              proc { |last| call_operation_according_to_parameter(last, operation, parameter) }
            end
          end

          # Calls series constructor based on previous result type.
          #
          # Handles different `last` types to enable flexible constructor usage:
          #
          # - **UndefinedSerie**: Normal constructor call (pipeline start)
          # - **Array**: Pass array elements as arguments
          # - **Hash**: Pass hash as keyword arguments
          # - **nil**: Call with parameter
          # - **Serie**: Error (cannot reconstruct from serie)
          # - **Proc**: Evaluate proc first, then call constructor
          #
          # This enables patterns like:
          # - `({ S: [1, 2, 3] })` - Direct constructor
          # - `operation, :S` - Constructor from operation result
          #
          # @param last [Object] previous pipeline result
          # @param constructor [Symbol] constructor name (e.g., :S, :H)
          # @param parameter [Object] constructor parameters
          #
          # @return [Serie] constructed series
          #
          # @raise [RuntimeError] if last is Serie (invalid)
          # @raise [RuntimeError] if parameter type unexpected
          #
          # @api private
          private def call_constructor_according_to_last_and_parameter(last, constructor, parameter)
            case last
            when Proc
              call_constructor_according_to_last_and_parameter(last.call, constructor, parameter)

            when Musa::Series::Constructors::UndefinedSerie
              case parameter
              when Hash
                Musa::Series::Constructors.method(constructor).call(**parameter)
              when Array
                Musa::Series::Constructors.method(constructor).call(*parameter)
              else
                raise "Unexpected parameter #{parameter} for constructor #{constructor}"
              end

            when Serie
              raise "Unexpected source serie #{last} for constructor #{constructor}"

            when nil
              Musa::Series::Constructors.method(constructor).call(*parameter)

            when Array
              raise "Unexpected parameter #{parameter} for constructor #{constructor} " \
                "because the previous operation on the pipeline chain returned non-nil #{last}" \
                unless parameter.nil?

              Musa::Series::Constructors.method(constructor).call(*last)

            when Hash
              raise "Unexpected parameter #{parameter} for constructor #{constructor} " \
                "because the previous operation on the pipeline chain returned non-nil #{last}" \
                unless parameter.nil?

              Musa::Series::Constructors.method(constructor).call(**last)

            else
              raise ArgumentError, "Don't know how to handle last #{last}"
            end
          end

          # Calls series operation with appropriate parameter handling.
          #
          # Handles different parameter types for operation calls:
          #
          # - **nil**: No parameter, simple call
          # - **Symbol**: Chained call (e.g., `operation.parameter`)
          # - **Proc**: Block parameter (e.g., `operation { |x| x }`)
          # - **Array of 2 Procs**: Composed block (proc1 >> proc2)
          # - **Other**: Direct parameter
          #
          # @param target [Object] object to call operation on
          # @param operation [Symbol] operation name
          # @param parameter [Object, nil] operation parameter
          #
          # @return [Object] operation result
          #
          # @raise [ArgumentError] if Array parameter invalid
          #
          # @example No parameter
          #   call_operation_according_to_parameter(serie, :reverse, nil)
          #   # => serie.reverse
          #
          # @example With block
          #   call_operation_according_to_parameter(serie, :map, ->(x) { x * 2 })
          #   # => serie.map { |x| x * 2 }
          #
          # @api private
          private def call_operation_according_to_parameter(target, operation, parameter)
            case parameter
            when nil
              target.send(operation)
            when Symbol
              target.send(operation).send(parameter)
            when Proc
              target.send(operation, &parameter)
            when Array
              unless parameter.size == 2 && parameter.all? { |_| _.is_a?(Proc) }
                raise ArgumentError, "Don't know how to handle parameter #{parameter}"
              end

              target.send(operation, &(parameter.first >> parameter.last))
            else
              target.send(operation, parameter)
            end
          end

          # Checks if symbol is a series constructor.
          #
          # @param operation [Symbol] operation name
          #
          # @return [Boolean] true if constructor
          #
          # @api private
          private def is_a_series_constructor?(operation)
            Musa::Series::Constructors.instance_methods.include?(operation)
          end

          # Checks if symbol is a series operation.
          #
          # @param operation [Symbol] operation name
          #
          # @return [Boolean] true if operation
          #
          # @api private
          private def is_a_series_operation?(operation)
            Musa::Series::Operations.instance_methods.include?(operation)
          end

          # Enables DSL method syntax via method_missing.
          #
          # Implements the DSL's natural syntax by intercepting undefined methods:
          #
          # - **Series operations/constructors**: Return symbol for parsing
          # - **With arguments/block**: Create pipeline with those elements
          # - **Without arguments**: Return symbol for routing
          #
          # This allows expressions like:
          #
          # ```ruby
          # composer = Composer.new(input: S(1, 2, 3)) do
          #   # `reverse` → returns :reverse (operation symbol)
          #   # `my_step reverse, { skip: 1 }` → creates pipeline named :my_step
          #   # `route input, to: step1` → uses :step1 symbol for routing
          #
          #   my_step reverse, { skip: 1 }
          #   route input, to: my_step
          #   route my_step, to: output
          # end
          #
          # composer.output.i.to_a  # => [2, 1]
          # ```
          #
          # @param symbol [Symbol] method name called
          # @param args [Array] method arguments
          # @param block [Proc, nil] block passed to method
          #
          # @return [Symbol, void] symbol for parsing or creates pipeline
          #
          # @api private
          private def method_missing(symbol, *args, &block)
            if is_a_series_constructor?(symbol) || is_a_series_operation?(symbol)
              symbol
            elsif args.any? || block
              args += [block] if block
              pipeline(symbol, args)
            else # for non-series methods
              symbol
            end
          end

          # Declares which methods respond_to for method_missing.
          #
          # @param method_name [Symbol] method to check
          # @param include_private [Boolean] include private methods
          #
          # @return [Boolean] true if responds to method
          #
          # @api private
          private def respond_to_missing?(method_name, include_private = false)
            Musa::Series::Operations.instance_methods.include?(method_name) ||
            Musa::Series::Constructors.instance_methods.include?(method_name) ||
            @pipelines.key?(method_name) ||
            super
          end
        end

        private_constant :Pipeline
        private_constant :Route
        private_constant :DSLContext
      end
    end
  end
end
