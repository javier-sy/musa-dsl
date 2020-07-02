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

      def _tick

        position_to_run = @position_mutex.synchronize { @position += 1 }

        @before_tick.each { |block| block.call Rational(position_to_run, @ticks_per_bar) }

        queue = @timeslots[position_to_run]

        if queue
          until queue.empty?

            command = queue.shift
            @timeslots.delete position_to_run if queue.empty?

            if command.key?(:parent_control) && !command[:parent_control].stopped?
              @event_handlers.push command[:parent_control]

              @@tick_mutex.synchronize do
                command[:block].call *command[:value_parameters], **command[:key_parameters] if command[:block]
              end

              @event_handlers.pop
            else
              @@tick_mutex.synchronize do
                command[:block].call *command[:value_parameters], **command[:key_parameters] if command[:block]
              end
            end
          end
        end

        Thread.pass
      end

      def _hold_public_ticks
        @hold_public_ticks = true
      end

      def _release_public_ticks
        @hold_ticks.times { _tick }
        @hold_ticks = 0
        @hold_public_ticks = false
      end

      def _raw_numeric_at(bar_position, force_first: nil, &block)
        force_first ||= false

        position = bar_position.rationalize * @ticks_per_bar

        if position == @position
          begin
            yield
          rescue StandardError, ScriptError => e
            _rescue_error e
          end

        elsif position > @position
          @timeslots[position] ||= []

          value = { block: block, value_parameters: [], key_parameters: {} }
          if force_first
            @timeslots[position].insert 0, value
          else
            @timeslots[position] << value
          end
        else
          _log "BaseSequencer._raw_numeric_at: warning: ignoring past at command for #{Rational(position, @ticks_per_bar)}" if @do_log
        end

        nil
      end

      def _numeric_at(bar_position, control, with: nil, debug: nil, &block)
        raise ArgumentError, 'Block is mandatory' unless block

        position = bar_position.rationalize * @ticks_per_bar

        if position != position.round
          original_position = position
          position = position.round.rationalize

          if @do_log
            _log "BaseSequencer._numeric_at: warning: rounding position #{bar_position} (#{original_position}) "\
          "to tick precision: #{position / @ticks_per_bar} (#{position})"
          end
        end

        value_parameters = []
        value_parameters << with if !with.nil? && !with.is_a?(Hash)

        if block_given?
          block_key_parameters_binder =
              SmartProcBinder.new block, on_rescue: proc { |e| _rescue_error(e) }

          key_parameters = {}
          key_parameters.merge! block_key_parameters_binder._apply(nil, with).last if with.is_a?(Hash)

          key_parameters[:control] = control if block_key_parameters_binder.key?(:control)

          if position == @position
            @debug_at.call if debug && @debug_at

            begin
              locked = @@tick_mutex.try_lock
              block_key_parameters_binder._call(value_parameters, key_parameters)
            ensure
              @@tick_mutex.unlock if locked
            end

          elsif position > @position
            @timeslots[position] = [] unless @timeslots[position]

            @timeslots[position] << {parent_control: control, block: @on_debug_at } if debug && @on_debug_at
            @timeslots[position] << {parent_control: control, block: block_key_parameters_binder, value_parameters: value_parameters, key_parameters: key_parameters }
          else
            _log "BaseSequencer._numeric_at: warning: ignoring past at command for #{Rational(position, @ticks_per_bar)}" if @do_log
          end
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

      def _every(binterval, control, block_procedure_binder: nil, &block)
        block ||= proc {}

        block_procedure_binder ||= SmartProcBinder.new block, on_rescue: proc { |e| _rescue_error(e) }

        _numeric_at position, control do
          control._start ||= position

          duration_exceeded = (control._start + control.duration_value - binterval) <= position if control.duration_value
          till_exceeded = control.till_value - binterval <= position if control.till_value
          condition_failed = !control.condition_block.call if control.condition_block

          block_procedure_binder.call(control: control) unless control.stopped? || condition_failed || till_exceeded

          unless control.stopped? || duration_exceeded || till_exceeded || condition_failed
            _numeric_at position + binterval, control do
              _every binterval, control, block_procedure_binder: block_procedure_binder
            end
          else
            control.do_on_stop.each(&:call)

            control.do_after.each do |do_after|
              _numeric_at position + binterval + do_after[:bars], control, &do_after[:block]
            end
          end
        end

        nil
      end

      def _move(every: nil, from:, to: nil, step: nil, duration: nil, till: nil, function: nil, right_open: nil, on_stop: nil, after_bars: nil, after: nil, &block)

        raise ArgumentError, "Cannot use duration: #{duration} and till: #{till} parameters at the same time. Use only one of them." if till && duration
        raise ArgumentError, "Invalid use: 'function:' parameter is incompatible with 'step:' parameter" if function && step
        raise ArgumentError, "Invalid use: 'function:' parameter needs 'to:' parameter not nil" if function && !to

        array_mode = from.is_a?(Array)

        from = from.arrayfy
        size = from.size

        every = every.arrayfy(size: size)
        to = to.arrayfy(size: size)
        step = step.arrayfy(size: size)

        # from, to, step, every
        # from, to, step, (duration | till)
        # from, to, every, (duration | till)
        # from, step, every, (duration | till)

        block ||= proc {}

        step.map!.with_index do |step, i|
          (step && to[i] && ((step > 0 && to[i] < from[i]) || (step < 0 && from[i] < to[i]))) ? -step : step
        end

        right_open ||= false

        function ||= proc { |ratio| ratio }
        function = function.arrayfy(size: size)

        function_range = 1r.arrayfy(size: size)
        function_offset = 0r.arrayfy(size: size)

        start_position = position

        if duration || till
          effective_duration = duration || till - start_position
          right_open_offset = right_open ? 0 : 1 # Add 1 tick to arrive to final value in duration time (no need to add an extra tick)

          size.times do |i|
            if to[i] && step[i] && !every[i]
              steps = (to[i] - from[i]) / step[i]
              every[i] = Rational(effective_duration, steps + right_open_offset)

            elsif to[i] && !step[i] && !every[i]
              function_range[i] = to[i] - from[i]
              function_offset[i] = from[i]

              from[i] = 0r
              to[i] = 1r

              step[i] = 1r / (effective_duration * @ticks_per_bar - right_open_offset)
              every[i] = @tick_duration

            elsif to[i] && !step[i] && every[i]
              function_range[i] = to[i] - from[i]
              function_offset[i] = from[i]

              from[i] = 0r
              to[i] = 1r

              steps = effective_duration / every[i]
              step[i] = 1r / (steps - right_open_offset)

            elsif !to[i] && step[i] && every[i]
              # ok
            elsif !to[i] && !step[i] && every[i]
              step[i] = 1r

            else
              raise ArgumentError, 'Cannot use this parameters combination'
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

        size.times.each do |i|
          every_groups[every[i]] ||= []
          every_groups[every[i]] << i
        end

        control = MoveControl.new(@event_handlers.last, every_groups.size,
                                  duration: duration, till: till,
                                  on_stop: on_stop, after_bars: after_bars, after: after)

        control.on_stop do
          control.do_after.each do |do_after|
            _numeric_at position + do_after[:bars], control, &do_after[:block]
          end
        end

        @event_handlers.push control

        _numeric_at start_position, control do
          values = from.dup
          next_values = Array.new(size)

          ii = 0
          last_position = nil

          every_groups.each_pair do |every_group, affected_indexes|
            iii = ii # to make a local scope with ii external scope value
            first = true

            _every every_group, control.every_controls[ii] do
              if first
                first = false
              else
                i = affected_indexes.first

                if to[i] && (values[i] >= to[i] && step[i].positive? || values[i] <= to[i] && step[i].negative?)
                  control.every_controls[iii].stop
                else
                  affected_indexes.each do |i|
                    values[i] += step[i]
                  end
                end
              end

              affected_indexes.each do |i|
                next_values[i] = values[i] + step[i]
                if to[i] && (next_values[i] > to[i] && step[i].positive? || next_values[i] < to[i] && step[i].negative?)
                  next_values[i] = nil
                end
              end

              if position != last_position
                effective_values = from.clone(freeze: false).map!.with_index do |_, i|
                  function[i].call(values[i]) * function_range[i] + function_offset[i]
                end

                effective_next_values = from.clone(freeze: false).map!.with_index do |_, i|
                  function[i].call(next_values[i]) * function_range[i] + function_offset[i] unless next_values[i].nil?
                end

                value_parameters, key_parameters =
                  if array_mode
                    binder.apply(effective_values, effective_next_values, control: control, duration: every_group, right_open: right_open)
                  else
                    binder.apply(effective_values.first, effective_next_values.first, control: control, duration: every_group, right_open: right_open)
                  end

                yield *value_parameters, **key_parameters

                last_position = position
              end

            end
            ii += 1
          end
        end

        @event_handlers.pop

        control
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

      def _log(msg = nil)
        m = '...' unless msg
        m = ": #{msg}" if msg

        warn "#{position.to_f.round(3)} [#{position}]#{m}"
      end
    end
  end
end

