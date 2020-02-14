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
      def initialize(base, transcriptor: nil)
        @base = base
        @last = base.clone

        @transcriptor = transcriptor
      end

      attr_accessor :transcriptor
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

        if @transcriptor
          @transcriptor.transcript(result)
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

