require_relative '../core-ext/arrayfy'
require_relative '../core-ext/smart-proc-binder'

require_relative 'base-sequencer-implementation-control'
require_relative 'base-sequencer-implementation-play-helper'

using Musa::Extension::Arrayfy
using Musa::Extension::DeepCopy

module Musa
  module Sequencer
    class BaseSequencer
      include Musa::Extension::SmartProcBinder
      include Musa::Extension::DeepCopy

      private

      def _tick(position_to_run)

        @before_tick.each { |block| block.call position_to_run }

        queue = @timeslots[position_to_run]

        if queue
          until queue.empty?

            command = queue.shift
            @timeslots.delete position_to_run if queue.empty?

            if command.key?(:parent_control) && !command[:parent_control].stopped?
              @event_handlers.push command[:parent_control]

              @tick_mutex.synchronize do
                command[:block].call *command[:value_parameters], **command[:key_parameters] if command[:block]
              end

              @event_handlers.pop
            else
              @tick_mutex.synchronize do
                command[:block].call *command[:value_parameters], **command[:key_parameters] if command[:block]
              end
            end
          end
        end

        Thread.pass
      end

      def _raw_numeric_at(at_position, force_first: nil, &block)
        force_first ||= false

        if at_position == @position
          begin
            yield
          rescue StandardError, ScriptError => e
            _rescue_error e
          end

        elsif at_position > @position
          @timeslots[at_position] ||= []

          value = { block: block, value_parameters: [], key_parameters: {} }
          if force_first
            @timeslots[at_position].insert 0, value
          else
            @timeslots[at_position] << value
          end
        else
          _log "BaseSequencer._raw_numeric_at: warning: ignoring past at command for #{at_position}" if @do_log
        end

        nil
      end

      def _numeric_at(at_position, control, with: nil, debug: nil, &block)
        raise ArgumentError, "'at_position' parameter cannot be nil" if at_position.nil?
        raise ArgumentError, 'Yield block is mandatory' unless block

        at_position = _check_position(at_position)

        value_parameters = []
        value_parameters << with if !with.nil? && !with.is_a?(Hash)

        block_key_parameters_binder =
            SmartProcBinder.new block, on_rescue: proc { |e| _rescue_error(e) }

        key_parameters = {}
        key_parameters.merge! block_key_parameters_binder._apply(nil, with).last if with.is_a?(Hash)

        key_parameters[:control] = control if block_key_parameters_binder.key?(:control)

        if at_position == @position
          @debug_at.call if debug && @debug_at

          begin
            locked = @tick_mutex.try_lock
            block_key_parameters_binder._call(value_parameters, key_parameters)
          ensure
            @tick_mutex.unlock if locked
          end

        elsif @position.nil? || at_position > @position

          @timeslots[at_position] ||= []

          @timeslots[at_position] << { parent_control: control, block: @on_debug_at } if debug && @on_debug_at

          @timeslots[at_position] << { parent_control: control, block: block_key_parameters_binder,
                                       value_parameters: value_parameters,
                                       key_parameters: key_parameters }
        else
          _log "BaseSequencer._numeric_at: warning: ignoring past 'at' command for #{at_position}" if @do_log
        end

        nil
      end

      def _serie_at(bar_position_serie, control, with: nil, debug: nil, &block)

        bar_position = bar_position_serie.next_value

        with_value = if with.respond_to? :next_value
                       with.next_value
                     else
                       with
                     end

        if bar_position
          _numeric_at bar_position, control, with: with_value, debug: debug, &block

          _numeric_at bar_position, control, debug: false do
            _serie_at bar_position_serie, control, with: with, debug: debug, &block
          end
        else
          # serie finalizada
        end

        nil
      end

      def _play(serie, control, nl_context = nil, mode: nil, decoder: nil, __play_eval: nil, **mode_args, &block)

        block ||= proc {}

        __play_eval ||= PlayEval.create \
          mode,
          SmartProcBinder.new(block,
                              on_rescue: proc { |e| _rescue_error(e) }),
          decoder,
          nl_context

        element = nil

        if control.stopped?
          # nothing to do
        elsif control.paused?
          control.store_continuation  sequencer: self,
                                      serie: serie,
                                      nl_context: nl_context,
                                      mode: mode,
                                      decoder: decoder,
                                      play_eval: __play_eval,
                                      mode_args: mode_args
        else
          element = serie.next_value
        end

        if element
          operation = __play_eval.run_operation element

          case operation[:current_operation]

          when :none

          when :block

            __play_eval.block_procedure_binder.call operation[:current_parameter], control: control

          when :event

            control._launch operation[:current_event],
                            operation[:current_value_parameters],
                            operation[:current_key_parameters]

          when :play

            control2 = PlayControl.new control
            control3 = PlayControl.new control2
            control3.after { control3.launch :sync }

            _play operation[:current_parameter].instance,
                  control3,
                  __play_eval: __play_eval.subcontext,
                  **mode_args

            control2.on :sync do
              _play serie, control, __play_eval: __play_eval, **mode_args
            end

          when :no_eval_play

            control2 = PlayControl.new control
            control3 = PlayControl.new control2
            control3.after { control3.launch :sync }

            _play operation[:current_parameter].instance,
                  control3,
                  __play_eval: WaitModePlayEval.new(__play_eval.block_procedure_binder),
                  **mode_args

            control2.on :sync do
              _play serie, control, __play_eval: __play_eval, **mode_args
            end

          when :parallel_play

            control2 = PlayControl.new control

            operation[:current_parameter].each do |current_parameter|
              control3 = PlayControl.new control2
              control3.after { control3.launch :sync }

              _play current_parameter.instance,
                    control3,
                    __play_eval: __play_eval.subcontext,
                    **mode_args
            end

            counter = operation[:current_parameter].size

            control2.on :sync do
              counter -= 1
              _play serie, control, __play_eval: __play_eval, **mode_args if counter == 0
            end
          end

          case operation[:continue_operation]
          when :now
            _numeric_at position, control do
              _play serie, control, __play_eval: __play_eval, **mode_args
            end

          when :at
            _numeric_at operation[:continue_parameter], control do
              _play serie, control, __play_eval: __play_eval, **mode_args
            end

          when :wait
            _numeric_at position + operation[:continue_parameter].rationalize, control do
              _play serie, control, __play_eval: __play_eval, **mode_args
            end

          when :on
            control.on operation[:continue_parameter], only_once: true do
              _play serie, control, __play_eval: __play_eval, **mode_args
            end
          end
        else
          control2 = EventHandler.new control

          control.do_after.each do |do_after|
            _numeric_at position, control2, &do_after
          end
        end

        nil
      end

      def _every(interval, control, block_procedure_binder: nil, &block)
        block ||= proc {}

        block_procedure_binder ||= SmartProcBinder.new block, on_rescue: proc { |e| _rescue_error(e) }

        _numeric_at position, control do
          control._start_position ||= position
          control._execution_counter ||= 0

          duration_exceeded =
              (control._start_position + control.duration_value - interval) <= position if interval && control.duration_value

          till_exceeded = control.till_value - interval <= position if interval && control.till_value

          condition_failed = !control.condition_block.call if control.condition_block

          unless control.stopped? || condition_failed || till_exceeded
            block_procedure_binder.call(control: control)
            control._execution_counter += 1
          end


          unless control.stopped? || duration_exceeded || till_exceeded || condition_failed || interval.nil?
            _numeric_at control._start_position + control._execution_counter * interval, control do
              _every interval, control, block_procedure_binder: block_procedure_binder
            end

          else
            control.do_on_stop.each(&:call)

            control.do_after.each do |do_after|
              _numeric_at position + (interval || 0) + do_after[:bars], control, &do_after[:block]
            end
          end
        end

        nil
      end

      def _move(every: nil,
                from:, to: nil, step: nil,
                duration: nil, till: nil,
                function: nil,
                right_open: nil,
                on_stop: nil,
                after_bars: nil, after: nil,
                &block)

        raise ArgumentError,
              "Cannot use duration: #{duration} and till: #{till} parameters at the same time. " \
              "Use only one of them." if till && duration

        raise ArgumentError,
              "Invalid use: 'function:' parameter is incompatible with 'step:' parameter" if function && step
        raise ArgumentError,
              "Invalid use: 'function:' parameter needs 'to:' parameter to be not nil" if function && !to

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

        start_position = position

        if duration || till
          effective_duration = duration || till - start_position

          # Add 1 tick to arrive to final value in duration time (no need to add an extra tick)
          right_open_offset = right_open.collect { |ro| ro ? 0 : 1 }

          size.times do |i|
            if to[i] && step[i] && !every[i]

              steps = (to[i] - from[i]) / step[i]

              # When to == from don't need to do any iteration with every
              if steps + right_open_offset[i] > 0
                every[i] = Rational(effective_duration, steps + right_open_offset[i])
              else
                every[i] = nil
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

        binder = SmartProcBinder.new(block)

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

        control = MoveControl.new(@event_handlers.last,
                                  duration: duration, till: till,
                                  on_stop: on_stop, after_bars: after_bars, after: after)

        control.on_stop do
          control.do_after.each do |do_after|
            _numeric_at position + do_after[:bars], control, &do_after[:block]
          end
        end

        @event_handlers.push control

        _numeric_at start_position, control do
          next_values = from.dup

          values = Array.new(size)
          stop = Array.new(size, false)
          last_position = Array.new(size)

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

                next_group_q_position = _quantize(next_group_position)

                affected_indexes.each do |i|
                  positions[i] = group_position
                  q_durations[i] = next_group_q_position - position

                  position_jitters[i] = group_position - position
                  duration_jitters[i] = next_group_position - next_group_q_position
                end
              end
            end

            process_indexes.flatten!

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

              control.stop if stop.all?

              effective_values = from.clone(freeze: false).map!.with_index do |_, i|
                function[i].call(values[i]) * function_range[i] + function_offset[i] unless values[i].nil?
              end

              effective_next_values = from.clone(freeze: false).map!.with_index do |_, i|
                function[i].call(next_values[i]) * function_range[i] +
                    function_offset[i] unless next_values[i].nil?
              end

              # TODO add to values and next_values the modules of the original from and/or to objects.

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

              yield *value_parameters, **key_parameters

              process_indexes.each { |i| last_position[i] = position }
            end
          end
        end

        @event_handlers.pop

        control
      end

      def _started_ago(last_positions, position, affected_indexes)
        Array.new(last_positions.size).tap do |a|
          last_positions.each_index do |i|
            if last_positions[i] && !affected_indexes.include?(i)
              a[i] = position - last_positions[i]
            end
          end
        end
      end

      def _durations(every_groups, largest_duration)
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

      def _hash_from_keys_and_values(keys, values)
        {}.tap { |h| keys.each_index { |i| h[keys[i]] = values[i] } }
      end

      def _common_interval(intervals)
        intervals = intervals.compact
        return nil if intervals.empty?

        lcm_denominators = intervals.collect(&:denominator).reduce(1, :lcm)
        numerators = intervals.collect { |i| i.numerator * lcm_denominators / i.denominator }
        gcd_numerators = numerators.reduce(numerators.first, :gcd)

        #intervals.reduce(1r, :*)

        Rational(gcd_numerators, lcm_denominators)
      end

      def _rescue_error(e)
        if @do_error_log
          _log e
          _log e.full_message(order: :top)
        end

        @on_error.each do |block|
          block.call e
        end
      end

      def _log(msg = nil, decimals: nil)
        m = '...' unless msg
        m = ": #{msg}" if msg


        decimals ||= @log_decimals
        integer_digits = decimals.to_i
        decimal_digits = ((decimals - integer_digits) * 10).round

        p = "%#{integer_digits + decimal_digits + 1}s" % ("%.#{decimal_digits}f" % position.to_f)

        warn "#{p}#{m} [#{position}]"
      end
    end
  end
end

