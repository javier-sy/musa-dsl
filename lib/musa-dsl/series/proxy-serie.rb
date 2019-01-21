module Musa
  module Series
    # TODO: adapt to series prototyping

    def PROXY(serie = nil)
      ProxySerie.new(serie)
    end

    class ProxySerie
      include Serie

      attr_reader :target

      def initialize(serie)
        @target = serie.instance if serie
        mark_as_instance!
      end

      def target=(target)
        @target = target.instance
      end

      def _prototype
        raise PrototypingSerieError, 'Cannot get prototype of a proxy serie'
      end

      def restart
        @target.restart if @target
      end

      def current_value
        @target.current_value if @target
      end

      def next_value
        @target.next_value if @target
      end

      def peek_next_value
        @target.peek_next_value if @target
      end

      def infinite?
        @target.infinite? if @target
      end

      private

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
    # TODO add test case
    def proxied
      Series::ProxySerie.new self
    end
  end
end
