module Musa
  module Sequencer
    class BaseSequencer
      # Tickless (continuous) timing implementation for BaseSequencer.
      #
      # TicklessBasedTiming provides continuous, non-quantized time progression
      # where events can be scheduled at any Rational position without rounding
      # to a tick grid. Time advances by jumping directly to the next scheduled
      # event, enabling precise timing for complex musical structures and
      # avoiding quantization artifacts.
      #
      # ## Tickless Time Model
      #
      # - **No quantization**: Positions are exact Rational values
      # - **Event-driven**: Time jumps to next scheduled event
      # - **Infinite resolution**: ticks_per_bar = Float::INFINITY
      # - **Zero tick duration**: tick_duration = 0r
      # - **Continuous time**: No discrete grid or rounding
      #
      # ## Time Progression
      #
      # Unlike tick-based mode that advances in fixed increments, tickless
      # mode advances position directly to the next scheduled event. If events
      # are at positions [1r, 1.25r, 1.5r, 2r], calling {#tick} jumps through
      # these exact positions without intermediate steps.
      #
      # - **Forward only**: Position cannot decrease (enforced)
      # - **Event jumping**: {#tick} moves to next scheduled position
      # - **Fast-forward**: {#position=} executes events up to target
      # - **No rounding**: Positions preserved exactly
      #
      # ## Comparison with Tick-Based Mode
      #
      # | Aspect | Tick-Based | Tickless |
      # |--------|-----------|----------|
      # | Time grid | Quantized to ticks | Continuous |
      # | Resolution | ticks_per_beat | Infinite (Rational) |
      # | Advancement | Fixed tick_duration | Jump to next event |
      # | Rounding | Yes (with warning) | No |
      # | Use case | Traditional sequencing | Complex timing, microtiming |
      #
      # ## Musical Applications
      #
      # - Complex polyrhythms without quantization loss
      # - Precise microtiming and groove timing
      # - Non-isochronous meters and irregular divisions
      # - Algorithmic composition with exact ratios
      # - Avoiding rounding errors in long sequences
      #
      # @example Creating tickless sequencer
      #   sequencer = BaseSequencer.new  # No tick parameters
      #   sequencer.ticks_per_bar   # => Float::INFINITY
      #   sequencer.tick_duration   # => 0r
      #   sequencer.position        # => nil
      #   # nil, not a bar number: a tickless sequencer has no position of its
      #   # own until it reaches the first scheduled event.
      #
      # @example Precise timing without quantization
      #   sequencer.at(1r) { puts "Event 1" }
      #   sequencer.at(1 + 1/7r) { puts "Event 2" }  # Exact 1/7 division
      #   sequencer.at(1 + 1/3r) { puts "Event 3" }  # Exact 1/3 division
      #   sequencer.tick  # Jumps to 1r
      #   sequencer.tick  # Jumps to 8/7r (1 + 1/7)
      #   sequencer.tick  # Jumps to 4/3r (1 + 1/3)
      #
      # @example Complex polyrhythm (5 against 7)
      #   require 'musa-dsl'
      #
      #   sequencer = Musa::Sequencer::BaseSequencer.new  # Tickless mode
      #
      #   7.times { |i| sequencer.at(1 + Rational(i, 7)) { puts "Note A at #{sequencer.position}" } }
      #   5.times { |i| sequencer.at(1 + Rational(i, 5)) { puts "Note B at #{sequencer.position}" } }
      #
      #   sequencer.run  # Events at exact rational positions
      #
      # @api private
      module TicklessBasedTiming

        # Current playback position in bars (Rational or nil).
        #
        # Position is nil before first event, then becomes the exact Rational
        # position of the current event. No quantization or rounding occurs.
        #
        # @return [Rational, nil] current position or nil before first event
        attr_reader :position

        # Returns infinite ticks per bar for tickless mode.
        #
        # Indicates unlimited timing resolution (no tick grid).
        #
        # @return [Float] Float::INFINITY
        #
        # @api public
        def ticks_per_bar
          Float::INFINITY
        end

        # Returns zero tick duration for tickless mode.
        #
        # Indicates infinitesimal tick duration (continuous time).
        #
        # @return [Rational] 0r
        #
        # @api public
        def tick_duration
          0r
        end

        # TODO implementar hold_public_ticks adaptado a modo tickless para permitir que una operación de asignación de
        # TODO posición con .position = X, finalice antes de comenzar a procesar el resto de ticks en un contexto multithread.
        # TODO pero tiene sentido cuando el modo tickless se usa SOLO con .run?
        # TODO tendría sentido sólo si también se usa con ticks temporizados, lo cual ocurriría si se reimplementa el modo tickbased
        # TODO a partir del modo tickless.

        # Advances sequencer to next scheduled event.
        #
        # Jumps position directly to the next event in the timeslots, skipping
        # any intermediate positions. Executes all handlers scheduled at that
        # position. This is the primary time progression method for tickless
        # sequencers.
        #
        # Unlike tick-based mode with fixed increments, tickless tick jumps to
        # wherever the next event is scheduled, enabling precise event-driven
        # timing without quantization.
        #
        # @return [void]
        #
        # @example Event-driven progression
        #   sequencer.at(1r) { puts "A" }
        #   sequencer.at(1.5r) { puts "B" }
        #   sequencer.at(2r) { puts "C" }
        #
        #   sequencer.tick  # position becomes 1r, prints "A"
        #   sequencer.tick  # position becomes 1.5r, prints "B"
        #   sequencer.tick  # position becomes 2r, prints "C"
        #
        # @example Ticking a schedule that has run out does nothing
        #   exhausted = Musa::Sequencer::BaseSequencer.new
        #   exhausted.at(1r) { }
        #   exhausted.tick
        #
        #   exhausted.tick
        #   exhausted.position  # => 1r  (it stays where it was)
        #
        # @api public
        def tick
          # `first_after` returns nil when the schedule is exhausted, which is
          # the END of time and not a position. Assigning it moved the position
          # back to nil -- the BEGINNING of time, the other thing nil means
          # here -- so a tick past the last event ran the clock backwards and
          # left the sequencer unmovable again (issue #76).
          #
          # A tick is "advance to the next event". With no next event there is
          # nothing to advance to and nobody to call.
          position_to_run = @position_mutex.synchronize do
            next_position = @timeslots.first_after(@position)
            @position = next_position if next_position

            next_position
          end

          _tick position_to_run if position_to_run
        end

        # TODO puede pensarse que un sequencer tickbased es como un ticklessbased en que cada tick se aavanza el position en 1 / ticks_per_bar
        # TODO esto haría que los eventos que cayeran en posiciones no cuantizadas por la resolución en ticks_per_bar se ejecutarían en el siguiente
        # TODO lo cual sería una ventaja porque eliminaría la necesidad de cuantizar en el _at.
        # TODO Por otro lado cuando se cuantiza en _at se redondea al más cercano, mientras que el modelo basado en avanzar redondea siempre hacia arriba,
        # TODO pero esto podría resolverse con una opción de cuantización opcional que en _at ajustara la posición a la más cercana.

        # Fast-forwards sequencer to new position.
        #
        # Jumps to a future position by executing all scheduled events between
        # current and target positions. Triggers on_fast_forward callbacks to
        # allow handlers to optimize processing during the jump.
        #
        # Position can only move forward - attempting to move backward raises
        # ArgumentError. Unlike tick-based mode, no quantization occurs.
        #
        # ## Fast-Forward Process
        #
        # 1. Validates new_position >= current position
        # 2. Calls on_fast_forward callbacks with `true` (entering fast-forward)
        # 3. Executes all events at positions <= new_position
        # 4. Sets position to new_position (exact, no rounding)
        # 5. Calls on_fast_forward callbacks with `false` (exiting fast-forward)
        #
        # @param new_position [Rational] target position (must be >= current)
        #
        # @return [void]
        #
        # @raise [ArgumentError] if new_position < current position
        #
        # It works from the start too, before any tick: a sequencer that has not
        # reached its first event has a nil position, which is the beginning of
        # time and not a missing one. Skipping an introduction while rendering,
        # or seeking before playback begins, is exactly when this is reached for.
        #
        # @example Jump to future position
        #   sequencer.at(1.25r) { puts "Event 1" }
        #   sequencer.at(1.5r) { puts "Event 2" }
        #   sequencer.at(2.75r) { puts "Event 3" }
        #
        #   sequencer.tick           # position becomes 1.25r, prints "Event 1"
        #   sequencer.position = 2r  # executes the event at 1.5r on the way
        #   sequencer.position       # => 2r
        #   # Exactly 2r: it stops where it was told, not at the next event (2.75r).
        #
        # @example Jump from the start, without ticking first
        #   from_scratch = Musa::Sequencer::BaseSequencer.new
        #   from_scratch.at(1.25r) { puts "Event 1" }
        #   from_scratch.at(2.75r) { puts "Event 2" }
        #
        #   from_scratch.position       # => nil
        #   from_scratch.position = 2r  # prints "Event 1" on the way
        #   from_scratch.position       # => 2r
        #
        # @example Past the end of the schedule
        #   beyond = Musa::Sequencer::BaseSequencer.new
        #   beyond.at(1r) { }
        #
        #   beyond.position = 9r  # runs the event and stops where it was told
        #   beyond.position       # => 9r
        #
        # @example Cannot move backward
        #   sequencer.position = 1r  # => ArgumentError: cannot move back
        #
        # @api public
        def position=(new_position)
          # A nil position is the beginning of time, not a missing one: nothing
          # is behind it, so no target can be a move backwards.
          raise ArgumentError, "Sequencer #{self}: cannot move back. current position: #{@position} new position: #{new_position}" \
            if @position && new_position < @position

          @on_fast_forward.each { |block| block.call(true) }

          begin
            loop do
              next_position = @position_mutex.synchronize { @timeslots.first_after(@position) }

              # nil here is the OTHER nil: the schedule is exhausted. Comparing
              # it raised in the middle of the jump, after the events had run
              # and before the position was assigned (issue #76).
              break if next_position.nil? || next_position > new_position

              # The position moves WITH the events, as it does in `tick` and in
              # tick-based mode. It used to stay put for the whole jump, so a
              # block asking `sequencer.position` while being fast-forwarded
              # over got the position the jump started from -- and, now that a
              # jump can start before the first tick, it would have got nil.
              _tick @position_mutex.synchronize { @position = next_position }
            end

            @position = new_position
          ensure
            # Whatever happens in there, fast-forward has to be switched off
            # again: the failed jump used to leave it on, and handlers that mute
            # themselves during a jump stayed muted for the rest of the run.
            @on_fast_forward.each { |block| block.call(false) }
          end
        end

        # Initializes tickless timing (no-op).
        #
        # Tickless mode requires no timing parameter calculation or setup.
        #
        # @return [void]
        # @api private
        private def _init_timing
        end

        # Resets position to nil (before first event).
        #
        # Sets position to nil, indicating sequencer has not yet reached any
        # scheduled event. First tick will advance to first scheduled position.
        #
        # @return [void]
        # @api private
        private def _reset_timing
          @position = nil
        end

        # Returns position unchanged (no quantization).
        #
        # Tickless mode preserves exact Rational positions without rounding.
        # The warn parameter is ignored (included for interface compatibility
        # with tick-based mode).
        #
        # @param position [Rational] position to pass through
        # @param warn [Boolean] ignored (for compatibility)
        #
        # @return [Rational] exact position unchanged
        #
        # @api private
        private def _quantize_position(position, warn: false)
          position
        end
      end
    end
  end
end
