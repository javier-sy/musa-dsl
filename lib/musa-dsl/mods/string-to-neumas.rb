require 'musa-dsl/neumalang'
require 'musa-dsl/generative/generative-grammar'

class String
  def to_neumas(language: nil, decode_with: nil, debug: nil)
    Musa::Neumalang.parse(self, language: language, decode_with: decode_with, debug: debug)
  end

  def to_neumas_to_node(language: nil, decode_with: nil, debug: nil)
    to_neumas(language: language, decode_with: decode_with, debug: debug).to_node
  end

  alias_method :neu, :to_neumas
  alias_method :nn, :to_neumas_to_node
end
