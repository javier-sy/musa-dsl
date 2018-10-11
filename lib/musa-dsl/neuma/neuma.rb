module Musa::Neuma
  module Dataset end

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
