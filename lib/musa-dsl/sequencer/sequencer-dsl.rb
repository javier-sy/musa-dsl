require 'forwardable'

class Musa::Sequencer
  extend Forwardable

  def_delegators :@sequencer, :raw_at, :tick, :on_debug_at, :on_block_error
  def_delegators :@sequencer, :on_fast_forward, :ticks_per_bar, :round, :position=, :size, :event_handler, :empty?

  def_delegators :@context, :position, :log
  def_delegators :@context, :with, :now, :at, :wait, :theme, :play, :every, :move
  def_delegators :@context, :everying, :playing, :moving
  def_delegators :@context, :launch, :on

  def initialize(quarter_notes_by_bar, quarter_note_divisions, sequencer: nil, do_log: nil, &block)
    @sequencer ||= Musa::BaseSequencer.new quarter_notes_by_bar, quarter_note_divisions, do_log: do_log
    @context = DSLContext.new @sequencer

    with &block if block
  end

  def reset
    @sequencer.reset
  end

  class DSLContext
    extend Forwardable

    attr_reader :sequencer

    def_delegators :@sequencer, :launch, :on, :position, :everying, :playing, :moving, :ticks_per_bar, :round, :log, :inspect

    def initialize(sequencer)
      @sequencer = sequencer
    end

    def with(*value_parameters, **key_parameters, &block)
      _as_context_run block, value_parameters, key_parameters
    end

    def now(*value_parameters, **key_parameters, &block)
      @sequencer.now *value_parameters, **key_parameters do |*value_args, **key_args|
        _as_context_run block, value_args, key_args
      end
    end

    def at(*value_parameters, **key_parameters, &block)
      @sequencer.at *value_parameters, **key_parameters do |*value_args, **key_args|
        _as_context_run block, value_args, key_args
      end
    end

    def wait(*value_parameters, **key_parameters, &block)
      @sequencer.wait *value_parameters, **key_parameters do
        _as_context_run block
      end
    end

    def theme(*value_parameters, **key_parameters)
      @sequencer.theme *value_parameters, context: self, **key_parameters
    end

    def play(*value_parameters, **key_parameters, &block)
      @sequencer.play *value_parameters, **key_parameters do |*value_args, **key_args|
        _as_context_run block, value_args, key_args
      end
    end

    def every(*value_parameters, **key_parameters, &block)
      @sequencer.every *value_parameters, **key_parameters do |*value_args, **key_args|
        _as_context_run block, value_args, KeyParametersProcedureBinder.new(block).apply(key_args)
      end
    end

    def move(*value_parameters, **key_parameters, &block)
      @sequencer.move *value_parameters, **key_parameters do |*value_args, **key_args|
        _as_context_run block, value_args, key_args
      end
    end
  end

  private_constant :DSLContext
end

module Musa::Theme
  def initialize(context)
    @context = context
  end

  def at_position(p, **_parameters)
    p
  end

  def run; end

  private

  def method_missing(method_name, *args, **key_args, &block)
    if @context.respond_to? method_name
      @context.send_nice method_name, *args, **key_args, &block
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private)
    @context.respond_to?(method_name, include_private) || super
  end
end
