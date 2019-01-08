module Musa::Neuma
  module Dataset
    class Decorator
      def process(element, **_parameters)
        element
      end
    end

    class TwoNeumasDecorator
      def process(element1, element2, **_parameters)
        element2
      end
    end

    class Decorators
      attr_reader :decorators
      attr_accessor :appogiatura_decorator

      def initialize(*decorators, appogiatura_decorator: nil, tick_duration: nil)
        @tick_duration = tick_duration || 1/96r
        @appogiatura_decorator = appogiatura_decorator
        @decorators = decorators
      end

      def process(element)
        if @appogiatura_decorator
          element = @appogiatura_decorator.process(element, tick_duration: @tick_duration)
        end

        @decorators.each do |processor|
          if element
            if element.is_a?(Array)
              element = element.collect { |element_i| processor.process(element_i, tick_duration: @tick_duration) }.flatten(1)
            else
              element = processor.process(element, tick_duration: @tick_duration)
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
    def initialize(start, processor: nil)
      @start = start.clone
      @last = start.clone

      @processor = processor
    end

    def subcontext
      Decoder.new @start
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
