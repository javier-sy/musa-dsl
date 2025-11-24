require_relative '../core-ext/arrayfy'
require_relative '../core-ext/inspect-nice'

module Musa::Sequencer
  class BaseSequencer
    using Musa::Extension::Arrayfy
    using Musa::Extension::InspectNice

    # Animates value(s) over time with flexible parameter control.
    #
    # Implements smooth value transitions supporting single values, arrays,
    # and hashes. Handles complex parameter calculation to derive missing
    # timing or step information. Uses _every for iteration scheduling.
    #
    # ## Yield Block Parameters
    #
    # Block receives current value(s), next value(s), and metadata:
    # - In single mode: `|value, next_value, control:, duration:, ...|`
    # - In array mode: `|values, next_values, control:, duration:, ...|`
    # - In hash mode: `|values_hash, next_values_hash, control:, ...|`
    #
    # Optional parameters: control, duration, quantized_duration,
    # position_jitter, duration_jitter, started_ago, right_open
    #
    # ## Implementation Details
    #
    # 1. Validates and normalizes parameters
    # 2. Calculates missing parameters (step or every) from others
    # 3. Creates MoveControl wrapping EveryControl
    # 4. Uses _every with common interval (GCD of all intervals)
    # 5. Calculates values, applies function, checks stop conditions
    # 6. Yields to user block with values and metadata
    #
    # @param every [Rational, Array, Hash, nil] interval(s) between iterations
    # @param from [Numeric, Array, Hash] starting value(s)
    # @param to [Numeric, Array, Hash, nil] target value(s)
    # @param step [Numeric, Array, Hash, nil] increment(s) per iteration
    # @param duration [Rational, nil] total duration in bars
    # @param till [Rational, nil] absolute end position
    # @param function [Proc, Array<Proc>, nil] interpolation function(s)
    # @param right_open [Boolean, Array, Hash, nil] exclude final value
    # @param on_stop [Proc, nil] callback when movement stops
    # @param after_bars [Rational, nil] delay for after callback
    # @param after [Proc, nil] callback after movement completes
    # @yield block to execute at each iteration with current/next values
    #
    # @return [MoveControl] control object for managing movement
    #
    # @raise [ArgumentError] if incompatible parameters used together
    # @raise [ArgumentError] if insufficient parameters to calculate movement
    #
    # @api private
    private def _move(every: nil,
                      from:, to: nil,
                      step: nil,
                      duration: nil, till: nil,
                      function: nil,
                      right_open: nil,
                      on_stop: nil,
                      after_bars: nil, after: nil,
                      &block)

      #
      # Main calling parameters error check
      #
      raise ArgumentError,
            "Cannot use duration: #{duration} and till: #{till} parameters at the same time. " \
              "Use only one of them." if till && duration

      raise ArgumentError,
            "Invalid use: 'function:' parameter is incompatible with 'step:' parameter" if function && step
      raise ArgumentError,
            "Invalid use: 'function:' parameter needs 'to:' parameter to be not nil" if function && !to

      #
      # Homogenize mode parameters
      #
      array_mode = from.is_a?(Array)
      hash_mode = from.is_a?(Hash)

      if array_mode
        from = from.arrayfy
        size = from.size

      elsif hash_mode
        hash_keys = from.keys
        from = from.values
        size = from.size

        if every.is_a?(Hash)
          every = hash_keys.collect { |k| every[k] }
          raise ArgumentError,
                "Invalid use: 'every:' parameter should contain the same keys as 'from:' Hash" \
              unless every.all? { |_| _ }
        end

        if to.is_a?(Hash)
          to = hash_keys.collect { |k| to[k] }
          raise ArgumentError,
                "Invalid use: 'to:' parameter should contain the same keys as 'from:' Hash" unless to.all? { |_| _ }
        end

        if step.is_a?(Hash)
          step = hash_keys.collect { |k| step[k] }
        end

        if right_open.is_a?(Hash)
          right_open = hash_keys.collect { |k| right_open[k] }
        end

      else
        from = from.arrayfy
        size = from.size
      end

      every = every.arrayfy(size: size)
      to = to.arrayfy(size: size)
      step = step.arrayfy(size: size)
      right_open = right_open.arrayfy(size: size)

      # from, to, step, every
      # from, to, step, (duration | till)
      # from, to, every, (duration | till)
      # from, step, every, (duration | till)

      block ||= proc {}

      step.map!.with_index do |s, i|
        (s && to[i] && ((s > 0 && to[i] < from[i]) || (s < 0 && from[i] < to[i]))) ? -s : s
      end

      right_open.map! { |v| v || false }

      function ||= proc { |ratio| ratio }
      function = function.arrayfy(size: size)

      function_range = 1r.arrayfy(size: size)
      function_offset = 0r.arrayfy(size: size)

      #
      # Prepare intervals, steps & transformation functions
      #
      start_position = position

      if duration || till
        effective_duration = duration || till - start_position

        # Add 1 tick to arrive to final value in duration time (no need to add an extra tick)
        right_open_offset = right_open.collect { |ro| ro ? 0 : 1 }

        size.times do |i|
          if to[i] && step[i] && !every[i]

            steps = (to[i] - from[i]) / step[i]

            # When to == from don't need to do any iteration with every
            every[i] = if steps + right_open_offset[i] > 0
                         Rational(effective_duration, steps + right_open_offset[i])
                       else
                         nil
                       end

          elsif to[i] && !step[i] && !every[i]

            if tick_duration > 0
              function_range[i] = to[i] - from[i]
              function_offset[i] = from[i]

              from[i] = 0r
              to[i] = 1r

              step[i] = 1r / (effective_duration * ticks_per_bar - right_open_offset[i])
              every[i] = tick_duration
            else
              raise ArgumentError, "Cannot use sequencer tickless mode without 'step' or 'every' parameter values"
            end

          elsif to[i] && !step[i] && every[i]
            function_range[i] = to[i] - from[i]
            function_offset[i] = from[i]

            from[i] = 0r
            to[i] = 1r

            steps = effective_duration / every[i]
            step[i] = 1r / (steps - right_open_offset[i])

          elsif !to[i] && step[i] && every[i]
            # ok
          elsif !to[i] && !step[i] && every[i]
            step[i] = 1r

          else
            raise ArgumentError, 'Cannot use this parameters combination (with \'duration\' or \'till\')'
          end
        end
      else
        size.times do |i|
          if to[i] && step[i] && every[i]
            # ok
          elsif to[i] && !step[i] && every[i]
            size.times do |i|
              step[i] = (to[i] <=> from[i]).to_r
            end
          else
            raise ArgumentError, 'Cannot use this parameters combination'
          end
        end
      end

      #
      # Prepare yield block, parameters to yield block and coincident moving interval groups
      #
      binder = Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)

      every_groups = {}
      group_counter = {}

      positions = Array.new(size)
      q_durations = Array.new(size)
      position_jitters = Array.new(size)
      duration_jitters = Array.new(size)

      size.times.each do |i|
        every_groups[every[i]] ||= []
        every_groups[every[i]] << i
        group_counter[every[i]] = 0
      end

      #
      # Initialize external control object
      #
      control = MoveControl.new(@event_handlers.last,
                                duration: duration, till: till,
                                on_stop: on_stop, after_bars: after_bars, after: after)

      control.on_stop do
        control.do_after.each do |do_after|
          _numeric_at position + do_after[:bars], control, &do_after[:block]
        end
      end

      @event_handlers.push control

      #
      # Let's go with the loop!
      #
      _numeric_at start_position, control do
        next_values = from.dup

        values = Array.new(size)
        stop = Array.new(size, false)
        last_position = Array.new(size)

        #
        # Ok, the loop is here...
        #
        _every _common_interval(every_groups.keys), control.every_control do
          process_indexes = []

          every_groups.each_pair do |group_interval, affected_indexes|
            group_position = start_position + ((group_interval || 0) * group_counter[group_interval])

            # We consider a position to be on current tick position when it is inside the interval of one tick
            # centered on the current tick (current tick +- 1/2 tick duration).
            # This allow to round the irregularly timed positions due to every intervals not integer
            # multiples of the tick_duration.
            #
            if tick_duration == 0 && group_position == position ||
                group_position >= position - tick_duration && group_position < position + tick_duration

              process_indexes << affected_indexes

              group_counter[group_interval] += 1

              next_group_position = start_position +
                  if group_interval
                    (group_interval * group_counter[group_interval])
                  else
                    effective_duration
                  end

              next_group_q_position = _quantize_position(next_group_position)

              affected_indexes.each do |i|
                positions[i] = group_position
                q_durations[i] = next_group_q_position - position

                position_jitters[i] = group_position - position
                duration_jitters[i] = next_group_position - next_group_q_position
              end
            end
          end

          process_indexes.flatten!

          #
          # Calculate values and next_values for yield block
          #
          if process_indexes.any?
            process_indexes.each do |i|
              unless stop[i]
                values[i] = next_values[i]
                next_values[i] += step[i]

                if to[i]
                  stop[i] = if right_open[i]
                              step[i].positive? ? next_values[i] >= to[i] : next_values[i] <= to[i]
                            else
                              step[i].positive? ? next_values[i] > to[i] : next_values[i] < to[i]
                            end

                  if stop[i]
                    if right_open[i]
                      next_values[i] = nil if values[i] == to[i]
                    else
                      next_values[i] = nil
                    end
                  end
                end
              end
            end

            #
            # Do we need stop?
            #
            control.stop if stop.all?

            #
            # Calculate effective values and next_values applying the parameter function
            #
            effective_values = from.clone(freeze: false).map!.with_index do |_, i|
              function[i].call(values[i]) * function_range[i] + function_offset[i] unless values[i].nil?
            end

            effective_next_values = from.clone(freeze: false).map!.with_index do |_, i|
              function[i].call(next_values[i]) * function_range[i] +
                  function_offset[i] unless next_values[i].nil?
            end

            # TODO add to 'values' and 'next_values' elements the modules of the original from and/or to objects (i.e. GDV).

            #
            # Adapt values to array/hash/value mode
            #
            value_parameters, key_parameters =
              if array_mode
                binder.apply(effective_values, effective_next_values,
                             control: control,
                             duration: _durations(every_groups, effective_duration),
                             quantized_duration: q_durations.dup,
                             started_ago: _started_ago(last_position, position, process_indexes),
                             position_jitter: position_jitters.dup,
                             duration_jitter: duration_jitters.dup,
                             right_open: right_open.dup)
              elsif hash_mode
                binder.apply(_hash_from_keys_and_values(hash_keys, effective_values),
                             _hash_from_keys_and_values(hash_keys, effective_next_values),
                             control: control,
                             duration: _hash_from_keys_and_values(
                                 hash_keys,
                                 _durations(every_groups, effective_duration)),
                             quantized_duration: _hash_from_keys_and_values(
                                 hash_keys,
                                 q_durations),
                             started_ago: _hash_from_keys_and_values(
                                 hash_keys,
                                 _started_ago(last_position, position, process_indexes)),
                             position_jitter: _hash_from_keys_and_values(
                                 hash_keys,
                                 position_jitters),
                             duration_jitter: _hash_from_keys_and_values(
                                 hash_keys,
                                 duration_jitters),
                             right_open: _hash_from_keys_and_values(hash_keys, right_open))
              else
                binder.apply(effective_values.first,
                             effective_next_values.first,
                             control: control,
                             duration: _durations(every_groups, effective_duration).first,
                             quantized_duration: q_durations.first,
                             position_jitter: position_jitters.first,
                             duration_jitter: duration_jitters.first,
                             started_ago: nil,
                             right_open: right_open.first)
              end

            #
            # Do the REAL thing
            #
            yield *value_parameters, **key_parameters

            process_indexes.each { |i| last_position[i] = position }
          end
        end
      end

      @event_handlers.pop

      control
    end

    # Calculates time elapsed since each value last changed.
    #
    # Returns array where each element is position delta since that value
    # was last updated, or nil if value is being updated this iteration.
    #
    # @param last_positions [Array<Rational, nil>] positions of last updates
    # @param position [Rational] current position
    # @param affected_indexes [Array<Integer>] indexes being updated now
    #
    # @return [Array<Rational, nil>] deltas or nils
    #
    # @api private
    private def _started_ago(last_positions, position, affected_indexes)
      Array.new(last_positions.size).tap do |a|
        last_positions.each_index do |i|
          if last_positions[i] && !affected_indexes.include?(i)
            a[i] = position - last_positions[i]
          end
        end
      end
    end

    # Calculates duration for each value based on interval grouping.
    #
    # Returns array of durations, one per value, based on its interval group.
    #
    # @param every_groups [Hash{Rational => Array<Integer>}] interval groups
    # @param largest_duration [Rational] fallback duration
    #
    # @return [Array<Rational>] durations per value
    #
    # @api private
    private def _durations(every_groups, largest_duration)
      [].tap do |a|
        if every_groups.any?
          every_groups.each_pair do |every_group, affected_indexes|
            affected_indexes.each do |i|
              a[i] = every_group || largest_duration
            end
          end
        else
          a << largest_duration
        end
      end
    end

    # Reconstructs hash from separate key and value arrays.
    #
    # @param keys [Array<Symbol>] hash keys
    # @param values [Array] hash values
    #
    # @return [Hash] reconstructed hash
    #
    # @api private
    private def _hash_from_keys_and_values(keys, values)
      {}.tap { |h| keys.each_index { |i| h[keys[i]] = values[i] } }
    end

    # Calculates greatest common divisor of intervals for scheduling.
    #
    # Computes GCD of all intervals to find common iteration frequency
    # that hits all interval positions. Uses rational arithmetic.
    #
    # @param intervals [Array<Rational>] intervals to find GCD of
    #
    # @return [Rational, nil] common interval or nil if empty
    #
    # @api private
    private def _common_interval(intervals)
      intervals = intervals.compact
      return nil if intervals.empty?

      lcm_denominators = intervals.collect(&:denominator).reduce(1, :lcm)
      numerators = intervals.collect { |i| i.numerator * lcm_denominators / i.denominator }
      gcd_numerators = numerators.reduce(numerators.first, :gcd)

      #intervals.reduce(1r, :*)

      Rational(gcd_numerators, lcm_denominators)
    end

    # Control object for move operations.
    #
    # Wraps EveryControl to provide move-specific lifecycle management.
    # Delegates timing control to EveryControl while adding move-specific
    # callbacks and state.
    #
    # ## Delegation Pattern
    #
    # MoveControl delegates to EveryControl for:
    # - Duration and till timing control
    # - Iteration scheduling
    # - Stop conditions
    #
    # Adds move-specific features:
    # - on_stop callbacks when movement completes
    # - after callbacks with delays
    # - Stopped state synchronization
    #
    # @example Basic move control
    #   control = sequencer.move(from: 0, to: 100, duration: 4r, every: 1/4r) { |v| }
    #   control.on_stop { puts "Movement finished!" }
    #   control.after(2r) { puts "2 bars after finish" }
    #   control.stop  # Manually halt movement
    #
    class MoveControl < EventHandler
      # @return [EveryControl] underlying every control for timing
      attr_reader :every_control
      # @return [Array<Proc>] stop callbacks
      attr_reader :do_on_stop
      # @return [Array<Hash>] after callbacks with delays
      attr_reader :do_after

      # Creates move control with timing parameters.
      #
      # @param parent [EventHandler] parent event handler
      # @param duration [Rational, nil] maximum duration in bars
      # @param till [Rational, nil] absolute stop position
      # @param on_stop [Proc, nil] stop callback
      # @param after_bars [Rational, nil] delay for after callback
      # @param after [Proc, nil] after callback block
      #
      # @api private
      def initialize(parent, duration: nil, till: nil, on_stop: nil, after_bars: nil, after: nil)
        super parent

        @every_control = EveryControl.new(self, duration: duration, till: till)

        @do_on_stop = []
        @do_after = []

        @do_on_stop << on_stop if on_stop
        self.after after_bars, &after if after

        @every_control.on_stop do
          @stop = true
          @do_on_stop.each(&:call)
        end
      end

      # Registers callback for when movement stops.
      #
      # @yield stop callback block
      #
      # @return [void]
      #
      def on_stop(&block)
        @do_on_stop << block
      end

      # Registers callback to execute after movement stops.
      #
      # @param bars [Numeric, nil] delay in bars after stop (default: 0)
      # @yield after callback block
      #
      # @return [void]
      #
      # @example Delayed callback
      #   control.after(2r) { puts "2 bars after movement ends" }
      #
      def after(bars = nil, &block)
        bars ||= 0
        @do_after << { bars: bars.rationalize, block: block }
      end

      # Stops movement.
      #
      # @return [void]
      #
      def stop
        @every_control.stop
      end

      # Checks if movement is stopped.
      #
      # @return [Boolean] true if stopped
      #
      def stopped?
        @stop
      end
    end

    private_constant :MoveControl
  end
end
