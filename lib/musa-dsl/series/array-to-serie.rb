require_relative '../series'

# TODO: esto sería un refinement, no?

class Array
  def to_serie(of_series: nil, recursive: nil)
    of_series ||= false
    recursive ||= false

    raise ArgumentError, 'Cannot convert to serie of_series and recursive simultaneously' if recursive && of_series

    if recursive
      Musa::Series::Constructors.S(*(collect { |_| _.is_a?(Array) ? _.to_serie(recursive: true) : _ }))
    elsif of_series
      Musa::Series::Constructors.S(*(collect { |_| Musa::Series::Constructors.S(*_) }))
    else
      Musa::Series::Constructors.S(*self)
    end
  end

  alias_method :s, :to_serie
end
