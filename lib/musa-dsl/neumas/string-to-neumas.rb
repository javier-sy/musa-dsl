require_relative '../neumalang'
require_relative '../generative/generative-grammar'

module Musa
  module Extension
    module Neumas
      refine String do
        def to_neumas(decode_with: nil, debug: nil)
          Musa::Neumalang::Neumalang.parse(self, decode_with: decode_with, debug: debug)
        end

        def to_neumas_to_node(decode_with: nil, debug: nil)
          to_neumas(decode_with: decode_with, debug: debug).to_node
        end

        def |(other)
          case other
          when String
            { kind: :parallel,
              parallel: [{ kind: :serie, serie: self.to_neumas },
                         { kind: :serie, serie: other.to_neumas }] }.extend(Musa::Neumas::Neuma::Parallel)
          else
            raise ArgumentError, "Don't know how to parallelize #{other}"
          end
        end


        alias_method :neumas, :to_neumas
        alias_method :n, :to_neumas
        alias_method :nn, :to_neumas_to_node
      end
    end
  end
end
