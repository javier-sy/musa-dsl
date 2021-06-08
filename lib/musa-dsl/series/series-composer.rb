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
            @pipelines[input] = { input: nil, output: @inputs[input] }

            @dsl.define_singleton_method input do
              input
            end
          end

          outputs&.each do |output|
            @outputs[output] = Series::Constructors.PROXY
            @pipelines[output] = { input: @outputs[output], output: nil }

            @dsl.define_singleton_method output do
              output
            end
          end

          @dsl.with &block
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

          def route(from, to:, as: nil, at: nil)
            raise NotImplementedError, "at: parameter not yet implemented" if at

            from_pipeline = @pipelines[from]
            to_pipeline = @pipelines[to]

            raise ArgumentError, "Pipeline '#{from}' not found." unless from_pipeline
            raise ArgumentError, "Pipeline '#{to}' not found." unless to_pipeline

            # TODO add "distribution center" as a serie that replicates the stream for several consumers series input
            # tipos:
            # - cada línea de distribución recibe todos los elementos; estos se guardan hasta que se consumen
            # - hay una línea master y varias followers; las followers obtienen lo que la master marque
            # - cuando una línea pide se obtiene un valor; el resto de líneas obtienen el mismo valor si se da dentro de un margen de tiempo X; si ha pasado más tiempo obtiene un nuevo valor
            #

            # TODO add routing to other inputs (source is the default input, sources can be an Array or a Hash of inputs, maybe others)
            #

            raise ArgumentError, "Pipeline '#{from}' already used (connected to #{@links_from[from]})" if @links_from[from]
            raise ArgumentError, "Pipeline '#{[to, as]}' input already connected (connected to #{@links_to[[to, as]]})" if @links_from[[to, as]]

            @links_from[from] = [to, as]
            @links_to[[to, as]] = from

            @links << [from, to, as]

            if as
              to_pipeline[:input].sources[as] = from_pipeline[:output]
            else
              to_pipeline[:input].source = from_pipeline[:output]
            end
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
                  raise ArgumentError, "Don\\'t know how to handle #{e}"
                end
              when Symbol
                operation = e

                if Musa::Series::Operations.instance_methods.include?(operation)
                  last = last.send(operation)
                end
              end

              first ||= last
            end

            @pipelines[name] = { input: first, output: last }

            define_singleton_method name do
              name
            end
          end

          private def method_missing(symbol, *args, &block)
            if Musa::Series::Operations.instance_methods.include?(symbol)
              symbol
            elsif Musa::Series::Constructors.instance_methods.include?(symbol)
              symbol
            else
              raise ArgumentError, "Pipeline '#{symbol}' is undefined" if args.empty?
              pipeline(symbol, args)
            end
          end

          private def respond_to_missing?(method_name, include_private = false)
            Musa::Series::Operations.instance_methods.include?(method_name) ||
              Musa::Series::Constructors.instance_methods.include?(method_name) ||
              @pipelines.has_key?(method_name) ||
              super
          end
        end

        private_constant :DSLContext
      end
    end
  end
end
