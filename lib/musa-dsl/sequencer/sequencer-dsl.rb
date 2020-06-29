require 'forwardable'

require_relative '../core-ext/with'

module Musa
  module Sequencer
    class Sequencer
      extend Forwardable

      def_delegators :@sequencer, :raw_at, :tick, :on_debug_at, :on_error, :on_fast_forward, :before_tick
      def_delegators :@sequencer, :beats_per_bar, :ticks_per_beat, :ticks_per_bar, :tick_duration, :round, :position=, :size, :event_handler, :empty?

      def_delegators :@context, :position, :log
      def_delegators :@context, :with, :now, :at, :wait, :play, :every, :move
      def_delegators :@context, :everying, :playing, :moving
      def_delegators :@context, :launch, :on

      def initialize(beats_per_bar, ticks_per_beat, sequencer: nil, do_log: nil, do_error_log: nil, &block)
        @sequencer = sequencer
        @sequencer ||= BaseSequencer.new beats_per_bar, ticks_per_beat, do_log: do_log, do_error_log: do_error_log
        @context = DSLContext.new @sequencer

        with &block if block_given?
      end

      def reset
        @sequencer.reset
      end

      class DSLContext
        extend Forwardable
        include Musa::Extension::SmartProcBinder
        include Musa::Extension::With

        attr_reader :sequencer

        def_delegators :@sequencer, :launch, :on,
                       :position, :size, :everying, :playing, :moving,
                       :ticks_per_bar, :round, :log, :inspect

        def initialize(sequencer)
          @sequencer = sequencer
        end

        def now(*value_parameters, **key_parameters, &block)
          block ||= proc {}

          @sequencer.now *value_parameters, **key_parameters do |*value_args, **key_args|
            with *value_args, **key_args, &block
          end
        end

        def at(*value_parameters, **key_parameters, &block)
          block ||= proc {}

          @sequencer.at *value_parameters, **key_parameters do |*value_args, **key_args|
            with *value_args, **key_args, &block
          end
        end

        def wait(*value_parameters, **key_parameters, &block)
          block ||= proc {}

          @sequencer.wait *value_parameters, **key_parameters do | *values, **key_values |
            with *values, **key_values, &block
          end
        end

        def play(*value_parameters, **key_parameters, &block)
          block ||= proc {}

          @sequencer.play *value_parameters, **key_parameters do |*value_args, **key_args|
            with *value_args, **key_args, &block
          end
        end

        def every(*value_parameters, **key_parameters, &block)
          block ||= proc {}

          @sequencer.every *value_parameters, **key_parameters do |*value_args, **key_args|
            args = SmartProcBinder.new(block)._apply(value_args, key_args)
            with *args.first, **args.last, &block
          end
        end

        def move(*value_parameters, **key_parameters, &block)
          block ||= proc {}

          @sequencer.move *value_parameters, **key_parameters do |*value_args, **key_args|
            with *value_args, **key_args, &block
          end
        end
      end

      private_constant :DSLContext
    end
  end
end

