require_relative '../core-ext/arrayfy'
require_relative '../core-ext/smart-proc-binder'
require_relative '../logger'

require_relative '../series'

require_relative 'timeslots'

require_relative 'base-sequencer-tick-based'
require_relative 'base-sequencer-tickless-based'

# Musical sequencer and scheduler system.
#
# Sequencer provides precise timing and scheduling for musical events,
# supporting both tick-based (quantized) and tickless (continuous) timing
# modes. Events are scheduled with musical time units (bars, beats, ticks)
# and executed sequentially.
#
# ## Core Concepts
#
# - **Position**: Current playback position in beats
# - **Timeslots**: Scheduled events indexed by time
# - **Timing Modes**:
#
#   - **Tick-based**: Quantized to beats_per_bar × ticks_per_beat grid
#   - **Tickless**: Continuous rational time (no quantization)
#
# - **Scheduling Methods**:
#
#   - `at`: Schedule block at absolute position
#   - `wait`: Schedule relative to current position
#   - `play`: Play series over time
#   - `every`: Repeat at intervals
#   - `move`: Animate value over time
#
# - **Event Handlers**: Hierarchical event pub/sub system
# - **Controls**: Objects returned by scheduling methods for lifecycle management
#
# ## Tick-based vs Tickless
#
# **Tick-based** (beats_per_bar and ticks_per_beat specified):
#
# - Positions quantized to tick grid
# - `tick` method advances by one tick
# - Suitable for MIDI-like discrete timing
# - Example: `BaseSequencer.new(4, 24)` → 4/4 time, 24 ticks per beat
#
# **Tickless** (no timing parameters):
#
# - Continuous rational time
# - `tick(position)` jumps to arbitrary position
# - Suitable for score-like continuous timing
# - Example: `BaseSequencer.new` → tickless mode
#
# ## Musical Time Units
#
# - **Bar**: Musical measure (defaults to 1.0 in value)
# - **Beat**: Subdivision of bar (e.g., quarter note in 4/4)
# - **Tick**: Smallest time quantum in tick-based mode
# - All times are Rational for precision
#
# @example Basic tick-based sequencer
#   seq = Musa::Sequencer::BaseSequencer.new(4, 24)  # 4/4, 24 ticks/beat
#
#   seq.at(1) { puts "Beat 1" }
#   seq.at(2) { puts "Beat 2" }
#   seq.at(3.5) { puts "Beat 3.5" }
#
#   seq.run  # Executes all scheduled events
#
# @example Tickless sequencer
#   seq = Musa::Sequencer::BaseSequencer.new  # Tickless mode
#
#   seq.at(1) { puts "Position 1" }
#   seq.at(1.5) { puts "Position 1.5" }
#
#   seq.tick(1)    # Jumps to position 1
#   seq.tick(1.5)  # Jumps to position 1.5
#
# @example Playing series
#   require 'musa-dsl'
#
#   clock = Musa::Clock::TimerClock.new bpm: 120
#   transport = Musa::Transport::Transport.new clock
#   output = MIDICommunications::Output.all.first
#   voices = Musa::MIDIVoices::MIDIVoices.new(
#     sequencer: transport.sequencer,
#     output: output,
#     channels: [0]
#   )
#   voice = voices.voices.first
#   seq = transport.sequencer
#
#   pitches = Musa::Series::S(60, 62, 64, 65, 67)
#   durations = Musa::Series::S(1, 1, 0.5, 0.5, 2)
#
#   seq.play(pitches.zip(durations)) do |pitch, duration|
#     voice.note pitch: pitch, duration: duration
#   end
#
#   transport.start_transport
#   sleep 10
#   transport.stop_transport
#
# @example Every and move
#   require 'musa-dsl'
#
#   clock = Musa::Clock::TimerClock.new bpm: 120
#   transport = Musa::Transport::Transport.new clock
#   output = MIDICommunications::Output.all.first
#   voices = Musa::MIDIVoices::MIDIVoices.new(
#     sequencer: transport.sequencer,
#     output: output,
#     channels: [0]
#   )
#   voice = voices.voices.first
#   seq = transport.sequencer
#
#   # Execute every beat
#   seq.every(1, till: 8) { puts "Tick at position: #{seq.position}" }
#
#   # Animate value from 0 to 127 over 4 beats
#   seq.move(every: 1/4r, from: 0, to: 127, duration: 4) do |value|
#     voice.controller[:volume] = value.round
#   end
#
#   transport.start_transport
#   sleep 10
#   transport.stop_transport
#
# @see https://en.wikipedia.org/wiki/Music_sequencer Music sequencer (Wikipedia)
# @see https://en.wikipedia.org/wiki/Scheduling_(computing) Scheduling (Wikipedia)
module Musa
  module Sequencer
    # Core sequencer for musical event scheduling and playback.
    #
    # BaseSequencer manages event scheduling, timing, and execution in both
    # tick-based (quantized) and tickless (continuous) modes.
    class BaseSequencer
      # @return [Rational, nil] beats per bar (tick-based mode only)
      attr_reader :beats_per_bar

      # @return [Rational, nil] ticks per beat (tick-based mode only)
      attr_reader :ticks_per_beat

      # @return [Rational] time offset for position calculations
      attr_reader :offset

      # @return [Rational] current running position
      attr_reader :running_position

      # @return [Array<EveryControl>] active every loops
      attr_reader :everying

      # @return [Array<PlayControl, PlayTimedControl>] active play operations
      attr_reader :playing

      # @return [Array<MoveControl>] active move operations
      attr_reader :moving

      # @return [Musa::Logger::Logger] sequencer logger
      attr_reader :logger

      # Creates sequencer with timing configuration.
      #
      # ## Timing Modes
      #
      # **Tick-based**: Provide both beats_per_bar and ticks_per_beat
      #
      # - Position quantized to tick grid
      # - `tick` advances by one tick
      #
      # **Tickless**: Omit beats_per_bar and ticks_per_beat
      #
      # - Continuous rational time
      # - `tick(position)` jumps to position
      #
      # @param beats_per_bar [Numeric, nil] beats per bar (nil for tickless)
      # @param ticks_per_beat [Numeric, nil] ticks per beat (nil for tickless)
      # @param offset [Rational, nil] starting position offset
      # @param logger [Musa::Logger::Logger, nil] custom logger
      # @param do_log [Boolean, nil] enable debug logging
      # @param do_error_log [Boolean, nil] enable error logging
      # @param log_position_format [Proc, nil] custom position formatter for logs
      #
      # @raise [ArgumentError] if only one of beats_per_bar/ticks_per_beat provided
      #
      # @example Tick-based 4/4 time
      #   seq = BaseSequencer.new(4, 24)
      #
      # @example Tick-based 3/4 time
      #   seq = BaseSequencer.new(3, 24)
      #
      # @example Tickless mode
      #   seq = BaseSequencer.new
      #
      # @example With offset
      #   seq = BaseSequencer.new(4, 24, offset: 10r)
      def initialize(beats_per_bar = nil, ticks_per_beat = nil,
                     offset: nil,
                     logger: nil,
                     do_log: nil, do_error_log: nil, log_position_format: nil)

        unless beats_per_bar && ticks_per_beat || beats_per_bar.nil? && ticks_per_beat.nil?
          raise ArgumentError, "'beats_per_bar' and 'ticks_per_beat' parameters should be both nil or both have values"
        end

        if logger
          @logger = logger
        else
          @logger = Musa::Logger::Logger.new(sequencer: self, position_format: log_position_format)

          @logger.fatal!
          @logger.error! if do_error_log || do_error_log.nil?
          @logger.debug! if do_log
        end

        @offset = offset || 0r

        if beats_per_bar && ticks_per_beat
          @beats_per_bar = Rational(beats_per_bar)
          @ticks_per_beat = Rational(ticks_per_beat)

          singleton_class.include TickBasedTiming
        else
          singleton_class.include TicklessBasedTiming
        end

        _init_timing

        @on_debug_at = []
        @on_error = []

        @before_tick = []
        @on_fast_forward = []

        @tick_mutex = Mutex.new
        @position_mutex = Mutex.new

        @timeslots = Timeslots.new

        @everying = []
        @playing = []
        @moving = []

        reset
      end

      # Resets sequencer to initial state.
      #
      # Clears all scheduled events, active operations, and event handlers.
      # Resets timing to start position.
      #
      # @return [void]
      def reset
        @timeslots.clear
        @everying.clear
        @playing.clear
        @moving.clear

        @event_handlers = [EventHandler.new]

        _reset_timing
      end

      # Counts total scheduled events.
      #
      # @return [Integer] number of scheduled events across all timeslots
      def size
        @timeslots.values.sum(&:size)
      end

      # Checks if sequencer has no scheduled events.
      #
      # @return [Boolean] true if no events scheduled
      def empty?
        @timeslots.empty?
      end

      # Quantizes position to tick grid (tick-based mode only).
      #
      # @param position [Rational] position to quantize
      # @param warn [Boolean] emit warning if quantization changes value
      #
      # @return [Rational] quantized position
      def quantize_position(position, warn: nil)
        warn ||= false
        _quantize_position(position, warn: warn)
      end

      # Executes all scheduled events until empty.
      #
      # Advances time tick by tick (or position by position in tickless mode)
      # until no events remain.
      #
      # @return [void]
      #
      # @example
      #   seq.at(1) { puts "Event 1" }
      #   seq.at(2) { puts "Event 2" }
      #   seq.run  # Executes both events
      def run
        tick until empty?
      end

      # Returns current event handler.
      #
      # @return [EventHandler] active event handler
      # @api private
      def event_handler
        @event_handlers.last
      end

      # Registers debug callback for scheduled events.
      #
      # @yield [event_info] debug information
      # @return [void]
      def on_debug_at(&block)
        @on_debug_at << Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)
      end

      # Registers error callback.
      #
      # @yield [error] error information
      # @return [void]
      def on_error(&block)
        @on_error << Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)
      end

      # Registers fast-forward callback (when jumping over events).
      #
      # @yield [skipped_events] information about skipped events
      # @return [void]
      def on_fast_forward(&block)
        @on_fast_forward << Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)
      end

      # Registers callback executed before each tick.
      #
      # @yield [position] current position before tick
      # @return [void]
      def before_tick(&block)
        @before_tick << Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)
      end

      # Subscribes to custom event.
      #
      # @param event [Symbol] event name
      # @yield [*args] event handler receiving event parameters
      # @return [void]
      def on(event, &block)
        @event_handlers.last.on event, &block
      end

      # Launches custom event.
      #
      # @param event [Symbol] event name
      # @param value_parameters [Array] positional parameters
      # @param key_parameters [Hash] keyword parameters
      # @return [void]
      def launch(event, *value_parameters, **key_parameters)
        @event_handlers.last.launch event, *value_parameters, **key_parameters
      end

      # Schedules block relative to current position.
      #
      # @param bars_delay [Numeric, Series, Array] delay from current position
      # @param debug [Boolean] enable debug logging
      # @yield block to execute at position + delay
      # @return [EventHandler] control object
      #
      # @example
      #   seq.wait(2) { puts "2 beats later" }
      def wait(bars_delay, debug: nil, &block)
        debug ||= false

        control = EventHandler.new @event_handlers.last
        @event_handlers.push control

        if bars_delay.is_a? Numeric
          _numeric_at position + bars_delay.rationalize, control, debug: debug, &block
        else
          bars_delay = Series::S(*bars_delay) if bars_delay.is_a?(Array)
          bars_delay = bars_delay.instance if bars_delay

          _serie_at bars_delay.with { |delay| position + delay }, control, debug: debug, &block
        end

        @event_handlers.pop

        control
      end

      # Schedules block at current position (immediate execution on next tick).
      #
      # @yield block to execute at current position
      # @return [EventHandler] control object
      #
      # @example
      #   seq.now { puts "Executes now" }
      def now(&block)
        control = EventHandler.new @event_handlers.last
        @event_handlers.push control

        _numeric_at position, control, &block

        @event_handlers.pop

        control
      end

      # Schedules block at absolute position (low-level, no control object).
      #
      # @param bar_position [Numeric] absolute position
      # @param force_first [Boolean] force execution before other events at same time
      # @yield block to execute
      # @return [nil]
      # @api private
      def raw_at(bar_position, force_first: nil, &block)
        _raw_numeric_at bar_position.rationalize, force_first: force_first, &block

        nil
      end

      # Schedules block at absolute position.
      #
      # @param bar_position [Numeric, Series, Array] absolute position(s)
      # @param debug [Boolean] enable debug logging
      # @yield block to execute at position
      # @return [EventHandler] control object
      #
      # @example Single position
      #   seq.at(4) { puts "At beat 4" }
      #
      # @example Series of positions
      #   seq.at([1, 2, 3.5, 4]) { |pos| puts "At #{pos}" }
      def at(bar_position, debug: nil, &block)
        debug ||= false

        control = EventHandler.new @event_handlers.last
        @event_handlers.push control

        if bar_position.is_a? Numeric
          _numeric_at bar_position.rationalize, control, debug: debug, &block
        else
          bar_position = Series::S(*bar_position) if bar_position.is_a? Array
          bar_position = bar_position.instance if bar_position

          _serie_at bar_position, control, debug: debug, &block
        end

        @event_handlers.pop

        control
      end

      # Plays series over time.
      #
      # Consumes series values sequentially, executing block for each value.
      # Timing determined by mode (see base-sequencer-implementation-play.rb).
      #
      # @param serie [Series] series to play
      # @param mode [Symbol] timing mode (:wait, :measure, etc.)
      # @param parameter [Symbol, nil] duration parameter name from serie values
      # @param after_bars [Numeric, nil] schedule block after play finishes
      # @param after [Proc, nil] block to execute after play finishes
      # @param context [Object, nil] context for neumalang processing
      # @param mode_args [Hash] additional mode-specific parameters
      # @yield [value] block executed for each serie value
      # @return [PlayControl] control object
      #
      # @example
      #   require 'musa-dsl'
      #
      #   clock = Musa::Clock::TimerClock.new bpm: 120
      #   transport = Musa::Transport::Transport.new clock
      #   output = MIDICommunications::Output.all.first
      #   voices = Musa::MIDIVoices::MIDIVoices.new(
      #     sequencer: transport.sequencer,
      #     output: output,
      #     channels: [0]
      #   )
      #   voice = voices.voices.first
      #   seq = transport.sequencer
      #
      #   seq.play(Musa::Series::S(60, 62, 64).zip(Musa::Series::S(1, 1, 2))) do |pitch, dur|
      #     voice.note pitch: pitch, duration: dur
      #   end
      def play(serie,
               mode: nil,
               parameter: nil,
               after_bars: nil,
               after: nil,
               context: nil,
               **mode_args,
               &block)

        mode ||= :wait

        control = PlayControl.new @event_handlers.last, after_bars: after_bars, after: after
        @event_handlers.push control

        _play serie.instance, control, context, mode: mode, parameter: parameter, **mode_args, &block

        @event_handlers.pop

        @playing << control

        control.after do
          @playing.delete control
        end

        control
      end

      def continuation_play(parameters)
        _play parameters[:serie],
              parameters[:control],
              parameters[:neumalang_context],
              mode: parameters[:mode],
              decoder: parameters[:decoder],
              __play_eval: parameters[:play_eval],
              **parameters[:mode_args]
      end

      # Plays timed series (series with embedded timing information).
      #
      # Similar to play but serie values include timing. See
      # base-sequencer-implementation-play-timed.rb for details.
      #
      # @param timed_serie [Series] timed series
      # @param at [Rational, nil] starting position
      # @param on_stop [Proc, nil] callback when playback stops
      # @param after_bars [Numeric, nil] schedule after completion
      # @param after [Proc, nil] block after completion
      # @yield [value] block for each value
      # @return [PlayTimedControl] control object
      def play_timed(timed_serie,
                     at: nil,
                     on_stop: nil,
                     after_bars: nil, after: nil,
                     &block)

        at ||= position

        control = PlayTimedControl.new(@event_handlers.last,
                                       on_stop: on_stop, after_bars: after_bars, after: after)

        control.on_stop do
          control.do_after.each do |do_after|
            _numeric_at position + do_after[:bars], control, &do_after[:block]
          end
        end

        @event_handlers.push control

        _play_timed(timed_serie.instance, at, control, &block)

        @event_handlers.pop

        @playing << control

        control.after do
          @playing.delete control
        end

        control
      end

      # Executes block repeatedly at regular intervals.
      #
      # @param interval [Numeric, nil] interval between executions (nil = once)
      # @param duration [Numeric, nil] total duration
      # @param till [Numeric, nil] end position
      # @param condition [Proc, nil] continue while condition true
      # @param on_stop [Proc, nil] callback when loop stops
      # @param after_bars [Numeric, nil] schedule after completion
      # @param after [Proc, nil] block after completion
      # @yield [position] block executed each interval
      # @return [EveryControl] control object
      #
      # @example
      #   seq.every(1, till: 8) { |pos| puts "Beat #{pos}" }
      def every(interval,
                duration: nil, till: nil,
                condition: nil,
                on_stop: nil,
                after_bars: nil, after: nil,
                &block)

        # nil interval means 'only once'
        interval = interval.rationalize unless interval.nil?

        control = EveryControl.new @event_handlers.last,
                                   duration: duration,
                                   till: till,
                                   condition: condition,
                                   on_stop: on_stop,
                                   after_bars: after_bars,
                                   after: after

        @event_handlers.push control

        _every interval, control, &block

        @event_handlers.pop

        @everying << control

        control.after do
          @everying.delete control
        end

        control
      end

      # Animates value from start to end over time.
      #
      # @param every [Numeric] interval between updates
      # @param from [Numeric] starting value
      # @param to [Numeric] ending value
      # @param step [Numeric, nil] value increment per step
      # @param duration [Numeric, nil] total duration
      # @param till [Numeric, nil] end position
      # @param function [Symbol, Proc, nil] interpolation function
      # @param right_open [Boolean, nil] exclude final value
      # @param on_stop [Proc, nil] callback when animation stops
      # @param after_bars [Numeric, nil] schedule after completion
      # @param after [Proc, nil] block after completion
      # @yield [value] block executed with interpolated value
      # @return [MoveControl] control object
      #
      # @example Linear fade
      #   require 'musa-dsl'
      #
      #   clock = Musa::Clock::TimerClock.new bpm: 120
      #   transport = Musa::Transport::Transport.new clock
      #   output = MIDICommunications::Output.all.first
      #   voices = Musa::MIDIVoices::MIDIVoices.new(
      #     sequencer: transport.sequencer,
      #     output: output,
      #     channels: [0]
      #   )
      #   voice = voices.voices.first
      #   seq = transport.sequencer
      #
      #   seq.move(every: 1/4r, from: 0, to: 127, duration: 4) do |val|
      #     voice.controller[:volume] = val.round
      #   end
      def move(every: nil,
               from: nil, to: nil, step: nil,
               duration: nil, till: nil,
               function: nil,
               right_open: nil,
               on_stop: nil,
               after_bars: nil,
               after: nil,
               &block)

        control = _move every: every,
                        from: from, to: to, step: step,
                        duration: duration, till: till,
                        function: function,
                        right_open: right_open,
                        on_stop: on_stop,
                        after_bars: after_bars,
                        after: after,
                        &block

        @moving << control

        control.after do
          @moving.delete control
        end

        control
      end

      def debug(msg = nil)
        @logger.debug { msg || '...' }
      end

      def to_s
        super + ": position=#{position}"
      end
    end
  end
end

