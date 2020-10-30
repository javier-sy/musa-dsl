require_relative '../datasets/e'

module Musa
  module Series
    extend self

    def QUANTIZE(time_value_serie, reference: nil, step: nil)
      reference ||= 0r
      step ||= 1r

      Quantizer.new(reference, step, time_value_serie)
    end

    class Quantizer
      include Serie

      attr_reader :source

      def initialize(reference, step, source)
        @halfway_offset = step / 2r

        @reference = reference - @halfway_offset
        @step_size = step

        @source = source

        _restart false

        mark_regarding! source
      end

      def _restart(restart_sources = true)
        @source_values = []
        @crossings = []

        @source.restart if restart_sources
      end

      def _next_value
        if @crossings.size > 1
          cross = @crossings.shift
          next_cross = @crossings.first

          cross[:duration] = next_cross[:time] - cross[:time]

        else
          while process_next && @crossings.size <= 1; end

          if @crossings.size > 1
            cross = @crossings.shift
            next_cross = @crossings.first

            cross[:duration] = next_cross[:time] - cross[:time]

          elsif @crossings.size == 1 && @crossings[0][:duration]
            cross = @crossings.shift

          else
            cross = nil
          end
        end

        cross&.extend(AbsD).extend(AbsTimed)
      end

      private def process_next
        time, value = @source.next_value

        if time && value
          raise RuntimeError, "'time:' value should be greater than previous time pushed" \
            unless @source_values.empty? || time > @source_values.last[:time]

          @source_values << { time: time, value: value, is_first: @source_values.empty?, is_last: !@source.peek_next_value }

          new_crossings = []
          i = 0

          while new_crossings.empty? && i < @source_values.size - 1
            new_crossings = calculate_crossings(
                @source_values[0][:time],
                @source_values[0][:value],
                @source_values[i+1][:time],
                @source_values[i+1][:value],
                is_first: @source_values[0][:is_first],
                is_last: @source_values[i+1][:is_last])

            i += 1
          end

          if !new_crossings.empty?
            if !@crossings.empty? && @crossings[-1][:time] == new_crossings[0][:time]
              @crossings[-1] = new_crossings.shift
            end

            until new_crossings.empty?
              @crossings << new_crossings.shift
            end

            i.times { @source_values.shift }
          end

          true
        else
          nil
        end
      end

      private def calculate_crossings(from_time, from_value, to_time, to_value, is_first:, is_last:)
        sign = to_value >= from_value ? 1r : -1r

        if sign == 1
          previous_step = ((from_value - @reference) / @step_size).ceil
          last_step = ((to_value - @reference) / @step_size).floor
        else
          previous_step = ((from_value - @reference) / @step_size).floor
          last_step = ((to_value - @reference) / @step_size).ceil
        end

        delta_value = to_value - from_value
        delta_time = to_time - from_time

        crossings = []

        previous_step.step(last_step, sign) do |i|
          value = @reference + i * @step_size

          first = is_first && i == previous_step
          last = is_last && i == last_step

          if first && from_value != value
            crossings << { time: from_time,
                           value: @reference + (i - sign) * @step_size + sign * @halfway_offset }
          end

          crossings << { time: from_time + (delta_time / delta_value) * (value - from_value),
                         value: value + sign * @halfway_offset }

          if last && to_value != value
            crossings.last[:duration] = to_time - crossings.last[:time]
          end
        end

        if crossings.empty? && is_first && is_last
          crossings << { time: from_time,
                         value: round_quantize(from_value, @reference + @halfway_offset, @step_size),
                         duration: to_time - from_time }
        end

        crossings
      end

      private def round_quantize(value, reference, step_size)
        ((value - reference) / step_size).round * step_size + reference
      end

      def infinite?
        !!@source.infinite?
      end
    end

    private_constant :Quantizer
  end
end
