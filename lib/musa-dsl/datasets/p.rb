require_relative 'dataset'
require_relative 'ps'

require_relative '../series'
require_relative '../sequencer'

module Musa::Datasets
  module P
    include Dataset

    def to_ps_serie(base_duration: nil)
      base_duration ||= 1/4r # TODO review incoherence between neumalang 1/4r base duration for quarter notes and general 1r size of bar

      # TODO if instead of using clone (needed because of p.shift) we use index counter the P elements would be evaluated on the last moment

      Musa::Series::E(clone, base_duration) do |p, base_duration|
        (p.size >= 3) ?
          { from: p.shift,
            duration: p.shift * base_duration,
            to: p.first,
            right_open: (p.length > 1) }.extend(PS).tap { |_| _.base_duration = base_duration } : nil
      end
    end

    def to_timed_serie(time_start: nil, time_start_component: nil, base_duration: nil)
      time_start ||= 0r
      time_start += self.first&.[](time_start_component) || 0r

      base_duration ||= 1/4r # TODO review incoherence between neumalang 1/4r base duration for quarter notes and general 1r size of bar

      # TODO if instead of using clone (needed because of p.shift) we use index counter the P elements would be evaluated on the last moment

      Musa::Series::E(clone, base_duration, context: { time: time_start }) do |p, base_duration, context: |
        value = p.shift

        if value
          r = { time: context[:time], value: value } if !value.nil?

          delta_time = p.shift
          context[:time] += delta_time * base_duration if delta_time

          r&.extend(AbsTimed)
        end
      end
    end

    def map(&block)
      i = 0
      clone.map! do |element|
        # Process with block only the values (values are the alternating elements because P
        # structure is <value> <duration> <value> <duration> <value>)
        #
        if (i += 1) % 2 == 1
          block.call(element)
        else
          element
        end
      end
    end
  end
end