module Musa::Datasets
  module DatasetDecorators
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
  end
end
