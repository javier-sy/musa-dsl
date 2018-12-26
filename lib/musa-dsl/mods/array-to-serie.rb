require 'musa-dsl/series'

class Array
  def to_serie(of_series: nil)
    of_series ||= false

    if of_series
      S(collect { |_| S(_) })
    else
      S(self)
    end
  end
end
