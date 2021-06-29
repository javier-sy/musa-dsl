require_relative 'base-series'

module Musa
  module Series::Constructors
    def PROXY(serie = nil)
      ProxySerie.new(serie)
    end

    class ProxySerie
      include Series::Serie.with(source: true)

      def initialize(serie)
        self.source = serie
        init
      end

      private def _restart
        @source.restart if @source
      end

      private def _next_value
        @source.next_value if @source
      end

      def infinite?
        @source.infinite? if @source
      end

      private def method_missing(method_name, *args, **key_args, &block)
        if @source && @source.respond_to?(method_name)
          @source.send method_name, *args, **key_args, &block
        else
          super
        end
      end

      private def respond_to_missing?(method_name, include_private)
        @source && @source.respond_to?(method_name, include_private) # || super
      end
    end
  end

  module Series::Operations
    # TODO add test case
    def proxy
      Series::ProxySerie.new(self)
    end
  end
end
