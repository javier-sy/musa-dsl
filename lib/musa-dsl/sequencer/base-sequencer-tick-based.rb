module Musa
  module Sequencer
    class BaseSequencer
      module TickBasedTiming

        attr_reader :position, :ticks_per_bar, :tick_duration

        def tick
          if @hold_public_ticks
            @hold_ticks += 1
          else
            _tick @position_mutex.synchronize { @position += @tick_duration }
          end
        end

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

        private

        def _init_timing
          @ticks_per_bar = Rational(beats_per_bar * ticks_per_beat)
          @tick_duration = Rational(1, @ticks_per_bar)
        end

        def _reset_timing
          @position = @position_mutex.synchronize { 1r - @tick_duration }
        end

        def _check_position(position)
          ticks_position = position / @tick_duration

          if ticks_position.round != ticks_position
            original_position = position
            position = ticks_position.round * @tick_duration

            if @do_log
              _log "BaseSequencer._numeric_at: warning: rounding "\
                  "position #{position} (#{original_position.to_f.round(5)}) "\
                  "to tick precision: #{position} (#{position.to_f.round(5)})"
            end
          end

          position
        end

        def _quantize(position)
          (position / @tick_duration).round * @tick_duration
        end

        def _hold_public_ticks
          @hold_public_ticks = true
        end

        def _release_public_ticks
          @hold_ticks.times { _tick(@position_mutex.synchronize { @position += @tick_duration }) }
          @hold_ticks = 0
          @hold_public_ticks = false
        end
      end
    end
  end
end
