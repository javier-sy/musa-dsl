module Musa
  module Extension
    module DynamicProxy
      module DynamicProxyModule
        def method_missing(method_name, *args, **key_args, &block)
          raise NoMethodError, "Method '#{method_name}' is unknown because self is a DynamicProxy with undefined receiver" unless @receiver

          if @receiver.respond_to? method_name
            @receiver.send method_name, *args, **key_args, &block
          else
            super
          end
        end

        def respond_to_missing?(method_name, include_private)
          @receiver&.respond_to?(method_name, include_private) || super
        end

        def has_receiver?
          !@receiver.nil?
        end

        alias _is_a? is_a?

        def is_a?(klass)
          _is_a?(klass) || @receiver&.is_a?(klass)
        end

        alias _kind_of? kind_of?

        def kind_of?(klass)
          _kind_of?(klass) || @receiver&.is_a?(klass)
        end

        alias _instance_of? instance_of?

        def instance_of?(klass)
          _instance_of?(klass) || @receiver&.instance_of?(klass)
        end

        alias _equalequal ==

        def ==(object)
          _equalequal(object) || @receiver&.==(object)
        end

        alias _eql? eql?

        def eql?(object)
          _eql?(object) || @receiver&.eql?(object)
        end
      end

      class DynamicProxy
        include DynamicProxyModule

        def initialize(receiver = nil)
          @receiver = receiver
        end

        attr_accessor :receiver
      end
    end
  end
end
