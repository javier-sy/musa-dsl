module Musa
  class Timer
    def initialize(seconds, correction: nil, stop: nil, &block)
      seconds = seconds.rationalize unless seconds.is_a?(Rational)

      correction = correction || 0r
      correction = correction.rationalize unless correction.is_a?(Rational)

      @thread = Thread.current

      stop if stop
      @next_moment = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      loop do
        unless @stop
          yield

          @next_moment += seconds
          to_sleep = (@next_moment  + correction) - Process.clock_gettime(Process::CLOCK_MONOTONIC)

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
