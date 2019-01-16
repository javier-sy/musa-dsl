require 'musa-dsl/series'

class Array
  def to_serie(of_series: nil, recursive: nil)
    of_series ||= false
    recursive ||= false

    if recursive
      S(*(collect { |_| _.is_a?(Array) ? _.to_serie(recursive: true) : _ }))
    elsif of_series
      S(*(collect { |_| S(*_) }))
    else
      S(*self)
    end
  end

  alias_method :s, :to_serie
end
