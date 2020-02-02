require_relative '../series'
require_relative '../neumalang'

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
    when Musa::Neumas::Neumas then e
    when Musa::Neumas::Neuma::Parallel then _SE([e], extends: Musa::Neumas::Neumas)
    when String then e.to_neumas
    else
      raise ArgumentError, "Don't know how to convert to neumas #{e}"
    end
  end
end

