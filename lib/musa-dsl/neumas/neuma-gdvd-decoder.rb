require_relative 'neuma-decoder'

module Musa::Neumas
  module Decoders
    class NeumaDifferentialDecoder < DifferentialDecoder # to get a GDVd
      def initialize(base_duration: nil)
        @base_duration = base_duration || Rational(1,4)
      end

      def process(gdvd)
        gdvd.clone.tap { |_| _.base_duration = @base_duration }
      end
    end
  end
end