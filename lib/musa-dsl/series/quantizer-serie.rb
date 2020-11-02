require_relative '../datasets/e'

module Musa
  module Series
    extend self

    def QUANTIZE(time_value_serie, reference: nil, step: nil, value_attribute: nil, crossings_aware: nil)
      reference ||= 0r
      step ||= 1r
      value_attribute ||= :value
      crossings_aware ||= false

      if crossings_aware
        CrossingsAwareQuantizer.new(reference, step, time_value_serie, value_attribute)
      else
        RawQuantizer.new(reference, step, time_value_serie, value_attribute)
      end
    end

    class RawQuantizer
      include Serie

      attr_reader :source

      def initialize(reference, step, source, value_attribute)
        @reference = reference
        @step_size = step

        @source = source
        @value_attribute = value_attribute

        _restart false

        mark_regarding! source
      end

      def _restart(restart_sources = true)
        @last_processed_q_value = nil
        @last_processed_time = nil

        @before_last_processed_q_value = nil

        @points = []
        @crossings = []

        @source.restart if restart_sources
      end

      def _next_value
        if !@crossings.empty?
          @crossings.shift.extend(AbsD).extend(AbsTimed)
        else
          while @points.size < 2 && process_more; end

          there_are_more_values = !!@source.peek_next_value

          if @points.size >= 2
            point = @points.shift
            # point[:info] ||= ""

            next_point = @points[0]

            from_value = point[@value_attribute]
            from_time = point[:time]

            to_value = next_point[@value_attribute]
            to_time = next_point[:time]

            sign = to_value > from_value ? 1r : -1r

            if to_value != from_value
              time_increment = to_time - from_time
              step_time_increment = time_increment / (to_value - from_value)

              step_size_increment = @step_size.abs * sign

              intermediate_point_time = from_time

              from_value.step(to_value, step_size_increment) do |value|

                if value == to_value && there_are_more_values
                  @crossings[-1][:duration] = to_time - @crossings[-1][:time]
                  # @crossings[-1][:info] += "; added duration at intermediate on value == to_value && there_are_more_values"
                else
                  intermediate_point = point.clone

                  intermediate_point[:time] = intermediate_point_time
                  intermediate_point[@value_attribute] = value

                  # intermediate_point[:info] += "intermediate_point there_are_more_values #{there_are_more_values || 'nil'}"
                  @crossings << intermediate_point

                  if @crossings[-2]
                    @crossings[-2][:duration] = @crossings[-1][:time] - @crossings[-2][:time]
                    # @crossings[-2][:info] += "; added duration at intermediate"
                  end

                  intermediate_point_time += step_time_increment
                end
              end
            else
              point[:duration] = @points.first[:time] - point[:time]
              # point[:info] += "standalone"
              @crossings << point
            end

            _next_value
          else
            nil
          end
        end
      end

      private def process_more
        case n = @source.next_value
        when nil
          time = value = nil
        when AbsTimed
          time = n[:time].rationalize
          value = n[@value_attribute].rationalize
        when Array
          time = n[0].rationalize
          value = n[1].rationalize
        else
          raise RuntimeError, "Don't know how to process #{n}"
        end

        if time && value
          q_value = round_quantize(value, @reference, @step_size)

          if q_value != @last_processed_q_value
            if @last_processed_q_value && @last_processed_time != @points.last[:time]
              @points << { time: @last_processed_time, @value_attribute => @last_processed_q_value }
            end

            @points << { time: time, @value_attribute => q_value }
          end

          @last_processed_q_value = q_value
          @last_processed_time = time

          true
        else
          false
        end
      end

      private def round_quantize(value, reference, step_size)
        ((value - reference) / step_size).round * step_size + reference
      end

      def infinite?
        !!@source.infinite?
      end
    end

    private_constant :RawQuantizer

    class CrossingsAwareQuantizer
      include Serie

      attr_reader :source

      def initialize(reference, step, source, value_attribute)
        @halfway_offset = step / 2r

        @reference = reference - @halfway_offset
        @step_size = step

        @source = source
        @value_attribute = value_attribute

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
        case n = @source.next_value
        when nil
          time = value = nil
        when AbsTimed
          time = n[:time].rationalize
          value = n[@value_attribute].rationalize
        when Array
          time = n[0].rationalize
          value = n[1].rationalize
        else
          raise RuntimeError, "Don't know how to process #{n}"
        end

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
                @source_values[i][:time],
                @source_values[i][:value],
                @source_values[i+1][:time],
                @source_values[i+1][:value],
                is_first: @source_values[0][:is_first],
                is_last: @source_values[i+1][:is_last])

            i += 1
          end

          unless new_crossings.empty?
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

      private def calculate_crossings(from_time, from_value,
                                      last_from_time, last_from_value,
                                      to_time, to_value,
                                      is_first:, is_last:)

        sign = to_value >= from_value ? 1r : -1r

        # TODO remove code commented and x variable
        # puts "\ncalculate_crossings...\tfrom_time #{from_time} last_from_time #{last_from_time} to_time #{to_time}\n\t\t\tfrom_value #{from_value} last_from_value #{last_from_value} to_value #{to_value}\n\t\t\tis_first #{is_first} is_last #{is_last}\n\t\t\tsign #{sign}"

        if sign == 1
          from_step = ((from_value - @reference) / @step_size).ceil
          previous_step = ((last_from_value - @reference) / @step_size).ceil
          last_step = ((to_value - @reference) / @step_size).floor
        else
          from_step = ((from_value - @reference) / @step_size).floor
          previous_step = ((last_from_value - @reference) / @step_size).floor
          last_step = ((to_value - @reference) / @step_size).ceil
        end

        # puts "calculate_crossings:\tfrom_step #{from_step} previous_step #{previous_step} last_step #{last_step}"

        crossings = []


        if from_time < last_from_time && (previous_step <=> last_step) == -sign
          added_start_point_as_crossing = true

          crossings << x = { time: from_time,
                             @value_attribute =>
                                 @reference + (from_step - sign) * @step_size + sign * @halfway_offset }

          # puts "calculate_crossings:\tfrom_time < last_from_time && (previous_step <=> last_step) == sign"
          # puts "calculate_crossings:\tadded #{x}"
        end

        previous_step.step(last_step, sign) do |i|
          value = @reference + i * @step_size

          first = is_first && i == previous_step && !added_start_point_as_crossing
          last = is_last && i == last_step

          delta_value = to_value - last_from_value
          delta_time = to_time - last_from_time

          # puts "calculate_crossings:\tvalue #{value} delta_time #{delta_time} delta_value #{delta_value}"

          if first && from_value != value
            crossings << x = { time: last_from_time,
                               @value_attribute => @reference + (i - sign) * @step_size + sign * @halfway_offset }
            # puts "calculate_crossings:\tfirst && from_value != value"
            # puts "calculate_crossings:\tadded #{x}"
          end

          crossings << x = { time: last_from_time + (delta_time / delta_value) * (value - last_from_value),
                             @value_attribute => value + sign * @halfway_offset }


          if last && to_value != value
            crossings.last[:duration] = to_time - crossings.last[:time]
          end

          # puts "calculate_crossings:\t..."
          # puts "calculate_crossings:\tadded #{x}"
        end

        if crossings.empty? && is_first && is_last
          crossings << x = { time: from_time,
                             @value_attribute => round_quantize(from_value, @reference + @halfway_offset, @step_size),
                             duration: to_time - from_time }
          # puts "calculate_crossings:\tcrossings.empty? && is_first && is_last"
          # puts "calculate_crossings:\tadded #{x}"
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

    private_constant :CrossingsAwareQuantizer

  end
end
