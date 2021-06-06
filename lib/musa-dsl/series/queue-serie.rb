require_relative 'base-series'

module Musa
  module Series::Constructors
    def QUEUE(*series)
      QueueSerie.new(series)
    end

    class QueueSerie
      include Series::Serie

      attr_reader :sources

      def initialize(series)
        @sources = if series[0].prototype?
                     series.collect(&:prototype).freeze
                   else
                     series.collect(&:instance)
                   end

        _restart false

        mark_regarding! @sources[0]
      end

      def <<(serie)
        # when queue is a prototype it is also frozen so no serie can be added (it would raise an Exception if tried).
        # when queue is an instance the added serie should also be an instance (raise an Exception otherwise)
        #
        raise ArgumentError, "Only an instance serie can be queued" unless serie.instance?

        @sources << serie
        check_current
        self
      end

      def clear
        # only instance queue can be cleared
        #
        @sources.clear
        restart
        self
      end

      def _restart(restart_sources = true)
        @index = -1
        forward if restart_sources
      end

      def _next_value
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

      private

      def forward
        @index += 1
        @current = @sources[@index]&.restart
      end

      def check_current
        @current = @sources[@index].restart unless @current
      end

      def method_missing(method_name, *args, **key_args, &block)
        if @current&.respond_to?(method_name)
          @current.send method_name, *args, **key_args, &block
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private)
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
