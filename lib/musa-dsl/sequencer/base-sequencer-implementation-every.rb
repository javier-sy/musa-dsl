module Musa; module Sequencer
  class BaseSequencer
    private def _every(interval, control, block_procedure_binder: nil, &block)
      block ||= proc {}

      block_procedure_binder ||= SmartProcBinder.new block, on_rescue: proc { |e| _rescue_error(e) }

      _numeric_at position, control do
        control._start_position ||= position
        control._execution_counter ||= 0

        duration_exceeded =
            (control._start_position + control.duration_value - interval) <= position if interval && control.duration_value

        till_exceeded = control.till_value - interval <= position if interval && control.till_value

        condition_failed = !control.condition_block.call if control.condition_block

        unless control.stopped? || condition_failed || till_exceeded
          block_procedure_binder.call(control: control)
          control._execution_counter += 1
        end


        unless control.stopped? || duration_exceeded || till_exceeded || condition_failed || interval.nil?
          _numeric_at control._start_position + control._execution_counter * interval, control do
            _every interval, control, block_procedure_binder: block_procedure_binder
          end

        else
          control.do_on_stop.each(&:call)

          control.do_after.each do |do_after|
            _numeric_at position + (interval || 0) + do_after[:bars], control, &do_after[:block]
          end
        end
      end

      nil
    end

    class EveryControl < EventHandler
      attr_reader :duration_value, :till_value, :condition_block, :do_on_stop, :do_after

      attr_accessor :_start_position
      attr_accessor :_execution_counter

      def initialize(parent, duration: nil, till: nil, condition: nil, on_stop: nil, after_bars: nil, after: nil)
        super parent

        @duration_value = duration
        @till_value = till
        @condition_block = condition

        @do_on_stop = []
        @do_after = []

        @do_on_stop << on_stop if on_stop

        self.after after_bars, &after if after
      end

      def duration(value)
        @duration_value = value.rationalize
      end

      def till(value)
        @till_value = value.rationalize
      end

      def condition(&block)
        @condition_block = block
      end

      def on_stop(&block)
        @do_on_stop << block
      end

      def after(bars = nil, &block)
        bars ||= 0
        @do_after << { bars: bars.rationalize, block: block }
      end
    end

    private_constant :EveryControl
  end
end; end
