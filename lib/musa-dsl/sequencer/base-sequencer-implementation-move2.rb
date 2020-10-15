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
          reference = reference.hashify(keys: ps[:from].keys)
          step = step.hashify(keys: ps[:from].keys)
          quantizer = {}.tap { |_| component.each { |k| _[k] = Quantizer.new } }
        else
          component = (0 .. ps[:from].size-1).to_a
          reference = reference.arrayfy(size: ps[:from].size)
          step = step.arrayfy(size: ps[:from].size)
          quantizer = Array.new(ps[:from].size) { Quantizer.new }
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
        _move2_step(ps_serie, hash_mode, component, reference, step, binder, control, quantizer)
      else
        # normal move from: to: ¿¿?? too many missing parameters to be a reasonable option?
      end

      @event_handlers.pop

      control

    end


    def _move2_every(...)
      raise NotImplementedError
    end

    def _move2_step(ps_serie, hash_mode, components, references, steps, binder, control, quantizers, first_ps = true)

      if ps = ps_serie.next_value
        ps.validate!

        puts
        puts "#{position.inspect}: ps #{ps}"

        finish_position = position + ps[:duration]

        periodic_group = {}

        components.each do |c|

          quantizers[c].push time: finish_position, value: ps[:to][c], last: ps_serie.peek_next_value.nil?

          quantizers[c].crossing(references[c] + steps[c] / 2r, steps[c]).each do |v|

            time = v[:time]
            value = v[:value]
            crossing = v[:crossing]
            sign = v[:sign]
            first = v[:first]
            last = v[:last]

            if crossing
              periodic_group[time] ||= {}
              periodic_group[time][c] = value + sign * steps[c] / 2r
            end
          end
        end

        periodic_group.each_pair do |time, effective_values|

          _numeric_at time, control do
            binder.call(effective_values, control: control)
          end

          # binder.apply(effective_values, effective_next_values,
          #              control: control,
          #              duration: _durations(every_groups, effective_duration),
          #              quantized_duration: q_durations.dup,
          #              started_ago: _started_ago(last_position, position, process_indexes),
          #              position_jitter: position_jitters.dup,
          #              duration_jitter: duration_jitters.dup,
          #              right_open: right_open.dup)
        end

        _numeric_at finish_position, control do
          _move2_step(ps_serie, hash_mode, components, references, steps, binder, control, quantizers, false)
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
      # Quantizer gets a flow of time and value pairs of one line (via push method) and can answer
      # where the line cross and touch the quantizing boundaries (via crossing method).
      #
      def initialize(reference, step_size)
        @reference = reference
        @step_size = step_size

        reset
      end

      def push(time:, value:, last: nil)
        raise ArgumentError, "'time:' value should be greater than previous time pushed" \
          unless @values.empty? || time > @values.last[:time]

        raise ArgumentError, "Can't push more values because last value has been received. You can 'reset' the quantizer to restart." \
          if @received_last

        if @values.empty?
          @first = value
        end

        @values.push({ time: time, value: value, is_last: last })
        @received_last = true if last

        if @values.size > 2
          @values.shift
          @first = nil
        end

        nil
      end

      # el planteamiento de quantizer tiene que ser que se puedan ir enviando por push datos
      # y que se vayan consumiendo con crossing() pero sólo si efectivamente hay cruces; si no los hay se guardan los datos
      # para ir acumulando los time y que las duration se puedan calcular correctamente
      # en el peor de los casos, cuando se recibe un push last: true habrá que contar todos los elementos añadidos y
      # generar aunque sea un sólo crossing "falso" que cuente la duración desde el principio hasta el final y quede como first: true, last: true y crossing: false


      def last
        @values.last
      end

      def reset
        @values = []
        @first = nil
        @last = nil
        @received_last = nil

        @time_cursor = nil
        @crossings = []
      end

      def crossing(upto_index = nil)
        upto_index = 1
        # The method returns an array of the crossing quantizing boundaries crossed or touched by the line.
        # The method calculates the possible steps where the line could
        # touch or cross a quantizing boundary (defined by a reference start point and a step_size incremental).
        # If the line doesn't cross nor touches any quantizing boundary the method returns [].
        # If the line is incomplete (not pushed a minimum of 2 points) the method returns nil.
        # For each possible crossing point the method calculates whether it is only a "touch" point (touching but not crossing the quantizing boundary)
        # or it is a crossing point (where the line really cross the boundary).
        # First and last points of the line could be touching points but as no previous (for first) or further (for last) line continuation exists
        # the method can't know if them really cross the boundary. For this reason the method returns a first: true or last: true,
        # to indicate this condition.
        # On each point the method returns, when known (on start and on crossing), whether the next point will be greater (sign 1) or minor (sign -1).
        # Please note the method doesn't return the begin and end points of the line unless they are a touch point. The method only returns
        # the crossing or touch points.
        # For instance: for a line (time, value) from (1, 1.5) to (3, 4), reference = 0 and step_size = 1, the method
        # only returns the crossing at values 2 (crossing: true), 3 (crossing: true) and the touch point 4 (crossing: false, last: true).

        return nil unless @values && @values.size >= 2

        last = @values[upto_index]
        previous = @values[upto_index - 1]

        last_value = last[:value]
        last_time = last[:time]

        previous_value = previous[:value]
        previous_time = previous[:time]

        sign = last_value >= previous_value ? 1r : -1r

        if sign == 1
          previous_step = ((previous_value - @reference) / @step_size).ceil
          last_step = ((last_value - @reference) / @step_size).floor
        else
          previous_step = ((previous_value - @reference) / @step_size).floor
          last_step = ((last_value - @reference) / @step_size).ceil
        end

        delta_value = last_value - previous_value
        delta_time = last_time - previous_time

        crossings = []

        # if @first
        #   crossings << { time: previous_time,
        #                  value: round_quantize(previous_value, @reference, @step_size),
        #                  first: true,
        #                  last: false,
        #                  sign: sign,
        #                  crossing: !(previous_step <=> last_step).zero? }
        # end

        previous_step.step(last_step, sign) do |i|

          value = @reference + i * @step_size

          first = !!(i == previous_step && @first == value)

          crossing = if sign > 0
                       value < last_value
                     else
                       value > last_value
                     end && !first

          crossings << { time: previous_time + (delta_time / delta_value) * (value - previous_value),
                         value: value,
                         first: first,
                         last: !!(i == last_step && last_value == value && last[:is_last]),
                         sign: first || crossing ? sign : nil,
                         crossing: crossing }
        end

        crossings
      end

      private def round_quantize(value, reference, step_size)
        ((value - reference) / step_size).round * step_size + reference
      end
    end

    # TODO uncomment: private_constant :Quantizer




  end
end; end

