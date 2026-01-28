module Musa
  module Sequencer
    class BaseSequencer
      # Tick-based timing implementation for BaseSequencer.
      #
      # TickBasedTiming provides quantized time progression where time advances
      # in discrete tick increments. Musical time is divided into bars, beats,
      # and ticks, with position rounded to the nearest tick boundary. This
      # provides a traditional sequencer timing model similar to DAWs and MIDI
      # sequencers.
      #
      # ## Tick-Based Time Model
      #
      # Time is quantized to a grid determined by:
      #
      # - **beats_per_bar**: Time signature numerator (e.g., 4 for 4/4)
      # - **ticks_per_beat**: Subdivisions per beat (resolution)
      # - **ticks_per_bar**: Total ticks = beats_per_bar × ticks_per_beat
      # - **tick_duration**: 1 / ticks_per_bar (Rational)
      #
      # Position always aligns to tick boundaries. Non-aligned positions are
      # rounded with a warning.
      #
      # ## Time Progression
      #
      # - **Forward only**: Position cannot decrease (enforced)
      # - **Tick advancement**: {#tick} increments by tick_duration
      # - **Fast-forward**: {#position=} jumps to future position
      # - **Quantization**: All positions rounded to tick grid
      #
      # ## Fast-Forward Mechanism
      #
      # When jumping forward via `position=`:
      # 1. Triggers on_fast_forward callbacks with `true`
      # 2. Ticks forward until reaching target position
      # 3. Triggers on_fast_forward callbacks with `false`
      # 4. Allows event handlers to skip/optimize during jumps
      #
      # ## Musical Applications
      #
      # - Traditional MIDI sequencing with quantized timing
      # - Grid-aligned rhythmic patterns
      # - Time signature-based composition (4/4, 3/4, etc.)
      # - Tick-precise event scheduling
      #
      # @example Creating tick-based sequencer (4/4, 96 ticks per beat)
      #   sequencer = BaseSequencer.new(4, 96)  # 4 beats, 96 ticks/beat
      #   sequencer.ticks_per_bar  # => 384r
      #   sequencer.tick_duration  # => 1/384r
      #   sequencer.position       # => 1r (start of bar 1)
      #
      # @example Advancing time with tick
      #   sequencer.tick  # Advance one tick (1/384 of a bar)
      #   sequencer.position  # => 385/384r
      #
      # @example Fast-forward to future position
      #   sequencer.position = 2r  # Jump to bar 2
      #   # Triggers on_fast_forward(true), ticks forward, on_fast_forward(false)
      #
      # @example Quantization warning
      #   sequencer.at(1.5001r) { puts "event" }
      #   # WARN: rounding position 1.5001 to tick precision: 1.5
      #
      # @api private
      module TickBasedTiming
        using Musa::Extension::InspectNice

        # Current playback position in bars (Rational).
        #
        # Always aligned to tick boundaries. Bar 1 starts at position 1r.
        #
        # @return [Rational] current position
        attr_reader :position

        # Total ticks per bar (beats_per_bar × ticks_per_beat).
        #
        # @return [Rational] ticks per bar
        attr_reader :ticks_per_bar

        # Duration of one tick in bars (1 / ticks_per_bar).
        #
        # @return [Rational] tick duration
        attr_reader :tick_duration

        # Advances sequencer by one tick.
        #
        # Increments position by tick_duration and executes all events
        # scheduled at the new position. This is the primary time progression
        # method for tick-based sequencers.
        #
        # If ticks are held (during fast-forward), accumulates ticks in buffer
        # without executing events until released.
        #
        # @return [void]
        #
        # @example Normal tick progression
        #   sequencer.position  # => 1r
        #   sequencer.tick
        #   sequencer.position  # => 385/384r (1 + 1/384)
        #
        # @api public
        def tick
          if @hold_public_ticks
            @hold_ticks += 1
          else
            _tick @position_mutex.synchronize { @position += @tick_duration }
          end
        end

        # Fast-forwards sequencer to new position.
        #
        # Jumps to a future position by ticking forward until reaching the
        # target. Executes all scheduled events between current and target
        # positions. Triggers on_fast_forward callbacks to allow handlers
        # to optimize processing during the jump.
        #
        # Position can only move forward - attempting to move backward raises
        # ArgumentError. Position is automatically quantized to tick boundaries.
        #
        # ## Fast-Forward Process
        #
        # 1. Validates new_position >= current position
        # 2. Calls on_fast_forward callbacks with `true` (entering fast-forward)
        # 3. Holds public tick accumulation
        # 4. Ticks forward, executing events at each tick
        # 5. Releases accumulated ticks
        # 6. Calls on_fast_forward callbacks with `false` (exiting fast-forward)
        #
        # @param new_position [Rational] target position (must be >= current)
        #
        # @return [void]
        #
        # @raise [ArgumentError] if new_position < current position
        #
        # @example Jump to future bar
        #   sequencer.position  # => 1r
        #   sequencer.position = 5r  # Fast-forward to bar 5
        #   # Executes all events from bar 1 to bar 5
        #
        # @example Cannot move backward
        #   sequencer.position = 0r
        #   # => ArgumentError: cannot move back
        #
        # @api public
        def position=(new_position)
          raise ArgumentError,
                "Sequencer #{self}: cannot move back. current position: #{@position} new position: #{new_position}" \
                  if new_position < position

          _hold_public_ticks
          @on_fast_forward.each { |block| block.call(true) }

          _tick(@position_mutex.synchronize { @position += @tick_duration }) while @position < new_position

          @on_fast_forward.each { |block| block.call(false) }
          _release_public_ticks
        end

        # Initializes tick-based timing parameters.
        #
        # Calculates derived timing values from beats_per_bar and ticks_per_beat.
        #
        # @return [void]
        # @api private
        private def _init_timing
          @ticks_per_bar = Rational(beats_per_bar * ticks_per_beat)
          @tick_duration = Rational(1, @ticks_per_bar)

          @hold_public_ticks = false
          @hold_ticks = 0
        end

        # Resets position to start of first bar.
        #
        # Sets position to 1r + offset - tick_duration, so first tick brings
        # position to 1r + offset (start of bar 1).
        #
        # @return [void]
        # @api private
        private def _reset_timing
          @position = @position_mutex.synchronize { 1r + @offset - @tick_duration }
        end

        # Quantizes position to nearest tick boundary.
        #
        # Rounds non-aligned positions to the tick grid, optionally logging
        # a warning when rounding occurs. Ensures all positions align with
        # tick_duration increments for consistent timing.
        #
        # @param position [Rational] position to quantize
        # @param warn [Boolean] log warning if rounding occurs (default: true)
        #
        # @return [Rational] quantized position aligned to tick grid
        #
        # @example Quantization to tick boundaries
        #   # With 384 ticks per bar, tick_duration = 1/384r
        #   _quantize_position(1.5001r)  # => 1.5r (385/384 ticks)
        #   # Logs warning: "rounding position 1.5001 to tick precision: 1.5"
        #
        # @api private
        private def _quantize_position(position, warn: true)
          ticks_position = position / @tick_duration

          if ticks_position.round != ticks_position
            if warn
              @logger.warn('BaseSequencer') do
                '_check_position: rounding ' \
                  "position #{position.inspect} (#{position.to_f.round(5)}) "\
                  "to tick precision: #{(ticks_position.round * @tick_duration).inspect} (#{(ticks_position.round * @tick_duration).to_f.round(5)})"
              end
            end
          end

          # Always convert to Rational to ensure consistent hash key types
          # (Float keys like 1.5 would not match Rational keys like 3/2r in timeslots hash)
          ticks_position.round * @tick_duration
        end

        # Holds tick accumulation during fast-forward.
        #
        # Prevents immediate tick execution, buffering ticks for batch release.
        # Used during position= to collect ticks that occur during the jump.
        #
        # @return [void]
        # @api private
        private def _hold_public_ticks
          @hold_public_ticks = true
        end

        # Releases accumulated ticks after fast-forward.
        #
        # Executes all buffered ticks collected during hold period. Restores
        # normal tick processing.
        #
        # @return [void]
        # @api private
        private def _release_public_ticks
          @hold_ticks.times { _tick(@position_mutex.synchronize { @position += @tick_duration }) }
          @hold_ticks = 0
          @hold_public_ticks = false
        end
      end
    end
  end
end
