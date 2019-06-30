module Musa
  class Timer
    attr_accessor :period

    def initialize(period_in_seconds, correction: nil, stop: nil)
      @period = period_in_seconds.rationalize
      @correction = (correction || 0r).rationalize
      @stop ||= false
    end

    def run
      @thread = Thread.current

      @next_moment = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      loop do
        unless @stop
          yield

          @next_moment += @period
          to_sleep = (@next_moment  + @correction) - Process.clock_gettime(Process::CLOCK_MONOTONIC)

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
