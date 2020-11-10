using Musa::Extension::Hashify
using Musa::Extension::Arrayfy

using Musa::Extension::InspectNice

module Musa; module Sequencer
  class BaseSequencer
    private def _play_timed(timed_serie,
                    control,
                    reference: nil,
                    step: nil,
                    right_open: nil,
                    &block)

      reference ||= 0r
      step ||= 1r

      if first_value_sample = timed_serie.peek_next_value

        debug "_play_timed: first_value_sample #{first_value_sample}"

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

      binder = SmartProcBinder.new(block)


      _play_timed_step(hash_mode, components, quantized_series, position, last_positions, binder, control)

    end


    private def _play_timed_step(hash_mode, components, quantized_series, start_position, last_positions,
                                 binder, control)

      affected_components_by_time = {}

      components.each do |component|
        if v = quantized_series[component].peek_next_value

          debug "_play_timed_step: quantized_series[#{component}].peek_next_value #{v}"
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

          debug "_play_timed_step: before binder.call: durations #{durations} q_durations #{q_durations}"

          binder.call(values, next_values,
                      duration: durations,
                      quantized_duration: q_durations,
                      started_ago: started_ago,
                      control: control)

          _play_timed_step(hash_mode, components, quantized_series, start_position, last_positions,
                           binder, control)
        end
      end
    end

    # TODO implement this alternative play method as another mode
    # Este es un modo muy interesante pero que implica un procesamiento diferente en el yield_block que no me
    # sirve para el código de samples/multidim_sample, puesto que en este el next_values es literal,
    # mientras que samples/multidim_sample necesita que el next_value sea nil si el valor no cambia durante el periodo.
    #
    private def _play_timed_step_b(hash_mode, components, quantized_series, start_position, last_positions,
                                   binder, control)

      affected_components_by_time = {}

      components.each do |component|
        if v = quantized_series[component].peek_next_value
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

          _play_timed_step_b(hash_mode, components, quantized_series, start_position, last_positions,
                             binder, control)
        end
      end
    end

    class PlayTimedControl < EventHandler
      attr_reader :do_on_stop, :do_after

      def initialize(parent, on_stop: nil, after_bars: nil, after: nil)
        super parent
        @do_on_stop = []
        @do_after = []

        @do_on_stop << on_stop if on_stop
        self.after after_bars, &after if after
      end

      def on_stop(&block)
        @do_on_stop << block
      end

      def after(bars = nil, &block)
        bars ||= 0
        @do_after << { bars: bars.rationalize, block: block }
      end
    end

    private_constant :PlayTimedControl
  end
end; end

