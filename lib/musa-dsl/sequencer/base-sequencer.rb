require_relative '../core-ext/arrayfy'
require_relative '../core-ext/smart-proc-binder'
require_relative '../logger'

require_relative '../series'

require_relative 'timeslots'

require_relative 'base-sequencer-tick-based'
require_relative 'base-sequencer-tickless-based'

module Musa
  module Sequencer
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
    # ## Block Parameter Flexibility (SmartProcBinder)
    #
    # All scheduling methods (`every`, `play`, `move`, `play_timed`) pass parameters
    # to user blocks via SmartProcBinder. This means blocks can declare **only the
    # parameters they need** — undeclared parameters are silently ignored.
    #
    # Keyword parameters (like `control:`) must be declared as keyword arguments
    # in the block signature (`|control:|`), not as positional arguments (`|control|`).
    #
    # | Method | Positional params | Keyword params |
    # |--------|-------------------|----------------|
    # | `every` | _(none)_ | `control:` |
    # | `play` | element (+ hash keys as keywords) | `control:` |
    # | `move` | value, next_value | `control:`, `duration:`, `quantized_duration:`, `started_ago:`, `position_jitter:`, `duration_jitter:`, `right_open:` |
    # | `play_timed` | values (+ extra attributes as keywords) | `time:`, `started_ago:`, `control:` |
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
    # - `tick` advances to the next scheduled position (it takes no argument)
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
    #   seq.tick  # Jumps to position 1 -- tick takes no argument; in tickless
    #   seq.tick  # mode it advances to wherever the next event is scheduled.
    #
    # @example Playing series
    #   seq = Musa::Sequencer::BaseSequencer.new(4, 24)
    #
    #   # Series are combined with H, which yields the hashes play consumes;
    #   # there is no `zip`. The :duration of each element is what makes play
    #   # walk time.
    #   notes = Musa::Series::Constructors.H(
    #     pitch: Musa::Series::Constructors.S(60, 62, 64, 65, 67),
    #     duration: Musa::Series::Constructors.S(1r, 1r, 1/2r, 1/2r, 2r))
    #   played_notes = []
    #
    #   seq.play(notes) do |pitch:, duration:|
    #     played_notes << { pitch: pitch, duration: duration, position: seq.position }
    #   end
    #
    #   seq.run
    #   played_notes.collect { |n| n[:pitch] }  # => [60, 62, 64, 65, 67]
    #
    # @example Every and move
    #   seq = Musa::Sequencer::BaseSequencer.new(4, 24)
    #
    #   tick_positions = []
    #   volume_values = []
    #
    #   # Execute every beat
    #   seq.every(1, till: 8) { tick_positions << seq.position }
    #
    #   # Animate value from 0 to 127 over 4 beats
    #   seq.move(every: 1/4r, from: 0, to: 127, duration: 4) do |value|
    #     volume_values << value.round
    #   end
    #
    #   seq.run
    #
    #   tick_positions.size            # => 7
    #   tick_positions.first           # => 95/96r
    #   volume_values.first            # => 0
    #   volume_values.last             # => 127
    #
    #   # 95/96 and not 1: a sequencer with a tick grid starts one tick before
    #   # bar 1, so an `every` written outside any `at` pulses one tick before
    #   # each bar. Inside `at 1` it lands on them. And seven pulses and not
    #   # eight, because `till:` is where it stops rather than the last one it
    #   # plays.
    #
    # The per-method examples further down are written against:
    #
    #     sequencer = BaseSequencer.new(4, 24)
    #
    # @api public
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
      # - `tick` advances to next scheduled position (without timing quantization)
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
      #
      # @example Resetting sequencer state
      #   seq = Musa::Sequencer::BaseSequencer.new(4, 24)
      #
      #   # Schedule some events
      #   seq.at(1) { puts "Event 1" }
      #   seq.at(2) { puts "Event 2" }
      #   seq.every(1, till: 8) { puts "Repeating" }
      #
      #   puts seq.size  # => 3 (scheduled events)
      #
      #   # Three: the `every` counts too. `size` is how many things are waiting
      #   # to happen, and a repeating one is a single waiting thing.
      #   puts seq.empty?  # => false
      #
      #   # Reset clears everything
      #   seq.reset
      #
      #   puts seq.size  # => 0
      #   puts seq.empty?  # => true
      #   puts seq.position  # => 95/96
      #   # Back to one tick before bar 1, not to zero: with 4 beats of 24 ticks
      #   # the reset position is 1r - 1/96r, so the next tick lands on bar 1.
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
      # @example Running until nothing is left
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
      # Callback is invoked when debug logging is enabled (see do_log parameter in
      # initialize). Called before executing each scheduled event, allowing inspection
      # of sequencer state at event execution time.
      #
      # @yield debug callback (receives no parameters)
      # @return [void]
      #
      # @example Monitoring event execution
      #   seq = Musa::Sequencer::BaseSequencer.new(4, 24, do_log: true)
      #
      #   debug_calls = []
      #
      #   seq.on_debug_at do
      #     debug_calls << { position: seq.position, time: Time.now }
      #   end
      #
      #   seq.at(1) { puts "Event 1" }
      #   seq.at(2) { puts "Event 2" }
      #
      #   seq.run
      #
      #   debug_calls.map { |c| c[:position] }  # => [(1/1), (2/1)]
      #
      #   # One call per event, at the position the event was scheduled for:
      #   # `at 1` lands on 1. (An `every` written outside any `at` would not --
      #   # see {#every} -- but that is about `every`, not about this hook.)
      def on_debug_at(&block)
        @on_debug_at << Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)
      end

      # Registers error callback.
      #
      # Callback is invoked when an error occurs during event execution. The error
      # is logged and passed to all registered error handlers. Handlers receive the
      # exception object and can process or report it.
      #
      # @yield [error] error callback receiving the exception object
      # @yieldparam error [StandardError, ScriptError] the exception that occurred
      # @return [void]
      #
      # @example Handling errors in scheduled events
      #   seq = Musa::Sequencer::BaseSequencer.new(4, 24, do_error_log: false)
      #
      #   errors = []
      #
      #   seq.on_error do |error|
      #     errors << { message: error.message, position: seq.position }
      #   end
      #
      #   seq.at(1) { puts "Normal event" }
      #   seq.at(2) { raise "Something went wrong!" }
      #   seq.at(3) { puts "This still executes" }
      #
      #   seq.run
      #
      #   errors  # => [{ message: "Something went wrong!", position: (2/1) }]
      #
      #   # The event at 3 ran anyway: an exception in a scheduled block is
      #   # reported and swallowed, never propagated to the sequencer's loop.
      #   # One broken voice does not stop the piece.
      def on_error(&block)
        @on_error << Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)
      end

      # Registers fast-forward callback (when jumping over events).
      #
      # Callback is invoked when position is changed directly (via position=), causing
      # the sequencer to skip ahead. Called twice: once with true when fast-forward
      # begins, and once with false when it completes. Events between old and new
      # positions are executed during fast-forward.
      #
      # @yield [is_starting] callback receiving fast-forward state
      # @yieldparam is_starting [Boolean] true when fast-forward begins, false when it ends
      # @return [void]
      #
      # @example Tracking fast-forward operations
      #   seq = Musa::Sequencer::BaseSequencer.new(4, 24)
      #
      #   ff_state = []
      #
      #   seq.on_fast_forward do |is_starting|
      #     if is_starting
      #       ff_state << "Fast-forward started from position #{seq.position}"
      #     else
      #       ff_state << "Fast-forward ended at position #{seq.position}"
      #     end
      #   end
      #
      #   seq.at(1) { puts "Event 1" }
      #   seq.at(5) { puts "Event 5" }
      #
      #   # Jump to position 10 (executes events at 1 and 5 during fast-forward)
      #   seq.position = 10
      #
      #   ff_state
      #   # => ["Fast-forward started from position 95/96",
      #   #     "Fast-forward ended at position 10/1"]
      #
      #   # 95/96 and not 0: a sequencer with a tick grid starts one tick before
      #   # bar 1, so that its first tick IS bar 1. Everything that reads the
      #   # position before anything has played sees that, including this.
      def on_fast_forward(&block)
        @on_fast_forward << Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)
      end

      # Registers callback executed before each tick.
      #
      # Callback is invoked before processing events at each position. Useful for
      # logging, metrics collection, or performing pre-tick setup. Receives the
      # position about to be executed.
      #
      # @yield [position] callback receiving the upcoming position
      # @yieldparam position [Rational] the position about to be processed
      # @return [void]
      #
      # @example Logging tick positions
      #   seq = Musa::Sequencer::BaseSequencer.new(4, 24)
      #
      #   tick_log = []
      #
      #   seq.before_tick do |position|
      #     tick_log << position
      #   end
      #
      #   seq.at(1) { puts "Event" }
      #   seq.at(2) { puts "Event" }
      #
      #   seq.tick  # Executes position 1
      #   seq.tick  # Advances position
      #   seq.tick  # Executes position 2
      #
      #   # tick_log contains [1, 1 + 1/96r, 2, ...]
      #
      # @example Conditional event scheduling
      #   seq = Musa::Sequencer::BaseSequencer.new(4, 24)
      #
      #   seq.before_tick do |position|
      #     # Schedule event only on whole beats
      #     if position == position.to_i
      #       seq.now { puts "Beat #{position}" }
      #     end
      #   end
      #
      #   seq.at(5) { puts "Trigger" }  # Start the sequencer
      #   seq.run
      def before_tick(&block)
        @before_tick << Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)
      end

      # Subscribes to custom event.
      #
      # Registers a handler for custom events in the sequencer's pub/sub system.
      # Events can be launched from scheduled blocks and handled at the sequencer
      # level or at specific control levels. Supports hierarchical event delegation.
      #
      # @param event [Symbol] event name
      # @yield [*args] event handler receiving event parameters
      # @return [void]
      #
      # @example Basic event pub/sub
      #   seq = Musa::Sequencer::BaseSequencer.new(4, 24)
      #
      #   received_values = []
      #
      #   # Subscribe to custom event
      #   seq.on(:note_played) do |pitch, velocity|
      #     received_values << { pitch: pitch, velocity: velocity }
      #   end
      #
      #   # Launch event from scheduled block
      #   seq.at(1) do
      #     seq.launch(:note_played, 60, 100)
      #   end
      #
      #   seq.at(2) do
      #     seq.launch(:note_played, 64, 80)
      #   end
      #
      #   seq.run
      #
      #   received_values
      #   # => [{ pitch: 60, velocity: 100 }, { pitch: 64, velocity: 80 }]
      #
      #   # The arguments of `launch` reach the handler as its block parameters,
      #   # and the handler runs where the launch happened -- at position 1, not
      #   # afterwards.
      #
      # @example Hierarchical event handling with control
      #   seq = Musa::Sequencer::BaseSequencer.new(4, 24)
      #
      #   global_events = []
      #   local_events = []
      #
      #   # Global handler (sequencer level)
      #   seq.on(:finished) do |name|
      #     global_events << name
      #   end
      #
      #   # Local handler (control level)
      #   control = seq.at(1) do |control:|
      #     control.launch(:finished, "local task")
      #   end
      #
      #   control.on(:finished) do |name|
      #     local_events << name
      #   end
      #
      #   seq.run
      #
      #   local_events   # => ["local task"]
      #   global_events  # => []
      #
      #   # The event was handled where it was launched and did not bubble up.
      #   # A handler registered inside an `at` shadows the outer one for the
      #   # duration of that block, which is how a section can answer for itself
      #   # without unregistering anything.
      def on(event, &block)
        @event_handlers.last.on event, &block
      end

      # Launches custom event.
      #
      # Publishes a custom event to registered handlers. Events bubble up through
      # the handler hierarchy if not handled locally. Supports both positional and
      # keyword parameters.
      #
      # @param event [Symbol] event name
      # @param value_parameters [Array] positional parameters
      # @param key_parameters [Hash] keyword parameters
      # @return [void]
      #
      # @see #on
      def launch(event, *value_parameters, **key_parameters)
        @event_handlers.last.launch event, *value_parameters, **key_parameters
      end

      # Schedules block relative to current position.
      #
      # Returns a control object whose `.stop` method cancels execution:
      # the block will not run if the control is stopped before its scheduled
      # position. For series-based delays, `.stop` also prevents further
      # elements from being scheduled.
      #
      # @param bars_delay [Numeric, Series, Array] delay from current position
      # @param debug [Boolean] enable debug logging
      # @yield block to execute at position + delay
      # @return [EventHandler] control object (supports .stop to cancel)
      #
      # @example Basic wait
      #   seq.wait(2) { puts "2 beats later" }
      #
      # @example Cancelling a scheduled wait
      #   h = seq.wait(4) { puts "won't run" }
      #   h.stop
      def wait(bars_delay, debug: nil, &block)
        debug ||= false

        control = EventHandler.new @event_handlers.last
        @event_handlers.push control

        if bars_delay.is_a? Numeric
          _numeric_at position + bars_delay.rationalize, control, debug: debug, skip_if_stopped: true, &block
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
      # Returns a control object whose `.stop` method cancels execution
      # if the block hasn't run yet (e.g., scheduled at current position
      # but not yet reached by the tick loop).
      #
      # @yield block to execute at current position
      # @return [EventHandler] control object (supports .stop to cancel)
      #
      # @example
      #   seq.now { puts "Executes now" }
      def now(&block)
        control = EventHandler.new @event_handlers.last
        @event_handlers.push control

        _numeric_at position, control, skip_if_stopped: true, &block

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
      # Returns a control object whose `.stop` method cancels execution:
      # the block will not run if the control is stopped before the scheduled
      # position. For series-based positions, `.stop` also prevents further
      # elements from being scheduled.
      #
      # @param bar_position [Numeric, Series, Array] absolute position(s)
      # @param debug [Boolean] enable debug logging
      # @yield block to execute at position
      # @return [EventHandler] control object (supports .stop to cancel)
      #
      # @example Single position
      #   seq.at(4) { puts "At beat 4" }
      #
      # @example Series of positions
      #   seq.at([1, 2, 3.5, 4]) { |pos| puts "At #{pos}" }
      #
      # @example Cancelling a scheduled at
      #   h = seq.at(8) { puts "won't run" }
      #   h.stop
      def at(bar_position, debug: nil, &block)
        debug ||= false

        control = EventHandler.new @event_handlers.last
        @event_handlers.push control

        if bar_position.is_a? Numeric
          _numeric_at bar_position.rationalize, control, debug: debug, skip_if_stopped: true, &block
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
      # Consumes series values sequentially, evaluating each element to determine
      # operation and scheduling continuation. Supports pause/continue,
      # nested plays, parallel plays, and event-driven continuation.
      # Timing determined by mode.
      #
      # @param serie [Series] series to play
      # @param mode [Symbol] running mode (:at, :wait, :neumalang). Defaults to :wait
      # @param parameter [Symbol, nil] duration parameter name from serie values
      # @param on_stop [Proc, nil] callback when play stops (any reason, including manual stop)
      # @param after_bars [Numeric, nil] delay for after callback
      # @param after [Proc, nil] callback after play completes naturally (NOT on manual stop)
      # @param context [Object, nil] context for neumalang processing
      # @param mode_args [Hash] additional mode-specific parameters
      # @yield block executed for each serie value (via SmartProcBinder — declare only the parameters you need)
      # @yieldparam element [Object] the current serie element (positional). When the element is a Hash,
      #   its keys are also available as keyword arguments (e.g., `|note:, duration:|`)
      # @yieldparam control [PlayControl] the play control object (keyword, optional)
      # @return [PlayControl] control object
      #
      # ## Available Running Modes
      #
      # - **:wait** (default): Elements with duration specify wait time before next element
      # - **:at**: Elements specify absolute positions via :at key
      # - **:neumalang**: Full Neumalang DSL with variables, commands, series, etc.
      #
      #
      # @example Playing notes from a series
      #   seq = Musa::Sequencer::BaseSequencer.new(4, 24)
      #
      #   notes = Musa::Series::Constructors.H(
      #     pitch: Musa::Series::Constructors.S(60, 62, 64),
      #     duration: Musa::Series::Constructors.S(1r, 1r, 2r))
      #   played_notes = []
      #
      #   seq.play(notes) do |pitch:, duration:|
      #     played_notes << { pitch: pitch, duration: duration, position: seq.position }
      #   end
      #
      #   seq.run
      #   played_notes.collect { |n| n[:pitch] }  # => [60, 62, 64]
      #
      # @example Parallel plays
      #   seq = Musa::Sequencer::BaseSequencer.new(4, 24)
      #
      #   # Simultaneous voices are simultaneous plays, one per voice: play takes
      #   # a serie, not an array of them.
      #   melody = Musa::Series::Constructors.H(
      #     pitch: Musa::Series::Constructors.S(60, 62, 64),
      #     duration: Musa::Series::Constructors.S(1r, 1r, 1r))
      #   harmony = Musa::Series::Constructors.H(
      #     pitch: Musa::Series::Constructors.S(48, 52, 55),
      #     duration: Musa::Series::Constructors.S(1r, 1r, 1r))
      #   played_notes = []
      #
      #   [melody, harmony].each do |voice|
      #     seq.play(voice) { |pitch:, duration:| played_notes << pitch }
      #   end
      #
      #   seq.run
      #   played_notes  # => [60, 48, 62, 52, 64, 55]
      def play(serie,
               mode: nil,
               parameter: nil,
               on_stop: nil,
               after_bars: nil,
               after: nil,
               context: nil,
               **mode_args,
               &block)

        mode ||= :wait

        control = PlayControl.new @event_handlers.last, on_stop: on_stop, after_bars: after_bars, after: after
        @event_handlers.push control

        _play serie.instance, control, context, mode: mode, parameter: parameter, **mode_args, &block

        @event_handlers.pop

        @playing << control

        control.on_stop do
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
      # Similar to play but serie values include timing: each element specifies its
      # own timing via `:time` attribute. Unlike regular `play` which derives timing
      # from evaluation mode, play_timed uses explicit times from series data.
      #
      # ## Timed Series Format
      #
      # Each element must have:
      #
      # - **:time**: Rational time offset from start
      # - **:value**: Actual value(s) - Hash or Array
      # - Optional extra attributes (passed to block)
      #
      # ## Value Modes
      #
      # - **Hash mode**: `{ time: 0r, value: {pitch: 60, velocity: 96} }`
      # - **Array mode**: `{ time: 0r, value: [60, 96] }`
      #
      # Mode is detected from first element and applied to entire series.
      #
      # ## Component Tracking
      #
      # Tracks last update time per component (hash key or array index) to
      # calculate `started_ago` - how long since each component changed.
      #
      # @param timed_serie [Series] timed series
      # @param at [Rational, nil] starting position
      # @param on_stop [Proc, nil] callback when playback stops
      # @param after_bars [Numeric, nil] schedule after completion
      # @param after [Proc, nil] block after completion
      # @yield block for each timed value (via SmartProcBinder — declare only the parameters you need)
      # @yieldparam values [Hash, Array] current component values (positional). Hash in hash mode, Array in array mode
      # @yieldparam time [Rational] absolute position of this event (keyword, optional)
      # @yieldparam started_ago [Hash, Array] time since each component's last update (keyword, optional)
      # @yieldparam control [PlayTimedControl] the play_timed control object (keyword, optional)
      # @return [PlayTimedControl] control object
      #
      # @example Hash mode timed series
      #   seq = Musa::Sequencer::BaseSequencer.new(4, 24)
      #
      #   timed_notes = Musa::Series::Constructors.S(
      #     { time: 0r, value: {pitch: 60, velocity: 96} },
      #     { time: 1r, value: {pitch: 64, velocity: 80} },
      #     { time: 2r, value: {pitch: 67, velocity: 64} }
      #   )
      #
      #   played_notes = []
      #
      #   seq.play_timed(timed_notes) do |values, time:, started_ago:, control:|
      #     played_notes << { pitch: values[:pitch], velocity: values[:velocity], time: time }
      #   end
      #
      #   seq.run
      #
      #   played_notes
      #   # => [{ pitch: 60, velocity: 96, time: (95/96) },
      #   #     { pitch: 64, velocity: 80, time: (191/96) },
      #   #     { pitch: 67, velocity: 64, time: (287/96) }]
      #   #
      #   # NOTE the yielded `time:` is the sequencer's ABSOLUTE POSITION when the
      #   # event fires, not the `time:` of the serie's element. The sequencer sits
      #   # one tick before bar 1 until it starts (95/96 of a bar, with 24 ticks per
      #   # beat and 4 beats per bar), so that its first tick lands exactly on bar 1;
      #   # the element at serie time 0 fires there. The intervals do match the
      #   # serie: each following event is exactly one bar later.
      #
      # @example Array mode with extra attributes
      #   seq = Musa::Sequencer::BaseSequencer.new(4, 24)
      #
      #   timed = Musa::Series::Constructors.S(
      #     { time: 0r, value: [60, 96], channel: 0 },
      #     { time: 1r, value: [64, 80], channel: 1 }
      #   )
      #
      #   played_notes = []
      #
      #   seq.play_timed(timed) do |values, channel:, time:, started_ago:, control:|
      #     played_notes << { pitch: values[0], velocity: values[1], channel: channel, time: time }
      #   end
      #
      #   seq.run
      #
      #   played_notes
      #   # => [{ pitch: 60, velocity: 96, channel: [0, 0], time: (95/96) },
      #   #     { pitch: 64, velocity: 80, channel: [1, 0], time: (191/96) }]
      #
      #   # `channel: 0` arrives as `[0, 0]`, not as 0: in array mode every
      #   # attribute is brought to the arity of `value`, and a scalar is
      #   # repeated across it. Written as `channel: [0]` it arrives as
      #   # `[0, nil]` instead -- padded, not repeated. Either way the block
      #   # receives an array, and reading it as a number is the mistake this
      #   # example used to invite.

      def play_timed(timed_serie,
                     at: nil,
                     on_stop: nil,
                     after_bars: nil, after: nil,
                     &block)

        at ||= position

        control = PlayTimedControl.new(@event_handlers.last,
                                       on_stop: on_stop, after_bars: after_bars, after: after)

        @event_handlers.push control

        _play_timed(timed_serie.instance, at, control, &block)

        @event_handlers.pop

        @playing << control

        control.on_stop do
          @playing.delete control
        end

        control
      end

      # Executes block repeatedly at regular intervals.
      #
      # ## Execution Model
      #
      # Every loop schedules itself recursively:
      # 1. Execute block at current position
      # 2. Check stopping conditions
      # 3. If not stopped, schedule next iteration at start + counter * interval
      # 4. If stopped, call on_stop and after callbacks
      #
      # This ensures precise timing - iterations are scheduled relative to start
      # position, not accumulated from previous iteration (avoiding drift).
      #
      # ## Stopping Conditions
      #
      # Loop stops when any of these conditions is met:
      #
      # - **manual stop**: `control.stop` called
      # - **duration**: elapsed time >= duration (in bars)
      # - **till**: current position >= till position
      # - **condition**: condition block returns false
      # - **nil interval**: immediate stop after first execution
      #
      # ## Block Parameters (via SmartProcBinder)
      #
      # The block receives the following keyword parameter via SmartProcBinder.
      # You can declare only the parameters you need — undeclared ones are silently ignored.
      #
      # - **control:** [EveryControl] — the control object for the current loop
      #
      # @param interval [Numeric, nil] interval between executions (nil = once)
      # @param duration [Numeric, nil] total duration
      # @param till [Numeric, nil] end position
      # @param condition [Proc, nil] continue while condition true
      # @param on_stop [Proc, nil] callback when loop stops
      # @param after_bars [Numeric, nil] schedule after completion
      # @param after [Proc, nil] block after completion
      # @yieldparam control [EveryControl] the loop's control object (keyword, optional)
      # @return [EveryControl] control object
      #
      # @example No parameters needed
      #   seq.every(1, till: 8) { puts "Beat at #{seq.position}" }
      #
      # @example Accessing the control object (keyword argument)
      #   seq.every(1r, duration: 4r) do |control:|
      #     puts "Iteration #{control._execution_counter}"
      #   end
      #
      # @example Conditional loop
      #   seq = Musa::Sequencer::BaseSequencer.new(4, 24)
      #   count = 0
      #   positions = []
      #
      #   seq.every(1r, condition: proc { count < 3 }) do
      #     count += 1
      #     positions << seq.position
      #   end
      #   seq.at(10) { }   # keeps the run going past the loop
      #   seq.run
      #
      #   positions  # => [(95/96), (191/96), (287/96)]
      #   count      # => 3
      #
      #   # The condition is asked BEFORE each pulse, so it guards the one that
      #   # has not happened yet: three pulses for `count < 3`, not four.
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

        control.on_stop do
          @everying.delete control
        end

        control
      end

      # Animates value from start to end over time. 
      # Supports single values, arrays, and hashes
      # with flexible parameter combinations for controlling timing and interpolation.
      #
      # ## Value Modes
      #
      # - **Single value**: `from: 0, to: 100`
      # - **Array**: `from: [60, 0.5], to: [72, 1.0]` - multiple values
      # - **Hash**: `from: {pitch: 60}, to: {pitch: 72}` - named values
      #
      # ## Parameter Combinations
      #
      # Move requires enough information to calculate both step size and iteration
      # interval. Valid combinations:
      #
      # - `from, to, step, every` - All explicit
      # - `from, to, step, duration/till` - Calculates every from steps needed
      # - `from, to, every, duration/till` - Calculates step from duration
      # - `from, step, every, duration/till` - Open-ended with time limit
      #
      # ## Interpolation
      #
      # - **Linear** (default): `function: proc { |ratio| ratio }`
      # - **Ease-in**: `function: proc { |ratio| ratio ** 2 }`
      # - **Ease-out**: `function: proc { |ratio| 1 - (1 - ratio) ** 2 }`
      # - **Custom**: Any proc mapping [0..1] to [0..1]
      #
      # ## Applications
      #
      # - Pitch bends and glissandi
      # - Volume fades and swells
      # - Filter sweeps and modulation
      # - Tempo changes and rubato
      # - Multi-parameter automation
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
      # @yield block executed with interpolated value (via SmartProcBinder — declare only the parameters you need)
      # @yieldparam value [Numeric, Array, Hash] current interpolated value(s) (positional)
      # @yieldparam next_value [Numeric, Array, Hash, nil] next interpolated value(s), nil at end (positional)
      # @yieldparam control [MoveControl] the move control object (keyword, optional)
      # @yieldparam duration [Numeric, Array, Hash] interval duration per component (keyword, optional)
      # @yieldparam quantized_duration [Numeric, Array, Hash] quantized interval duration (keyword, optional)
      # @yieldparam started_ago [Numeric, Array, Hash, nil] time since component last changed (keyword, optional)
      # @yieldparam position_jitter [Numeric, Array, Hash] position rounding error (keyword, optional)
      # @yieldparam duration_jitter [Numeric, Array, Hash] duration rounding error (keyword, optional)
      # @yieldparam right_open [Boolean, Array, Hash] whether final value is excluded (keyword, optional)
      # @return [MoveControl] control object
      #
      # @example Simple pitch glide
      #   seq = Musa::Sequencer::BaseSequencer.new(4, 24)
      #
      #   pitch_values = []
      #
      #   seq.move(from: 60, to: 72, duration: 4r, every: 1/4r) do |pitch|
      #     pitch_values << { pitch: pitch.round, position: seq.position }
      #   end
      #
      #   seq.run
      #
      #   pitch_values.size          # => 16
      #   pitch_values.first(3)
      #   # => [{ pitch: 60, position: (95/96) },
      #   #     { pitch: 61, position: (119/96) },
      #   #     { pitch: 62, position: (143/96) }]
      #   pitch_values.last          # => { pitch: 72, position: (455/96) }
      #
      #   # Sixteen steps and not seventeen: `duration: 4r` at `every: 1/4r` is
      #   # 16 intervals, and the last one lands ON 72 -- the arrival is a step,
      #   # not an extra one after the last.
      #
      # @example Multi-parameter fade
      #   seq = Musa::Sequencer::BaseSequencer.new(4, 24)
      #
      #   controller_values = []
      #
      #   seq.move(
      #     from: {volume: 0, brightness: 0},
      #     to: {volume: 127, brightness: 127},
      #     duration: 8r,
      #     every: 1/8r
      #   ) do |params|
      #     controller_values << {
      #       volume: params[:volume].round,
      #       brightness: params[:brightness].round,
      #       position: seq.position
      #     }
      #   end
      #
      #   seq.run
      #
      #   controller_values.size   # => 64
      #   controller_values.first  # => { volume: 0, brightness: 0, position: (95/96) }
      #   controller_values.last   # => { volume: 127, brightness: 127, position: (851/96) }
      #
      #   # Both parameters are interpolated from the same ratio, so they arrive
      #   # together whatever their ranges.
      #
      # @example Non-linear interpolation
      #   seq = BaseSequencer.new(4, 24)
      #   values = []
      #
      #   seq.move(
      #     from: 0, to: 100,
      #     duration: 4r, every: 1/16r,
      #     function: proc { |ratio| ratio ** 2 }  # Ease-in
      #   ) { |value| values << value }
      #   seq.run
      #
      #   values.first(4)                 # => [(0/1), (100/3969), (400/3969), (100/441)]
      #   values[values.size / 2].to_f    # => 25.79994960947342
      #   values.last                     # => (100/1)
      #
      #   # Halfway through it is at 25.8 of 100, not at 50: that is what the
      #   # ease-in buys. The function reshapes the ratio, not the endpoints --
      #   # it still starts at `from` and arrives at `to`. And the values stay
      #   # rational all the way: 100/3969 rather than 0.0252.
      #
      # @example Linear fade (only positional value needed)
      #   seq = Musa::Sequencer::BaseSequencer.new(4, 24)
      #
      #   volume_values = []
      #
      #   seq.move(every: 1/4r, from: 0, to: 127, duration: 4) do |value|
      #     volume_values << value.round
      #   end
      #
      #   seq.run
      #
      #   volume_values.size      # => 16
      #   volume_values.first(4)  # => [0, 8, 17, 25]
      #   volume_values.last      # => 127
      #
      #   # The step is 127/15 and not 8: sixteen values means fifteen intervals
      #   # between the endpoints, so it climbs 8, 9, 8, 9... rather than by a
      #   # round number. `.round` is what makes that visible.
      #
      # @example Using keyword parameters
      #   seq.move(from: 60, to: 72, duration: 4r, every: 1/4r) do |value, next_value, control:, duration:|
      #     puts "value=#{value.round} next=#{next_value&.round} dur=#{duration}"
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

        control.on_stop do
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

