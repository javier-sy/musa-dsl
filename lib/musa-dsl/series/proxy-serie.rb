require_relative 'base-series'

module Musa
  module Series::Constructors
    def PROXY(serie = nil)
      ProxySerie.new(serie)
    end

    class ProxySerie
      include Series::Serie.with(source: true, source_as: :proxy_source)

      def initialize(serie)
        self.proxy_source = serie
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
        if @source
          if @source.respond_to?(method_name)
            @source.send method_name, *args, **key_args, &block
          else
            raise NoMethodError, "undefined method '#{method_name}' for proxied #{@source.to_s}"
          end
        else
          super
        end
      end

      private def respond_to_missing?(method_name, include_private)
        @source && @source.respond_to?(method_name, include_private) # || super ??
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
