module Musa::Neumas
  module Decoders
    module Parser
      extend self

      def parse(expression, base_duration: nil)
        base_duration ||= 1/4r
        expression.clone.extend(Musa::Datasets::GDVd).tap do |_|
          _.base_duration = base_duration

          _[:abs_duration] *= base_duration if _.has_key?(:abs_duration)
          _[:delta_duration] *= base_duration if _.has_key?(:delta_duration)
        end
      end
    end
  end
end
