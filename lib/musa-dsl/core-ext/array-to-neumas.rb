require 'musa-dsl/series'
require 'musa-dsl/neumalang'

class Array
  def to_neumas
    if length > 1
      MERGE(*collect { |e| convert_to_neumas(e) })
    else
      convert_to_neumas(first)
    end
  end

  alias_method :neumas, :to_neumas
  alias_method :n, :to_neumas

  private

  def convert_to_neumas(e)
    case e
    when Musa::Neumalang::Neumas then e
    when Musa::Neumalang::Neuma::Parallel then _SE([e], extends: Musa::Neumalang::Neumas)
    when String then e.to_neumas
    else
      raise ArgumentError, "Don't know how to convert to neumas #{e}"
    end
  end
end

