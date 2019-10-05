require 'musa-dsl/core-ext/arrayfy'
require 'musa-dsl/core-ext/key-parameters-procedure-binder'

require_relative 'base-sequencer-implementation-control'
require_relative 'base-sequencer-implementation-play-helper'

class Musa::BaseSequencer
  private

  def _tick
    position_to_run = @position_mutex.synchronize { @position += 1 }

    @before_tick.each { |block| block.call Rational(position_to_run, @ticks_per_bar) }

    if @score[position_to_run]
      @score[position_to_run].each do |command|

        if command.key?(:parent_control) && !command[:parent_control].stopped?
          @event_handlers.push command[:parent_control]

          @@tick_mutex.synchronize do
            original_stdout = $stdout
            original_stderr = $stderr

            $stdout = command[:parent_control].stdout
            $stderr = command[:parent_control].stderr

            command[:block]._call command[:value_parameters], command[:key_parameters] if command[:block]

            $stdout = original_stdout
            $stderr = original_stderr
          end

          @event_handlers.pop
        else
          @@tick_mutex.synchronize do
            command[:block]._call command[:value_parameters], command[:key_parameters] if command[:block]
          end
        end
      end

      @score.delete position_to_run
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
        _rescue_block_error e
      end

    elsif position > @position
      @score[position] = [] unless @score[position]

      value = { block: block, value_parameters: [], key_parameters: {} }
      if force_first
        @score[position].insert 0, value
      else
        @score[position] << value
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
        KeyParametersProcedureBinder.new block, on_rescue: proc { |e| _rescue_block_error(e) }

      key_parameters = {}
      key_parameters.merge! block_key_parameters_binder.apply with if with.is_a? Hash

      key_parameters[:control] = control if block_key_parameters_binder.key?(:control)

      if position == @position
        @debug_at.call if debug && @debug_at

        begin
          locked = @@tick_mutex.try_lock

          if locked
            original_stdout = $stdout
            original_stderr = $stderr

            $stdout = control.stdout
            $stderr = control.stderr
          end

          block_key_parameters_binder._call value_parameters, key_parameters
        ensure
          if locked
            $stdout = original_stdout
            $stderr = original_stderr
          end

          @@tick_mutex.unlock if locked
        end

      elsif position > @position
        @score[position] = [] unless @score[position]

        @score[position] << { parent_control: control, block: @on_debug_at } if debug && @on_debug_at
        @score[position] << { parent_control: control, block: block_key_parameters_binder, value_parameters: value_parameters, key_parameters: key_parameters }
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
      KeyParametersProcedureBinder.new(block,
                                       on_rescue: proc { |e| _rescue_block_error(e) }),
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
        #now do
        _numeric_at position, control do
          _play serie, control, __play_eval: __play_eval, **mode_args
        end

      when :at
        #at operation[:continue_parameter] do
        _numeric_at operation[:continue_parameter], control do
          _play serie, control, __play_eval: __play_eval, **mode_args
        end

      when :wait
        #wait operation[:continue_parameter] do
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

    block_procedure_binder ||= KeyParametersProcedureBinder.new block, on_rescue: proc { |e| _rescue_block_error(e) }

    _numeric_at position, control do
      control._start ||= position

      duration_exceeded = (control._start + control.duration_value - binterval) <= position if control.duration_value
      till_exceeded = control.till_value - binterval <= position if control.till_value
      condition_failed = !instance_eval(&control.condition) if control.condition

      block_procedure_binder.call(control: control) unless control.stopped?

      if !control.stopped? && !duration_exceeded && !till_exceeded && !condition_failed

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

    # from, to, step, every
    # from, to, step, (duration | till)
    # from, to, every, (duration | till)
    # from, step, every, (duration | till)

    block ||= proc {}

    step = -step if step && to && ((step > 0 && to < from) || (step < 0 && from < to))
    right_open ||= false

    function ||= proc { |ratio| ratio }
    function_range = 1r
    function_offset = 0r

    start_position = position

    if duration || till
      effective_duration = duration || till - start_position
      right_open_offset = right_open ? 0 : 1 # Add 1 tick to arrive to final value in duration time (no need to add an extra tick)

      if to && step && !every
        steps = (to - from) / step
        every = Rational(effective_duration, steps + right_open_offset)

      elsif to && !step && !every
        function_range = to - from
        function_offset = from

        from = 0r
        to = 1r

        step = 1r / (effective_duration * @ticks_per_bar - right_open_offset)
        every = @tick_duration

      elsif to && !step && every
        function_range = to - from
        function_offset = from

        from = 0r
        to = 1r

        steps = effective_duration / every
        step = 1r / (steps - right_open_offset)

      elsif !to && step && every
        # ok
      elsif !to && !step && every
        step = 1r

      else
        raise ArgumentError, 'Cannot use this parameters combination'
      end
    else
      if to && step && every
        # ok
      elsif to && !step && every
        step = (to <=> from).to_r
      else
        raise ArgumentError, 'Cannot use this parameters combination'
      end
    end

    binder = KeyParametersProcedureBinder.new(block)

    every_control = EveryControl.new(@event_handlers.last, capture_stdout: true, duration: duration, till: till, on_stop: on_stop, after_bars: after_bars, after: after)

    control = MoveControl.new(every_control)

    @event_handlers.push control

    _numeric_at start_position, control do
      value = from

      _every every, every_control do

        parameters = binder.apply(control: control)

        yield function.call(value) * function_range + function_offset, **parameters

        if to && (value >= to && step.positive? || value <= to && step.negative?)
          control.stop
        else
          value += step
        end
      end
    end

    @event_handlers.pop

    control
  end

  def _rescue_block_error(e)
    _log e
    _log e.full_message(order: :top)

    @on_block_error.each do |block|
      block.call e
    end
  end

  def _log(msg = nil)
    m = '...' unless msg
    m = ": #{msg}" if msg

    warn "#{position.to_f.round(3)} [#{position}]#{m}"
  end
end
