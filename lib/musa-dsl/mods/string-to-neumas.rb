require 'musa-dsl/neumalang'

class String
  def to_neumas(language: nil, decode_with: nil, debug: nil)
    Musa::Neumalang.parse(self, language: language, decode_with: decode_with, debug: debug)
  end
end
