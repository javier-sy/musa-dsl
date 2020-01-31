require 'forwardable'

module Musa
  module Sequencer
    class Sequencer
      extend Forwardable

      def_delegators :@sequencer, :raw_at, :tick, :on_debug_at, :on_block_error, :on_fast_forward, :before_tick
      def_delegators :@sequencer, :beats_per_bar, :ticks_per_beat, :ticks_per_bar, :tick_duration, :round, :position=, :size, :event_handler, :empty?

      def_delegators :@context, :position, :log
      def_delegators :@context, :with, :now, :at, :wait, :play, :every, :move
      def_delegators :@context, :everying, :playing, :moving
      def_delegators :@context, :launch, :on

      def initialize(beats_per_bar, ticks_per_beat, sequencer: nil, do_log: nil, &block)
        @sequencer ||= BaseSequencer.new beats_per_bar, ticks_per_beat, do_log: do_log
        @context = DSLContext.new @sequencer

        with &block if block
      end

      def reset
        @sequencer.reset
      end

      class DSLContext
        extend Forwardable

        attr_reader :sequencer

        def_delegators :@sequencer, :launch, :on,
                       :position, :everying, :playing, :moving,
                       :ticks_per_bar, :round, :log, :inspect

        def initialize(sequencer)
          @sequencer = sequencer
        end

        def with(*value_parameters, **key_parameters, &block)
          block ||= proc {}

          instance_exec *value_parameters, **key_parameters, &block
        end

        def now(*value_parameters, **key_parameters, &block)
          block ||= proc {}

          @sequencer.now *value_parameters, **key_parameters do |*value_args, **key_args|
            instance_exec *value_args, **key_args, &block
          end
        end

        def at(*value_parameters, **key_parameters, &block)
          block ||= proc {}

          @sequencer.at *value_parameters, **key_parameters do |*value_args, **key_args|
            instance_exec *value_args, **key_args, &block
          end
        end

        def wait(*value_parameters, **key_parameters, &block)
          block ||= proc {}

          @sequencer.wait *value_parameters, **key_parameters do | *values, **key_values |
            instance_exec *values, **key_values, &block
          end
        end

        def play(*value_parameters, **key_parameters, &block)
          block ||= proc {}

          @sequencer.play *value_parameters, **key_parameters do |*value_args, **key_args|
            instance_exec *value_args, **key_args, &block
          end
        end

        def every(*value_parameters, **key_parameters, &block)
          block ||= proc {}

          @sequencer.every *value_parameters, **key_parameters do |*value_args, **key_args|
            instance_exec *value_args, **KeyParametersProcedureBinder.new(block).apply(key_args), &block
          end
        end

        def move(*value_parameters, **key_parameters, &block)
          block ||= proc {}

          @sequencer.move *value_parameters, **key_parameters do |*value_args, **key_args|
            instance_exec *value_args, **key_args, &block
          end
        end
      end

      private_constant :DSLContext
    end
  end
end

