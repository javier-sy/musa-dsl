using Musa::Extension::Hashify
using Musa::Extension::Arrayfy

using Musa::Extension::InspectNice

module Musa; module Sequencer
  class BaseSequencer

    def move3(timed_serie,
              reference: nil,
              step: nil,
              right_open: nil,
              on_stop: nil,
              after_bars: nil, after: nil,
              &block)

      control = _move3(timed_serie.instance,
                       reference: reference,
                       step: step,
                       right_open: right_open,
                       on_stop: on_stop,
                       after_bars: after_bars, after: after,
                       &block)

      # TODO falta pasar la craeción del control y la parte final de on_stop, after_bars aquí (ahora está en _move3)
    end

    def _move3(timed_serie,
               reference: nil,
               step: nil,
               right_open: nil,
               on_stop: nil,
               after_bars: nil, after: nil,
               &block)

      reference ||= 0r
      step ||= 1r

      if first_value_sample = timed_serie.peek_next_value

        debug "_move3: first_value_sample #{first_value_sample}"

        hash_mode = first_value_sample[:value].is_a?(Hash)

        if hash_mode
          components = first_value_sample[:value].keys

          reference = reference.hashify(keys: components)
          step = step.hashify(keys: components)
          right_open = right_open.hashify(keys:components)
        else
          size = first_value_sample[:value].size
          components = (0 .. size-1).to_a

          reference = reference.arrayfy(size: size)
          step = step.arrayfy(size: size)
          right_open = right_open.arrayfy(size: size)
        end

        split = timed_serie.flatten_timed.split
        quantized_series = hash_mode ? {} : []

        components.each do |component|
          quantized_series[component] =
              QUANTIZE(split[component],
                       reference: reference[component],
                       step: step[component],
                       right_open: right_open[component],
                       stops: true).instance
        end

        last_positions = hash_mode ? {} : []
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

      _move3_step(hash_mode, components, quantized_series, position, last_positions, binder, control)

      @event_handlers.pop

      control
    end


    def _move3_step(hash_mode, components, quantized_series, start_position, last_positions, binder, control)

      affected_components_by_time = {}

      components.each do |component|
        if v = quantized_series[component].peek_next_value

          debug "_move3_step: quantized_series[#{component}].peek_next_value #{v}"
          time = v[:time]

          affected_components_by_time[time] ||= []
          affected_components_by_time[time] << component
        end
      end

      if affected_components_by_time.any?
        time = affected_components_by_time.keys.sort.first

        values = hash_mode ? {} : []
        next_values = hash_mode ? {} : []
        durations = hash_mode ? {} : []
        q_durations = hash_mode ? {} : []
        started_ago = hash_mode ? {} : []

        affected_components_by_time[time].each do |component|
          value = quantized_series[component].next_value

          values[component] = value[:value]
          durations[component] = value[:duration]

          q_durations[component] =
              _quantize_position(time + durations[component], warn: false) -
              _quantize_position(time, warn: false)

          nv = quantized_series[component].peek_next_value
          next_values[component] = (nv && nv[:value] != values[component]) ? nv[:value] : nil

          last_positions[component] = _quantize_position(time, warn: false)
        end

        components.each do |component|
          if last_positions[component] && last_positions[component] != time
            sa = _quantize_position(time, warn: false) - last_positions[component]
            started_ago[component] = (sa == 0) ? nil : sa
          end
        end

        _numeric_at start_position + _quantize_position(time, warn: false), control do

          debug "_move_3_step: before binder.call: durations #{durations} q_durations #{q_durations}"

          binder.call(values, next_values,
                      duration: durations,
                      quantized_duration: q_durations,
                      started_ago: started_ago,
                      control: control)

          _move3_step(hash_mode, components, quantized_series, start_position, last_positions, binder, control)
        end
      end
    end



    # Este es un modo muy interesante pero que implica un procesamiento diferente en el yield_block que no me
    # sirve para el código de samples/multidim_sample, puesto que en este el next_values es literal, mientras que samples/multidim_sample
    # necesita que el next_value sea nil si el valor no cambia durante el periodo.
    #
    def _move3_tipoA_step(hash_mode, components, quantized_series, start_position, last_positions, binder, control)

      affected_components_by_time = {}

      components.each do |component|
        if v = quantized_series[component].peek_next_value

          debug "_move3_step: quantized_series[#{component}].peek_next_value #{v}"
          time = v[:time]

          affected_components_by_time[time] ||= []
          affected_components_by_time[time] << component
        end
      end

      if !affected_components_by_time.empty?
        time = affected_components_by_time.keys.sort.first

        values = hash_mode ? {} : []
        next_values = hash_mode ? {} : []
        durations = hash_mode ? {} : []
        q_durations = hash_mode ? {} : []
        started_ago = hash_mode ? {} : []

        affected_components_by_time[time].each do |component|
          value = quantized_series[component].next_value

          values[component] = value[:value]
          durations[component] = value[:duration]

          q_durations[component] =
              _quantize_position(time + durations[component], warn: false) -
                  _quantize_position(time, warn: false)

          last_positions[component] = _quantize_position(time, warn: false)
        end

        components.each do |component|
          nv = quantized_series[component].peek_next_value
          next_values[component] = nv[:value] if nv

          if last_positions[component] && last_positions[component] != time
            started_ago[component] = _quantize_position(time, warn: false) - last_positions[component]
          end
        end

        _numeric_at start_position + _quantize_position(time, warn: false), control do
          binder.call(values, next_values,
                      duration: durations,
                      quantized_duration: q_durations,
                      started_ago: started_ago,
                      control: control)

          _move3_step(hash_mode, components, quantized_series, start_position, last_positions, binder, control)
        end
      end
    end
  end
end; end

