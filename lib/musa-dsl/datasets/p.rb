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

      Musa::Series::Constructors.E(clone, base_duration) do |p, base_duration|
        (p.size >= 3) ?
          { from: p.shift,
            duration: p.shift * base_duration,
            to: p.first,
            right_open: (p.length > 1) }.extend(PS).tap { |_| _.base_duration = base_duration } : nil
      end
    end

    def to_timed_serie(time_start: nil, time_start_component: nil, base_duration: nil)
      time_start ||= 0r
      time_start += self.first[time_start_component] if time_start_component

      base_duration ||= 1/4r # TODO review incoherence between neumalang 1/4r base duration for quarter notes and general 1r size of bar

      PtoTimedSerie.new(self, base_duration, time_start)
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

    class PtoTimedSerie
      include Musa::Series::Serie.base

      def initialize(origin, base_duration, time_start)
        @origin = origin
        @base_duration = base_duration
        @time_start = time_start

        _restart

        mark_as_prototype!
      end

      attr_accessor :origin
      attr_accessor :base_duration
      attr_accessor :time_start

      def _restart
        @index = 0
        @time = @time_start
      end

      def _next_value
        if value = @origin[@index]
          @index += 1
          r = { time: @time, value: value }.extend(AbsTimed)

          delta_time = @origin[@index]
          @index += 1
          @time += delta_time * @base_duration if delta_time

          r
        end
      end
    end
  end
end