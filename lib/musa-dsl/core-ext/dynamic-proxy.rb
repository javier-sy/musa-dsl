module Musa
  module Extension
    # Module providing dynamic proxy pattern implementation.
    #
    # DynamicProxy allows creating objects that forward all method calls to a
    # receiver object, which can be set/changed dynamically. This is useful for
    # lazy initialization, placeholder objects, and delegation patterns.
    #
    # ## Features
    #
    # - Transparent method forwarding via method_missing
    # - Dynamic receiver assignment
    # - Type checking delegation (is_a?, kind_of?, instance_of?)
    # - Equality delegation (==, eql?)
    # - Safe handling when receiver is nil
    #
    # @example Basic usage
    #   proxy = Musa::Extension::DynamicProxy::DynamicProxy.new
    #   proxy.receiver = "Hello"
    #   proxy.upcase  # => "HELLO" (forwarded to String)
    #
    # @example Lazy initialization
    #   proxy = DynamicProxy.new
    #   # ... later ...
    #   proxy.receiver = expensive_object
    #   proxy.some_method  # Now forwards to expensive_object
    module DynamicProxy
      # Mixin module providing dynamic proxy behavior.
      #
      # This module can be included in classes to add proxy capabilities.
      # Requires an @receiver instance variable to be set.
      module DynamicProxyModule
        # Forwards unknown methods to the receiver.
        #
        # @raise [NoMethodError] if @receiver is nil or doesn't respond to method.
        def method_missing(method_name, *args, **key_args, &block)
          raise NoMethodError, "Method '#{method_name}' is unknown because self is a DynamicProxy with undefined receiver" unless @receiver

          if @receiver.respond_to? method_name
            @receiver.send method_name, *args, **key_args, &block
          else
            super
          end
        end

        # Declares which methods the proxy responds to.
        #
        # @return [Boolean] true if receiver responds to method, false otherwise.
        def respond_to_missing?(method_name, include_private)
          @receiver&.respond_to?(method_name, include_private) || super
        end

        # Checks if the proxy has a receiver assigned.
        #
        # @return [Boolean] true if @receiver is not nil.
        def has_receiver?
          !@receiver.nil?
        end

        # Preserve original is_a? for internal use
        alias _is_a? is_a?

        # Delegates is_a? check to receiver or uses original.
        #
        # @param klass [Class] class to check against.
        # @return [Boolean] true if proxy or receiver is instance of klass.
        def is_a?(klass)
          _is_a?(klass) || @receiver&.is_a?(klass)
        end

        # Preserve original kind_of? for internal use
        alias _kind_of? kind_of?

        # Delegates kind_of? check to receiver or uses original.
        #
        # @param klass [Class] class to check against.
        # @return [Boolean] true if proxy or receiver is kind of klass.
        def kind_of?(klass)
          _kind_of?(klass) || @receiver&.is_a?(klass)
        end

        # Preserve original instance_of? for internal use
        alias _instance_of? instance_of?

        # Delegates instance_of? check to receiver or uses original.
        #
        # @param klass [Class] class to check against.
        # @return [Boolean] true if proxy or receiver is instance of klass.
        def instance_of?(klass)
          _instance_of?(klass) || @receiver&.instance_of?(klass)
        end

        # Preserve original == for internal use
        alias _equalequal ==

        # Delegates equality check to receiver or uses original.
        #
        # @param object [Object] object to compare with.
        # @return [Boolean] true if proxy or receiver equals object.
        def ==(object)
          _equalequal(object) || @receiver&.==(object)
        end

        # Preserve original eql? for internal use
        alias _eql? eql?

        # Delegates eql? check to receiver or uses original.
        #
        # @param object [Object] object to compare with.
        # @return [Boolean] true if proxy or receiver eql? object.
        def eql?(object)
          _eql?(object) || @receiver&.eql?(object)
        end
      end

      # Concrete DynamicProxy class ready for instantiation.
      #
      # @example
      #   proxy = DynamicProxy.new
      #   proxy.receiver = [1, 2, 3]
      #   proxy.size      # => 3
      #   proxy.first     # => 1
      #   proxy.is_a?(Array)  # => true
      class DynamicProxy
        include DynamicProxyModule

        # Creates a new dynamic proxy.
        #
        # @param receiver [Object, nil] optional initial receiver object.
        def initialize(receiver = nil)
          @receiver = receiver
        end

        # The object to which methods are delegated.
        #
        # @return [Object, nil] current receiver.
        attr_accessor :receiver
      end
    end
  end
end
