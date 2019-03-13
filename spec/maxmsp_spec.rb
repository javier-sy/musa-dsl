require 'spec_helper'

require 'musa-dsl'

require 'osc-ruby'

class Musa::Max

  def initialize(host, port, prefix_id = nil)
    @client = OSC::Client.new(host, port)
    @prefix_id = prefix_id
    @id = 0

    @factory = MaxObjectFactory.new(self)

    init
    clear
  end

  attr_reader :factory

  def send(*values)
    @client.send OSC::Message.new(*values)
  end

  def init
    send '/initialize'
  end

  def clear
    send '/clear'
  end

  attr_reader :prefix_id

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

  class Toggle < MaxObject
    max_class 'toggle'
    def_messages :bang
    def_inlets :in
    def_outlets :out
  end

  class Dac_ < MaxObject
    max_class 'dac~', as: 'dac_'
    def_messages :start, :stop

    attr_reader :channels, :in

    def initialize(max, *channels)
      @channels = []
      channels.each_index { |position| @channels[position] = Inlet.new(self, position, control: (position == 0), signal: true) }
      @in = @channels[0]
      super
    end
  end

  class Cycle_ < MaxObject
    max_class 'cycle~', as: 'cycle_'
    def_inlets :in
    def_outlets :out, signal: true
  end

  class Multiply_ < MaxObject
    max_class '*~', as: 'multiply_'
    def_inlets :a, :b, signal: true
    def_outlets :out, signal: true
  end

  class Sig_ < MaxObject
    max_class 'sig~', as: 'sig_'
    def_inlets :in
    def_outlets :out, signal: true
  end
end

RSpec.describe Musa::Max do
  context 'Communication with Max' do
    it 'Simple selection 1' do

      max = Musa::Max.new('localhost', 9000).factory


      t = max.toggle
      dac = max.dac_ 1, 2

      t.out.connect to: dac.in

      c = max.cycle_ 1000
      m = max.multiply_ 0.05

      c.out.connect to: m.a

      m.out.connect to: dac.channels[0]
      m.out.connect to: dac.channels[1]

      t.bang

      sleep 3

      c2 = max.cycle_ 2300
      m2 = max.multiply_ 0.002

      c2.out.connect to: m2.a
      m2.out.connect to: m.a

      sleep 3

      t.bang


      #m = max.message 100
      #c = max.number

      #b.connect to: m
      #m.connect to: c



    end
  end
end
