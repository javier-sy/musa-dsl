# Proxy serie providing late binding and method delegation.
#
# Proxy series enable late binding - creating serie placeholder that will
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
# @api public
require_relative 'base-series'

module Musa
  module Series::Constructors
    # Creates proxy serie with optional initial source.
    #
    # @param serie [Serie, nil] initial source serie (default: nil)
    #
    # @return [ProxySerie] proxy serie
    #
    # @example Empty proxy
    #   proxy = PROXY()
    #   # Assign later: proxy.proxy_source = S(1, 2, 3)
    #
    # @example With initial source
    #   proxy = PROXY(S(1, 2, 3))
    #
    # @api public
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
