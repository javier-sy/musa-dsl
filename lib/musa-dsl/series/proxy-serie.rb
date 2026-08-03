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
    # ## Cycles
    #
    # A proxy that points back into the serie it is part of closes a cycle: the
    # material loops instead of ending. This has to be declared with
    # `cyclic: true`, because a cycle changes what every walk of the graph has to
    # do and should not appear by accident -- a proxy that closes one without
    # having been declared raises ArgumentError. The reverse is fine: declaring a
    # proxy cyclic and pointing it somewhere that does not loop back is exactly
    # the forward reference the declaration exists for.
    #
    # What a cycle is for is material whose repetition is not decided in advance:
    # a QUEUE fed while the loop is already sounding, an E() reading state that
    # changes between turns. For a serie that is fully known beforehand, `.repeat`
    # says the same thing without any of this.
    #
    # @param serie [Serie, nil] initial source serie (default: nil)
    # @param cyclic [Boolean, nil] whether this proxy may close a cycle
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
    #   loop_serie = PROXY(cyclic: true)
    #   sequence = S(1, 2, 3).after(loop_serie)
    #   loop_serie.proxy_source = sequence
    #
    #   # The circle closes, and the state of a cycle is the state of what feeds
    #   # it from outside -- here S(1, 2, 3), a prototype.
    #   sequence.state    # => :prototype
    #   loop_serie.state  # => :prototype
    #
    #   # It never runs out, and says so without walking round itself.
    #   sequence.infinite?  # => true
    #
    #   i = sequence.i
    #   9.times.collect { i.next_value }  # => [1, 2, 3, 1, 2, 3, 1, 2, 3]
    #
    # @example Two materials calling each other
    #   to_b = PROXY(cyclic: true)
    #   to_a = PROXY(cyclic: true)
    #
    #   a = S(1, 2).after(to_b)
    #   b = S(3, 4).after(to_a)
    #
    #   to_b.proxy_source = b
    #   to_a.proxy_source = a
    #
    #   i = a.i
    #   8.times.collect { i.next_value }  # => [1, 2, 3, 4, 1, 2, 3, 4]
    #
    # @example A cycle that comes back empty ends
    #   n = 0
    #   material = E(nil) { n += 1; n <= 3 ? n : nil }
    #
    #   back = PROXY(cyclic: true)
    #   cycle = material.after(back)
    #   back.proxy_source = cycle
    #
    #   # One turn per request: when the turn produces nothing, the loop is over
    #   # instead of spinning forever.
    #   i = cycle.i
    #   5.times.collect { i.next_value }  # => [1, 2, 3, nil, nil]
    #
    # @example With initial source
    #   PROXY(S(1, 2, 3)).i.to_a  # => [1, 2, 3]
    #
    # @api public
    def PROXY(serie = nil, cyclic: nil)
      ProxySerie.new(serie, cyclic: cyclic)
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
    #   proxy = ProxySerie.new(original).i
    #   proxy.next_value  # => 1 (delegates to original)
    #
    # @example Dynamic serie switching
    #   serie_a = S(1, 2, 3)
    #   serie_b = S(10, 20, 30)
    #   proxy = ProxySerie.new(serie_a).i
    #   proxy.next_value  # => 1
    #   proxy.proxy_source = serie_b.i
    #   proxy.next_value  # => 10
    #
    # @api private
    class ProxySerie
      include Series::Serie::Base
      include Series::Serie::WithSource

      alias proxy_source source

      # @param serie [Serie, nil] the serie this stands for
      # @param cyclic [Boolean, nil] whether this proxy is allowed to close a
      #   cycle. A proxy may be declared cyclic and not close one yet -- that is
      #   the whole point of a forward reference -- but a proxy that closes one
      #   without having been declared raises: a cycle changes what every other
      #   walk of the graph has to do, and it should not appear by accident.
      def initialize(serie = nil, cyclic: nil)
        @cyclic = !!cyclic
        self.proxy_source = serie
        init
      end

      # @return [Boolean] whether this proxy was declared able to close a cycle
      def cyclic?
        @cyclic
      end

      # @return [Boolean] whether it actually closes one. The declaration is a
      #   permission; this is the fact, and it is what every walk asks about.
      #
      #   Answered the first time it is asked, not when the source is assigned: a
      #   proxy can become part of a cycle that a later assignment somewhere else
      #   closes -- in A -> pB -> B -> pA -> A neither assignment sees the whole
      #   loop, only the second one does. By the time anyone walks the graph it is
      #   already built, so asking then gives the true answer.
      def closes_cycle?
        if @closes_cycle.nil?
          @closes_cycle = !@source.nil? && closes_cycle_through?(@source)
          raise ArgumentError, UNDECLARED_CYCLE if @closes_cycle && !@cyclic
        end

        @closes_cycle
      end

      # @return [Serie, nil] where the cycle continues
      def cycle_target
        @source
      end

      UNDECLARED_CYCLE =
        'This proxy closes a cycle and was not declared cyclic. ' \
        'Use PROXY(cyclic: true) to say so.'

      private_constant :UNDECLARED_CYCLE

      def source=(serie)
        @closes_cycle = nil

        raise ArgumentError, UNDECLARED_CYCLE if serie && !@cyclic && closes_cycle_through?(serie)

        super
      end

      alias proxy_source= source=

      # In cyclic mode the proxy restarts nothing: its source is the cycle it is
      # part of, and restarting it from here is restarting whoever is iterating.
      # The rewind is the outermost node's job, from its own frame.
      private def _restart
        return if closes_cycle?

        @source.restart if @source
      end

      private def _next_value
        return nil if @_delegating          # re-entry through the cycle: stop here

        @_delegating = true
        begin
          @source.next_value if @source
        ensure
          @_delegating = false
        end
      end

      # Cuts the structural walk: asking the source would go round the cycle.
      def infinite?
        check_state_permissions(allows_prototype: true)

        return true if closes_cycle?

        @source&.infinite? || false
      end

      # Does the graph hanging from `serie` come back to this proxy?
      #
      # @api private
      private def closes_cycle_through?(serie, visited = nil)
        visited ||= []
        return false if visited.any? { |seen| seen.equal?(serie) }
        return true if serie.equal?(self)

        visited << serie

        upstream = []
        upstream << serie.source if serie.respond_to?(:source)
        case (more = serie.respond_to?(:sources) ? serie.sources : nil)
        when Array then upstream.concat(more)
        when Hash then upstream.concat(more.values)
        end

        upstream.compact.any? { |up| closes_cycle_through?(up, visited) }
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
