#
# @api public
require_relative 'base-series'

module Musa
  module Series::Constructors
    # Creates a proxy serie with optional initial source.
    #
    # Proxy series enable late binding - creating a serie placeholder that will
    # be resolved later. Useful for:
    #
    # ## Use Cases
    #
    # - **Forward references**: Reference series before definition
    # - **Circular structures**: Self-referential or mutually referential series
    # - **Dependency injection**: Define structure, inject source later
    # - **Dynamic routing**: Change source serie at runtime
    #
    # ## Method Delegation
    #
    # Proxy delegates all methods to underlying source via method_missing,
    # making it transparent proxy for most operations.
    #
    # ## State Resolution
    #
    # Proxy starts in :undefined state, becomes :prototype/:instance when
    # source is set and resolved.
    #
    # @param serie [Serie, nil] initial source serie (default: nil)
    #
    # @return [ProxySerie] proxy serie
    #
    # @example Forward reference
    #   proxy = PROXY()
    #   proxy.undefined?  # => true
    #
    #   # Define later
    #   proxy.proxy_source = S(1, 2, 3)
    #   proxy.prototype?  # => true
    #
    # @example Circular structure
    #   loop_serie = PROXY()
    #   sequence = S(1, 2, 3).after(loop_serie)
    #   loop_serie.proxy_source = sequence
    #   # Creates infinite loop: 1, 2, 3, 1, 2, 3, ...
    #
    # @example With initial source
    #   proxy = PROXY(S(1, 2, 3))
    #
    # @api public
    def PROXY(serie = nil)
      ProxySerie.new(serie)
    end

    # Proxy/wrapper serie that delegates to another serie.
    #
    # Acts as transparent proxy forwarding all method calls to the wrapped
    # serie. Useful for lazy evaluation, conditional serie switching, or
    # adding indirection layer.
    #
    # The proxy can be reassigned to a different serie dynamically by
    # changing the `proxy_source` attribute.
    #
    # @example Basic proxy
    #   original = FromArray.new([1, 2, 3])
    #   proxy = ProxySerie.new(original)
    #   proxy.next_value  # => 1 (delegates to original)
    #
    # @example Dynamic serie switching
    #   proxy = ProxySerie.new(serie_a)
    #   proxy.next_value  # Uses serie_a
    #   proxy.proxy_source = serie_b
    #   proxy.next_value  # Now uses serie_b
    #
    # @api private
    class ProxySerie
      include Series::Serie::Base
      include Series::Serie::WithSource

      alias proxy_source source
      alias proxy_source= source=

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
