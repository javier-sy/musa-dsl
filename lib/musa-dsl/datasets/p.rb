require_relative 'dataset'
require_relative 'ps'

module Musa::Datasets
  module P
    include Dataset

    def to_ps_serie(base_duration = nil)
      base_duration ||= 1/4r

      p = clone

      Musa::Series::E() do
        (p.size >= 3) ?
          { from: p.shift,
            duration: p.shift * base_duration,
            to: p.first,
            right_open: (p.length > 1) }.extend(PS).tap { |_| _.base_duration = base_duration } : nil
      end
    end
  end
end