require_relative '../core-ext/inspect-nice'

module Musa::Sequencer
  class BaseSequencer
    using Musa::Extension::InspectNice

    # Initializes timed series playback.
    #
    # Peeks first element to determine mode (hash/array), extract component
    # IDs and extra attribute names. Then delegates to _play_timed_step for
    # recursive processing.
    #
    # @param timed_serie [Series] timed series with :time and :value
    # @param start_position [Rational] position offset for all times
    # @param control [PlayTimedControl] control object
    # @yield block to call for each element with values and metadata
    #
    # @return [void]
    #
    # @api private
    private def _play_timed(timed_serie, start_position, control, &block)

      if first_value_sample = timed_serie.peek_next_value
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

      binder = Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)

      _play_timed_step(hash_mode, component_ids, extra_attribute_names, timed_serie,
                       start_position, last_positions, binder, control)
    end

    # Recursively processes timed series elements.
    #
    # Gets next element, extracts values for affected components, calculates
    # started_ago for unchanged components, schedules user block at element's
    # time, and recursively calls itself for next element.
    #
    # ## Component Processing
    #
    # Only processes components with non-nil values in current element.
    # Tracks last update position per component to calculate started_ago.
    #
    # ## Block Parameters
    #
    # Calls user block with:
    # - values (hash or array of current values)
    # - extra_attributes (hash per attribute name, or array)
    # - time: absolute position (start_position + element time)
    # - started_ago: hash/array of deltas since last update per component
    # - control: control object
    #
    # @param hash_mode [Boolean] true if hash mode, false if array mode
    # @param component_ids [Array] component identifiers (keys or indices)
    # @param extra_attribute_names [Set] names of extra attributes
    # @param timed_serie [Series] series being played
    # @param start_position [Rational] position offset
    # @param last_positions [Hash, Array] last update positions per component
    # @param binder [SmartProcBinder] user block binder
    # @param control [PlayTimedControl] control object
    #
    # @return [void]
    #
    # @api private
    private def _play_timed_step(hash_mode,
                                 component_ids, extra_attribute_names,
                                 timed_serie,
                                 start_position,
                                 last_positions,
                                 binder, control)

      source_next_value = control.stopped? ? nil : timed_serie.next_value

      if source_next_value
        affected_components = component_ids.select { |_| !source_next_value[:value][_].nil? }

        if affected_components&.any?
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

          _numeric_at _quantize_position(start_position + time, warn: true), control do
            unless control.stopped?
              binder.call(values,
                          **extra_attributes,
                          time: start_position + time,
                          started_ago: started_ago,
                          control: control)
            end

            _play_timed_step(hash_mode,
                             component_ids, extra_attribute_names,
                             timed_serie,
                             start_position,
                             last_positions,
                             binder, control)
          end
        end
      else
        control.do_on_stop.each(&:call)

        unless control.stopped?
          control.do_after.each do |do_after|
            _numeric_at position + do_after[:bars], control, &do_after[:block]
          end
        end
      end
    end

    # Control object for play_timed operations.
    #
    # Manages lifecycle of timed series playback with callbacks.
    # Simpler than PlayControl - no pause/continue support.
    #
    # @example Basic play_timed control
    #   control = sequencer.play_timed(timed_series) { |values| ... }
    #   control.on_stop { puts "Playback finished!" }
    #   control.after(2r) { puts "2 bars after end" }
    #
    # @api private
    class PlayTimedControl < EventHandler
      # @return [Array<Proc>] stop callbacks
      attr_reader :do_on_stop
      # @return [Array<Hash>] after callbacks with delays
      attr_reader :do_after

      # Creates play_timed control with callbacks.
      #
      # @param parent [EventHandler] parent event handler
      # @param on_stop [Proc, nil] stop callback
      # @param after_bars [Rational, nil] delay for after callback
      # @param after [Proc, nil] after callback block
      #
      # @api private
      def initialize(parent, on_stop: nil, after_bars: nil, after: nil)
        super parent
        @do_on_stop = []
        @do_after = []

        @do_on_stop << on_stop if on_stop
        self.after after_bars, &after if after
      end

      # Registers callback for when playback stops (any reason, including manual stop).
      #
      # @yield stop callback block
      #
      # @return [void]
      #
      # @api private
      def on_stop(&block)
        @do_on_stop << block
      end

      # Registers callback to execute after playback terminates naturally
      # (series exhausted). NOT called on manual stop (.stop).
      #
      # @param bars [Numeric, nil] delay in bars after natural termination (default: 0)
      # @yield after callback block
      #
      # @return [void]
      #
      # @example Delayed callback
      #   control.after(4r) { puts "4 bars after playback ends" }
      #
      # @api private
      def after(bars = nil, &block)
        bars ||= 0
        @do_after << { bars: bars.rationalize, block: block }
      end
    end

    private_constant :PlayTimedControl
  end
end

