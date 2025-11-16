require_relative 'clock'

module Musa
  module Clock
    # Internal timer-based clock for standalone operation.
    #
    # TimerClock uses a high-precision Timer to generate ticks at a configurable
    # rate. It's the standard clock for compositions that don't need external
    # synchronization.
    #
    # ## Configuration Methods
    #
    # The clock can be configured in three equivalent ways:
    #
    # 1. **BPM + ticks_per_beat**: Musical tempo-based (most common)
    # 2. **Period**: Direct tick period in seconds
    # 3. **Any combination**: Changes one parameter, others auto-calculate
    #
    # ## Relationship Between Parameters
    #
    #     period = 60 / (bpm * ticks_per_beat)
    #
    # Example: 120 BPM, 24 ticks/beat → period = 60/(120*24) = 0.02083s
    #
    # ## States
    #
    # - **Not started**: Clock created but not running
    # - **Started**: Clock running, generating ticks
    # - **Paused**: Clock started but temporarily stopped
    #
    # ## Use Cases
    #
    # - Standalone compositions without external sync
    # - Testing with precise, reproducible timing
    # - Live coding with internal timing
    #
    # @example Basic setup with BPM
    #   clock = TimerClock.new(bpm: 120, ticks_per_beat: 24)
    #   transport = Transport.new(clock, beats_per_bar: 4)
    #   transport.start
    #
    # @example With timing correction
    #   # Correction compensates for system-specific timing offsets
    #   clock = TimerClock.new(bpm: 140, correction: -0.001)
    #
    # @example Dynamic tempo changes
    #   clock = TimerClock.new(bpm: 120)
    #   # ... later, while running:
    #   clock.bpm = 140  # Tempo change takes effect immediately
    #
    # @see Timer Internal precision timer
    # @see Transport Connects clock to sequencer
    class TimerClock < Clock
      # Creates a new timer-based clock.
      #
      # At least one timing parameter must be provided (period, bpm, or ticks_per_beat).
      # Missing parameters use defaults: bpm=120, ticks_per_beat=24.
      #
      # @param period [Numeric, nil] tick period in seconds (direct specification)
      # @param ticks_per_beat [Numeric, nil] number of ticks per beat (default: 24)
      # @param bpm [Numeric, nil] beats per minute (default: 120)
      # @param correction [Numeric, nil] timing correction in seconds (for calibration)
      # @param delayed_ticks_error [Numeric, nil] threshold for error-level logging
      # @param logger [Logger, nil] logger for warnings/errors
      # @param do_log [Boolean, nil] enable timing logs
      #
      # @example
      #   # All equivalent for 120 BPM, 24 ticks/beat:
      #   TimerClock.new(bpm: 120, ticks_per_beat: 24)
      #   TimerClock.new(bpm: 120)  # ticks_per_beat defaults to 24
      #   TimerClock.new(period: 0.02083, ticks_per_beat: 24)
      def initialize(period = nil, ticks_per_beat: nil, bpm: nil, correction: nil, delayed_ticks_error: nil, logger: nil, do_log: nil)
        do_log ||= false

        super()

        @correction = correction

        # Set parameters in any combination
        self.period = period if period
        self.ticks_per_beat = ticks_per_beat if ticks_per_beat
        self.bpm = bpm if bpm

        # Apply defaults
        self.bpm ||= 120
        self.ticks_per_beat ||= 24

        @started = false
        @paused = false

        @delayed_ticks_error = delayed_ticks_error
        @logger = logger
        @do_log = do_log
      end

      # Current tick period in seconds.
      #
      # @return [Rational] seconds between ticks
      attr_reader :period

      # Number of ticks per beat.
      #
      # @return [Rational] ticks per beat (typically 24 or 96)
      attr_reader :ticks_per_beat

      # Current tempo in beats per minute.
      #
      # @return [Rational] BPM
      attr_reader :bpm

      # Sets the tick period in seconds and recalculates BPM.
      #
      # @param period_in_seconds [Numeric] new period in seconds
      # @return [Rational] the rationalized period
      #
      # @note If clock is running, change takes effect immediately via @timer.period
      def period=(period_in_seconds)
        @period = period_in_seconds.rationalize
        @bpm = 60r / (@period * @ticks_per_beat) if @period && @ticks_per_beat
        @timer.period = @period if @timer
      end

      # Sets ticks per beat and recalculates period.
      #
      # @param ticks [Numeric] new ticks per beat
      # @return [Rational] the rationalized ticks_per_beat
      #
      # @note Common values: 24 (standard), 96 (high resolution)
      # @note If clock is running, change takes effect immediately
      def ticks_per_beat=(ticks)
        @ticks_per_beat = ticks.rationalize
        @period = 60r / (@bpm * @ticks_per_beat) if @bpm && @ticks_per_beat
        @timer.period = @period if @timer && @period
      end

      # Sets tempo in BPM and recalculates period.
      #
      # @param bpm [Numeric] new tempo in beats per minute
      # @return [Rational] the rationalized BPM
      #
      # @note If clock is running, tempo change takes effect immediately
      # @example Tempo automation
      #   clock.bpm = 120
      #   sleep 10
      #   clock.bpm = 140  # Speed up!
      def bpm=(bpm)
        @bpm =  bpm.rationalize
        @period = 60r / (@bpm * @ticks_per_beat) if @bpm && @ticks_per_beat
        @timer.period = @period if @timer && @period
      end

      # Checks if the clock has been started.
      #
      # @return [Boolean] true if started (even if currently paused)
      def started?
        @started
      end

      # Checks if the clock is paused.
      #
      # @return [Boolean] true if paused
      def paused?
        @paused
      end

      # Starts the clock's run loop.
      #
      # This method blocks and runs the timer loop, yielding for each tick.
      # The clock starts in a paused state and must be explicitly started
      # via {#start}.
      #
      # @yield Called once per tick
      # @return [void]
      #
      # @note This method blocks until {#terminate} is called
      # @note Clock begins paused; call {#start} to begin ticking
      def run
        @run = true

        while @run
          @timer = Timer.new(@period,
                             correction: @correction,
                             stop: true,
                             delayed_ticks_error: @delayed_ticks_error,
                             logger: @logger,
                             do_log: @do_log)

          @timer.run do
            yield if block_given?
          end
        end
      end

      # Starts the clock from paused state.
      #
      # Triggers @on_start callbacks and begins generating ticks.
      # Has no effect if already started.
      #
      # @return [void]
      #
      # @note Must call {#run} first to start the run loop
      # @note Calls registered on_start callbacks
      def start
        unless @started
          @on_start.each(&:call)
          @started = true
          @paused = false
          @timer.continue
        end
      end

      # Stops the clock and resets to initial state.
      #
      # Triggers @on_stop callbacks and marks clock as not started.
      # Has no effect if not currently started.
      #
      # @return [void]
      #
      # @note Calls registered on_stop callbacks
      # @note Different from {#pause}: stop resets to initial state
      def stop
        if @started
          @timer.stop
          @started = false
          @paused = false
          @on_stop.each(&:call)
        end
      end

      # Pauses the clock without stopping it.
      #
      # Ticks stop but clock remains in started state. Use {#continue}
      # to resume.
      #
      # @return [void]
      #
      # @note No effect if not started or already paused
      # @see #continue
      def pause
        if @started && !@paused
          @timer.stop
          @paused = true
        end
      end

      # Resumes the clock from paused state.
      #
      # Continues generating ticks. Has no effect if not paused.
      #
      # @return [void]
      #
      # @note No effect if not started or not paused
      # @see #pause
      def continue
        if @started && @paused
          @paused = false
          @timer.continue
        end
      end

      # Terminates the clock's run loop.
      #
      # Causes {#run} to exit. This is the clean shutdown mechanism.
      #
      # @return [void]
      #
      # @note After calling this, {#run} will exit
      def terminate
        @run = false
      end
    end
  end
end
