module Musa
  module Sequencer
    class BaseSequencer
      module TicklessBasedTiming

        attr_reader :position

        def ticks_per_bar
          Float::INFINITY
        end

        def tick_duration
          0r
        end

        # TODO implementar hold_public_ticks adaptado a modo tickless para permitir que una operación de asignación de
        # TODO posición con .position = X, finalice antes de comenzar a procesar el resto de ticks en un contexto multithread.
        # TODO pero tiene sentido cuando el modo tickless se usa SOLO con .run?
        # TODO tendría sentido sólo si también se usa con ticks temporizados, lo cual ocurriría si se reimplementa el modo tickbased
        # TODO a partir del modo tickless.

        def tick
          _tick @position_mutex.synchronize { @position = @timeslots.first_after(@position) }
        end

        # TODO puede pensarse que un sequencer tickbased es como un ticklessbased en que cada tick se aavanza el position en 1 / ticks_per_bar
        # TODO esto haría que los eventos que cayeran en posiciones no cuantizadas por la resolución en ticks_per_bar se ejecutarían en el siguiente
        # TODO lo cual sería una ventaja porque eliminaría la necesidad de cuantizar en el _at.
        # TODO Por otro lado cuando se cuantiza en _at se redondea al más cercano, mientras que el modelo basado en avanzar redondea siempre hacia arriba,
        # TODO pero esto podría resolverse con una opción de cuantización opcional que en _at ajustara la posición a la más cercana.

        def position=(new_position)
          raise ArgumentError, "Sequencer #{self}: cannot move back. current position: #{@position} new position: #{new_position}" if new_position < @position

          @on_fast_forward.each { |block| block.call(true) }

          loop do
            next_position = nil

            @position_mutex.synchronize do
              next_position = @timeslots.first_after(@position)
            end

            if next_position <= new_position
              _tick next_position
            else
              break
            end
          end

          @position = new_position

          @on_fast_forward.each { |block| block.call(false) }
        end

        private def _init_timing
        end

        private def _reset_timing
          @position = nil
        end

        private def _quantize_position(position, warn: false)
          position
        end
      end
    end
  end
end
