using Musa::Extension::Hashify
using Musa::Extension::Arrayfy

using Musa::Extension::InspectNice

module Musa; module Sequencer
  class BaseSequencer
    private def _play_timed(timed_serie,
                    control,
                    &block)

      if first_value_sample = timed_serie.peek_next_value
        debug "_play_timed: first_value_sample #{first_value_sample}"

        hash_mode = first_value_sample[:value].is_a?(Hash)

        if hash_mode
          component_ids = first_value_sample[:value].keys
        else
          size = first_value_sample[:value].size
          component_ids = (0 .. size-1).to_a
        end
        extra_attribute_names = Set[*(first_value_sample.keys - [:time, :value])]

        last_positions = hash_mode ? {} : []
      end

      binder = SmartProcBinder.new(block)

      _play_timed_step(hash_mode, component_ids, extra_attribute_names, timed_serie,
                       position, last_positions, binder, control)
    end

    private def _play_timed_step(hash_mode,
                                 component_ids, extra_attribute_names,
                                 timed_serie,
                                 start_position,
                                 last_positions,
                                 binder, control)

      source_next_value = timed_serie.next_value

      affected_components = component_ids.select { |_| !source_next_value[:value][_].nil? } if source_next_value

      if affected_components && affected_components.any?
        time = source_next_value[:time]

        values = hash_mode ? {} : []
        extra_attributes = extra_attribute_names.collect { |_| [_, hash_mode ? {} : []] }.to_h
        started_ago = hash_mode ? {} : []

        affected_components.each do |component|
          values[component] = source_next_value[:value][component]

          extra_attribute_names.each do |attribute_name|
            extra_attributes[attribute_name][component] = source_next_value[attribute_name][component]
          end

          last_positions[component] = _quantize_position(time, warn: false)
        end

        component_ids.each do |component|
          if last_positions[component] && last_positions[component] != time
            sa = _quantize_position(time, warn: false) - last_positions[component]
            started_ago[component] = (sa == 0) ? nil : sa
          end
        end

        _numeric_at start_position + _quantize_position(time, warn: false), control do
          binder.call(values,
                      **extra_attributes,
                      started_ago: started_ago,
                      control: control)

          _play_timed_step(hash_mode,
                           component_ids, extra_attribute_names,
                           timed_serie,
                           start_position,
                           last_positions,
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

