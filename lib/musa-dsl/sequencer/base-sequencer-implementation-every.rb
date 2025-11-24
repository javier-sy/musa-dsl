module Musa::Sequencer
  class BaseSequencer
    # Implements recurring event execution at regular intervals.
    #
    # Recursively schedules block execution at interval-based positions.
    # Handles stopping conditions, callbacks, and precise timing without drift.
    #
    # ## Timing Precision
    #
    # Next iteration is always scheduled at:
    #   start_position + execution_counter * interval
    #
    # This ensures iterations align to exact positions regardless of execution
    # time or accumulated delays.
    #
    # @param interval [Rational, nil] bars between iterations (nil = one-shot)
    # @param control [EveryControl] control object managing lifecycle
    # @param block_procedure_binder [SmartProcBinder, nil] cached binder (for recursion)
    # @yield block to execute each iteration (receives control:)
    #
    # @return [nil]
    #
    # @api private
    private def _every(interval, control, block_procedure_binder: nil, &block)
      block ||= proc {}

      block_procedure_binder ||=
        Musa::Extension::SmartProcBinder::SmartProcBinder.new block, on_rescue: proc { |e| _rescue_error(e) }

      _numeric_at position, control do
        control._start_position ||= position
        control._execution_counter ||= 0

        if interval && control.duration_value
          duration_exceeded = (control._start_position + control.duration_value - interval) <= position
        end

        till_exceeded = control.till_value - interval <= position if interval && control.till_value

        condition_failed = !control.condition_block.call if control.condition_block

        unless control.stopped? || condition_failed || till_exceeded
          block_procedure_binder.call(control: control)
          control._execution_counter += 1
        end


        if control.stopped? || duration_exceeded || till_exceeded || condition_failed || interval.nil?
          control.do_on_stop.each(&:call)

          control.do_after.each do |do_after|
            # _numeric_at position + (interval || 0) + do_after[:bars], control, &do_after[:block]
            _numeric_at position + do_after[:bars], control, &do_after[:block]
          end
        else
          _numeric_at control._start_position + control._execution_counter * interval, control do
            _every interval, control, block_procedure_binder: block_procedure_binder
          end
        end
      end

      nil
    end

    # Control object for every loops.
    #
    # Manages lifecycle of every loop including stopping conditions, callbacks,
    # and execution tracking. Extends EventHandler to support event-based
    # control (e.g., launching custom events).
    #
    # ## Stopping Conditions
    #
    # - **duration**: Maximum loop duration in bars
    # - **till**: Absolute position to stop at
    # - **condition**: Proc returning true to continue, false to stop
    # - **manual stop**: Call `control.stop` to halt loop
    #
    # ## Callbacks
    #
    # - **on_stop**: Called when loop stops (any reason)
    # - **after**: Called after loop stops, with optional delay in bars
    #
    # ## Execution Tracking
    #
    # - **_start_position**: Position when loop started
    # - **_execution_counter**: Number of iterations executed
    #
    # @example Dynamic control
    #   control = sequencer.every(1r) { |control| puts control._execution_counter }
    #   control.duration(4r)  # Stop after 4 bars
    #   control.on_stop { puts "Finished!" }
    #   control.after(2r) { puts "2 bars after finish" }
    #
    class EveryControl < EventHandler
      # @return [Rational, nil] maximum duration in bars
      attr_reader :duration_value
      # @return [Rational, nil] absolute position to stop at
      attr_reader :till_value
      # @return [Proc, nil] condition block (returns true to continue)
      attr_reader :condition_block
      # @return [Array<Proc>] callbacks when loop stops
      attr_reader :do_on_stop
      # @return [Array<Hash>] after callbacks with delays
      attr_reader :do_after

      # @return [Rational] position when loop started
      # @api private
      attr_accessor :_start_position
      # @return [Integer] number of iterations executed
      # @api private
      attr_accessor :_execution_counter

      # Creates every loop control.
      #
      # @param parent [EventHandler] parent event handler
      # @param duration [Rational, nil] maximum duration in bars
      # @param till [Rational, nil] absolute stop position
      # @param condition [Proc, nil] continuation condition
      # @param on_stop [Proc, nil] stop callback
      # @param after_bars [Rational, nil] delay for after callback
      # @param after [Proc, nil] after callback block
      #
      # @api private
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

      # Sets maximum loop duration.
      #
      # @param value [Numeric] duration in bars
      #
      # @return [void]
      #
      # @api private
      def duration(value)
        @duration_value = value.rationalize
      end

      # Sets absolute stop position.
      #
      # @param value [Numeric] position to stop at
      #
      # @return [void]
      #
      # @api private
      def till(value)
        @till_value = value.rationalize
      end

      # Sets continuation condition.
      #
      # @yield condition block (returns true to continue, false to stop)
      #
      # @return [void]
      #
      # @api private
      def condition(&block)
        @condition_block = block
      end

      # Registers callback for when loop stops.
      #
      # @yield stop callback block
      #
      # @return [void]
      #
      # @api private
      def on_stop(&block)
        @do_on_stop << block
      end

      # Registers callback to execute after loop stops.
      #
      # @param bars [Numeric, nil] delay in bars after stop (default: 0)
      # @yield after callback block
      #
      # @return [void]
      #
      # @example Immediate after callback
      #   control.after { puts "Done" }
      #
      # @example Delayed after callback
      #   control.after(2r) { puts "2 bars after stop" }
      #
      # @api private
      def after(bars = nil, &block)
        bars ||= 0
        @do_after << { bars: bars.rationalize, block: block }
      end
    end

    private_constant :EveryControl
  end
end
