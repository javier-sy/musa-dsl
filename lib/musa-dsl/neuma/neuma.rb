module Musa::Neuma
  module Dataset
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

    def modificator_string(modificator, parameters)
      case parameters
      when true
        modificator
      when Array
        modificator.to_s + '(' +
          parameters.collect do |parameter|
            case parameter
            when String
              "\"#{parameter}\""
            when Numeric
              "#{parameter}"
            when Symbol
              "#{parameter}"
            end
          end.join(', ') + ')'
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
    def initialize(start)
      @start = start.clone
      @last = start.clone
    end

    def subcontext
      Decoder.new @start
    end

    def decode(attributes)
      result = apply parse(attributes), on: @last

      @last = result.clone

      result
    end

    def apply(_action, on:)
      raise NotImplementedError
    end
  end
end
