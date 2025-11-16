require_relative 'clock'

module Musa
  module Clock
    # Simple clock for testing with fixed tick count or custom condition.
    #
    # DummyClock is designed for testing and simulations where you want to:
    # - Generate a specific number of ticks
    # - Control ticking via a custom condition block
    # - Avoid real-time delays (uses Thread.pass, not sleep)
    #
    # ## Modes of Operation
    #
    # 1. **Fixed tick count**: Runs for exactly N ticks then stops
    # 2. **Custom condition**: Runs while a block returns true
    #
    # ## Use Cases
    #
    # - Unit testing sequencer logic
    # - Simulations with known tick counts
    # - Fast-forward testing without real-time delays
    # - Debugging specific tick sequences
    #
    # @example Fixed tick count
    #   clock = DummyClock.new(100)  # Exactly 100 ticks
    #   transport = Transport.new(clock)
    #   transport.start  # Runs 100 ticks, then stops
    #
    # @example Custom condition
    #   clock = DummyClock.new { continue_running? }
    #   transport = Transport.new(clock)
    #   transport.start  # Runs while continue_running? is true
    #
    # @example Testing specific sequences
    #   ticks = 0
    #   clock = DummyClock.new { ticks < 50 || some_condition }
    #   # Runs minimum 50 ticks, then checks some_condition
    #
    # @see TimerClock For real-time operation
    class DummyClock < Clock
      # Creates a new dummy clock with tick limit or condition.
      #
      # @param ticks [Integer, nil] number of ticks to generate (mutually exclusive with block)
      # @param do_log [Boolean, nil] enable logging
      # @yield Condition block called each iteration; runs while truthy
      #
      # @raise [ArgumentError] if both ticks and block are provided
      #
      # @note Only one of ticks or block should be provided
      def initialize(ticks = nil, do_log: nil, &block)
        do_log ||= false

        super()

        raise ArgumentError, 'Cannot initialize with ticks and block. You can only use one of the parameters.' if ticks && block

        @ticks = ticks
        @do_log = do_log
        @block = block
      end

      # Condition block for continuing (can be changed dynamically).
      #
      # @return [Proc, nil] the condition block
      attr_accessor :block

      # Number of ticks remaining (can be changed dynamically).
      #
      # @return [Integer, nil] ticks remaining
      attr_accessor :ticks

      # Runs the clock loop, yielding for each tick.
      #
      # Calls on_start callbacks, then yields while the condition is true.
      # Uses Thread.pass instead of sleep for fast operation.
      # Calls on_stop callbacks when done.
      #
      # @yield Called once per tick
      # @return [void]
      #
      # @note No real-time delays; runs as fast as possible
      def run
        @on_start.each(&:call)
        @run = true

        while @run && eval_condition
          yield if block_given?

          Thread.pass  # Cooperate with other threads
        end

        @on_stop.each(&:call)
      end

      # Terminates the clock loop.
      #
      # @return [void]
      def terminate
        @run = false
      end

      private

      # Evaluates continuation condition based on mode.
      #
      # @return [Boolean] true to continue, false to stop
      # @api private
      def eval_condition
        if @ticks
          # Tick count mode: decrement and check
          @ticks -= 1
          @ticks.positive?
        else
          # Block condition mode
          @block.call
        end
      end
    end
  end
end
