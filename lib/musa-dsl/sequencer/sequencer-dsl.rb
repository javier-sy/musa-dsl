require 'forwardable'

require_relative '../core-ext/with'

module Musa
  module Sequencer
    # High-level DSL wrapper for BaseSequencer.
    #
    # Provides user-friendly interface with block context management via
    # `with` method. Wraps BaseSequencer methods to automatically evaluate
    # blocks in DSL context, enabling clean musical composition code.
    #
    # ## DSL Context
    #
    # Blocks passed to scheduling methods (now, at, wait, play, every, move)
    # are evaluated in DSL context via `with`, providing access to sequencer
    # methods and allowing for cleaner composition syntax.
    #
    # ## Delegation
    #
    # Delegates most methods to either BaseSequencer or DSLContext:
    #
    # - Timing: beats_per_bar, ticks_per_beat, position, tick, reset
    # - Scheduling: now, at, wait, play, play_timed, every, move
    # - Events: launch, on
    # - Inspection: size, empty?, everying, playing, moving
    #
    # ## Musical Applications
    #
    # Provides composer-friendly API for:
    #
    # - Musical composition scripts
    # - Interactive sequencing
    # - Live coding
    # - Algorithmic composition
    #
    # @example Basic DSL usage
    #   sequencer = Musa::Sequencer::Sequencer.new(4, 96) do
    #     at(1r) { puts "Bar 1" }
    #     at(2r) { puts "Bar 2" }
    #
    #     every(1r, duration: 4r) do
    #       puts "Every beat"
    #     end
    #   end
    #
    #   sequencer.run
    #
    # @example DSL context access
    #   sequencer = Musa::Sequencer::Sequencer.new(4, 96) do
    #     at(1r) do
    #       puts "Position: #{position}"  # DSL context method
    #
    #       wait(1r) { puts "One bar later" }  # Nested scheduling
    #     end
    #   end
    #
    # @api public
    class Sequencer
      extend Forwardable

      # Delegates to BaseSequencer
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

      # Delegates to DSLContext
      def_delegators :@dsl, :position, :quantize_position, :logger, :debug
      def_delegators :@dsl, :now, :at, :wait, :play, :play_timed, :every, :move
      def_delegators :@dsl, :everying, :playing, :moving
      def_delegators :@dsl, :launch, :on
      def_delegators :@dsl, :run

      # Creates sequencer with optional initialization block.
      #
      # @param beats_per_bar [Integer, nil] beats per bar (tick-based mode)
      # @param ticks_per_beat [Integer, nil] ticks per beat (tick-based mode)
      # @param offset [Rational, nil] starting position offset
      # @param sequencer [BaseSequencer, nil] use existing sequencer
      # @param logger [Logger, nil] logger instance
      # @param do_log [Boolean, nil] enable logging
      # @param do_error_log [Boolean, nil] enable error logging
      # @param log_position_format [Symbol, nil] position format for logs
      # @param dsl_context_class [Class, nil] custom DSL context class
      # @param keep_block_context [Boolean, nil] preserve block's original binding
      # @yield initialization block evaluated in DSL context
      #
      # @example Tick-based sequencer
      #   seq = Sequencer.new(4, 96) do
      #     at(1r) { puts "Start" }
      #   end
      #
      # @example Tickless sequencer
      #   seq = Sequencer.new do
      #     at(1r) { puts "Start" }
      #   end
      #
      # @api public
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

      # Evaluates block in DSL context.
      #
      # Provides `with` method for evaluating blocks with DSL context access.
      #
      # @param value_parameters [Array] positional parameters
      # @param key_parameters [Hash] keyword parameters
      # @yield block to evaluate in DSL context
      #
      # @return [Object] block return value
      #
      # @api public
      def with(*value_parameters, **key_parameters, &block)
        @dsl.with(*value_parameters, **key_parameters, &block)
      end

      # DSL context providing block evaluation with sequencer method access.
      #
      # Wraps BaseSequencer methods to evaluate user blocks in controlled
      # context via `with`. Enables clean DSL syntax by providing direct
      # access to sequencer methods within block scopes.
      #
      # ## Block Context Modes
      #
      # - **keep_block_context: false** (default): Evaluate blocks in DSL context
      # - **keep_block_context: true**: Preserve block's original binding
      #
      # @api private
      class DSLContext
        extend Forwardable
        include Musa::Extension::With

        # @return [BaseSequencer] underlying sequencer
        # @api private
        attr_reader :sequencer

        # Delegates to BaseSequencer
        def_delegators :@sequencer,
                       :launch, :on,
                       :position, :quantize_position,
                       :size,
                       :everying, :playing, :moving,
                       :ticks_per_bar, :logger, :debug, :inspect,
                       :run

        # @api private
        def initialize(sequencer, keep_block_context:)
          @sequencer = sequencer
          @keep_block_context_on_with = keep_block_context
        end

        # Schedules block at current position via DSL context.
        #
        # Wraps BaseSequencer#now, evaluating block in DSL context.
        #
        # @param value_parameters [Array] parameters to pass to block
        # @param key_parameters [Hash] keyword parameters
        # @yield block to execute at current position
        # @return [void]
        # @api private
        def now(*value_parameters, **key_parameters, &block)
          block ||= proc {}

          @sequencer.now *value_parameters, **key_parameters do |*value_args, **key_args|
            with *value_args, **key_args, keep_block_context: @keep_block_context_on_with, &block
          end
        end

        # Schedules block at absolute position via DSL context.
        #
        # Wraps BaseSequencer#at, evaluating block in DSL context.
        #
        # @param value_parameters [Array] parameters (first is position)
        # @param key_parameters [Hash] keyword parameters
        # @yield block to execute at position
        # @return [void]
        # @api private
        def at(*value_parameters, **key_parameters, &block)
          block ||= proc {}

          @sequencer.at *value_parameters, **key_parameters do |*value_args, **key_args|
            with *value_args, **key_args, keep_block_context: @keep_block_context_on_with, &block
          end
        end

        # Schedules block after wait duration via DSL context.
        #
        # Wraps BaseSequencer#wait, evaluating block in DSL context.
        #
        # @param value_parameters [Array] parameters (first is duration)
        # @param key_parameters [Hash] keyword parameters
        # @yield block to execute after wait
        # @return [void]
        # @api private
        def wait(*value_parameters, **key_parameters, &block)
          block ||= proc {}
          @sequencer.wait *value_parameters, **key_parameters do |*values, **key_values|
            with *values, **key_values, keep_block_context: @keep_block_context_on_with, &block
          end
        end

        # Plays series via DSL context.
        #
        # Wraps BaseSequencer#play, evaluating block in DSL context.
        #
        # @param value_parameters [Array] parameters (series, etc.)
        # @param key_parameters [Hash] keyword parameters
        # @yield block to execute for each element
        # @return [PlayControl] control object
        # @api private
        def play(*value_parameters, **key_parameters, &block)
          block ||= proc {}

          @sequencer.play *value_parameters, **key_parameters do |*value_args, **key_args|
            with *value_args, **key_args, keep_block_context: @keep_block_context_on_with, &block
          end
        end

        # Plays timed series via DSL context.
        #
        # Wraps BaseSequencer#play_timed, evaluating block in DSL context.
        #
        # @param value_parameters [Array] parameters (timed series, etc.)
        # @param key_parameters [Hash] keyword parameters
        # @yield block to execute for each element
        # @return [PlayTimedControl] control object
        # @api private
        def play_timed(*value_parameters, **key_parameters, &block)
          block ||= proc {}

          @sequencer.play_timed *value_parameters, **key_parameters do |*value_args, **key_args|
            with *value_args, **key_args, keep_block_context: @keep_block_context_on_with, &block
          end
        end

        # Repeats block at intervals via DSL context.
        #
        # Wraps BaseSequencer#every, evaluating block in DSL context.
        # Uses SmartProcBinder to apply parameters before with.
        #
        # @param value_parameters [Array] parameters (interval, etc.)
        # @param key_parameters [Hash] keyword parameters
        # @yield block to execute each iteration
        # @return [EveryControl] control object
        # @api private
        def every(*value_parameters, **key_parameters, &block)
          block ||= proc {}

          @sequencer.every *value_parameters, **key_parameters do |*value_args, **key_args|
            args = Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)._apply(value_args, key_args)
            with *args.first, **args.last, keep_block_context: @keep_block_context_on_with, &block
          end
        end

        # Animates values over time via DSL context.
        #
        # Wraps BaseSequencer#move, evaluating block in DSL context.
        #
        # @param value_parameters [Array] parameters (from, to, etc.)
        # @param key_parameters [Hash] keyword parameters
        # @yield block to execute each iteration with current value
        # @return [MoveControl] control object
        # @api private
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

