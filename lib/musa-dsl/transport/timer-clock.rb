require 'musa-dsl/transport/clock'

module Musa
  module Clock
    class TimerClock < Clock
      def initialize(period = nil, ticks_per_beat: nil, bpm: nil, correction: nil, do_log: nil)
        do_log ||= false

        super()

        @correction = correction

        self.period = period if period
        self.ticks_per_beat = ticks_per_beat if ticks_per_beat
        self.bpm = bpm if bpm

        self.bpm ||= 120
        self.ticks_per_beat ||= 24

        @started = false
        @paused = false

        @do_log = do_log
      end

      attr_reader :period, :ticks_per_beat, :bpm

      def period=(period_in_seconds)
        @period = period_in_seconds.rationalize
        @bpm = 60r / (@period * @ticks_per_beat) if @period && @ticks_per_beat
        @timer.period = @period if @timer
      end

      def ticks_per_beat=(ticks)
        @ticks_per_beat = ticks.rationalize
        @period = 60r / (@bpm * @ticks_per_beat) if @bpm && @ticks_per_beat
        @timer.period = @period if @timer && @period
      end

      def bpm=(bpm)
        @bpm =  bpm.rationalize
        @period = 60r / (@bpm * @ticks_per_beat) if @bpm && @ticks_per_beat
        @timer.period = @period if @timer && @period
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
end
