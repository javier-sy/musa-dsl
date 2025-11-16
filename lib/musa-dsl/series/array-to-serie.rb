# Array extension adding Serie conversion methods.
#
# Extends Ruby's Array class with `to_serie` method for convenient
# conversion to Musa::Series::Serie objects.
#
# ## Conversion Modes
#
# - **Basic**: Simple array to serie conversion
# - **of_series**: Each element becomes a serie (array of arrays → serie of series)
# - **recursive**: Nested arrays recursively converted to nested series
#
# ## Usage
#
# ### Basic Conversion
#
# ```ruby
# [1, 2, 3].to_serie  # => S(1, 2, 3)
# ```
#
# ### Serie of Series
#
# ```ruby
# [[1, 2], [3, 4]].to_serie(of_series: true)
# # => S(S(1, 2), S(3, 4))
# ```
#
# ### Recursive Conversion
#
# ```ruby
# [[1, [2, 3]], [4, 5]].to_serie(recursive: true)
# # => S(S(1, S(2, 3)), S(4, 5))
# ```
#
# ## Musical Applications
#
# - Quick serie creation from literals
# - Converting algorithmic arrays to series
# - Nested musical structures (phrases, sections)
# - Data-driven composition
#
# @see Musa::Series::Constructors#S Basic serie constructor
#
require_relative '../series'

# TODO: esto sería un refinement, no?

# Ruby Array class extended with Serie conversion.
#
# @api public
class Array
  # Converts array to Serie.
  #
  # Three conversion modes:
  # - **Basic**: Direct conversion to serie
  # - **of_series**: Each element becomes serie (for array of arrays)
  # - **recursive**: Recursive conversion of nested arrays
  #
  # @param of_series [Boolean, nil] convert each element to serie (default: false)
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
  #   [[1, 2], [3, 4]].to_serie(of_series: true)
  #   # Each [1,2], [3,4] becomes S(1,2), S(3,4)
  #
  # @example Recursive conversion
  #   [[1, [2, 3]], [4, 5]].to_serie(recursive: true)
  #   # Nested arrays become nested series
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
