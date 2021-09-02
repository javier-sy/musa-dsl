require_relative '../core-ext/arrayfy'
require_relative '../core-ext/smart-proc-binder'
require_relative '../logger'

require_relative '../series'

require_relative 'timeslots'

require_relative 'base-sequencer-tick-based'
require_relative 'base-sequencer-tickless-based'

module Musa
  module Sequencer
    class BaseSequencer
      attr_reader :beats_per_bar, :ticks_per_beat
      attr_reader :running_position
      attr_reader :everying, :playing, :moving
      attr_reader :logger

      def initialize(beats_per_bar = nil, ticks_per_beat = nil,
                     logger: nil,
                     do_log: nil, do_error_log: nil, log_position_format: nil)

        raise ArgumentError,
              "'beats_per_bar' and 'ticks_per_beat' parameters should be both nil or both have values" \
              unless beats_per_bar && ticks_per_beat || beats_per_bar.nil? && ticks_per_beat.nil?

        if logger
          @logger = logger
        else
          @logger = Musa::Logger::Logger.new(sequencer: self, position_format: log_position_format)

          @logger.fatal!
          @logger.error! if do_error_log || do_error_log.nil?
          @logger.debug! if do_log
        end

        if beats_per_bar && ticks_per_beat
          @beats_per_bar = Rational(beats_per_bar)
          @ticks_per_beat = Rational(ticks_per_beat)

          self.singleton_class.include TickBasedTiming
        else
          self.singleton_class.include TicklessBasedTiming
        end

        _init_timing

        @on_debug_at = []
        @on_error = []

        @before_tick = []
        @on_fast_forward = []

        @tick_mutex = Mutex.new
        @position_mutex = Mutex.new

        @timeslots = Timeslots.new

        @everying = []
        @playing = []
        @moving = []

        reset
      end

      def reset
        @timeslots.clear
        @everying.clear
        @playing.clear
        @moving.clear

        @event_handlers = [EventHandler.new]

        _reset_timing
      end

      def size
        @timeslots.values.sum(&:size)
      end

      def empty?
        @timeslots.empty?
      end

      def quantize_position(position, warn: nil)
        warn ||= false
        _quantize_position(position, warn: warn)
      end

      def run
        tick until empty?
      end

      def event_handler
        @event_handlers.last
      end

      def on_debug_at(&block)
        @on_debug_at << Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)
      end

      def on_error(&block)
        @on_error << Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)
      end

      def on_fast_forward(&block)
        @on_fast_forward << Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)
      end

      def before_tick(&block)
        @before_tick << Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)
      end

      def on(event, &block)
        @event_handlers.last.on event, &block
      end

      def launch(event, *value_parameters, **key_parameters)
        @event_handlers.last.launch event, *value_parameters, **key_parameters
      end

      def wait(bars_delay, debug: nil, &block)
        debug ||= false

        control = EventHandler.new @event_handlers.last
        @event_handlers.push control

        if bars_delay.is_a? Numeric
          _numeric_at position + bars_delay.rationalize, control, debug: debug, &block
        else
          bars_delay = Series::S(*bars_delay) if bars_delay.is_a?(Array)
          bars_delay = bars_delay.instance if bars_delay

          _serie_at bars_delay.with { |delay| position + delay }, control, debug: debug, &block
        end

        @event_handlers.pop

        control
      end

      def now(&block)
        control = EventHandler.new @event_handlers.last
        @event_handlers.push control

        _numeric_at position, control, &block

        @event_handlers.pop

        control
      end

      def raw_at(bar_position, force_first: nil, &block)
        _raw_numeric_at bar_position.rationalize, force_first: force_first, &block

        nil
      end

      def at(bar_position, debug: nil, &block)
        debug ||= false

        control = EventHandler.new @event_handlers.last
        @event_handlers.push control

        if bar_position.is_a? Numeric
          _numeric_at bar_position.rationalize, control, debug: debug, &block
        else
          bar_position = Series::S(*bar_position) if bar_position.is_a? Array
          bar_position = bar_position.instance if bar_position

          _serie_at bar_position, control, debug: debug, &block
        end

        @event_handlers.pop

        control
      end

      def play(serie,
               mode: nil,
               parameter: nil,
               after_bars: nil,
               after: nil,
               context: nil,
               **mode_args,
               &block)

        mode ||= :wait

        control = PlayControl.new @event_handlers.last, after_bars: after_bars, after: after
        @event_handlers.push control

        _play serie.instance, control, context, mode: mode, parameter: parameter, **mode_args, &block

        @event_handlers.pop

        @playing << control

        control.after do
          @playing.delete control
        end

        control
      end

      def continuation_play(parameters)
        _play parameters[:serie],
              parameters[:control],
              parameters[:neumalang_context],
              mode: parameters[:mode],
              decoder: parameters[:decoder],
              __play_eval: parameters[:play_eval],
              **parameters[:mode_args]
      end

      def play_timed(timed_serie,
                     on_stop: nil,
                     after_bars: nil, after: nil,
                     &block)

        control = PlayTimedControl.new(@event_handlers.last,
                                       on_stop: on_stop, after_bars: after_bars, after: after)

        control.on_stop do
          control.do_after.each do |do_after|
            _numeric_at position + do_after[:bars], control, &do_after[:block]
          end
        end

        @event_handlers.push control

        _play_timed(timed_serie.instance, control, &block)

        @event_handlers.pop

        @playing << control

        control.after do
          @playing.delete control
        end

        control
      end

      def every(interval,
                duration: nil, till: nil,
                condition: nil,
                on_stop: nil,
                after_bars: nil, after: nil,
                &block)

        # nil interval means 'only once'
        interval = interval.rationalize unless interval.nil?

        control = EveryControl.new @event_handlers.last,
                                   duration: duration,
                                   till: till,
                                   condition: condition,
                                   on_stop: on_stop,
                                   after_bars: after_bars,
                                   after: after

        @event_handlers.push control

        _every interval, control, &block

        @event_handlers.pop

        @everying << control

        control.after do
          @everying.delete control
        end

        control
      end

      def move(every: nil,
               from: nil, to: nil, step: nil,
               duration: nil, till: nil,
               function: nil,
               right_open: nil,
               on_stop: nil,
               after_bars: nil,
               after: nil,
               &block)

        control = _move every: every,
                        from: from, to: to, step: step,
                        duration: duration, till: till,
                        function: function,
                        right_open: right_open,
                        on_stop: on_stop,
                        after_bars: after_bars,
                        after: after,
                        &block

        @moving << control

        control.after do
          @moving.delete control
        end

        control
      end

      def debug(msg = nil)
        @logger.debug { msg || '...' }
      end

      def to_s
        super + ": position=#{position}"
      end
    end
  end
end

