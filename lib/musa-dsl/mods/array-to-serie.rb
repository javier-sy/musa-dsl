require 'musa-dsl/series'

class Array
  def to_serie(of_series: nil)
    of_series ||= false

    if of_series
      S(self)
    else
      S(collect { |_| S(_) })
    end
  end
end
