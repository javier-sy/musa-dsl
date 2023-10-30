module Musa
  module Sequencer
    class BaseSequencer
      module TickBasedTiming
        using Musa::Extension::InspectNice

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

        private def _init_timing
          @ticks_per_bar = Rational(beats_per_bar * ticks_per_beat)
          @tick_duration = Rational(1, @ticks_per_bar)

          @hold_public_ticks = false
          @hold_ticks = 0
        end

        private def _reset_timing
          @position = @position_mutex.synchronize { 1r + @offset - @tick_duration }
        end

        private def _quantize_position(position, warn: true)
          ticks_position = position / @tick_duration

          if ticks_position.round != ticks_position
            original_position = position
            position = ticks_position.round * @tick_duration

            if warn
              @logger.warn('BaseSequencer') do
                '_check_position: rounding ' \
                  "position #{original_position.inspect} (#{original_position.to_f.round(5)}) "\
                  "to tick precision: #{position.inspect} (#{position.to_f.round(5)})"
              end
            end
          end

          position
        end

        private def _hold_public_ticks
          @hold_public_ticks = true
        end

        private def _release_public_ticks
          @hold_ticks.times { _tick(@position_mutex.synchronize { @position += @tick_duration }) }
          @hold_ticks = 0
          @hold_public_ticks = false
        end
      end
    end
  end
end
