require_relative 'base-series'

require_relative '../core-ext/with'

module Musa
  module Series
    module Composer
      class Composer
        using Musa::Extension::Arrayfy

        attr_reader :inputs, :outputs

        def initialize(inputs: [:input], outputs: [:output], &block)
          @pipelines = {}

          @links = Set[]
          @links_from = {}
          @links_to = {}

          @dsl = DSLContext.new(@pipelines, @links, @links_from, @links_to)
          @inputs = {}
          @outputs = {}

          inputs&.each do |input|
            @inputs[input] = Series::Constructors.PROXY
            @pipelines[input] = { input: nil, output: @inputs[input].buffered }

            @dsl.define_singleton_method(input) { input }
          end

          outputs&.each do |output|
            @outputs[output] = Series::Constructors.PROXY
            @pipelines[output] = { input: @outputs[output], output: nil }

            @dsl.define_singleton_method(output) { output }
          end

          @dsl.with &block if block
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

        class DSLContext
          include Musa::Extension::With

          def initialize(pipelines, links, links_from, links_to)
            @pipelines = pipelines

            @links = links
            @links_from = links_from
            @links_to = links_to
          end

          def route(from, to:, on: nil, as: nil)
            from_pipeline = @pipelines[from]
            to_pipeline = @pipelines[to]

            raise ArgumentError, "Pipeline '#{from}' not found." unless from_pipeline
            raise ArgumentError, "Pipeline '#{to}' not found." unless to_pipeline

            @links_from[from] ||= Set[]

            on ||= as ? :sources : :source

            raise ArgumentError, "Pipeline #{@links_to[[to, on, as]]} already connected to pipeline #{to} on #{on} as #{as}" if @links_to[[to, on, as]]

            if as
              to_pipeline[:input].send(on)[as] = from_pipeline[:output].buffer
            else
              to_pipeline[:input].send("#{on.to_s}=".to_sym, from_pipeline[:output].buffer)
            end

            @links_from[from] << [to, on, as]
            @links_to[[to, on, as]] = from
            @links << [from, to, on, as]
          end

          def pipeline(name, elements)
            first = last = nil

            elements.each do |e|
              case e
              when Hash
                if e.size == 1
                  operation = e.keys.first
                  parameters = e.values.first

                  if Musa::Series::Constructors.instance_methods.include?(operation)
                    raise ArgumentError, "Called constructor '#{operation}' ignoring previous elements" unless last.nil?

                    last = Musa::Series::Constructors.method(operation).call(*parameters)

                  elsif Musa::Series::Operations.instance_methods.include?(operation)
                    first = last = Musa::Series::Constructors.PROXY if last.nil?
                    last = last.send(operation, *parameters)

                  end
                else
                  raise ArgumentError, "Don't know how to handle #{e}"
                end
              when Symbol
                first = last = Musa::Series::Constructors.PROXY if last.nil?
                last = last.send(e) if Musa::Series::Operations.instance_methods.include?(e)

              when Proc
                first = last = Musa::Series::Constructors.PROXY if last.nil?
                last = last.eval(e)
              end

              first ||= last
            end

            @pipelines[name] = { input: first, output: last.buffered }

            define_singleton_method(name) { name }
          end

          private def method_missing(symbol, *args, &block)
            if Musa::Series::Operations.instance_methods.include?(symbol)
              symbol
            elsif Musa::Series::Constructors.instance_methods.include?(symbol)
              symbol
            else
              raise ArgumentError, "Pipeline '#{symbol}' is undefined" if args.empty? && !block

              args += [block] if block
              pipeline(symbol, args)
            end
          end

          private def respond_to_missing?(method_name, include_private = false)
            Musa::Series::Operations.instance_methods.include?(method_name) ||
            Musa::Series::Constructors.instance_methods.include?(method_name) ||
            @pipelines.key?(method_name) ||
            super
          end
        end

        private_constant :DSLContext
      end
    end
  end
end
