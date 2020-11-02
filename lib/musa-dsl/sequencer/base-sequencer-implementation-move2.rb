using Musa::Extension::Hashify
using Musa::Extension::Arrayfy

using Musa::Extension::InspectNice

module Musa; module Sequencer
  class BaseSequencer

    def move3(timed_serie,
              reference: nil,
              step: nil,
              on_stop: nil,
              after_bars: nil, after: nil,
              &block)

      control = _move3(timed_serie.instance,
                       reference: reference,
                       step: step,
                       on_stop: on_stop,
                       after_bars: after_bars, after: after,
                       &block)

      # TODO falta pasar la craeción del control y la parte final de on_stop, after_bars aquí (ahora está en _move3)
    end


    def _move3(timed_serie,
               reference: nil,
               step: nil,
               on_stop: nil,
               after_bars: nil, after: nil,
               &block)

      reference ||= 0r
      step ||= 1r

      # ###########################################################
      # #
      #
      # components = [:pitch, :dynamics, :instrument]
      # reference = reference.hashify(keys: components)
      # step = step.hashify(keys: components)
      # quantized_series = {}
      # split = timed_serie.flatten_timed.split
      # components.each do |component|
      #   puts "\n\ncomponent #{component} (raw)"
      #   pp split[component].to_a
      #   puts "\n\ncomponent #{component} (quantized)"
      #   quantized_series[component] =
      #       QUANTIZE(split[component],
      #                reference: reference[component],
      #                step: step[component]).instance
      #   pp quantized_series[component].to_a
      # end
      #
      # return
      #
      # #
      # ###########################################################

      if first_value_sample = timed_serie.peek_next_value

        debug "_move3: first_value_sample #{first_value_sample}"

        hash_mode = first_value_sample[:value].is_a?(Hash)

        if hash_mode
          components = first_value_sample[:value].keys

          reference = reference.hashify(keys: components)
          step = step.hashify(keys: components)
        else
          size = first_value_sample[:value].size
          components = (0 .. size-1).to_a

          reference = reference.arrayfy(size: size)
          step = step.arrayfy(size: size)
        end

        split = timed_serie.flatten_timed.split
        quantized_series = hash_mode ? {} : []

        components.each do |component|
          quantized_series[component] =
              QUANTIZE(split[component],
                       reference: reference[component],
                       step: step[component]).instance
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

            q_durations[component] = _quantize_position(time + durations[component]) - _quantize_position(time)

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





  end
end; end

