require_relative 'neuma-decoder'
require_relative 'neuma-gdvd-parser'

module Musa::Neumas
  module Decoder
    class NeumaDifferentialDecoder < DifferentialDecoder # to get a GDVd
      def initialize(base_duration: nil)
        @base_duration = base_duration || Rational(1,4)
      end

      def parse(expression)
        Parser.parse(expression, base_duration: @base_duration)
      end
    end
  end
end