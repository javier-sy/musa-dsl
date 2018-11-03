require 'musa-dsl/mods/arrayfy'
require 'musa-dsl/mods/key-parameters-procedure-binder'

require 'musa-dsl/series'

class Musa::BaseSequencer
  attr_reader :ticks_per_bar, :running_position
  attr_reader :everying, :playing, :moving

  @@tick_mutex = Mutex.new

  def initialize(quarter_notes_by_bar, quarter_note_divisions, do_log: nil)
    do_log ||= false

    @on_debug_at = []
    @on_fast_forward = []
    @on_block_error = []

    @ticks_per_bar = Rational(quarter_notes_by_bar * quarter_note_divisions)

    @score = {}

    @everying = []
    @playing = []
    @moving = []

    @do_log = do_log

    reset
  end

  def reset
    @score.clear
    @everying.clear
    @playing.clear
    @moving.clear
    
    @event_handlers = [EventHandler.new]

    @position = @ticks_per_bar - 1
  end

  def tick
    position_to_run = (@position += 1)

    if @score[position_to_run]
      @score[position_to_run].each do |command|
        if command.key?(:parent_control)
          @event_handlers.push command[:parent_control]

          @@tick_mutex.synchronize do
            original_stdout = $stdout
            original_stderr = $stderr

            $stdout = command[:parent_control].stdout
            $stderr = command[:parent_control].stderr

            command[:block].call *command[:value_parameters], **command[:key_parameters]

            $stdout = original_stdout
            $stderr = original_stderr
          end

          @event_handlers.pop
        else
          @@tick_mutex.synchronize do
            command[:block].call *command[:value_parameters], **command[:key_parameters]
          end
        end
      end

      @score.delete position_to_run
    end
  end

  def size
    @score.size
  end

  def empty?
    @score.empty?
  end

  def round(bar)
    Rational((bar * @ticks_per_bar).round(0), @ticks_per_bar)
  end

  def event_handler
    @event_handlers.last
  end

  def on_debug_at(&block)
    @on_debug_at << block
  end

  def on_block_error(&block)
    @on_block_error << block
  end

  def on_fast_forward(&block)
    @on_fast_forward << block
  end

  def position
    Rational(@position, @ticks_per_bar)
  end

  def position=(bposition)
    position = bposition * @ticks_per_bar

    raise ArgumentError, "Sequencer #{self}: cannot move back. current position: #{@position} new position: #{position}" if position < @position

    @on_fast_forward.each { |block| block.call(true) }

    tick while @position < position

    @on_fast_forward.each { |block| block.call(false) }
  end

  def on(event, &block)
    @event_handlers.last.on event, &block
  end

  def launch(event, *value_parameters, **key_parameters)
    @event_handlers.last.launch event, *value_parameters, **key_parameters
  end

  def wait(bars_delay, with: nil, debug: nil, &block)
    debug ||= false

    control = EventHandler.new @event_handlers.last, capture_stdout: true
    @event_handlers.push control

    if bars_delay.is_a? Numeric
      _numeric_at position + bars_delay.rationalize, control, with: with, debug: debug, &block
    else
      bars_delay = Series::S(*bars_delay) if bars_delay.is_a? Array
      with = Series::S(*with).repeat if with.is_a? Array

      starting_position = position
      _serie_at bars_delay.eval { |delay| starting_position + delay }, control, with: with, debug: debug, &block
    end

    @event_handlers.pop

    control
  end

  def now(with: nil, &block)
    control = EventHandler.new @event_handlers.last, capture_stdout: true
    @event_handlers.push control

    _numeric_at position, control, with: with, &block

    @event_handlers.pop

    control
  end

  def raw_at(bar_position, force_first: nil, &block)
    _raw_numeric_at bar_position, force_first: force_first, &block

    nil
  end

  def at(bar_position, with: nil, debug: nil, &block)
    debug ||= false

    control = EventHandler.new @event_handlers.last, capture_stdout: true
    @event_handlers.push control

    if bar_position.is_a? Numeric
      _numeric_at bar_position, control, with: with, debug: debug, &block
    else
      bar_position = Series::S(*bar_position) if bar_position.is_a? Array
      with = Series::S(*with).repeat if with.is_a? Array

      _serie_at bar_position, control, with: with, debug: debug, &block
    end

    @event_handlers.pop

    control
  end

  def theme(theme, at:, debug: nil, **parameters)
    debug ||= false

    control = EventHandler.new @event_handlers.last, capture_stdout: true
    @event_handlers.push control

    _theme theme, control, at: at, debug: debug, **parameters

    @event_handlers.pop

    control
  end

  def play(serie, mode: nil, parameter: nil, after: nil, context: nil, **mode_args, &block)
    mode ||= :wait

    control = PlayControl.new @event_handlers.last, after: after, capture_stdout: true
    @event_handlers.push control

    _play serie, control, context, mode: mode, parameter: parameter, **mode_args, &block

    @event_handlers.pop

    @playing << control

    control.after do
      @playing.delete control
    end

    control
  end

  def every(binterval, duration: nil, till: nil, condition: nil, on_stop: nil, after_bars: nil, after: nil, &block)
    binterval = binterval.rationalize

    control = EveryControl.new @event_handlers.last, capture_stdout: true, duration: duration, till: till, condition: condition, on_stop: on_stop, after_bars: after_bars, after: after
    @event_handlers.push control

    _every binterval, control, &block

    @event_handlers.pop

    @everying << control

    control.after do
      @everying.delete control
    end

    control
  end

  # TODO: estaría bien que from y to pudiera tener un Hash, de modo que el movimiento se realice entre los valores de sus atributos
  # TODO tb estaría bien que pudiera ser un Array de Hash, con la misma semántica en modo polifónico
  def move(every: nil, from: nil, to: nil, diff: nil, using_init: nil, using: nil, step: nil, duration: nil, till: nil, on_stop: nil, after_bars: nil, after: nil, &block)
    every ||= Rational(1, @ticks_per_bar)
    every = every.rationalize unless every.is_a?(Rational)

    control = _move every: every, from: from, to: to, diff: diff, using_init: using_init, using: using, step: step, duration: duration, till: till, on_stop: on_stop, after_bars: after_bars, after: after, &block

    @moving << control

    control.after do
      @moving.delete control
    end

    control
  end

  def log(msg = nil)
    _log msg
  end

  def to_s
    super + ": position=#{position}"
  end

  alias inspect to_s
end

module Musa::BaseTheme
  def at_position(p, **_parameters)
    p
  end

  def run; end
end
