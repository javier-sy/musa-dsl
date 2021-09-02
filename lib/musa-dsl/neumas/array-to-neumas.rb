require_relative '../series'
require_relative '../neumalang'

module Musa
  module Extension
    module Neumas
      refine Array do
        def to_neumas
          if length > 1
            Musa::Series::Constructors.MERGE(*collect { |e| convert_to_neumas(e) })
          else
            convert_to_neumas(first)
          end
        end

        alias_method :neumas, :to_neumas
        alias_method :n, :to_neumas

        private

        def convert_to_neumas(e)
          case e
          when Musa::Neumas::Neuma::Serie then e
          when Musa::Neumas::Neuma::Parallel then Musa::Series::Constructors.S(e).extend(Musa::Neumas::Neuma::Serie)
          when String then e.to_neumas
          else
            raise ArgumentError, "Don't know how to convert to neumas #{e}"
          end
        end
      end
    end
  end
end

