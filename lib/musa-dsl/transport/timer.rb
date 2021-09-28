module Musa
  module Clock
    class Timer
      attr_accessor :period

      def initialize(tick_period_in_seconds, correction: nil, stop: nil, delayed_ticks_error: nil, logger: nil, do_log: nil)
        @period = tick_period_in_seconds.rationalize
        @correction = (correction || 0r).rationalize
        @stop = stop || false

        @delayed_ticks_error = delayed_ticks_error || 1.0
        @logger = logger
        @do_log = do_log
      end

      def run
        @thread = Thread.current

        @next_moment = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        loop do
          unless @stop
            yield

            @next_moment += @period
            to_sleep = (@next_moment + @correction) - Process.clock_gettime(Process::CLOCK_MONOTONIC)

            if @do_log && to_sleep.negative? & @logger
              tick_errors = -to_sleep / @period
              if tick_errors >= @delayed_ticks_error
                @logger.error "Timer delayed #{tick_errors.round(2)} ticks (#{-to_sleep}s)"
              else
                @logger.warn "Timer delayed #{tick_errors.round(2)} ticks (#{-to_sleep}s)"
              end
            end

            sleep to_sleep if to_sleep > 0.0
          end

          sleep if @stop
        end
      end

      def stop
        @stop = true
      end

      def continue
        @stop = false
        @next_moment = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        @thread.run
      end
    end
  end
end
