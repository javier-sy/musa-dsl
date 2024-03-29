require 'forwardable'

require_relative '../core-ext/with'

module Musa
  module Sequencer
    class Sequencer
      extend Forwardable

      def_delegators :@sequencer,
                     :beats_per_bar, :ticks_per_beat, :ticks_per_bar, :tick_duration,
                     :offset,
                     :size, :empty?,
                     :on_debug_at, :on_error, :on_fast_forward, :before_tick,
                     :raw_at,
                     :tick,
                     :reset,
                     :position=,
                     :event_handler

      def_delegators :@dsl, :position, :quantize_position, :logger, :debug
      def_delegators :@dsl, :now, :at, :wait, :play, :play_timed, :every, :move
      def_delegators :@dsl, :everying, :playing, :moving
      def_delegators :@dsl, :launch, :on
      def_delegators :@dsl, :run

      def initialize(beats_per_bar = nil,
                     ticks_per_beat = nil,
                     offset: nil,
                     sequencer: nil,
                     logger: nil,
                     do_log: nil, do_error_log: nil, log_position_format: nil,
                     dsl_context_class: nil,
                     keep_block_context: nil,
                     &block)

        @sequencer = sequencer
        @sequencer ||= BaseSequencer.new beats_per_bar, ticks_per_beat,
                                         offset: offset,
                                         logger: logger,
                                         do_log: do_log,
                                         do_error_log: do_error_log,
                                         log_position_format: log_position_format

        dsl_context_class ||= DSLContext

        @dsl = dsl_context_class.new @sequencer, keep_block_context: keep_block_context

        @dsl.with &block if block_given?
      end

      def with(*value_parameters, **key_parameters, &block)
        @dsl.with(*value_parameters, **key_parameters, &block)
      end

      class DSLContext
        extend Forwardable
        include Musa::Extension::With

        attr_reader :sequencer

        def_delegators :@sequencer,
                       :launch, :on,
                       :position, :quantize_position,
                       :size,
                       :everying, :playing, :moving,
                       :ticks_per_bar, :logger, :debug, :inspect,
                       :run

        def initialize(sequencer, keep_block_context:)
          @sequencer = sequencer
          @keep_block_context_on_with = keep_block_context
        end

        def now(*value_parameters, **key_parameters, &block)
          block ||= proc {}

          @sequencer.now *value_parameters, **key_parameters do |*value_args, **key_args|
            with *value_args, **key_args, keep_block_context: @keep_block_context_on_with, &block
          end
        end

        def at(*value_parameters, **key_parameters, &block)
          block ||= proc {}

          @sequencer.at *value_parameters, **key_parameters do |*value_args, **key_args|
            with *value_args, **key_args, keep_block_context: @keep_block_context_on_with, &block
          end
        end

        def wait(*value_parameters, **key_parameters, &block)
          block ||= proc {}
          @sequencer.wait *value_parameters, **key_parameters do |*values, **key_values|
            with *values, **key_values, keep_block_context: @keep_block_context_on_with, &block
          end
        end

        def play(*value_parameters, **key_parameters, &block)
          block ||= proc {}

          @sequencer.play *value_parameters, **key_parameters do |*value_args, **key_args|
            with *value_args, **key_args, keep_block_context: @keep_block_context_on_with, &block
          end
        end

        def play_timed(*value_parameters, **key_parameters, &block)
          block ||= proc {}

          @sequencer.play_timed *value_parameters, **key_parameters do |*value_args, **key_args|
            with *value_args, **key_args, keep_block_context: @keep_block_context_on_with, &block
          end
        end

        def every(*value_parameters, **key_parameters, &block)
          block ||= proc {}

          @sequencer.every *value_parameters, **key_parameters do |*value_args, **key_args|
            args = Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)._apply(value_args, key_args)
            with *args.first, **args.last, keep_block_context: @keep_block_context_on_with, &block
          end
        end

        def move(*value_parameters, **key_parameters, &block)
          block ||= proc {}

          @sequencer.move *value_parameters, **key_parameters do |*value_args, **key_args|
            with *value_args, **key_args, keep_block_context: @keep_block_context_on_with, &block
          end
        end
      end
    end
  end
end

