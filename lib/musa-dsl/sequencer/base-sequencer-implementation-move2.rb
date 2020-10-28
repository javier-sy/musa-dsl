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
  end
end; end

