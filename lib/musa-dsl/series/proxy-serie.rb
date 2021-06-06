require_relative 'base-series'

module Musa
  module Series::Constructors
    def PROXY(serie = nil)
      ProxySerie.new(serie)
    end

    class ProxySerie
      include Series::Serie

      attr_reader :source

      def initialize(serie)
        @source = serie

        if @source
          mark_regarding! @source
        else
          mark_as_prototype!
        end
      end

      def source=(source)
        # when proxy is a prototype it is also frozen so we cannot change the source (it will raise an exception).
        # when proxy is an instance the only kind of source that can be assigned is also an instance (otherwise will raise an exception)
        #
        raise ArgumentError, "Only an instance serie can be proxied when the proxy is an instance" unless source.instance?
        @source = source
      end

      def _restart
        @source.restart if @source
      end

      def _next_value
        @source.next_value if @source
      end

      def infinite?
        @source.infinite? if @source
      end

      private

      def method_missing(method_name, *args, **key_args, &block)
        if @source && @source.respond_to?(method_name)
          @source.send method_name, *args, **key_args, &block
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private)
        @source && @source.respond_to?(method_name, include_private) # || super
      end
    end
  end

  module Series::Operations
    # TODO add test case
    def proxy
      Series::ProxySerie.new self
    end
  end
end
