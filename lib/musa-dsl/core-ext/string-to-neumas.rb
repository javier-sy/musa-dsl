require 'musa-dsl/neumalang'
require 'musa-dsl/generative/generative-grammar'

class String
  def to_neumas(language: nil, decode_with: nil, debug: nil)
    Musa::Neumalang::Neumalang.parse(self, language: language, decode_with: decode_with, debug: debug)
  end

  def to_neumas_to_node(language: nil, decode_with: nil, debug: nil)
    to_neumas(language: language, decode_with: decode_with, debug: debug).to_node
  end

  def |(other)
    case other
    when String
      { kind: :parallel,
        parallel: [{ kind: :serie, serie: self.to_neumas },
                   { kind: :serie, serie: other.to_neumas }] }.extend(Musa::Neumalang::Neuma::Parallel)
    else
      raise ArgumentError, "Don't know how to parallelize #{other}"
    end
  end

  alias_method :neumas, :to_neumas
  alias_method :n, :to_neumas
  alias_method :nn, :to_neumas_to_node
end
