require_relative 'clock'

module Musa
  module Clock
    # Simple clock for testing with fixed tick count or custom condition.
    #
    # DummyClock is designed for testing and batch processing where automatic
    # execution without external dependencies is desired.
    #
    # ## Activation Model
    #
    # **IMPORTANT**: Unlike TimerClock, InputMidiClock, and ExternalTickClock,
    # DummyClock **activates automatically** when `transport.start` is called.
    # It immediately begins generating ticks without waiting for external signals.
    #
    # This activation model is appropriate for:
    # 
    # - **Unit testing**: No external dependencies, deterministic execution
    # - **Batch processing**: Generate music as fast as possible
    # - **Fast-forward simulations**: Skip real-time delays
    # - **Deterministic debugging**: Predictable tick counts
    #
    # ## Modes of Operation
    #
    # 1. **Fixed tick count**: Runs for exactly N ticks then stops
    # 2. **Custom condition**: Runs while a block returns true
    #
    # ## Differences from Other Clocks
    #
    # DummyClock is the only clock that starts generating ticks immediately
    # upon `transport.start`. It uses Thread.pass instead of sleep, making
    # execution as fast as possible without real-time constraints.
    #
    # @example Fixed tick count (automatic activation)
    #   clock = DummyClock.new(100)  # Exactly 100 ticks
    #   transport = Transport.new(clock, 4, 24)
    #
    #   pulses = []
    #   transport.sequencer.every(1) { pulses << transport.sequencer.position }
    #
    #   transport.start  # Immediately runs 100 ticks, then stops
    #
    #   pulses  # => [(95/96), (191/96)]
    #
    #   # 4 beats of 24 ticks is 96 ticks to the bar, so a hundred of them is one
    #   # bar and a bit: an `every 1` written outside any `at` pulses twice, one
    #   # tick before each bar. The clock stops where it stops -- nothing rounds
    #   # it up to a whole bar.
    #
    # @example Custom condition (automatic activation)
    #   continue = true
    #   clock = DummyClock.new { continue }
    #   transport = Transport.new(clock, 4, 24)
    #
    #   pulses = 0
    #   transport.sequencer.every(1) do
    #     pulses += 1
    #     continue = false if pulses >= 5
    #   end
    #
    #   transport.start  # Immediately begins, stops when the block says so
    #
    #   pulses  # => 5
    #
    #   # The block is asked BEFORE each tick, so what it guards is the tick that
    #   # has not happened yet.
    #
    # @example Testing specific sequences
    #   ticks = 0
    #   some_condition = true
    #   clock = DummyClock.new { ticks < 50 || some_condition }
    #   transport = Transport.new(clock, 4, 24)
    #
    #   transport.sequencer.every(1) do
    #     ticks += 1
    #     some_condition = false if ticks >= 60
    #   end
    #   transport.start
    #
    #   ticks  # => 60
    #
    #   # Sixty and not fifty: the two clauses are OR'd, so the condition holds
    #   # while EITHER is true. `ticks < 50` stops mattering at 50 and the flag
    #   # carries it to 60. Reading it as "a minimum of 50" is reading the first
    #   # clause and ignoring the second.
    #
    # @see TimerClock For real-time operation with external activation
    # @see InputMidiClock For MIDI-synchronized operation
    # @see ExternalTickClock For manual tick control
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
      # Calls {#stop} when done (idempotent).
      #
      # @yield Called once per tick
      # @return [void]
      #
      # @note No real-time delays; runs as fast as possible
      def run
        @on_start.each(&:call)
        @run = true
        @stopped = false

        while @run && eval_condition
          yield if block_given?

          Thread.pass  # Cooperate with other threads
        end

        stop  # Idempotent: if terminate already called stop, this is a no-op
      end

      # Stops the clock and fires on_stop callbacks.
      #
      # @return [void]
      def stop
        @run = false
        super
      end

      # Terminates the clock loop.
      #
      # Calls {#stop} to ensure on_stop callbacks fire, then ensures the
      # run loop exits.
      #
      # @return [void]
      def terminate
        stop
      end

      private

      # Evaluates continuation condition based on mode.
      #
      # @return [Boolean] true to continue, false to stop
      # @api private
      def eval_condition
        if @ticks
          # Tick count mode: spend one and say whether it was there to spend.
          # The comparison has to be `>= 0` and not `> 0` BECAUSE the decrement
          # happens first: what is being asked is not "are there any left?" but
          # "was there one for this turn?". Testing before spending would take
          # the other comparison.
          (@ticks -= 1) >= 0
        else
          # Block condition mode
          @block.call
        end
      end
    end
  end
end
