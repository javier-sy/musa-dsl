module Musa
  # Clock and timing infrastructure for musical transport.
  #
  # The Clock module provides the foundation for all timing mechanisms in Musa DSL.
  # Clocks generate regular ticks that drive the sequencer forward, and can be
  # sourced from internal timers, external MIDI clock, or manual control.
  #
  # ## Architecture
  #
  # - **Clock (base class)**: Abstract interface for all clock implementations
  # - **TimerClock**: Internal high-precision timer-based clock
  # - **InputMidiClock**: Synchronized to external MIDI Clock messages
  # - **ExternalTickClock**: Manually triggered ticks (for testing/integration)
  # - **DummyClock**: Simplified clock for testing
  #
  # ## Clock Lifecycle
  #
  # 1. **Creation**: Clock instance created with configuration
  # 2. **Registration**: Callbacks registered (on_start, on_stop, on_change_position)
  # 3. **Running**: Clock.run called (blocks, generates ticks via yield)
  # 4. **Termination**: Clock.terminate called to stop
  #
  # @see Transport Connects clocks to sequencers
  # @see Sequencer Receives ticks from clocks
  module Clock
    # Abstract base class for all clock implementations.
    #
    # This class defines the interface and callback infrastructure that all
    # concrete clock implementations must follow. Subclasses must implement
    # the `run` and `terminate` methods.
    #
    # ## Callback System
    #
    # Clocks maintain three callback collections:
    #
    # - **on_start**: Called when clock starts running
    # - **on_stop**: Called when clock stops
    # - **on_change_position**: Called when position changes (seek/jump)
    #
    # ## Subclass Responsibilities
    #
    # Concrete clocks must:
    #
    # 1. Implement `run(&block)` - Start generating ticks, yield for each tick
    # 2. Override `stop` if additional cleanup is needed (call super)
    # 3. Override `terminate` to call `stop` then exit the run loop
    # 4. Manage @run state properly
    # 5. Reset `@stopped = false` at the start of `run` (and in `start` if applicable)
    #
    # @example Creating a simple clock subclass
    #   class SimpleClock < Clock
    #     def run
    #       @stopped = false
    #       @run = true
    #       @on_start.each(&:call)
    #
    #       while @run
    #         yield if block_given?  # Generate tick
    #         sleep 0.1
    #       end
    #
    #       stop  # Fires on_stop callbacks (idempotent)
    #     end
    #
    #     def terminate
    #       stop         # Ensures on_stop callbacks fire
    #       @run = false # Exits the run loop
    #     end
    #   end
    #
    # @abstract Subclass and implement {#run} and {#terminate}
    class Clock
      # Initializes the clock with empty callback collections.
      def initialize
        @run = nil
        @stopped = false
        @on_start = []
        @on_stop = []
        @on_change_position = []
      end

      # Checks if the clock is currently running.
      #
      # @return [Boolean] true if clock is running, false otherwise.
      def running?
        @run
      end

      # Stops the clock and fires on_stop callbacks.
      #
      # Idempotent: calling stop multiple times only fires callbacks once.
      # Subclasses that need additional stop logic (e.g., pausing a timer)
      # should override and call super.
      #
      # @return [void]
      def stop
        return if @stopped

        @stopped = true
        @on_stop.each(&:call)
      end

      # Registers a callback to be called when the clock starts.
      #
      # Multiple callbacks can be registered and will be called in order.
      #
      # @yield Called when clock starts running.
      # @return [void]
      #
      # @example
      #   clock.on_start { puts "Clock started!" }
      def on_start(&block)
        @on_start << block
      end

      # Registers a callback to be called when the clock stops.
      #
      # Multiple callbacks can be registered and will be called in order.
      #
      # @yield Called when clock stops running.
      # @return [void]
      #
      # @example
      #   clock.on_stop { puts "Clock stopped!" }
      def on_stop(&block)
        @on_stop << block
      end

      # Registers a callback to be called when playback position changes.
      #
      # This is typically used for handling seek/jump operations where the
      # transport position changes non-linearly.
      #
      # @yield [bars, beats, midi_beats] Position change information
      # @yieldparam bars [Rational, nil] new position in bars
      # @yieldparam beats [Rational, nil] new position in beats
      # @yieldparam midi_beats [Integer, nil] new position in MIDI beats (for MIDI Clock)
      # @return [void]
      #
      # @example
      #   clock.on_change_position do |bars:, beats:, midi_beats:|
      #     puts "Position changed to bar #{bars}"
      #   end
      def on_change_position(&block)
        @on_change_position << block
      end

      # Starts the clock running and generates ticks.
      #
      # This method should block and yield once per tick. Subclasses must
      # implement this method.
      #
      # Subclasses should reset `@stopped = false` at the start of `run`
      # to allow stop/start cycles.
      #
      # @yield Called once per tick to advance the sequencer.
      # @return [void]
      #
      # @raise [NotImplementedError] if not overridden by subclass.
      #
      # @note This method typically runs in a loop until {#terminate} is called.
      # @note Subclasses should call @on_start callbacks when starting.
      # @note Subclasses should call {#stop} (not @on_stop directly) when stopping.
      def run
        raise NotImplementedError
      end

      # Stops the clock and terminates the run loop.
      #
      # Calls {#stop} to ensure on_stop callbacks fire, then exits the run loop.
      # Subclasses must implement this method.
      #
      # @return [void]
      #
      # @raise [NotImplementedError] if not overridden by subclass.
      #
      # @note After calling this, {#run} should exit.
      # @note Must call {#stop} to guarantee on_stop callbacks fire.
      def terminate
        raise NotImplementedError
      end
    end
  end
end
