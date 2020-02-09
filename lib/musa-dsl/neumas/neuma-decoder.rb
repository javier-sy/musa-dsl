require_relative 'neumas'

module Musa::Neumas
  module Decoders
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

      attr_accessor :processor
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
end

