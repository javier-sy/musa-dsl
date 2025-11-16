# Queue serie for dynamic series concatenation.
#
# Queue allows adding series dynamically during playback, creating flexible
# sequential playback with runtime modification.
#
# ## Features
#
# - **Dynamic addition**: Add series with `<<` during playback
# - **Sequential playback**: Plays series in queue order
# - **Method delegation**: Delegates methods to current serie
# - **Clear**: Can clear queue and reset
#
# ## Use Cases
#
# - Interactive sequencing with user input
# - Dynamic phrase assembly
# - Playlist-style serie management
# - Reactive composition systems
# - Live coding pattern queuing
#
# @example Basic queue
#   queue = QUEUE(S(1, 2, 3)).i
#   queue.next_value  # => 1
#   queue << S(4, 5, 6).i  # Add dynamically
#   queue.to_a  # => [2, 3, 4, 5, 6]
#
# @example Dynamic playlist
#   queue = QUEUE().i
#   queue << melody1.i
#   queue << melody2.i
#   # Plays melody1 then melody2
#
# @api public
require_relative 'base-series'

module Musa
  module Series::Constructors
    # Creates queue serie from initial series.
    #
    # @param series [Array<Serie>] initial series in queue
    #
    # @return [QueueSerie] queue serie
    #
    # @example Create queue
    #   queue = QUEUE(S(1, 2), S(3, 4))
    #   queue.i.to_a  # => [1, 2, 3, 4]
    #
    # @api public
    def QUEUE(*series)
      QueueSerie.new(series)
    end

    # Serie that processes multiple source series in queue/sequence fashion.
    #
    # Combines multiple series by playing them sequentially - when one
    # series exhausts, moves to the next. New series can be added dynamically
    # with `<<` operator.
    #
    # All queued series must be instances (not prototypes). The queue can
    # be cleared with `clear` method.
    #
    # @example Sequential series playback
    #   serie_a = FromArray.new([1, 2, 3]).instance
    #   serie_b = FromArray.new([4, 5, 6]).instance
    #   queue = QueueSerie.new([serie_a, serie_b])
    #   queue.next_value  # => 1
    #   queue.next_value  # => 2
    #   queue.next_value  # => 3
    #   queue.next_value  # => 4 (switches to serie_b)
    #
    # @example Dynamic queueing
    #   queue = QueueSerie.new([serie_a]).instance
    #   queue << serie_b  # Add series on the fly
    #   queue.clear       # Empty the queue
    #
    # @api private
    class QueueSerie
      include Series::Serie.with(sources: true)

      def initialize(series)
        self.sources = series
        init
      end

      def <<(serie)
        # when queue is a prototype it is also frozen so no serie can be added (it would raise an Exception if tried).
        # when queue is an instance the added serie should also be an instance (raise an Exception otherwise)
        #
        raise ArgumentError, "Only an instance serie can be queued" unless serie.instance?

        @sources << serie
        @current ||= @sources[@index]

        self
      end

      def clear
        @sources.clear
        init
        self
      end

      private def _init
        @index = 0
        @current = @sources[@index]
        @restart_sources = false
      end

      private def _restart
        @current.restart
        @restart_sources = true
      end

      private def _next_value
        value = nil

        if @current
          value = @current.next_value

          if value.nil?
            forward
            value = next_value
          end
        end

        value
      end

      def infinite?
        !!@sources.find(&:infinite?)
      end

      private def forward
        @index += 1
        @current = @sources[@index]
        @current&.restart if @restart_sources
      end

      private def method_missing(method_name, *args, **key_args, &block)
        if @current&.respond_to?(method_name)
          @current.send method_name, *args, **key_args, &block
        else
          super
        end
      end

      private def respond_to_missing?(method_name, include_private)
        @current&.respond_to?(method_name, include_private) # || super
      end
    end
  end

  module Series::Operations
    def queued
      Series::Constructors.QUEUE(self)
    end
  end
end
