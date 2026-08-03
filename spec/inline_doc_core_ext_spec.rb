require 'spec_helper'
require 'musa-dsl'

RSpec.describe 'Core Extensions Inline Documentation Examples' do
  include Musa::All

  context 'ExplodeRanges (array-explode-ranges.rb)' do
    using Musa::Extension::ExplodeRanges

  end

  context 'Arrayfy (arrayfy.rb)' do
    using Musa::Extension::Arrayfy

    it '@example Repetition with size' do
      expect(5.arrayfy(size: 3)).to eq([5, 5, 5])
      expect([1, 2].arrayfy(size: 5)).to eq([1, 2, 1, 2, 1])
      expect([1, 2, 3].arrayfy(size: 2)).to eq([1, 2])
    end

    it '@example Default values for nil' do
      expect(nil.arrayfy(size: 3, default: 0)).to eq([0, 0, 0])
      expect([1, nil, 3].arrayfy(size: 5, default: -1)).to eq([1, -1, 3, 1, -1])
    end

    it '@example Musical application - velocity normalization' do
      # User provides single velocity for chord
      velocities = 90.arrayfy(size: 3)
      expect(velocities).to eq([90, 90, 90])

      # User provides array of velocities that cycles
      velocities = [80, 100].arrayfy(size: 5)
      expect(velocities).to eq([80, 100, 80, 100, 80])
    end

    it '@example Nil handling' do
      result = nil.arrayfy(size: 2, default: :empty)
      expect(result).to eq([:empty, :empty])
    end

    it '@example Truncating longer array' do
      result = [1, 2, 3, 4, 5].arrayfy(size: 3)
      expect(result).to eq([1, 2, 3])
    end

    it '@example Preserving dataset modules' do
      p_sequence = [60, 1, 62].extend(Musa::Datasets::P)
      result = p_sequence.arrayfy(size: 6)

      # Padding to a longer size repeats the content, and the P travels with it.
      expect(result).to eq [60, 1, 62, 60, 1, 62]
      expect(result).to be_a Musa::Datasets::P
    end
  end

  context 'Hashify (hashify.rb)' do
    using Musa::Extension::Hashify

    it '@example Preserving dataset modules' do
      event = { pitch: 60, velocity: 100 }.extend(Musa::Datasets::AbsI)
      result = event.hashify(keys: [:pitch, :velocity])

      # Nothing missing to add, so the content is untouched -- and still AbsI.
      expect(result).to eq(pitch: 60, velocity: 100)
      expect(result).to be_a Musa::Datasets::AbsI
    end
  end

  context 'DeepCopy (deep-copy.rb)' do
    using Musa::Extension::DeepCopy

    it '@example Preserving modules' do
      event = [60, 100].extend(Musa::Datasets::V)
      copy = Musa::Extension::DeepCopy::DeepCopy.deep_copy(event)

      # The content travels; the singleton modules do NOT. That is the claim the
      # comment here used to make in prose, and the reason the next call exists.
      expect(copy).to eq [60, 100]
      expect(copy).not_to be_a Musa::Datasets::V

      Musa::Extension::DeepCopy::DeepCopy.copy_singleton_class_modules(event, copy)

      expect(copy).to be_a Musa::Datasets::V
    end

    it '@example Carrying the singleton modules over' do
      source = [60, 100].extend(Musa::Datasets::V)
      target = [60, 100]
      Musa::Extension::DeepCopy::DeepCopy.copy_singleton_class_modules(source, target)

      # Only the modules move: the target keeps the content it already had.
      expect(target).to eq [60, 100]
      expect(target).to be_a Musa::Datasets::V
    end

    it '@example Shallow dup (default)' do
      arr = [[1, 2]]
      copy = arr.dup
      copy[0] << 3
      expect(arr).to eq([[1, 2, 3]])  # inner array shared
    end

    it '@example Deep dup' do
      arr = [[1, 2]]
      copy = arr.dup(deep: true)
      copy[0] << 3
      expect(arr).to eq([[1, 2]])  # inner array independent
    end

    it '@example freeze: true freezes the whole copy, all the way down' do
      copy = { nested: { value: 1 } }.clone(deep: true, freeze: true)

      expect(copy.frozen?).to be true
      expect(copy[:nested].frozen?).to be true
    end

    it '@example By default each node keeps the state its own original had' do
      original = { constant: { name: 'white' }.freeze, mutable: [1] }
      copy = original.clone(deep: true)

      expect(copy.frozen?).to be false
      expect(copy[:constant].frozen?).to be true
      expect(copy[:mutable].frozen?).to be false
    end
  end

  context 'DynamicProxy (dynamic-proxy.rb)' do

  end

  context 'InspectNice (inspect-nice.rb)' do
    using Musa::Extension::InspectNice

    it '@example Rational formatting (detailed mode)' do
      expect((5/4r).inspect).to eq("1+1/4r")
      expect((3/2r).inspect).to eq("1+1/2r")
      expect((2/1r).inspect).to eq("2r")
      expect((-3/4r).inspect).to eq("-3/4r")
    end

    it '@example Rational formatting (simple mode)' do
      Rational.to_s_as_inspect = false
      expect((5/4r).to_s).to eq("5/4")
      expect((2/1r).to_s).to eq("2")
      Rational.to_s_as_inspect = nil  # Reset for other tests
    end

    it 'Detailed format examples' do
      expect((5/4r).inspect).to eq("1+1/4r")
      expect((7/4r).inspect).to eq("1+3/4r")
      expect((-3/2r).inspect).to eq("-1-1/2r")
      expect((8/4r).inspect).to eq("2r")
      expect((3/4r).inspect).to eq("3/4r")
    end

    it '@example Simple format' do
      expect((5/4r).inspect(simple: true)).to eq("5/4")
      expect((8/4r).inspect(simple: true)).to eq("2")
    end

    it '@example When to_s_as_inspect is false/nil' do
      Rational.to_s_as_inspect = false
      expect((5/4r).to_s).to eq("5/4")
      Rational.to_s_as_inspect = nil  # Reset
    end
  end

  context 'SmartProcBinder (smart-proc-binder.rb)' do
    it 'reports a proc\'s positional parameters as optional and a lambda\'s as required' do
      from_proc = Musa::Extension::SmartProcBinder::SmartProcBinder.new(proc { |a, b, c:| })
      from_lambda = Musa::Extension::SmartProcBinder::SmartProcBinder.new(lambda { |a, b, c:| })

      # A proc tolerates the wrong number of arguments and a lambda does not,
      # which is why the positional types differ. A keyword without a default is
      # :keyreq in both.
      expect(from_proc.parameters).to eq [[:opt, :a], [:opt, :b], [:keyreq, :c]]
      expect(from_lambda.parameters).to eq [[:req, :a], [:req, :b], [:keyreq, :c]]
    end

    it '@example Checking parameter support' do
      block = proc { |pitch:, velocity:| }
      binder = Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)

      expect(binder.key?(:pitch)).to be true
      expect(binder.has_key?(:velocity)).to be true
      expect(binder.key?(:unknown)).to be false
    end

    it '@example Keywords, including a **rest that accepts any' do
      block1 = proc { |a:, b:, **rest| }
      binder1 = Musa::Extension::SmartProcBinder::SmartProcBinder.new(block1)
      expect(binder1.key?(:a)).to be true
      expect(binder1.key?(:unknown)).to be true  # has **rest

      block2 = proc { |a:, b:| }
      binder2 = Musa::Extension::SmartProcBinder::SmartProcBinder.new(block2)
      expect(binder2.key?(:unknown)).to be false
    end

    it '@example Inspecting binder state' do
      block = proc { |a, b, c:, **rest| }
      binder = Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)
      result = binder.inspect
      expect(result).to include("SmartProcBinder")
      expect(result).to include("parameters")
      expect(result).to include("key_parameters")
    end
  end

  context 'With (with.rb)' do
    it '@example DSL mode (instance_eval)' do
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

    it '@example Caller context with _ parameter' do
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
    it '@example Complete workflow' do
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

    it '@example Basic usage without sequencer' do
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

    it '@example With sequencer integration' do
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
