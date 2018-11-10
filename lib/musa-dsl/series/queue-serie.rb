module Musa
  module Series
    def QUEUE(*series)
      QueueSerie.new(series)
    end

    class QueueSerie
      include Serie

      attr_reader :targets, :target

      def initialize(series)
        @targets = series.clone
        @targets ||= []

        _restart
      end

      def <<(serie)
        @targets << serie
        check_current
        self
      end

      def clear
        @targets.clear
        restart
        self
      end

      def _restart
        @index = -1
        forward
      end

      def _next_value
        value = nil

        if @target
          value = @target.next_value

          if value.nil?
            forward
            value = next_value
          end
        end

        value
      end

      def infinite?
        !!@targets.find(&:infinite?)
      end

      def deterministic?
        !@targets.find() { |t| !t.deterministic? }
      end

      private

      def forward
        @index += 1
        @target = nil
        @target = @targets[@index].restart if @index < @targets.size
      end

      def check_current
        @target = @targets[@index].restart unless @target
      end

      def method_missing(method_name, *args, **key_args, &block)
        if @target && @target.respond_to?(method_name)
          @target.send_nice method_name, *args, **key_args, &block
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private)
        @target && @target.respond_to?(method_name, include_private) # || super
      end
    end
  end

  module SerieOperations
    def queued
      Series::QueueSerie.new [self]
    end
  end
end
