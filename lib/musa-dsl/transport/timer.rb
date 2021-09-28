module Musa
  module Clock
    class Timer
      attr_accessor :period

      def initialize(period_in_seconds, correction: nil, stop: nil, logger: nil, do_log: nil)
        @period = period_in_seconds.rationalize
        @correction = (correction || 0r).rationalize
        @stop = stop || false
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
            to_sleep = (@next_moment  + @correction) - Process.clock_gettime(Process::CLOCK_MONOTONIC)

            if @do_log && to_sleep.negative?
              @logger&.error "Timer delayed #{-to_sleep}s (near #{(-to_sleep / @period).round} ticks)"
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
