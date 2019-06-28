require 'musa-dsl/transport/clock'
require 'nibbler'

module Musa
  class TimerClock < Clock
    def initialize(period, correction: nil, do_log: nil)
      do_log ||= false

      super()

      @period = period
      @correction = correction

      @started = false
      @paused = false

      @do_log = do_log
    end

    def started?
      @started
    end

    def paused?
      @paused
    end

    def run
      @run = true

      while @run
        @timer = Timer.new(@period, correction: @correction, stop: true)

        @timer.run do
          yield if block_given?
        end
      end
    end

    def start
      unless @started
        @on_start.each(&:call)
        @started = true
        @paused = false
        @timer.continue
      end
    end

    def stop
      if @started
        @timer.stop
        @started = false
        @paused = false
        @on_stop.each(&:call)
      end
    end

    def pause
      if @started && !@paused
        @timer.stop
        @paused = true
      end
    end

    def continue
      if @started && @paused
        @paused = false
        @timer.continue
      end
    end

    def terminate
      @run = false
    end
  end
end
