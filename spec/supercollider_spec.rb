require 'spec_helper'

require 'musa-dsl'

require 'fast_osc'

class Musa::Supercollider

  def initialize(host, port)
    @supercollider = IO.popen(
        ['/Applications/SuperCollider/SuperCollider.app/Contents/Resources/scsynth',
         '-u', port.to_s,
         '-H', 'H and F Series Multi Track Usb Audio'],
        mode: 'r',
        err: :out)

    thread = Thread.current

    Thread.new do
      loop do
        puts s = @supercollider.gets.strip
        thread.wakeup if s == 'SuperCollider 3 server ready.'
      end
    end

    Thread.stop

    @client = UDPSocket.new
    @client.connect host, port

    @waiting_threads = {}

    Thread.new do
      loop do
        message, parameters = decode(@client.recvmsg()[0])
        thread = @waiting_threads[message]

        if thread
          @waiting_threads[message] = parameters
          thread.wakeup
        end
      end
    end

    @id = 0
  end

  def encode(message, parameters)
    FastOsc.encode_single_message(message, parameters)
  end

  def decode(osc_message)
    FastOsc.decode_single_message(osc_message)
  end

  def send(message, *parameters, wait: nil, then: nil)
    @client.send encode(message, parameters), 0
    wait wait if wait
  end

  def wait(message)
    @waiting_threads[message] = Thread.current
    Thread.stop
    @waiting_threads.delete message
  end

  def quit
    send '/quit'
  end

  def status
    send '/status', wait: '/status.reply'
  end

  def version
    send '/version', wait: '/version.reply'
  end

  def sync
    send '/sync', wait: '/synced'
  end

  def dumpOSC(code)
    send '/dumpOSC', code
  end

  def notify(value)
    send '/notify', value
  end

  def next_id
    @id += 1
  end

  class MaxObjectFactory

    class << self
      def register(name, clazz)
        define_method name do |*parameters, **key_parameters|
          clazz.new @max, *parameters, **key_parameters
        end
      end
    end

    def initialize(max)
      @max = max
    end
  end

  class MaxObject

    class << self
      def max_class(name, as: nil)
        as ||= name
        @max_class_name = name
        MaxObjectFactory.register as.intern, self
      end

      attr_reader :max_class_name

      def def_messages(*messages)
        messages.each do |message|
          define_method message do
            self.message message
          end
        end
      end

      # TODO hacer un constructor que haga estos define_method en una sola pasada con contenido simplificado?

      def def_inlets(*inlets, control: nil, signal: nil)
        signal ||= false
        control ||= !signal

        @inlets_count ||= -1
        inlets.each do |name|
          position = @inlets_count += 1
          define_method name do
            @inlets ||= {}
            @inlets[name] ||= Inlet.new(self, position, control: control, signal: signal)
          end
        end
      end

      def def_outlets(*outlets, signal: nil)
        signal ||= false

        @outlets_count ||= -1
        outlets.each do |name|
          position = @outlets_count += 1
          define_method name do
            @outlets ||= {}
            @outlets[name] ||= Outlet.new(self, position, control: !signal, signal: signal)
          end
        end
      end
    end

    attr_reader :max
    attr_reader :max_id

    attr_reader :default_inlet, :default_outlet

    def initialize(max, *parameters, **key_parameters)
      @max = max
      @id = max.next_id
      @max_id = "#{max.prefix_id}_#{self.class.name}_#{@id}"

      @max.send '/create', @max_id, self.class.max_class_name, *parameters, *key_parameters.collect { |k, v| ["@#{k}", v] }.flatten
    end

    def remove
      @max.send '/remove', @max_id
    end

    def message(message)
      @max.send '/message', @max_id, message.to_s
    end

    class Port
      attr_reader :object
      attr_reader :position

      def initialize(object, position, control:, signal:)
        @object = object
        @position = position
        @control = control
        @signal = signal
      end

      def signal?
        @signal ? true : false
      end

      def control?
        @control ? false : true
      end
    end

    class Inlet < Port
      def connect(from:)
        raise ArgumentError, 'Cannot connect inlet to inlet' unless from.is_a?(Outlet)
        raise ArgumentError, 'Cannot connect different kind of ports. Verify signal/control kind.' unless signal? == from.signal? || control? == from.control?

        @object.max.send '/connect', from.object.max_id, from.position, @object.max_id, @position
      end

      def disconnect(from:)
        # TODO
      end
    end

    class Outlet < Port
      def connect(to:)
        raise ArgumentError, 'Cannot connect outlet to outlet' unless to.is_a?(Inlet)
        raise ArgumentError, 'Cannot connect different kind of ports. Verify signal/control kind.' unless signal? == to.signal? || control? == to.control?

        @object.max.send '/connect', @object.max_id, @position, to.object.max_id, to.position
      end

      def disconnect(to:)
        # TODO
      end
    end
  end

  class Button < MaxObject
    max_class 'button'
    def_messages :bang
    def_inlets :in
    def_outlets :out
  end

  class Cycle_ < MaxObject
    max_class 'cycle~', as: 'cycle_'
    def_inlets :in
    def_outlets :out, signal: true
  end
end

RSpec.describe Musa::Supercollider do
  context 'Communication with Supercollider' do
    it 'Simple selection 1' do

      sc = Musa::Supercollider.new('localhost', 9000)

      puts "sc.status = #{sc.status}"
      puts "sc.version = #{sc.version}"

      sc.sync

      sleep 3

      sc.quit


    end
  end
end
