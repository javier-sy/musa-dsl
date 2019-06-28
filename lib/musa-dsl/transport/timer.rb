module Musa
  class Timer
    def initialize(seconds, correction: nil, stop: nil)
      @seconds = seconds.rationalize
      @correction = (correction || 0r).rationalize
      @stop ||= false
    end

    def run
      @thread = Thread.current

      @next_moment = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      loop do
        unless @stop
          yield

          @next_moment += @seconds
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
