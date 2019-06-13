module Musa
  class Timer
    def initialize(correction)
      @correction = correction
    end

    def every(seconds, &block)
      next_moment = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      loop do
        yield

        next_moment += seconds
        to_sleep = next_moment - Process.clock_gettime(Process::CLOCK_MONOTONIC) + @correction
        sleep to_sleep if to_sleep > 0.0
      end
    end
  end
end
