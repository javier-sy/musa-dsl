module Musa::Neumalang
  module Neumas # Neumas serie
    # TODO implementar | ???? neumas | neumas = parallel neumas, no?

    def render

    end
  end

  module Neuma
    module Parallel
      include Neuma
    end

    def |(other)
      if is_a?(Parallel)
        clone.tap { |_| _[:parallel] << convert_to_parallel_element(other) }.extend(Parallel)
      else
        { kind: :parallel,
          parallel: [clone, convert_to_parallel_element(other)]
        }.extend(Parallel)
      end
    end

    private

    def convert_to_parallel_element(e)
      case e
      when String then { kind: :serie, serie: e.to_neumas }.extend(Neuma)
      else
        raise ArgumentError, "Dont know how to convert to neuma #{e}"
      end
    end
  end

  module Dataset
    class Decorator
      def process(element, base_duration:, tick_duration:)
        element
      end

      def check(value_or_array, &block)
        if block_given?
          if value_or_array.is_a?(Array)
            value_or_array.each { |value| yield value }
          else
            yield value_or_array
          end
        end
      end
    end

    class TwoNeumasDecorator < Decorator
      def process(element1, element2, base_duration:, tick_duration:)
        element2
      end
    end

    class Decorators
      attr_reader :decorators
      attr_accessor :appogiatura_decorator

      def initialize(*decorators, appogiatura_decorator: nil, base_duration: nil, tick_duration: nil)
        @base_duration = 1/4r
        @tick_duration = tick_duration || 1/96r

        @appogiatura_decorator = appogiatura_decorator
        @decorators = decorators
      end

      def process(element)
        if @appogiatura_decorator
          element = @appogiatura_decorator.process(element, base_duration: @base_duration, tick_duration: @tick_duration)
        end

        @decorators.each do |processor|
          if element
            if element.is_a?(Array)
              element = element.collect { |element_i| processor.process(element_i, base_duration: @base_duration, tick_duration: @tick_duration) }.flatten(1)
            else
              element = processor.process(element, base_duration: @base_duration, tick_duration: @tick_duration)
            end
          end
        end

        element
      end
    end

    protected

    def positive_sign_of(x)
      x >= 0 ? '+' : ''
    end

    def sign_of(x)
      '++-'[x <=> 0]
    end

    def velocity_of(x)
      %w[ppp pp p mp mf f ff fff][x + 3]
    end

    def modificator_string(modificator, parameter_or_parameters)
      case parameter_or_parameters
      when true
        modificator.to_s
      when Array
        "#{modificator.to_s}(#{parameter_or_parameters.collect { |p| parameter_to_string(p) }.join(', ')})"
      else
        "#{modificator.to_s}(#{parameter_to_string(parameter_or_parameters)})"
      end
    end

    private

    def parameter_to_string(parameter)
      case parameter
      when String
        "\"#{parameter}\""
      when Numeric
        "#{parameter}"
      when Symbol
        "#{parameter}"
      end
    end
  end

  class ProtoDecoder
    def subcontext
      self
    end

    def decode(_element)
      raise NotImplementedError
    end
  end

  class DifferentialDecoder < ProtoDecoder
    def decode(attributes)
      parse attributes
    end

    def parse(_attributes)
      raise NotImplementedError
    end
  end

  class Decoder < DifferentialDecoder
    def initialize(base, processor: nil)
      @base = base
      @last = base.clone

      @processor = processor
    end

    attr_reader :base

    def base=(base)
      @base = base
      @last = base.clone
    end

    def subcontext
      Decoder.new @base
    end

    def decode(attributes)
      result = apply parse(attributes), on: @last

      @last = result.clone

      if @processor
        @processor.process(result)
      else
        result
      end
    end

    def apply(_action, on:)
      raise NotImplementedError
    end
  end
end
