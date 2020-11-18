require_relative '../datasets/e'
require_relative '../core-ext/inspect-nice'

# TODO remove debugging puts, intermediate hash comments on :info and InspectNice
using Musa::Extension::InspectNice

module Musa
  module Series
    module SerieOperations
      def quantize(reference: nil, step: nil,
                   value_attribute: nil,
                   stops: nil,
                   predictive: nil,
                   left_open: nil,
                   right_open: nil)

        Series.QUANTIZE(self,
                        reference: reference,
                        step: step,
                        value_attribute: value_attribute,
                        stops: stops,
                        predictive: predictive,
                        left_open: left_open,
                        right_open: right_open)
      end
    end
  end

  module Series
    extend self

    def QUANTIZE(time_value_serie,
                 reference: nil, step: nil,
                 value_attribute: nil,
                 stops: nil,
                 predictive: nil,
                 left_open: nil,
                 right_open: nil)

      reference ||= 0r
      step ||= 1r
      value_attribute ||= :value
      stops ||= false
      predictive ||= false

      if predictive
        raise ArgumentError, "Predictive quantization doesn't allow parameters 'left_open' or 'right_open'" if left_open || right_open

        PredictiveQuantizer.new(reference, step, time_value_serie, value_attribute, stops)
      else
        # By default: left closed and right_open
        # By default 2:
        #   if right_open is true and left_open is nil, left_open will be false
        #   if left_open is true and right_open is nil, right_open will be false

        right_open = right_open.nil? ? !left_open : right_open
        left_open = left_open.nil? ? !right_open : left_open

        RawQuantizer.new(reference, step, time_value_serie, value_attribute, stops, left_open, right_open)
      end
    end

    module QuantizerTools
      private def get_time_value(n)
        case n
        when nil
          time = value = nil
        when Musa::Datasets::AbsTimed
          time = n[:time].rationalize
          value = n[@value_attribute].rationalize
        when Array
          time = n[0].rationalize
          value = n[1].rationalize
        else
          raise RuntimeError, "Don't know how to process #{n}"
        end

        return time, value
      end
    end

    private_constant :QuantizerTools

    class RawQuantizer
      include Serie
      include QuantizerTools

      attr_reader :source

      def initialize(reference, step, source, value_attribute, stops, left_open, right_open)
        @reference = reference
        @step_size = step.abs

        @source = source
        @value_attribute = value_attribute

        @stops = stops
        @left_open = left_open
        @right_open = right_open

        _restart false

        mark_regarding! source
      end

      def _restart(restart_sources = true)
        @last_processed_q_value = nil
        @last_processed_time = nil

        @before_last_processed_q_value = nil

        @points = []
        @segments = []

        @source.restart if restart_sources
      end

      def _next_value
        if @stops
          i = 2

          loop do
            while @segments.size < i && process2; end

            first = @segments[0]
            last = @segments[i - 1]

            # puts "_next_value: first #{first || 'nil'} last #{last || 'nil'}"

            break if first.nil?

            if last.nil? || last[:stop] || first[:value] != last[:value]
              # puts "_next_value: found segments:"

              durations_to_sum = @segments.shift(i-1)

              # durations_to_sum.each { |i| puts i.inspect }
              #
              # puts "_next_value: result #{{ time: first[:time],
              #                  @value_attribute => first[:value],
              #                  duration: durations_to_sum.sum { |_| _[:duration] } }}"

              return { time: first[:time],
                       @value_attribute => first[:value],
                       duration: durations_to_sum.sum { |_| _[:duration] } }
                         .extend(Musa::Datasets::AbsTimed)
                         .extend(Musa::Datasets::AbsD)
            else
              i += 1
            end
          end

          return nil

        else
          i = 2
          # puts "\n\n"
          loop do
            while @segments.size < i && process2; end

            first = @segments[0]
            last = @segments[i - 1]

            # puts "_next_value: first #{first || 'nil'} last #{last || 'nil'}"

            break if first.nil?

            if last.nil? || first[:value] != last[:value]

              # puts "_next_value: found segments:"

              durations_to_sum = @segments.shift(i-1)

              # durations_to_sum.each { |i| puts i.inspect }
              #
              # puts "_next_value: result #{{ time: first[:time],
              #                  @value_attribute => first[:value],
              #                  duration: durations_to_sum.sum { |_| _[:duration] } }}"

              return { time: first[:time],
                       @value_attribute => first[:value],
                       duration: durations_to_sum.sum { |_| _[:duration] } }
                         .extend(Musa::Datasets::AbsTimed)
                         .extend(Musa::Datasets::AbsD)
            else
              i += 1
            end
          end

          return nil
        end
      end

      private def process2
        while (ready_count = count_ready_points) <= 2 &&
              process(*get_time_value(@source.next_value), !@source.peek_next_value)
        end

        if ready_count >= 2
          point = @points.shift

          from_time = point[:time]
          from_value = point[:value]

          next_point = @points.first

          to_time = next_point[:time]
          to_value = next_point[:value]
          to_point_is_last = next_point[:last]

          sign = to_value <=> from_value # to_value > from_value => +1

          # puts "process2: from_time #{from_time} from_value #{from_value} to_time #{to_time} to_value #{to_value} to_last #{to_point_is_last || 'nil'} sign #{sign}"

          if sign == 0
            if @segments.last && @segments.last[:time] == from_time

              @segments.last[:duration] = to_time - from_time
              @segments.last[:info] += '; edited on a as start'

            else
              @segments << { time: from_time,
                             value: from_value,
                             duration: to_time - from_time,
                             info: 'added on a as start' }

            end

            if !to_point_is_last
              @segments << { time: to_time,
                             value: from_value,
                             duration: 0,
                             stop: true,
                             info: 'added on a as end stop' }
            end
          else
            time_increment = to_time - from_time

            step_value_increment = @step_size * sign

            extra_steps = 0

            if @right_open
              loop_to_value = to_value - step_value_increment
            else
              loop_to_value = to_value
              extra_steps += 1
            end

            if @left_open
              loop_from_value = from_value + step_value_increment
              extra_steps -= 1
            else
              loop_from_value = from_value
            end

            step_time_increment = time_increment / ((to_value - from_value).abs + extra_steps)

            intermediate_point_time = from_time

            # puts "process2: loop_from_value #{loop_from_value} loop_to_value #{loop_to_value} step_value_increment #{step_value_increment} step_time_increment #{step_time_increment}"

            loop_from_value.step(loop_to_value, step_value_increment) do |value|
              if @segments.last &&
                @segments.last[:time] == intermediate_point_time &&
                @segments.last[:value] == value

                @segments.last[:duration] = step_time_increment
                @segments.last[:info] += '; edited on b'

                # puts "process2: editing #{@segments.last}"

              else
                @segments <<  v = { time: intermediate_point_time,
                                    value: value,
                                    duration: step_time_increment,
                                    info: 'added on b' }

                # puts "process2: adding #{v.inspect}"
              end

              intermediate_point_time += step_time_increment
            end
          end

          true
        else
          false
        end
      end

      private def count_ready_points
        @points.select { |_| _[:ready] }.size
      end

      private def process(time, value, last_time_value)
        if time && value
          raise RuntimeError, 'time only can go forward' if @last_processed_time && time <= @last_processed_time

          q_value = round_quantize(value)

          # A continuation point time will be changed if new points of equal value arrive.
          # For this reason this point is not ready to consume.
          # A ready point is a well determined point that can be consumed.
          # When we arrive to a well determined point all the previous points become also determined (ready).

          if q_value == @last_processed_q_value && !last_time_value
            if @points.size == 1 || @points.last[:ready]
              # If @points.last is the first point of a segment the new point is a continuation point.
              # The continuation point is used as a stop point.
              @points << { time: time, value: q_value }
            else
              # @points.last is NOT the first point of a segment but a continuation point.
              @points.last[:time] = time
            end
          else
            @points.reverse_each do |point|
              break if point[:ready]
              point[:ready] = true
            end

            @points << { time: time, value: q_value, ready: true, last: last_time_value }
          end

          @last_processed_q_value = q_value
          @last_processed_time = time

          true
        else
          false
        end
      end

      private def round_quantize(value)
        round((value - @reference) / @step_size) * @step_size + @reference
      end

      private def round(value)
        i = value.floor
        value > (i + 1/2r) ? i + 1r : i.rationalize
      end

      def infinite?
        !!@source.infinite?
      end
    end

    private_constant :RawQuantizer

    class PredictiveQuantizer
      include Serie
      include QuantizerTools

      attr_reader :source

      def initialize(reference, step, source, value_attribute, include_stops)
        @reference = reference
        @step_size = step

        @source = source
        @value_attribute = value_attribute

        @include_stops = include_stops

        @halfway_offset = step / 2r
        @crossing_reference = reference - @halfway_offset

        _restart false

        mark_regarding! source
      end

      def _restart(restart_sources = true)
        @source.restart if restart_sources

        @last_time = nil
        @crossings = []

        @first = true
      end

      def infinite?
        !!@source.infinite?
      end

      def _next_value
        result = nil

        first_time, first_value = get_time_value(@source.peek_next_value) if @first

        while @crossings.size <= 2 && process_more; end

        @crossings.delete_if { |c| c[:stop] && c[:stops].nil? }

        if @crossings[0]
          time = @crossings[0][:time]
          value = @crossings[0][@value_attribute]

          if @first
            @first = false

            if time > first_time
              result = { time: first_time,
                         @value_attribute => round_to_nearest_quantize(first_value, value),
                         duration: time - first_time }
                           .extend(Musa::Datasets::AbsD)
                           .extend(Musa::Datasets::AbsTimed)
            else
              result = _next_value
            end
          else
            if @crossings[1]
              next_time = @crossings[1][:time]
              result = { time: time,
                         @value_attribute => value,
                         duration: next_time - time }
                           .extend(Musa::Datasets::AbsD)
                           .extend(Musa::Datasets::AbsTimed)

              @crossings.shift

            else
              if @last_time && @last_time > @crossings[0][:time]
                result = { time: @crossings[0][:time],
                           @value_attribute => @crossings[0][@value_attribute],
                           duration: @last_time - @crossings[0][:time] }
                             .extend(Musa::Datasets::AbsD)
                             .extend(Musa::Datasets::AbsTimed)

                @last_time = nil
              end
            end
          end
        else
          if @first && @last_time && @last_time > first_time
            result = { time: first_time,
                       value: round_to_nearest_quantize(first_value),
                       duration: @last_time - first_time }
                         .extend(Musa::Datasets::AbsD)
                         .extend(Musa::Datasets::AbsTimed)

            @first = false
            @last_time = false
          end
        end

        return result
      end

      private def process_more
        while (@crossings.size <= 2 || @crossings[-1][:stop]) && new_crossings = next_crossings
          new_crossings.each do |c|
            if @last_time.nil? || c[:time] > @last_time

              if c[:stop] &&
                  @crossings.dig(-1, :stop) &&
                  @crossings.dig(-1, @value_attribute) == c[@value_attribute]

                c[:stops] = (@crossings[-1][:stops] || 0) + 1

                @crossings[-1] = c
              else
                @crossings << c
              end
            end
          end
        end

        !!new_crossings
      end

      private def next_crossings
        from_time, from_value = get_time_value(@source.next_value)

        if from_time && from_value
          raise RuntimeError, "time only can go forward" if @last_time && from_time <= @last_time

          @last_time = from_time

          to_time, to_value = get_time_value(@source.peek_next_value)

          if to_time && to_value
            crossings(from_time, from_value, to_time, to_value)
          end
        end
      end

      private def crossings(from_time, from_value, to_time, to_value)
        sign = to_value >= from_value ? 1r : -1r

        if sign == 1
          from_step = ((from_value - @crossing_reference) / @step_size).ceil
          last_step = ((to_value - @crossing_reference) / @step_size).floor
        else
          from_step = ((from_value - @crossing_reference) / @step_size).floor
          last_step = ((to_value - @crossing_reference) / @step_size).ceil
        end

        delta_value = to_value - from_value
        delta_time = to_time - from_time

        crossings =
            from_step.step(last_step, sign).collect do |i|
              value = @crossing_reference + i * @step_size

              { time: from_time + (delta_time / delta_value) * (value - from_value),
                @value_attribute => value + sign * @halfway_offset }
            end

        if @include_stops
          first_crossing_time = crossings.dig(0, :time)
          last_crossing_time = crossings.dig(-1, :time)

          if first_crossing_time.nil? || from_time < first_crossing_time
            stop_before = [ { time: from_time,
                              @value_attribute =>
                                  round_to_nearest_quantize(from_value,
                                                            crossings.dig(0, @value_attribute)),
                              stop: true } ]
          else
            stop_before = []
          end

          if last_crossing_time.nil? || to_time > last_crossing_time
            stop_after = [ { time: to_time,
                             @value_attribute =>
                                 round_to_nearest_quantize(to_value,
                                                           crossings.dig(-1, @value_attribute)),
                             stop: true } ]
          else
            stop_after = []
          end

          stop_before + crossings + stop_after
        else
          crossings
        end
      end

      private def round_to_nearest_quantize(value, nearest = nil)
        v = (value - @reference) / @step_size

        if nearest
          a = v.floor * @step_size + @reference
          b = v.ceil * @step_size + @reference

          (nearest - a).abs < (nearest - b).abs ? a : b
        else
          v.round * @step_size + @reference
        end
      end
    end

    private_constant :PredictiveQuantizer
  end
end
