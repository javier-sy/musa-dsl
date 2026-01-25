module Musa
  module Clock
    # High-precision timer for generating regular ticks.
    #
    # Timer uses Ruby's monotonic clock (Process::CLOCK_MONOTONIC) for drift-free
    # timing. It compensates for processing delays and reports when the system
    # cannot keep up with the requested tick rate.
    #
    # ## Precision Features
    #
    # - **Monotonic clock**: Immune to system time changes
    # - **Drift compensation**: Calculates exact next tick time
    # - **Overload detection**: Reports delayed ticks when processing is slow
    # - **Correction parameter**: Fine-tune timing for specific systems
    #
    # ## Usage Pattern
    #
    # Timer is typically used internally by TimerClock, not directly. It runs
    # in a loop, yielding for each tick and managing precise sleep intervals.
    #
    # ## Timing Algorithm
    #
    # 1. Record next expected tick time
    # 2. Yield (caller processes tick)
    # 3. Add period to next_moment
    # 4. Calculate sleep time = (next_moment + correction) - current_time
    # 5. Sleep if positive, warn if negative (delayed)
    #
    # @example Internal use by TimerClock
    #   timer = Timer.new(0.02083, logger: logger)  # ~48 ticks/second
    #   timer.run { sequencer.tick }
    #
    # @see TimerClock Uses Timer internally
    class Timer
      # The period between ticks in seconds.
      #
      # @return [Rational] tick period in seconds
      attr_accessor :period

      # Creates a new precision timer.
      #
      # @param tick_period_in_seconds [Numeric] time between ticks in seconds
      # @param correction [Numeric, nil] timing correction offset in seconds (for calibration)
      # @param stop [Boolean, nil] initial stopped state (true = paused)
      # @param delayed_ticks_error [Numeric, nil] threshold for error-level logging (default: 1.0 tick)
      # @param logger [Logger, nil] logger for timing warnings/errors
      # @param do_log [Boolean, nil] enable logging
      #
      # @example 120 BPM, 24 ticks per beat
      #   period = 60.0 / (120 * 24)  # 0.02083 seconds
      #   timer = Timer.new(period, logger: logger)
      def initialize(tick_period_in_seconds, correction: nil, stop: nil, delayed_ticks_error: nil, logger: nil, do_log: nil)
        @period = tick_period_in_seconds.rationalize
        @correction = (correction || 0r).rationalize
        @stop = stop || false
        @terminate = false

        @delayed_ticks_error = delayed_ticks_error || 1.0
        @logger = logger
        @do_log = do_log
      end

      # Runs the timer loop, yielding for each tick.
      #
      # This method blocks and runs until terminated. For each tick:
      # 1. Yields to caller if not stopped
      # 2. Calculates next tick time
      # 3. Sleeps precisely until next tick
      # 4. Logs warnings if timing cannot be maintained
      #
      # When stopped (@stop = true), the thread sleeps until {#continue} is called.
      # When terminated (@terminate = true), the loop exits and this method returns.
      #
      # @yield Called once per tick for processing
      # @return [void]
      #
      # @note This method blocks the current thread until {#terminate} is called
      # @note Uses monotonic clock for drift-free timing
      def run
        @thread = Thread.current
        @terminate = false

        @next_moment = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        loop do
          break if @terminate

          unless @stop
            # Process the tick
            yield

            # Calculate next tick moment (compensates for processing time)
            @next_moment += @period
            to_sleep = (@next_moment + @correction) - Process.clock_gettime(Process::CLOCK_MONOTONIC)

            # Log timing issues if enabled
            if @do_log && to_sleep.negative? & @logger
              tick_errors = -to_sleep / @period
              if tick_errors >= @delayed_ticks_error
                @logger.error "Timer delayed #{tick_errors.round(2)} ticks (#{-to_sleep.round(3)}s)"
              else
                @logger.warn "Timer delayed #{tick_errors.round(2)} ticks (#{-to_sleep.round(3)}s)"
              end
            end

            # Sleep precisely until next tick (if not already late)
            sleep to_sleep if to_sleep > 0.0
          end

          # When stopped, sleep thread until continue or terminate is called
          if @stop
            break if @terminate
            sleep
          end
        end
      end

      # Pauses the timer without terminating the loop.
      #
      # The timer thread sleeps until {#continue} is called. Ticks are not
      # generated while stopped.
      #
      # @return [void]
      #
      # @see #continue
      def stop
        @stop = true
      end

      # Resumes the timer after being stopped.
      #
      # Resets the next tick moment to avoid a burst of catchup ticks,
      # then wakes the timer thread.
      #
      # @return [void]
      #
      # @note Resets timing baseline to prevent tick accumulation
      # @see #stop
      def continue
        @stop = false
        @next_moment = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        @thread.run
      end

      # Terminates the timer loop permanently.
      #
      # Unlike {#stop} which pauses the timer (allowing {#continue} to resume),
      # terminate causes the {#run} loop to exit completely. Use this for
      # clean shutdown.
      #
      # @return [void]
      #
      # @note This wakes the thread if sleeping and causes {#run} to return
      # @see #stop For pausing without terminating
      def terminate
        @terminate = true
        @thread&.wakeup
      end
    end
  end
end
