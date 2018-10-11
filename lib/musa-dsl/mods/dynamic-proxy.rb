require_relative 'send-nice'

class DynamicProxy
  def initialize(receiver)
    @receiver = receiver
  end

  attr_writer :receiver

  attr_reader :receiver

  def method_missing(method_name, *args, **key_args, &block)
    if @receiver.respond_to? method_name
      @receiver._send_nice method_name, args, key_args, &block
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private)
    @receiver.respond_to?(method_name, include_private) || super
  end

  alias _is_a? is_a?

  def is_a?(klass)
    _is_a?(klass) || @receiver.is_a?(klass)
  end

  alias _kind_of? kind_of?

  def kind_of?(klass)
    _kind_of?(klass) || @receiver.is_a?(klass)
  end

  alias _instance_of? instance_of?

  def instance_of?(klass)
    _instance_of?(klass) || @receiver.instance_of?(klass)
  end

  alias _equalequal ==

  def ==(object)
    _equalequal(object) || @receiver.==(object)
  end

  alias _eql? eql?

  def eql?(object)
    _eql?(object) || @receiver.eql?(object)
  end
end
