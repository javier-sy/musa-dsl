require_relative 'base-series'

require_relative '../core-ext/with'

module Musa
  module Series
    module Operations
      def composer(&block)
        Composer::Composer.new(input: self, &block).output
      end
    end

    module Composer
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
            p = PROXY()
            p.proxy_source = inputs[input] if inputs[input]

            @inputs[input] = @pipelines[input] = Pipeline.new(input, input: p, output: p.buffered, pipelines: @pipelines)

            @dsl.define_singleton_method(input) { input }
          end

          outputs&.each do |output|
            p = PROXY()
            @outputs[output] = @pipelines[output] = Pipeline.new(output, is_output: true, input: p, output: p, pipelines: @pipelines)

            @dsl.define_singleton_method(output) { output }
          end

          @dsl.with &block if block
          commit! if auto_commit
        end

        def input(name = nil)
          name ||= :input
          @inputs[name].input
        end

        def output(name = nil)
          raise "Can't access output if the Composer is uncommited. Call '.commit' first." unless @commited

          name ||= :output
          @outputs[name].output
        end

        def route(from, to:, on: nil, as: nil)
          @dsl.route(from, to: to, on: on, as: as)
        end

        def pipeline(name, *elements)
          @dsl.pipeline(name, elements)
        end

        def update(&block)
          @dsl.with &block
        end

        def commit!
          raise 'Already commited' if @commited

          @outputs.each_value do |pipeline|
            pipeline.commit!
          end

          @commited = true
        end

        class Pipeline
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

          def [](on, as)
            @routes[[on, as]]
          end

          def []=(on, as, source)
            @routes[[on, as]] = Route.new(on, as, source)
          end

          def commit!
            first_serie_operation = @first_proc&.call(NIL())
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

        class Route
          def initialize(on, as, source)
            @on = on
            @as = as
            @source = source
          end
          attr_accessor :on, :as, :source
        end

        class DSLContext
          include Musa::Extension::With

          def initialize(pipelines)
            @pipelines = pipelines
          end

          def route(from, to:, on: nil, as: nil)
            from_pipeline = @pipelines[from]
            to_pipeline = @pipelines[to]

            raise ArgumentError, "Pipeline '#{from}' not found." unless from_pipeline
            raise ArgumentError, "Pipeline '#{to}' not found." unless to_pipeline

            if to_pipeline.is_output && (on || as)
              raise ArgumentError, "Output pipeline #{to_pipeline.name} only allows default routing"
            end

            on ||= (as ? :sources : :source)

            raise ArgumentError,
                  "Source of pipeline #{to} on #{on} as #{as} already connected to #{to_pipeline[on, as].source.name}" \
                  unless to_pipeline[on, as].nil?


            to_pipeline[on, as] = from_pipeline
          end

          def pipeline(name, elements)
            first, chain = parse(elements)
            @pipelines[name] = Pipeline.new(name, first_proc: first, chain_proc: chain, pipelines: @pipelines)

            define_singleton_method(name) { name }
          end

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

          private def call_constructor_according_to_last_and_parameter(last, constructor, parameter)
            case last
            when Proc
              call_constructor_according_to_last_and_parameter(last.call, constructor, parameter)

            when Serie
              # TODO: ignoring last, should make an error?
              Musa::Series::Constructors.method(constructor).call(*parameter)

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

          private def is_a_series_constructor?(operation)
            Musa::Series::Constructors.instance_methods.include?(operation)
          end

          private def is_a_series_operation?(operation)
            Musa::Series::Operations.instance_methods.include?(operation)
          end

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
