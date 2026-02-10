require 'forwardable'

require_relative '../core-ext/with'

module Musa
  module Sequencer
    # High-level DSL wrapper for BaseSequencer.
    #
    # Provides user-friendly interface with block context management via
    # `with` method. Wraps BaseSequencer methods to automatically evaluate
    # blocks in DSL context, enabling clean musical composition code.
    #
    # ## DSL Context
    #
    # Blocks passed to scheduling methods (now, at, wait, play, every, move)
    # are evaluated in DSL context via `with`, providing access to sequencer
    # methods and allowing for cleaner composition syntax.
    #
    # ## Delegation
    #
    # Delegates most methods to either BaseSequencer or DSLContext:
    #
    # - Timing: beats_per_bar, ticks_per_beat, position, tick, reset
    # - Scheduling: now, at, wait, play, play_timed, every, move
    # - Events: launch, on
    # - Inspection: size, empty?, everying, playing, moving
    #
    # ## Musical Applications
    #
    # Provides composer-friendly API for:
    #
    # - Musical composition scripts
    # - Interactive sequencing
    # - Live coding
    # - Algorithmic composition
    #
    # @example Basic DSL usage
    #   sequencer = Musa::Sequencer::Sequencer.new(4, 96) do
    #     at(1r) { puts "Bar 1" }
    #     at(2r) { puts "Bar 2" }
    #
    #     every(1r, duration: 4r) do
    #       puts "Every beat"
    #     end
    #   end
    #
    #   sequencer.run
    #
    # @example DSL context access
    #   sequencer = Musa::Sequencer::Sequencer.new(4, 96) do
    #     at(1r) do
    #       puts "Position: #{position}"  # DSL context method
    #
    #       wait(1r) { puts "One bar later" }  # Nested scheduling
    #     end
    #   end
    #
    # @api public
    class Sequencer
      extend Forwardable

      # @!method beats_per_bar
      #   Returns beats per bar (time signature numerator).
      #
      #   Delegated from {BaseSequencer#beats_per_bar}.
      #
      #   @return [Integer, nil] beats per bar, or nil for tickless mode

      # @!method ticks_per_beat
      #   Returns ticks per beat (timing resolution).
      #
      #   Delegated from {BaseSequencer#ticks_per_beat}.
      #
      #   @return [Integer, nil] ticks per beat, or nil for tickless mode

      # @!method ticks_per_bar
      #   Returns total ticks per bar.
      #
      #   Delegated from BaseSequencer#ticks_per_bar.
      #
      #   @return [Integer, nil] ticks per bar, or nil for tickless mode

      # @!method tick_duration
      #   Returns duration of a single tick.
      #
      #   Delegated from BaseSequencer#tick_duration.
      #
      #   @return [Rational, nil] tick duration in bars, or nil for tickless mode

      # @!method offset
      #   Returns the sequencer's starting position offset.
      #
      #   Delegated from {BaseSequencer#offset}.
      #
      #   @return [Rational, nil] position offset

      # @!method size
      #   Returns number of scheduled events.
      #
      #   Delegated from {BaseSequencer#size}.
      #
      #   @return [Integer] count of pending events

      # @!method empty?
      #   Checks if sequencer has no scheduled events.
      #
      #   Delegated from {BaseSequencer#empty?}.
      #
      #   @return [Boolean] true if no events scheduled

      # @!method on_debug_at
      #   Registers debug handler for specific position.
      #
      #   Delegated from {BaseSequencer#on_debug_at}.
      #
      #   @yield block to execute when position is reached in debug mode

      # @!method on_error
      #   Registers error handler for sequencer errors.
      #
      #   Delegated from {BaseSequencer#on_error}.
      #
      #   @yield [Exception] block to handle errors

      # @!method on_fast_forward
      #   Registers handler called during fast-forward operations.
      #
      #   Delegated from {BaseSequencer#on_fast_forward}.
      #
      #   @yield block executed during fast-forward

      # @!method before_tick
      #   Registers handler called before each tick.
      #
      #   Delegated from {BaseSequencer#before_tick}.
      #
      #   @yield block executed before tick processing

      # @!method raw_at(position, &block)
      #   Schedules block at position without DSL context wrapping.
      #
      #   Delegated from {BaseSequencer#raw_at}.
      #
      #   @param position [Numeric, Rational] bar position
      #   @yield block to execute at position

      # @!method tick
      #   Advances sequencer by one tick and processes events.
      #
      #   Delegated from BaseSequencer#tick.
      #
      #   @return [void]

      # @!method reset
      #   Resets sequencer to initial state.
      #
      #   Delegated from {BaseSequencer#reset}.
      #
      #   @return [void]

      # @!method position=(value)
      #   Sets the current sequencer position.
      #
      #   Delegated from BaseSequencer#position=.
      #
      #   @param value [Numeric, Rational] new position in bars
      #   @return [void]

      # @!method event_handler
      #   Returns the event handler for launch/on events.
      #
      #   Delegated from {BaseSequencer#event_handler}.
      #
      #   @return [EventHandler] event handler instance
      def_delegators :@sequencer,
                     :beats_per_bar, :ticks_per_beat, :ticks_per_bar, :tick_duration,
                     :offset,
                     :size, :empty?,
                     :on_debug_at, :on_error, :on_fast_forward, :before_tick,
                     :raw_at,
                     :tick,
                     :reset,
                     :position=,
                     :event_handler

      # @!method position
      #   Returns current sequencer position in bars.
      #
      #   Delegated from {DSLContext#position}.
      #
      #   @return [Rational] current position

      # @!method quantize_position(reference, step, offset: nil)
      #   Quantizes a position to a grid.
      #
      #   Delegated from {DSLContext#quantize_position}.
      #
      #   @param reference [Numeric, Rational] reference position
      #   @param step [Numeric, Rational] grid step size
      #   @param offset [Numeric, Rational, nil] grid offset
      #   @return [Rational] quantized position

      # @!method logger
      #   Returns the sequencer's logger instance.
      #
      #   Delegated from {DSLContext#logger}.
      #
      #   @return [Logger, nil] logger instance

      # @!method debug
      #   Returns or enables debug mode.
      #
      #   Delegated from {DSLContext#debug}.
      #
      #   @return [Boolean] debug mode status

      # @!method now(*value_parameters, **key_parameters, &block)
      #   Executes block immediately at current position.
      #
      #   Delegated from {DSLContext#now}.
      #
      #   @param value_parameters [Array] parameters to pass to block
      #   @param key_parameters [Hash] keyword parameters
      #   @yield block to execute now
      #   @return [void]

      # @!method at(position, *value_parameters, **key_parameters, &block)
      #   Schedules block to execute at specified position.
      #
      #   Delegated from {DSLContext#at}.
      #
      #   @param position [Numeric, Rational] bar position
      #   @param value_parameters [Array] parameters to pass to block
      #   @param key_parameters [Hash] keyword parameters
      #   @yield block to execute at position
      #   @return [void]

      # @!method wait(duration, *value_parameters, **key_parameters, &block)
      #   Schedules block after waiting specified duration.
      #
      #   Delegated from {DSLContext#wait}.
      #
      #   @param duration [Numeric, Rational] wait duration in bars
      #   @param value_parameters [Array] parameters to pass to block
      #   @param key_parameters [Hash] keyword parameters
      #   @yield block to execute after wait
      #   @return [void]

      # @!method play(serie, decoder: nil, mode: nil, **options, &block)
      #   Plays a series using the decoder.
      #
      #   Delegated from {DSLContext#play}.
      #
      #   @param serie [Serie] series to play
      #   @param decoder [Object, nil] decoder for series elements
      #   @param mode [Symbol, nil] playback mode (:neumalang, etc.)
      #   @param options [Hash] additional play options
      #   @yield [element] block to process each element
      #   @return [PlayControl] control object for the playing series

      # @!method play_timed(timed_serie, **options, &block)
      #   Plays a timed series with explicit timing.
      #
      #   Delegated from {DSLContext#play_timed}.
      #
      #   @param timed_serie [Serie] timed series to play
      #   @param options [Hash] play options
      #   @yield [element, duration] block to process elements
      #   @return [PlayControl] control object

      # @!method every(interval, duration: nil, till: nil, **options, &block)
      #   Executes block repeatedly at interval.
      #
      #   Delegated from {DSLContext#every}.
      #
      #   @param interval [Numeric, Rational] repetition interval in bars
      #   @param duration [Numeric, Rational, nil] total duration
      #   @param till [Numeric, Rational, nil] end position
      #   @param options [Hash] additional options
      #   @yield block to execute each interval
      #   @return [EveryControl] control object

      # @!method move(from: nil, to: nil, duration: nil, step: nil, **options, &block)
      #   Interpolates values over time.
      #
      #   Delegated from {DSLContext#move}.
      #
      #   @param from [Numeric, nil] starting value
      #   @param to [Numeric, nil] ending value
      #   @param duration [Numeric, Rational, nil] interpolation duration
      #   @param step [Numeric, Rational, nil] time step
      #   @param options [Hash] additional options
      #   @yield [value] block receiving interpolated values
      #   @return [MoveControl] control object

      # @!method everying
      #   Returns control for active every loops.
      #
      #   Delegated from {DSLContext#everying}.
      #
      #   @return [EveryingControl] control for active loops

      # @!method playing
      #   Returns control for active play operations.
      #
      #   Delegated from {DSLContext#playing}.
      #
      #   @return [PlayingControl] control for active plays

      # @!method moving
      #   Returns control for active move interpolations.
      #
      #   Delegated from {DSLContext#moving}.
      #
      #   @return [MovingControl] control for active moves

      # @!method launch(event_name, *parameters, **key_parameters)
      #   Triggers an event by name.
      #
      #   Delegated from {DSLContext#launch}.
      #
      #   @param event_name [Symbol] event identifier
      #   @param parameters [Array] event parameters
      #   @param key_parameters [Hash] event keyword parameters
      #   @return [void]

      # @!method on(event_name, &block)
      #   Registers handler for named event.
      #
      #   Delegated from {DSLContext#on}.
      #
      #   @param event_name [Symbol] event identifier
      #   @yield block to execute when event fires
      #   @return [void]

      # @!method run
      #   Runs the sequencer until all events complete.
      #
      #   Delegated from {DSLContext#run}.
      #
      #   @return [void]
      def_delegators :@dsl, :position, :quantize_position, :logger, :debug
      def_delegators :@dsl, :now, :at, :wait, :play, :play_timed, :every, :move
      def_delegators :@dsl, :everying, :playing, :moving
      def_delegators :@dsl, :launch, :on
      def_delegators :@dsl, :run

      # Creates sequencer with optional initialization block.
      #
      # @param beats_per_bar [Integer, nil] beats per bar (tick-based mode)
      # @param ticks_per_beat [Integer, nil] ticks per beat (tick-based mode)
      # @param offset [Rational, nil] starting position offset
      # @param sequencer [BaseSequencer, nil] use existing sequencer
      # @param logger [Logger, nil] logger instance
      # @param do_log [Boolean, nil] enable logging
      # @param do_error_log [Boolean, nil] enable error logging
      # @param log_position_format [Symbol, nil] position format for logs
      # @param dsl_context_class [Class, nil] custom DSL context class
      # @param keep_block_context [Boolean, nil] preserve block's original binding
      # @yield initialization block evaluated in DSL context
      #
      # @example Tick-based sequencer
      #   seq = Sequencer.new(4, 96) do
      #     at(1r) { puts "Start" }
      #   end
      #
      # @example Tickless sequencer
      #   seq = Sequencer.new do
      #     at(1r) { puts "Start" }
      #   end
      #
      # @api public
      def initialize(beats_per_bar = nil,
                     ticks_per_beat = nil,
                     offset: nil,
                     sequencer: nil,
                     logger: nil,
                     do_log: nil, do_error_log: nil, log_position_format: nil,
                     dsl_context_class: nil,
                     keep_block_context: nil,
                     &block)

        @sequencer = sequencer
        @sequencer ||= BaseSequencer.new beats_per_bar, ticks_per_beat,
                                         offset: offset,
                                         logger: logger,
                                         do_log: do_log,
                                         do_error_log: do_error_log,
                                         log_position_format: log_position_format

        dsl_context_class ||= DSLContext

        @dsl = dsl_context_class.new @sequencer, keep_block_context: keep_block_context

        @dsl.with &block if block_given?
      end

      # Evaluates block in DSL context.
      #
      # Provides `with` method for evaluating blocks with DSL context access.
      # The block is executed in the DSL context, giving it direct access to
      # sequencer methods like at, wait, play, every, move without needing to
      # reference the sequencer object.
      #
      # @param value_parameters [Array] positional parameters
      # @param key_parameters [Hash] keyword parameters
      # @yield block to evaluate in DSL context
      #
      # @return [Object] block return value
      #
      # @example Evaluating blocks in DSL context
      #   seq = Musa::Sequencer::Sequencer.new(4, 96)
      #
      #   executed = []
      #
      #   # Use 'with' to evaluate block in DSL context
      #   seq.with do
      #     # Inside this block, we have direct access to DSL methods
      #     at(1) { executed << "bar 1" }
      #     at(2) { executed << "bar 2" }
      #
      #     every(1, duration: 4) do
      #       executed << "beat at #{position}"
      #     end
      #   end
      #
      #   seq.run
      #
      #   # executed contains ["bar 1", "beat at 1", "bar 2", "beat at 2", ...]
      #
      # @example Passing parameters to with block
      #   seq = Musa::Sequencer::Sequencer.new(4, 96)
      #
      #   notes = []
      #
      #   seq.with(60, 64, 67) do |c, e, g|
      #     at(1) { notes << c }  # Uses parameter c = 60
      #     at(2) { notes << e }  # Uses parameter e = 64
      #     at(3) { notes << g }  # Uses parameter g = 67
      #   end
      #
      #   seq.run
      #
      #   # notes contains [60, 64, 67]
      #
      # @example Comparison: with DSL context vs external context
      #   seq = Musa::Sequencer::Sequencer.new(4, 96)
      #
      #   # Without 'with': need to reference seq explicitly
      #   seq.at(1) { seq.at(2) { puts "nested" } }
      #
      #   # With 'with': DSL methods available directly
      #   seq.with do
      #     at(1) { at(2) { puts "nested" } }  # Cleaner syntax
      #   end
      #
      # @api public
      def with(*value_parameters, **key_parameters, &block)
        @dsl.with(*value_parameters, **key_parameters, &block)
      end

      # DSL context providing block evaluation with sequencer method access.
      #
      # Wraps BaseSequencer methods to evaluate user blocks in controlled
      # context via `with`. Enables clean DSL syntax by providing direct
      # access to sequencer methods within block scopes.
      #
      # ## Block Context Modes
      #
      # - **keep_block_context: false** (default): Evaluate blocks in DSL context
      # - **keep_block_context: true**: Preserve block's original binding
      #
      class DSLContext
        extend Forwardable
        include Musa::Extension::With

        # @return [BaseSequencer] underlying sequencer
        attr_reader :sequencer

        # @!method launch(event_name, *parameters, **key_parameters)
        #   Triggers an event by name.
        #
        #   Delegated from {BaseSequencer#launch}.
        #
        #   @param event_name [Symbol] event identifier
        #   @param parameters [Array] event parameters
        #   @param key_parameters [Hash] event keyword parameters
        #   @return [void]

        # @!method on(event_name, &block)
        #   Registers handler for named event.
        #
        #   Delegated from {BaseSequencer#on}.
        #
        #   @param event_name [Symbol] event identifier
        #   @yield block to execute when event fires
        #   @return [void]

        # @!method position
        #   Returns current sequencer position in bars.
        #
        #   Delegated from BaseSequencer#position.
        #
        #   @return [Rational] current position

        # @!method quantize_position(reference, step, offset: nil)
        #   Quantizes a position to a grid.
        #
        #   Delegated from {BaseSequencer#quantize_position}.
        #
        #   @param reference [Numeric, Rational] reference position
        #   @param step [Numeric, Rational] grid step size
        #   @param offset [Numeric, Rational, nil] grid offset
        #   @return [Rational] quantized position

        # @!method size
        #   Returns number of scheduled events.
        #
        #   Delegated from {BaseSequencer#size}.
        #
        #   @return [Integer] count of pending events

        # @!method everying
        #   Returns control for active every loops.
        #
        #   Delegated from {BaseSequencer#everying}.
        #
        #   @return [EveryingControl] control for active loops

        # @!method playing
        #   Returns control for active play operations.
        #
        #   Delegated from {BaseSequencer#playing}.
        #
        #   @return [PlayingControl] control for active plays

        # @!method moving
        #   Returns control for active move interpolations.
        #
        #   Delegated from {BaseSequencer#moving}.
        #
        #   @return [MovingControl] control for active moves

        # @!method ticks_per_bar
        #   Returns total ticks per bar.
        #
        #   Delegated from BaseSequencer#ticks_per_bar.
        #
        #   @return [Integer, nil] ticks per bar, or nil for tickless mode

        # @!method logger
        #   Returns the sequencer's logger instance.
        #
        #   Delegated from {BaseSequencer#logger}.
        #
        #   @return [Logger, nil] logger instance

        # @!method debug
        #   Returns or enables debug mode.
        #
        #   Delegated from {BaseSequencer#debug}.
        #
        #   @return [Boolean] debug mode status

        # @!method inspect
        #   Returns string representation of the context.
        #
        #   Delegated from BaseSequencer#inspect.
        #
        #   @return [String] inspection string

        # @!method run
        #   Runs the sequencer until all events complete.
        #
        #   Delegated from {BaseSequencer#run}.
        #
        #   @return [void]
        def_delegators :@sequencer,
                       :launch, :on,
                       :position, :quantize_position,
                       :size,
                       :everying, :playing, :moving,
                       :ticks_per_bar, :logger, :debug, :inspect,
                       :run

        # @api private
        def initialize(sequencer, keep_block_context:)
          @sequencer = sequencer
          @keep_block_context_on_with = keep_block_context
        end

        # Schedules block at current position via DSL context.
        #
        # Wraps BaseSequencer#now, evaluating block in DSL context.
        #
        # @param value_parameters [Array] parameters to pass to block
        # @param key_parameters [Hash] keyword parameters
        # @yield block to execute at current position
        # @return [void]
        def now(*value_parameters, **key_parameters, &block)
          block ||= proc {}

          @sequencer.now *value_parameters, **key_parameters do |*value_args, **key_args|
            with *value_args, **key_args, keep_block_context: @keep_block_context_on_with, &block
          end
        end

        # Schedules block at absolute position via DSL context.
        #
        # Wraps BaseSequencer#at, evaluating block in DSL context.
        #
        # @param value_parameters [Array] parameters (first is position)
        # @param key_parameters [Hash] keyword parameters
        # @yield block to execute at position
        # @return [void]
        def at(*value_parameters, **key_parameters, &block)
          block ||= proc {}

          @sequencer.at *value_parameters, **key_parameters do |*value_args, **key_args|
            with *value_args, **key_args, keep_block_context: @keep_block_context_on_with, &block
          end
        end

        # Schedules block after wait duration via DSL context.
        #
        # Wraps BaseSequencer#wait, evaluating block in DSL context.
        #
        # @param value_parameters [Array] parameters (first is duration)
        # @param key_parameters [Hash] keyword parameters
        # @yield block to execute after wait
        # @return [void]
        def wait(*value_parameters, **key_parameters, &block)
          block ||= proc {}
          @sequencer.wait *value_parameters, **key_parameters do |*values, **key_values|
            with *values, **key_values, keep_block_context: @keep_block_context_on_with, &block
          end
        end

        # Plays series via DSL context.
        #
        # Wraps BaseSequencer#play, evaluating block in DSL context.
        #
        # @param value_parameters [Array] parameters (series, etc.)
        # @param key_parameters [Hash] keyword parameters (on_stop:, after:, after_bars:, mode:, etc.)
        # @yield block to execute for each element
        # @return [PlayControl] control object
        #
        # @see BaseSequencer#play for full parameter documentation
        # @note on_stop: fires on any termination; after: fires only on natural termination (NOT on manual .stop)
        def play(*value_parameters, **key_parameters, &block)
          block ||= proc {}

          @sequencer.play *value_parameters, **key_parameters do |*value_args, **key_args|
            with *value_args, **key_args, keep_block_context: @keep_block_context_on_with, &block
          end
        end

        # Plays timed series via DSL context.
        #
        # Wraps BaseSequencer#play_timed, evaluating block in DSL context.
        #
        # @param value_parameters [Array] parameters (timed series, etc.)
        # @param key_parameters [Hash] keyword parameters (on_stop:, after:, after_bars:, at:)
        # @yield block to execute for each element
        # @return [PlayTimedControl] control object
        #
        # @see BaseSequencer#play_timed for full parameter documentation
        # @note on_stop: fires on any termination; after: fires only on natural termination (NOT on manual .stop)
        def play_timed(*value_parameters, **key_parameters, &block)
          block ||= proc {}

          @sequencer.play_timed *value_parameters, **key_parameters do |*value_args, **key_args|
            with *value_args, **key_args, keep_block_context: @keep_block_context_on_with, &block
          end
        end

        # Repeats block at intervals via DSL context.
        #
        # Wraps BaseSequencer#every, evaluating block in DSL context.
        # Uses SmartProcBinder to apply parameters before with.
        #
        # @param value_parameters [Array] parameters (interval, etc.)
        # @param key_parameters [Hash] keyword parameters (duration:, till:, condition:, on_stop:, after:, after_bars:)
        # @yield block to execute each iteration
        # @return [EveryControl] control object
        #
        # @see BaseSequencer#every for full parameter documentation
        # @note on_stop: fires on any termination; after: fires only on natural termination (NOT on manual .stop)
        def every(*value_parameters, **key_parameters, &block)
          block ||= proc {}

          @sequencer.every *value_parameters, **key_parameters do |*value_args, **key_args|
            args = Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)._apply(value_args, key_args)
            with *args.first, **args.last, keep_block_context: @keep_block_context_on_with, &block
          end
        end

        # Animates values over time via DSL context.
        #
        # Wraps BaseSequencer#move, evaluating block in DSL context.
        #
        # @param value_parameters [Array] parameters (from, to, etc.)
        # @param key_parameters [Hash] keyword parameters (every:, from:, to:, step:, duration:, till:, on_stop:, after:, after_bars:, etc.)
        # @yield block to execute each iteration with current value
        # @return [MoveControl] control object
        #
        # @see BaseSequencer#move for full parameter documentation
        # @note on_stop: fires on any termination; after: fires only on natural termination (NOT on manual .stop)
        def move(*value_parameters, **key_parameters, &block)
          block ||= proc {}

          @sequencer.move *value_parameters, **key_parameters do |*value_args, **key_args|
            with *value_args, **key_args, keep_block_context: @keep_block_context_on_with, &block
          end
        end
      end
    end
  end
end

