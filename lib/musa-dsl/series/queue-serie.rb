require_relative 'base-series'

module Musa
  module Series::Constructors
    def QUEUE(*series)
      QueueSerie.new(series)
    end

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
