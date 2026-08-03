require_relative '../series'


class Array
  # TODO: esto sería un refinement, no?
  
  # Converts array to Serie.
  #
  # Three conversion modes:
  #
  # - **Basic**: Direct conversion to serie
  # - **of_series**: Each element of the array becomes a new serie (for array of arrays)
  # - **recursive**: Recursive conversion of nested arrays
  #
  # @param of_series [Boolean, nil] convert each element to a serie (default: false)
  # @param recursive [Boolean, nil] recursively convert nested arrays (default: false)
  #
  # @return [Serie] converted serie
  #
  # @raise [ArgumentError] if both of_series and recursive are true
  #
  # @example Basic conversion
  #   [60, 64, 67].to_serie.i.to_a  # => [60, 64, 67]
  #
  # @example Serie of series
  #   nested = [[1, 2], [3, 4]].to_serie(of_series: true)
  #
  #   # Each element is a serie of its own, so reading one means instantiating it
  #   nested.i.to_a.collect { |serie| serie.i.to_a }
  #   # => [[1, 2], [3, 4]]
  #
  # @example Recursive conversion
  #   nested = [[1, [2, 3]], [4, 5]].to_serie(recursive: true)
  #
  #   # It goes all the way down: the first element is a serie holding a value
  #   # and another serie.
  #   first = nested.i.next_value.i.to_a
  #   first.first          # => 1
  #   first.last.i.to_a    # => [2, 3]
  #
  # @api public
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

  # Short alias for {#to_serie}.
  #
  # @return [Serie] converted serie
  #
  # @example Short form
  #   [1, 2, 3].s  # => S(1, 2, 3)
  #
  # @api public
  alias_method :s, :to_serie
end
