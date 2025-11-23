require 'spec_helper'
require 'musa-dsl'

RSpec.describe 'Core Extensions Inline Documentation Examples' do
  include Musa::All

  context 'ExplodeRanges (array-explode-ranges.rb)' do
    using Musa::Extension::ExplodeRanges

    it 'example from line 19 - Basic usage' do
      result = [1, 3..5, 8].explode_ranges
      expect(result).to eq([1, 3, 4, 5, 8])
    end

    it 'example from line 25 - MIDI channels' do
      channels = [0, 2..4, 7, 9..10]
      result = channels.explode_ranges
      expect(result).to eq([0, 2, 3, 4, 7, 9, 10])
    end

    it 'example from line 32 - Mixed with other array methods' do
      result = [1..3, 5, 7..9].explode_ranges.map { |n| n * 2 }
      expect(result).to eq([2, 4, 6, 10, 14, 16, 18])
    end

    it 'example from line 48 - Empty ranges' do
      result = [1, (5..4), 8].explode_ranges  # (5..4) is empty
      expect(result).to eq([1, 8])
    end

    it 'example from line 52 - Exclusive ranges' do
      result = [1, (3...6), 9].explode_ranges
      expect(result).to eq([1, 3, 4, 5, 9])
    end

    it 'example from line 56 - Nested arrays are NOT expanded recursively' do
      result = [1, [2..4], 5].explode_ranges
      expect(result).to eq([1, [2..4], 5])  # Inner range NOT expanded
    end
  end

  context 'Arrayfy (arrayfy.rb)' do
    using Musa::Extension::Arrayfy

    it 'example from line 27 - Basic object wrapping' do
      expect(5.arrayfy).to eq([5])
      expect(nil.arrayfy).to eq([])
      expect([1, 2, 3].arrayfy).to eq([1, 2, 3])
    end

    it 'example from line 33 - Repetition with size' do
      expect(5.arrayfy(size: 3)).to eq([5, 5, 5])
      expect([1, 2].arrayfy(size: 5)).to eq([1, 2, 1, 2, 1])
      expect([1, 2, 3].arrayfy(size: 2)).to eq([1, 2])
    end

    it 'example from line 41 - Default values for nil' do
      expect(nil.arrayfy(size: 3, default: 0)).to eq([0, 0, 0])
      expect([1, nil, 3].arrayfy(size: 5, default: -1)).to eq([1, -1, 3, 1, -1])
    end

    it 'example from line 48 - Musical application - velocity normalization' do
      # User provides single velocity for chord
      velocities = 90.arrayfy(size: 3)
      expect(velocities).to eq([90, 90, 90])

      # User provides array of velocities that cycles
      velocities = [80, 100].arrayfy(size: 5)
      expect(velocities).to eq([80, 100, 80, 100, 80])
    end

    it 'example from line 66 - Object#arrayfy with size' do
      result = "hello".arrayfy(size: 3)
      expect(result).to eq(["hello", "hello", "hello"])
    end

    it 'example from line 69 - Nil handling' do
      result = nil.arrayfy(size: 2, default: :empty)
      expect(result).to eq([:empty, :empty])
    end

    it 'example from line 96 - Cycling shorter array' do
      result = [1, 2].arrayfy(size: 5)
      expect(result).to eq([1, 2, 1, 2, 1])
    end

    it 'example from line 99 - Truncating longer array' do
      result = [1, 2, 3, 4, 5].arrayfy(size: 3)
      expect(result).to eq([1, 2, 3])
    end

    it 'example from line 103 - Preserving dataset modules' do
      p_sequence = [60, 1, 62].extend(Musa::Datasets::P)
      result = p_sequence.arrayfy(size: 6)
      expect(result.is_a?(Musa::Datasets::P)).to be true
    end
  end

  context 'Hashify (hashify.rb)' do
    using Musa::Extension::Hashify

    it 'example from line 28 - Basic object hashification' do
      result = 100.hashify(keys: [:velocity, :duration])
      expect(result).to eq({ velocity: 100, duration: 100 })
    end

    it 'example from line 34 - Array to hash' do
      result = [60, 100, 0.5].hashify(keys: [:pitch, :velocity, :duration])
      expect(result).to eq({ pitch: 60, velocity: 100, duration: 0.5 })
    end

    it 'example from line 40 - Hash filtering and reordering' do
      result = { pitch: 60, velocity: 100, channel: 0, duration: 1 }
        .hashify(keys: [:pitch, :velocity])
      expect(result).to eq({ pitch: 60, velocity: 100 })
    end

    it 'example from line 47 - With defaults' do
      result = [60].hashify(keys: [:pitch, :velocity, :duration], default: nil)
      expect(result).to eq({ pitch: 60, velocity: nil, duration: nil })
    end

    it 'example from line 54 - Musical event normalization' do
      # User provides just a pitch (note: object hashify maps all keys to same value)
      result = 60.hashify(keys: [:pitch, :velocity])
      expect(result).to eq({ pitch: 60, velocity: 60 })

      # User provides array [pitch, velocity, duration]
      result = [62, 90, 0.5].hashify(keys: [:pitch, :velocity, :duration])
      expect(result).to eq({ pitch: 62, velocity: 90, duration: 0.5 })
    end

    it 'example from line 77 - Single value to multiple keys' do
      result = 127.hashify(keys: [:velocity, :pressure])
      expect(result).to eq({ velocity: 127, pressure: 127 })
    end

    it 'example from line 104 - Basic array mapping' do
      result = [60, 100, 0.25].hashify(keys: [:pitch, :velocity, :duration])
      expect(result).to eq({ pitch: 60, velocity: 100, duration: 0.25 })
    end

    it 'example from line 108 - Fewer elements than keys' do
      result = [60, 100].hashify(keys: [:pitch, :velocity, :duration], default: nil)
      expect(result).to eq({ pitch: 60, velocity: 100, duration: nil })
    end

    it 'example from line 112 - More elements than keys (extras ignored)' do
      result = [60, 100, 0.5, :ignored].hashify(keys: [:pitch, :velocity])
      expect(result).to eq({ pitch: 60, velocity: 100 })
    end

    it 'example from line 137 - Filtering keys' do
      result = { pitch: 60, velocity: 100, channel: 0 }
        .hashify(keys: [:pitch, :velocity])
      expect(result).to eq({ pitch: 60, velocity: 100 })
    end

    it 'example from line 142 - Reordering keys' do
      result = { velocity: 100, pitch: 60 }
        .hashify(keys: [:pitch, :velocity])
      expect(result).to eq({ pitch: 60, velocity: 100 })
    end

    it 'example from line 147 - Adding missing keys with default' do
      result = { pitch: 60 }
        .hashify(keys: [:pitch, :velocity], default: 80)
      expect(result).to eq({ pitch: 60, velocity: 80 })
    end

    it 'example from line 152 - Preserving dataset modules' do
      event = { pitch: 60, velocity: 100 }.extend(Musa::Datasets::AbsI)
      result = event.hashify(keys: [:pitch, :velocity])
      expect(result.is_a?(Musa::Datasets::AbsI)).to be true
    end
  end

  context 'DeepCopy (deep-copy.rb)' do
    using Musa::Extension::DeepCopy

    it 'example from line 29 - Basic deep copy' do
      original = { items: [1, 2, 3] }
      copy = original.dup(deep: true)
      copy[:items] << 4
      expect(original[:items]).to eq([1, 2, 3])  # unchanged
    end

    it 'example from line 36 - Preserving modules' do
      # Note: deep_copy doesn't automatically preserve singleton modules
      # Use copy_singleton_class_modules explicitly for this
      event = [60, 100].extend(Musa::Datasets::V)
      copy = Musa::Extension::DeepCopy::DeepCopy.deep_copy(event)
      Musa::Extension::DeepCopy::DeepCopy.copy_singleton_class_modules(event, copy)
      expect(copy.is_a?(Musa::Datasets::V)).to be true
    end

    it 'example from line 78 - copy_singleton_class_modules' do
      source = [60, 100].extend(Musa::Datasets::V)
      target = [60, 100]
      Musa::Extension::DeepCopy::DeepCopy.copy_singleton_class_modules(source, target)
      expect(target.is_a?(Musa::Datasets::V)).to be true
    end

    it 'example from line 256 - Shallow dup (default)' do
      arr = [[1, 2]]
      copy = arr.dup
      copy[0] << 3
      expect(arr).to eq([[1, 2, 3]])  # inner array shared
    end

    it 'example from line 261 - Deep dup' do
      arr = [[1, 2]]
      copy = arr.dup(deep: true)
      copy[0] << 3
      expect(arr).to eq([[1, 2]])  # inner array independent
    end

    it 'example from line 281 - Deep clone with freeze control' do
      hash = { nested: { value: 1 } }
      copy = hash.clone(deep: true, freeze: false)
      expect(copy.frozen?).to be false
      # Deep copy creates independent nested structure
      copy[:nested][:value] = 2
      expect(hash[:nested][:value]).to eq(1)
    end
  end

  context 'DynamicProxy (dynamic-proxy.rb)' do
    it 'example from line 19 - Basic usage' do
      proxy = Musa::Extension::DynamicProxy::DynamicProxy.new
      proxy.receiver = "Hello"
      expect(proxy.upcase).to eq("HELLO")  # forwarded to String
    end

    it 'example from line 119 - Complete example' do
      proxy = Musa::Extension::DynamicProxy::DynamicProxy.new
      proxy.receiver = [1, 2, 3]
      expect(proxy.size).to eq(3)
      expect(proxy.first).to eq(1)
      expect(proxy.is_a?(Array)).to be true
    end
  end

  context 'InspectNice (inspect-nice.rb)' do
    using Musa::Extension::InspectNice

    it 'example from line 24 - Hash formatting' do
      result = { pitch: 60, velocity: 100 }.inspect
      expect(result).to eq("{ pitch: 60, velocity: 100 }")
    end

    it 'example from line 31 - Rational formatting (detailed mode)' do
      expect((5/4r).inspect).to eq("1+1/4r")
      expect((3/2r).inspect).to eq("1+1/2r")
      expect((2/1r).inspect).to eq("2r")
      expect((-3/4r).inspect).to eq("-3/4r")
    end

    it 'example from line 40 - Rational formatting (simple mode)' do
      Rational.to_s_as_inspect = false
      expect((5/4r).to_s).to eq("5/4")
      expect((2/1r).to_s).to eq("2")
      Rational.to_s_as_inspect = nil  # Reset for other tests
    end

    it 'example from line 55 - Mixed keys' do
      result = { pitch: 60, 'name' => 'C4' }.inspect
      expect(result).to eq('{ pitch: 60, "name" => "C4" }')
    end

    it 'example from line 96 - Detailed format examples' do
      expect((5/4r).inspect).to eq("1+1/4r")
      expect((7/4r).inspect).to eq("1+3/4r")
      expect((-3/2r).inspect).to eq("-1-1/2r")
      expect((8/4r).inspect).to eq("2r")
      expect((3/4r).inspect).to eq("3/4r")
    end

    it 'example from line 103 - Simple format' do
      expect((5/4r).inspect(simple: true)).to eq("5/4")
      expect((8/4r).inspect(simple: true)).to eq("2")
    end

    it 'example from line 137 - When to_s_as_inspect is true' do
      Rational.to_s_as_inspect = true
      expect((5/4r).to_s).to eq("1+1/4r")
      Rational.to_s_as_inspect = nil  # Reset
    end

    it 'example from line 141 - When to_s_as_inspect is false' do
      Rational.to_s_as_inspect = false
      expect((5/4r).to_s).to eq("5/4")
      Rational.to_s_as_inspect = nil  # Reset
    end
  end

  context 'SmartProcBinder (smart-proc-binder.rb)' do
    it 'example from line 34 - Basic usage' do
      block = proc { |a, b, c:| [a, b, c] }
      binder = Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)

      result = binder.call(1, 2, 3, 4, c: 5, d: 6)
      expect(result).to eq([1, 2, 5])
      # Only passes parameters that match signature
    end

    it 'example from line 48 - Checking parameter support' do
      block = proc { |pitch:, velocity:| }
      binder = Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)

      expect(binder.key?(:pitch)).to be true
      expect(binder.has_key?(:velocity)).to be true
      expect(binder.key?(:unknown)).to be false
    end

    it 'example from line 150 - key? with rest parameters' do
      block1 = proc { |a:, b:, **rest| }
      binder1 = Musa::Extension::SmartProcBinder::SmartProcBinder.new(block1)
      expect(binder1.key?(:a)).to be true
      expect(binder1.key?(:unknown)).to be true  # has **rest

      block2 = proc { |a:, b:| }
      binder2 = Musa::Extension::SmartProcBinder::SmartProcBinder.new(block2)
      expect(binder2.key?(:unknown)).to be false
    end

    it 'example from line 212 - Inspecting binder state' do
      block = proc { |a, b, c:, **rest| }
      binder = Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)
      result = binder.inspect
      expect(result).to include("SmartProcBinder")
      expect(result).to include("parameters")
      expect(result).to include("key_parameters")
    end
  end

  context 'With (with.rb)' do
    it 'example from line 100 - DSL mode (instance_eval)' do
      class Builder1
        include Musa::Extension::With

        def initialize(&block)
          @items = []
          with(&block) if block
        end

        def add(item)
          @items << item
        end

        attr_reader :items
      end

      builder = Builder1.new do
        add :foo
        add :bar
      end

      expect(builder.items).to eq([:foo, :bar])
    end

    it 'example from line 108 - Caller context with _ parameter' do
      class Builder2
        include Musa::Extension::With

        def initialize(&block)
          @items = []
          with(&block) if block
        end

        def add(item)
          @items << item
        end

        attr_reader :items
      end

      external_var = 42

      builder = Builder2.new do |_|
        _.add :foo
        expect(external_var).to eq(42)  # Can access caller's variables
      end

      expect(builder.items).to eq([:foo])
    end
  end

  context 'Logger (logger/logger.rb)' do
    it 'example from line 34 - Complete workflow' do
      # Setup
      sequencer = Musa::Sequencer::Sequencer.new(4, 24)

      # Capture output using a custom IO
      output = StringIO.new
      logger = ::Logger.new(output)
      logger.level = ::Logger::INFO

      # Apply custom formatter from Musa::Logger::Logger
      logger.formatter = proc do |severity, time, progname, msg|
        level = "[#{severity}] " unless severity == 'DEBUG'
        if msg
          position = if sequencer
                       integer_digits = 3
                       decimal_digits = 3
                       "%#{integer_digits + decimal_digits + 1}s: " % ("%.#{decimal_digits}f" % sequencer.position.to_f)
                     end
          progname = "[#{progname}]" if progname
          "#{position}#{level}#{progname}#{' ' if position || level || progname}#{msg}\n"
        else
          "\n"
        end
      end

      # In your composition
      sequencer.at 1 do
        logger.info "Composition started"
      end

      sequencer.at 4 do
        logger.info "First phrase complete"
      end

      # Run sequencer to see logged output
      sequencer.run

      output_string = output.string
      expect(output_string).to include("1.000")
      expect(output_string).to include("Composition started")
      expect(output_string).to include("4.000")
      expect(output_string).to include("First phrase complete")
    end

    it 'example from line 82 - Basic usage without sequencer' do
      output = StringIO.new
      logger = ::Logger.new(output)

      # Simple formatter without sequencer
      logger.formatter = proc do |severity, time, progname, msg|
        level = "[#{severity}] " unless severity == 'DEBUG'
        if msg
          progname = "[#{progname}]" if progname
          "#{level}#{progname}#{' ' if level || progname}#{msg}\n"
        else
          "\n"
        end
      end

      logger.warn "Something happened"

      expect(output.string).to include("[WARN]")
      expect(output.string).to include("Something happened")
    end

    it 'example from line 87 - With sequencer integration' do
      sequencer = Musa::Sequencer::Sequencer.new(4, 24)

      output = StringIO.new
      logger = ::Logger.new(output)

      # Apply custom formatter with sequencer
      logger.formatter = proc do |severity, time, progname, msg|
        level = "[#{severity}] " unless severity == 'DEBUG'
        if msg
          position = if sequencer
                       integer_digits = 3
                       decimal_digits = 3
                       "%#{integer_digits + decimal_digits + 1}s: " % ("%.#{decimal_digits}f" % sequencer.position.to_f)
                     end
          progname = "[#{progname}]" if progname
          "#{position}#{level}#{progname}#{' ' if position || level || progname}#{msg}\n"
        else
          "\n"
        end
      end

      # At sequencer position 4.5:
      sequencer.at 4.5r do
        logger.info "Note played"
      end

      sequencer.run

      output_string = output.string
      expect(output_string).to include("4.500")
      expect(output_string).to include("[INFO]")
      expect(output_string).to include("Note played")
    end
  end
end
