require_relative '../core-ext/smart-proc-binder'
require_relative '../core-ext/inspect-nice'
require_relative '../sequencer'

module Musa
  # Transport system connecting clocks to sequencers.
  #
  # The Transport module provides the infrastructure for managing musical playback,
  # connecting timing sources (clocks) to the sequencer that executes musical events.
  #
  # @see Transport Main transport class
  # @see Clock Clock implementations
  # @see Sequencer Event scheduling
  module Transport
    # Main transport class connecting clocks to sequencers with lifecycle management.
    #
    # Transport acts as the bridge between a clock (timing source) and a sequencer
    # (event scheduler). It manages the playback lifecycle, including initialization,
    # start/stop, and position changes, with support for callbacks at each stage.
    #
    # ## Architecture
    #
    #     Clock --ticks--> Transport --tick()--> Sequencer --events--> Music
    #
    # ## Lifecycle Phases
    #
    # 1. **before_begin**: Run once before first start (initialization)
    # 2. **on_start**: Run each time transport starts
    # 3. **Running**: Clock generates ticks → sequencer processes events
    # 4. **on_position_change**: Run when position jumps/seeks
    # 5. **after_stop**: Run when transport stops
    #
    # ## Position Management
    #
    # Transport handles three position formats:
    #
    # - **bars**: Musical position in bars (Rational)
    # - **beats**: Position in beats
    # - **midi_beats**: Position in MIDI beats (for MIDI Clock sync)
    #
    # ## Use Cases
    #
    # - Standalone compositions with internal timing
    # - DAW-synchronized playback via MIDI Clock
    # - Testing with dummy/external clocks
    # - Live coding with dynamic tempo changes
    #
    # @example Basic setup with TimerClock
    #   clock = Musa::Clock::TimerClock.new(bpm: 120)
    #   transport = Musa::Transport::Transport.new(
    #     clock,
    #     beats_per_bar: 4,
    #     ticks_per_beat: 24
    #   )
    #
    #   # Schedule events
    #   transport.sequencer.at 0 { puts "Start!" }
    #   transport.sequencer.at 4 { puts "Bar 4" }
    #
    #   transport.start
    #
    # @example With lifecycle callbacks
    #   transport = Transport.new(clock) do |t|
    #     t.before_begin { puts "Initializing..." }
    #     t.on_start { puts "Started!" }
    #     t.after_stop { puts "Stopped, cleaning up..." }
    #   end
    #
    # @example MIDI Clock synchronization
    #   midi_input = MIDICommunications::Input.all.first
    #   clock = Musa::Clock::InputMidiClock.new(midi_input)
    #   transport = Transport.new(clock)
    #   transport.start  # Waits for MIDI Clock Start
    #
    # @see Clock::TimerClock Internal timer-based clock
    # @see Clock::InputMidiClock MIDI Clock synchronized
    # @see Sequencer Event scheduling
    class Transport
      using Musa::Extension::InspectNice

      # The sequencer instance managing event scheduling.
      #
      # @return [Sequencer::Sequencer] the sequencer
      attr_reader :sequencer

      # Creates a new transport connecting a clock to a sequencer.
      #
      # @param clock [Clock] timing source (TimerClock, InputMidiClock, etc.)
      # @param beats_per_bar [Integer, nil] time signature numerator (default: 4)
      # @param ticks_per_beat [Integer, nil] timing resolution (default: 24)
      # @param offset [Rational, nil] time offset in bars (default: 0)
      # @param sequencer [Sequencer, nil] existing sequencer (creates new if nil)
      # @param before_begin [Proc, nil] callback run once before first start
      # @param on_start [Proc, nil] callback run each time transport starts
      # @param after_stop [Proc, nil] callback run when transport stops
      # @param on_position_change [Proc, nil] callback for position changes
      # @param logger [Logger, nil] logger instance
      # @param do_log [Boolean, nil] enable logging
      #
      # @example With callback parameters
      #   Transport.new(clock, 4, 24,
      #     on_start: -> (seq) { puts "Started at #{seq.position}" }
      #   )
      #
      # @example With callback methods
      #   transport = Transport.new(clock, 4, 24)
      #   transport.before_begin { setup_instruments }
      #   transport.on_start { start_recording }
      #   transport.after_stop { save_recording }
      def initialize(clock,
                     beats_per_bar = nil,
                     ticks_per_beat = nil,
                     offset: nil,
                     sequencer: nil,
                     before_begin: nil,
                     on_start: nil,
                     after_stop: nil,
                     on_position_change: nil,
                     logger: nil,
                     do_log: nil)

        beats_per_bar ||= 4
        ticks_per_beat ||= 24
        offset ||= 0r

        do_log ||= false

        @clock = clock

        @before_begin = []
        @before_begin << Musa::Extension::SmartProcBinder::SmartProcBinder.new(before_begin) if before_begin

        @on_start = []
        @on_start << Musa::Extension::SmartProcBinder::SmartProcBinder.new(on_start) if on_start

        @on_change_position = []
        @on_change_position << Musa::Extension::SmartProcBinder::SmartProcBinder.new(on_position_change) if on_position_change

        @after_stop = []
        @after_stop << Musa::Extension::SmartProcBinder::SmartProcBinder.new(after_stop) if after_stop

        @do_log = do_log

        @sequencer = sequencer
        @sequencer ||= Musa::Sequencer::Sequencer.new beats_per_bar, ticks_per_beat, offset: offset, logger: logger, do_log: @do_log

        @clock.on_start do
          do_on_start
        end

        @clock.on_stop do
          do_stop
        end

        @clock.on_change_position do |bars: nil, beats: nil, midi_beats: nil|
          change_position_to bars: bars, beats: beats, midi_beats: midi_beats
        end

        # TODO: Consider adding block/DSL support for cleaner initialization syntax.
        #
        # Future enhancement could yield a DSL context that provides direct access to
        # transport methods without requiring the transport variable. This would enable:
        #
        #   Transport.new(clock, 4, 24) do
        #     before_begin { setup_instruments }
        #     on_start { start_recording }
        #     after_stop { save_recording }
        #   end
        #
        # Instead of current approach:
        #
        #   transport = Transport.new(clock, 4, 24)
        #   transport.before_begin { setup_instruments }
        #   transport.on_start { start_recording }
        #   transport.after_stop { save_recording }
        #
        # Implementation would require a DSL context object that delegates methods to
        # the transport instance, similar to the sequencer DSL pattern.
      end

      # Registers a callback to run once before the first start.
      #
      # before_begin callbacks are run only once, before the very first start.
      # They're ideal for one-time setup like loading samples or initializing state.
      #
      # After a stop, before_begin runs again before the next start.
      #
      # @yield [sequencer] Called before first start
      # @yieldparam sequencer [Sequencer] the sequencer instance
      # @return [void]
      #
      # @example
      #   transport.before_begin do |seq|
      #     puts "Initializing at position #{seq.position}"
      #     load_samples
      #   end
      def before_begin(&block)
        @before_begin << Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)
      end

      # Registers a callback to run each time the transport starts.
      #
      # on_start callbacks run every time {#start} is called, after before_begin.
      #
      # @yield [sequencer] Called on each start
      # @yieldparam sequencer [Sequencer] the sequencer instance
      # @return [void]
      #
      # @example
      #   transport.on_start do |seq|
      #     puts "Starting playback at #{seq.position}"
      #   end
      def on_start(&block)
        @on_start << Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)
      end

      # Registers a callback to run when the transport stops.
      #
      # after_stop callbacks run when the clock stops, before the sequencer is reset.
      #
      # @yield [sequencer] Called when stopping
      # @yieldparam sequencer [Sequencer] the sequencer instance
      # @return [void]
      #
      # @example
      #   transport.after_stop do |seq|
      #     puts "Stopped at position #{seq.position}"
      #     cleanup_resources
      #   end
      def after_stop(&block)
        @after_stop << Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)
      end

      # Registers a callback for position changes.
      #
      # Called when playback position changes non-linearly (seek/jump), typically
      # from MIDI Song Position Pointer or manual position changes.
      #
      # @yield [sequencer] Called on position change
      # @yieldparam sequencer [Sequencer] the sequencer instance
      # @return [void]
      #
      # @example
      #   transport.on_change_position do |seq|
      #     puts "Position jumped to #{seq.position}"
      #     resync_external_devices
      #   end
      def on_change_position(&block)
        @on_change_position << Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)
      end

      # Starts the transport and begins playback.
      #
      # Runs before_begin (if first start or after stop), then starts the clock's
      # run loop. **Behavior depends on the clock type**:
      #
      # ## Clock Activation by Type
      #
      # **DummyClock** (automatic activation):
      # - Starts generating ticks immediately
      # - Blocks until tick count/condition completes
      # - No external activation needed
      #
      # **TimerClock** (external activation required):
      # - Blocks but remains paused until `clock.start` is called
      # - Must call `clock.start()` from another thread to begin ticks
      # - Typical pattern: `Thread.new { transport.start }` then `clock.start`
      #
      # **InputMidiClock** (MIDI activation required):
      # - Blocks waiting for MIDI "Start" (0xFA) message
      # - External DAW/device controls when ticks begin
      # - Automatically starts when MIDI Start received
      #
      # **ExternalTickClock** (manual tick control):
      # - Returns immediately (doesn't block)
      # - Call `clock.tick()` manually to generate each tick
      # - Complete control over timing from external system
      #
      # @return [void]
      #
      # @note Blocking behavior varies by clock type (see above)
      # @note For TimerClock, must call clock.start from separate thread
      #
      # @example With DummyClock (automatic)
      #   clock = DummyClock.new(100)
      #   transport = Transport.new(clock, 4, 24)
      #   transport.start  # Runs 100 ticks automatically, then returns
      #
      # @example With TimerClock (external activation)
      #   clock = TimerClock.new(bpm: 120)
      #   transport = Transport.new(clock, 4, 24)
      #
      #   thread = Thread.new { transport.start }  # Blocks waiting
      #   sleep 0.1
      #   clock.start  # Activate from external control
      #   thread.join
      #
      # @example With InputMidiClock (MIDI activation)
      #   input = MIDICommunications::Input.all.first
      #   clock = InputMidiClock.new(input)
      #   transport = Transport.new(clock, 4, 24)
      #   transport.start  # Blocks until MIDI Start received from DAW
      #
      # @example With ExternalTickClock (manual control)
      #   clock = ExternalTickClock.new
      #   transport = Transport.new(clock, 4, 24)
      #
      #   thread = Thread.new { transport.start }  # Returns immediately
      #   sleep 0.1
      #   100.times { clock.tick }  # Generate ticks manually
      #   transport.stop
      #   thread.join
      def start
        do_before_begin unless @before_begin_already_done

        @clock.run do
          @before_begin_already_done = false
          @sequencer.tick
        end
      end

      # Changes the playback position (seek/jump).
      #
      # Handles position changes from various sources, converting between formats.
      # **IMPORTANT**: Position changes trigger fast-forward, which executes all
      # intermediate events between current and target positions.
      #
      # ## Fast-Forward Behavior
      #
      # When changing position forward:
      # 1. Calls `sequencer.on_fast_forward` callbacks with `true` (entering fast-forward)
      # 2. Ticks through all intermediate positions, **executing all scheduled events**
      # 3. Calls `sequencer.on_fast_forward` callbacks with `false` (exiting fast-forward)
      # 4. Calls `on_change_position` callbacks at the new position
      #
      # When changing position backward (requires stop):
      # 1. Stops the transport (calls `after_stop` callbacks)
      # 2. Resets the sequencer to initial state
      # 3. Sets position to target
      # 4. Restarts (calls `on_start` callbacks)
      #
      # ## Handling Intermediate Events
      #
      # During fast-forward, all scheduled events execute. To prevent unwanted sound
      # output (e.g., MIDI notes), use `on_fast_forward` callbacks:
      #
      # - **MIDIVoices integration**: Set `midi_voices.fast_forward = true` during
      #   fast-forward to register note state internally without emitting MIDI messages
      # - **Custom handlers**: Check fast-forward state in event handlers to skip
      #   audio/visual output during position jumps
      #
      # @param bars [Numeric, nil] target position in bars
      # @param beats [Numeric, nil] offset in beats to add
      # @param midi_beats [Integer, nil] offset in MIDI beats (for MIDI Clock)
      #
      # @return [void]
      #
      # @raise [ArgumentError] if no valid position specified
      #
      # @note Backward seeks trigger stop/restart cycle
      # @note Calls on_change_position callbacks at new position
      # @note Calls sequencer.on_fast_forward callbacks during forward seek
      #
      # @example Jump to bar 8 (fast-forwards through bars 1-7)
      #   transport.change_position_to(bars: 8)
      #
      # @example MIDI Song Position Pointer
      #   transport.change_position_to(midi_beats: 96)  # Bar 4 in 4/4
      #
      # @example Preventing sound during fast-forward with MIDIVoices
      #   transport.sequencer.on_fast_forward do |is_starting|
      #     midi_voices.fast_forward = is_starting
      #   end
      #
      #   # Now position changes won't produce audible MIDI output
      #   transport.change_position_to(bars: 10)
      def change_position_to(bars: nil, beats: nil, midi_beats: nil)
        logger.debug('Transport') do
          "asked to change position to #{"#{bars} bars " if bars}#{"#{beats} beats " if beats}" \
          "#{"#{midi_beats} midi beats " if midi_beats}"
        end

        # Calculate position from provided parameters
        position = bars&.rationalize || 1r
        position += Rational(midi_beats, 4 * @sequencer.beats_per_bar) if midi_beats
        position += Rational(beats, @sequencer.beats_per_bar) if beats

        # Adjust for sequencer offset and tick duration
        position += @sequencer.offset
        position -= @sequencer.tick_duration

        raise ArgumentError, "undefined new position" unless position

        logger.debug('Transport') { "received message position change to #{position.inspect}" }

        start_again_later = false

        # Backward seek requires stop/restart to reinitialize state
        if @sequencer.position > position
          do_stop
          start_again_later = true
        end

        logger.debug('Transport') { "setting sequencer position #{position.inspect}" }

        # Schedule position change callback at new position
        @sequencer.raw_at position, force_first: true do
          @on_change_position.each { |block| block.call @sequencer }
        end

        @sequencer.position = position

        do_on_start if start_again_later
      end

      # Stops the transport.
      #
      # Terminates the clock, which triggers the stop sequence (after_stop callbacks,
      # sequencer reset, etc.)
      #
      # @return [void]
      def stop
        @clock.terminate
      end

      # Returns the transport's logger.
      #
      # Delegates to sequencer's logger.
      #
      # @return [Logger] the logger instance
      def logger
        @sequencer.logger
      end

      private

      # Executes before_begin callbacks.
      #
      # @api private
      def do_before_begin
        logger.debug('Transport') { 'doing before_begin initialization...' } unless @before_begin.empty?
        @before_begin.each { |block| block.call @sequencer }
        logger.debug('Transport') { 'doing before_begin initialization... done' } unless @before_begin.empty?
      end

      # Executes on_start callbacks.
      #
      # @api private
      def do_on_start
        logger.debug('Transport') { 'starting...' } unless @on_start.empty?
        @on_start.each { |block| block.call @sequencer }
        logger.debug('Transport') { 'starting... done' } unless @on_start.empty?
      end

      # Executes the stop sequence.
      #
      # Runs after_stop callbacks, resets the sequencer, then runs before_begin
      # callbacks (preparing for next start).
      #
      # @api private
      def do_stop
        logger.debug('Transport') { 'stopping...' } unless @after_stop.empty?
        @after_stop.each { |block| block.call @sequencer }
        logger.debug('Transport') { 'stopping... done' } unless @after_stop.empty?

        logger.debug('Transport') { 'resetting sequencer...' }
        @sequencer.reset
        logger.debug('Transport') { 'resetting sequencer... done' }

        # Prepare for next start
        do_before_begin
        @before_begin_already_done = true
      end
    end
  end
end
