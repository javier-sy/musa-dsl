using Musa::Extension::Hashify
using Musa::Extension::Arrayfy

using Musa::Extension::InspectNice

module Musa; module Sequencer
  class BaseSequencer
    def _move2(ps_serie,
               every: nil,
               reference: nil,
               step: nil,
               on_stop: nil,
               after_bars: nil, after: nil,
               &block)

      raise ArgumentError,
            "Cannot use 'every' and 'step' parameters at the same time. Use only one of them." if every && step

      raise ArgumentError,
            "Cannot use 'every' and 'step' parameters at the same time. Use only one of them." if every && step

      raise NotImplementedError, "TODO: add description for exception" unless every || step # TODO

      if ps = ps_serie.peek_next_value

        ps.validate!

        hash_mode = ps[:from].is_a?(Hash)

        if hash_mode
          component = ps[:from].keys
          last_positions = {}

          reference = reference.hashify(keys: ps[:from].keys)
          step = step.hashify(keys: ps[:from].keys)

          quantizer = {}.tap { |_| component.each { |k| _[k] = Quantizer.new reference[k], step[k] } }
        else
          component = (0 .. ps[:from].size-1).to_a
          last_positions = []

          reference = reference.arrayfy(size: ps[:from].size)
          step = step.arrayfy(size: ps[:from].size)

          quantizer = Array.new(ps[:from].size) { |i| Quantizer.new reference[i], step[i] }
        end

        component.each { |c| quantizer[c].push time: position, value: ps[:from][c] }
      end

      control = Move2Control.new(@event_handlers.last,
                                 on_stop: on_stop, after_bars: after_bars, after: after)

      control.on_stop do
        control.do_after.each do |do_after|
          _numeric_at position + do_after[:bars], control, &do_after[:block]
        end
      end

      binder = SmartProcBinder.new(block)

      @event_handlers.push control

      if every
        _move2_every(ps_serie, hash_mode, component, every, binder, control)
      elsif step
        _move2_step(ps_serie, hash_mode, component, last_positions, binder, control, quantizer)
      else
        # normal move from: to: ¿¿?? too many missing parameters to be a reasonable option?
      end

      @event_handlers.pop

      control

    end


    def _move2_every(...)
      raise NotImplementedError
    end

    def _move2_step(ps_serie, hash_mode, components, start_position = nil, last_positions, binder, control, quantizers)


      if ps = ps_serie.next_value
        ps.validate!
        is_last = ps_serie.peek_next_value.nil?

        puts
        puts "#{position.inspect}: ps #{ps} is_last = #{is_last}"

        start_position ||= position

        finish_position = start_position + ps[:duration]

        same_time_events = {}

        components.each do |c|
          quantizers[c].push time: finish_position, value: ps[:to][c], last: is_last

          while qi = quantizers[c].pop
            time = qi[:time]

            same_time_events[time] ||= {}
            same_time_events[time][c] = { value: qi[:value], duration: qi[:duration] }
          end
        end

        last_time = nil

        same_time_events.keys.sort.each do |time|
          events = same_time_events[time]

          values = hash_mode ? {} : []
          durations = hash_mode ? {} : []
          q_durations = hash_mode ? {} : []
          started_ago = hash_mode ? {} : []

          events.each_pair do |component, parameters|
            values[component] = parameters[:value]
            durations[component] = parameters[:duration]

            q_durations[component] = _quantize(time + durations[component]) - _quantize(time)

            last_positions[component] = time
          end

          components.each do |component|
            if last_positions[component] && last_positions[component] != time
              started_ago[component] = time - last_positions[component]
            end
          end

          _numeric_at time, control do
            binder.call(values, 'next_values',
                        duration: durations,
                        quantized_duration: q_durations,
                        started_ago: started_ago,
                        control: control)
          end

          last_time = time
        end

        _numeric_at last_time, control do
          _move2_step(ps_serie, hash_mode, components, finish_position, last_positions, binder, control, quantizers)
        end

      else
        # TODO is necessary to make a finish binder.call? or we can assume the last correct values have been already executed?
        # finish_values = hash_mode ? {} : []
        #
        # components.each do |c|
        #   quantized_value = round_quantize(quantizers[c].last[:value], references[c], steps[c])
        #   finish_values[c] = quantized_value if quantized_value != quantizers[c].last[:value]
        #
        #   # TODO what should we do with open_right???
        # end
        #
        # binder.call(finish_values, control: control)

        # TODO implement finish context and after block execution
      end
    end




    class Quantizer
      # Quantizer gets a flow of time and value pairs of one line (via push method) and offers a flow of quantized segments
      # with transitions on boundary crossings (via pop method).
      #
      def initialize(reference, step_size)
        @halfway_offset = step_size / 2r

        @reference = reference - @halfway_offset
        @step_size = step_size

        reset
      end

      def push(time:, value:, last: nil)
        last ||= false

        raise ArgumentError, "'time:' value should be greater than previous time pushed" \
          unless @values.empty? || time > @values.last[:time]

        raise ArgumentError, "Can't push more values because last value has been received. You can 'reset' the quantizer to restart." \
          if @received_last

        @values.push(v = { time: time, value: value, is_first: @values.empty?, is_last: last })
        @received_last = true if last

        nil
      end

      def last
        @values.last
      end

      def reset
        @values = []
        @received_last = nil

        @time_cursor = nil
        @crossings = []
      end

      def pop
        if @crossings.size > 1
          cross = @crossings.shift
          next_cross = @crossings.first

          cross[:duration] = next_cross[:time] - cross[:time]
          cross[:last] = next_cross[:last] && !@crossings[0][:duration]
        else
          process_next

          if @crossings.size > 1
            cross = @crossings.shift
            next_cross = @crossings.first

            cross[:duration] = next_cross[:time] - cross[:time]
            cross[:last] = next_cross[:last] && !@crossings[0][:duration]

          elsif @crossings.size == 1 && @crossings[0][:last] && @crossings[0][:duration]
            cross = @crossings.shift

          else
            cross = nil
          end
        end

        cross
      end

      private def process_next
        crossings = []
        i = 0

        while crossings.empty? && i < @values.size - 1
          crossings = calculate_crossings(
              @values[0][:time],
              @values[0][:value],
              @values[i+1][:time],
              @values[i+1][:value],
              is_first: @values[0][:is_first],
              is_last: @values[i+1][:is_last])

          i += 1
        end

        if !crossings.empty?
          if !@crossings.empty? && @crossings[-1][:time] == crossings[0][:time]
            @crossings[-1] = crossings.shift
          end

          until crossings.empty?
            @crossings << crossings.shift
          end

          i.times { @values.shift }
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
                           value: @reference + (i - sign) * @step_size + sign * @halfway_offset,
                           first: first,
                           last: false }
          end

          crossings << { time: from_time + (delta_time / delta_value) * (value - from_value),
                         value: value + sign * @halfway_offset,
                         first: first && from_value == value,
                         last: last }

          if last && to_value != value
            crossings.last[:duration] = to_time - crossings.last[:time]
          end
        end

        if crossings.empty? && is_first && is_last
          crossings << { time: from_time,
                         value: round_quantize(from_value, @reference + @halfway_offset, @step_size),
                         first: true,
                         last: true,
                         duration: to_time - from_time }
        end

        crossings
      end

      private def round_quantize(value, reference, step_size)
        ((value - reference) / step_size).round * step_size + reference
      end
    end
  end
end; end

