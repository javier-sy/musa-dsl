require 'musa-dsl/mods/arrayfy'
require 'musa-dsl/mods/key-parameters-procedure-binder'

require_relative 'base-sequencer-implementation-control'
require_relative 'base-sequencer-implementation-play-helper'

class Musa::BaseSequencer
  private

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
      _log "BaseSequencer._numeric_at: warning: rounding position #{bar_position} (#{original_position}) to tick precision: #{position / @ticks_per_bar} (#{position})" if @do_log
    end

    value_parameters = []
    value_parameters << with if !with.nil? && !with.is_a?(Hash)

    block_key_parameters_binder = KeyParametersProcedureBinder.new block, on_rescue: proc { |e| _rescue_block_error(e) }

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

  def _theme(theme, control, at:, debug: nil, **parameters)
    theme_constructor_parameters = {}

    run_method = theme.instance_method(:run)
    at_position_method = theme.instance_method(:at_position)
    at_position_method_parameter_binder = KeyParametersProcedureBinder.new at_position_method, on_rescue: proc { |e| _rescue_block_error(e) }

    run_parameters = run_method.parameters.collect { |p| [p[1], nil] }.compact.to_h
    run_parameters.delete :next_position

    parameters.each do |k, v|
      if run_parameters.include? k
        run_parameters[k] = v
      else
        theme_constructor_parameters[k] = v
      end
    end

    run_parameters[:at] = at.duplicate if run_parameters.include? :at

    theme_instance = theme.new **theme_constructor_parameters

    with_serie_at = H(run_parameters)
    with_serie_run = with_serie_at.slave

    _serie_at at.eval(with: with_serie_at) { |p, **parameters|
                if !parameters.empty?
                  effective_parameters = at_position_method_parameter_binder.apply parameters
                  theme_instance.at_position p, **effective_parameters
                else
                  _log "Warning: parameters serie for theme #{theme} is finished. Theme finished before at: serie is finished." if @do_log
                  nil
                end
              },
              control,
              with: with_serie_run,
              debug: debug do |**parameters|
      # TODO: optimizar inicialización KeyParamtersProcedureBinder
      effective_parameters = KeyParametersProcedureBinder.new(run_method).apply parameters
      theme_instance.run **effective_parameters
    end

    nil
  end

  def _play(serie, control, nl_context = nil, mode: nil, decoder: nil, __play_eval: nil, **mode_args, &block)
    __play_eval ||= PlayEval.create mode, KeyParametersProcedureBinder.new(block, on_rescue: proc { |e| _rescue_block_error(e) }), decoder, nl_context

    element = serie.next_value

    if element && !control.stopped?
      operation = __play_eval.run_operation element

      case operation[:current_operation]

      when :none

      when :block

        __play_eval.block_procedure_binder.call operation[:current_parameter], control: control

      when :event

        control._launch operation[:current_event], operation[:current_value_parameters], operation[:current_key_parameters]

      when :play

        control2 = PlayControl.new control
        control3 = PlayControl.new control2
        control3.after { control3.launch :sync }

        _play operation[:current_parameter], control3, __play_eval: __play_eval.subcontext, **mode_args

        control2.on :sync do
          _play serie, control, __play_eval: __play_eval, **mode_args
        end

      when :parallel_play

        control2 = PlayControl.new control

        operation[:current_parameter].each do |current_parameter|
          control3 = PlayControl.new control2
          control3.after { control3.launch :sync }

          _play current_parameter, control3, __play_eval: __play_eval.subcontext, **mode_args
        end

        counter = operation[:current_parameter].size

        control2.on :sync do
          counter -= 1
          _play serie, control, __play_eval: __play_eval, **mode_args if counter == 0
        end
      end

      case operation[:continue_operation]
      when :now
        now do
          _play serie, control, __play_eval: __play_eval, **mode_args
        end

      when :at
        at operation[:continue_parameter] do
          _play serie, control, __play_eval: __play_eval, **mode_args
        end

      when :wait
        wait operation[:continue_parameter] do
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

  def _move(every: nil, from:, to: nil, step: nil, duration: nil, till: nil, on_stop: nil, after_bars: nil, after: nil, &block)

    raise ArgumentError, "Cannot use duration: #{duration} and till: #{till} parameters at the same time. Use only one of them." if till && duration

    # from, to, step, every
    # from, to, step, (duration | till)
    # from, to, every, (duration | till)
    # from, step, every, (duration | till)

    step = -step if step && to && ((step > 0 && to < from) || (step < 0 && from < to))

    start_position = position

    if duration || till
      effective_duration = duration || till - start_position

      if to && step && !every
        steps = (to - from) / step
        every = Rational(effective_duration, steps)

      elsif to && !step && every
        steps = (to - from) / every
        step = (to - from) / steps

      elsif !to && step && every
        # ok
      else
        raise ArgumentError, 'Cannot use this parameters combination'
      end
    else
      if to && step && every
        # ok
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

        yield value, **parameters

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
