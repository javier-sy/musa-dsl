require_relative 'string-to-neumas'

using Musa::Extension::Neumas

module Musa
  module Neumas
    module Neuma
      module Parallel
        include Neuma
      end

      module Serie
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
          raise ArgumentError, "Don't know how to convert to neumas #{e}"
        end
      end
    end
  end
end
