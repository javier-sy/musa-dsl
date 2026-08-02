require_relative '../core-ext/inspect-nice'
require_relative 'base-sequencer-implementation-play-helper'

using Musa::Extension::InspectNice

module Musa::Sequencer
  class BaseSequencer
    # The sequencer these examples are written against:
    #
    #     sequencer = BaseSequencer.new(4, 24)
    #
    # Play implementation for series-based event scheduling.
    #
    # Implements the `play` method that consumes a Musa::Series and schedules
    # events based on series elements. Supports multiple evaluation modes for
    # interpreting series elements (e.g., as timing deltas, absolute positions,
    # or complex data structures).
    #
    # ## Execution Model
    #
    # Play iterates through series elements:
    # 1. Gets next element from series
    # 2. PlayEval evaluates element to determine operations
    # 3. Executes current operation (call block, launch event, nested play, etc.)
    # 4. Schedules continuation based on continue operation
    # 5. Recursively processes next element
    #
    # ## PlayEval System
    #
    # PlayEval.create builds appropriate evaluator based on mode parameter.
    # Evaluator's run_operation method returns hash with:
    #
    # - current_operation: what to do now (:block, :event, :play, etc.)
    # - current_parameter: data for current operation
    # - continue_operation: when to continue (:now, :at, :wait, :on)
    # - continue_parameter: data for continue operation
    #
    # ## Operations
    #
    # Current operations (what to do now):
    #
    # - **:none**: Skip element
    # - **:block**: Call user block with element
    # - **:event**: Launch named event
    # - **:play**: Nested sequential play
    # - **:no_eval_play**: Nested play without evaluation
    # - **:parallel_play**: Multiple parallel plays
    #
    # Continue operations (when to continue):
    #
    # - **:now**: Immediately
    # - **:at**: At absolute position
    # - **:wait**: After time delta
    # - **:on**: When event fires
    #
    # ## Running Modes
    #
    # Different modes interpret series elements differently:
    #
    # - **:at**: Elements specify absolute positions via :at key
    # - **:wait**: Elements with duration specify wait time
    # - **:neumalang**: Full Neumalang DSL with variables, commands, series, etc.
    #
    # @param serie [Series] series to play
    # @param control [PlayControl] control object for lifecycle
    # @param neumalang_context [Object, nil] context for neumalang evaluation
    # @param mode [Symbol, nil] running mode
    # @param decoder [Object, nil] custom decoder
    # @param __play_eval [PlayEval, nil] evaluator (internal, created if nil)
    # @param mode_args [Hash] additional mode-specific arguments
    # @yield block to call for each element (mode-dependent)
    #
    # @return [nil]
    #
    #
    # @api private

    # Plays series by iterating elements and scheduling events.
    #
    # Recursively consumes series, 
    #
    #
    #
    # @api private
    private def _play(serie,
                      control,
                      neumalang_context = nil,
                      mode: nil,
                      decoder: nil,
                      __play_eval: nil,
                      **mode_args,
                      &block)

      block ||= proc {}

      __play_eval ||= PlayEval.create \
          mode,
          Musa::Extension::SmartProcBinder::SmartProcBinder.new(block,
                                                                on_rescue: proc { |e| _rescue_error(e) }),
          decoder,
          neumalang_context

      element = nil

      if control.stopped?
        # nothing to do
      elsif control.paused?
        control.store_continuation sequencer: self,
                                   serie: serie,
                                   neumalang_context: neumalang_context,
                                   mode: mode,
                                   decoder: decoder,
                                   play_eval: __play_eval,
                                   mode_args: mode_args
      else
        element = serie.next_value
      end

      if element
        operation = __play_eval.run_operation element

        case operation[:current_operation]
        when :none
          # do nothing
        when :block
          # duplicating parameters as direct object value (operation[:current_parameter])
          # and key_passed parameters (**operation[:current_parameter])
          #
          run_block = proc do
            __play_eval.block_procedure_binder.call operation[:current_parameter],
                                                    **operation[:current_parameter],
                                                    control: control
          end

          # An element that says WHEN it sounds is scheduled at that position
          # rather than run inline. Only :at mode does this today; every other
          # mode leaves current_at nil and plays where the play already is.
          if operation[:current_at]
            _numeric_at _due_position(operation[:current_at]), control, &run_block
          else
            run_block.call
          end

        when :event
          control._launch operation[:current_event],
                          operation[:current_value_parameters],
                          operation[:current_key_parameters],
                          operation[:current_proc_parameter]

        when :play
          control2 = PlayControl.new control
          control3 = PlayControl.new control2
          control3.after { control3.launch :sync }

          _play operation[:current_parameter].instance,
                control3,
                __play_eval: __play_eval.subcontext,
                **mode_args

          control2.on :sync do
            _play serie, control, __play_eval: __play_eval, **mode_args
          end

        when :no_eval_play
          control2 = PlayControl.new control
          control3 = PlayControl.new control2
          control3.after { control3.launch :sync }

          _play operation[:current_parameter].instance,
                control3,
                __play_eval: WaitModePlayEval.new(__play_eval.block_procedure_binder),
                **mode_args

          control2.on :sync do
            _play serie, control, __play_eval: __play_eval, **mode_args
          end

        when :parallel_play
          control2 = PlayControl.new control

          operation[:current_parameter].each do |current_parameter|
            control3 = PlayControl.new control2
            control3.after { control3.launch :sync }

            _play current_parameter.instance,
                  control3,
                  __play_eval: __play_eval.subcontext,
                  **mode_args
          end

          counter = operation[:current_parameter].size

          control2.on :sync do
            counter -= 1
            _play serie, control, __play_eval: __play_eval, **mode_args if counter.zero?
          end
        end

        case operation[:continue_operation]
        when :now
          _numeric_at position, control do
            _play serie, control, __play_eval: __play_eval, **mode_args
          end

        when :at
          _numeric_at _due_position(operation[:continue_parameter]), control do
            _play serie, control, __play_eval: __play_eval, **mode_args
          end

        when :wait
          _numeric_at position + operation[:continue_parameter].rationalize, control do
            _play serie, control, __play_eval: __play_eval, **mode_args
          end

        when :on
          control.on operation[:continue_parameter], only_once: true do
            _play serie, control, __play_eval: __play_eval, **mode_args
          end
        end
      else
        # The play is over HERE, and the caller may not have the control yet: a
        # serie that resolves within a single instant unwinds inside this very
        # `play` call, because a continuation at the current position is run
        # inline. Saying so is what lets `after` and `on_stop` registered a
        # moment later still mean something (issue #84).
        control._finished! self, position

        control.do_on_stop.each(&:call)

        unless control.stopped?
          control2 = EventHandler.new control

          control.do_after.each do |do_after|
            _numeric_at position + do_after[:bars], control2, &do_after[:block]
          end
        end
      end

      nil
    end

    # Control object for play operations.
    #
    # Manages play lifecycle including pause/continue and after callbacks.
    # Extends EventHandler to support custom events and hierarchical control.
    #
    # ## Pause/Continue
    #
    # When paused:
    # 1. Stores continuation parameters (series state, evaluator, etc.)
    # 2. Stops processing series
    # 3. Awaits continue call
    #
    # When continued:
    # 1. Restores continuation parameters
    # 2. Resumes play from stored position
    #
    # ## After Callbacks
    #
    # Executed after play completes, with optional delay in bars.
    #
    # @example Basic play control
    #   seq = Musa::Sequencer::BaseSequencer.new(4, 24)
    #
    #   # play consumes datasets, not bare values: each element is a hash, and
    #   # its :duration is how far the player advances before the next one.
    #   series = Musa::Series::Constructors.S({ pitch: 60, duration: 1r },
    #                                         { pitch: 62, duration: 1r })
    #   played_notes = []
    #   after_executed = []
    #
    #   control = seq.play(series) do |pitch:, duration:|
    #     played_notes << { pitch: pitch, position: seq.position }
    #   end
    #
    #   control.after(2r) { after_executed << seq.position }
    #
    #   seq.run
    #   played_notes.collect { |n| n[:pitch] }  # => [60, 62]
    #   # after_executed holds the position 2 bars after play completes
    #
    # @api private
    class PlayControl < EventHandler
      # @return [Array<Proc>] callbacks when play stops (any reason, including manual stop)
      attr_reader :do_on_stop
      # @return [Array<Hash>] after callbacks with delays (only on natural termination)
      attr_reader :do_after

      # Creates play control with optional callbacks.
      #
      # @param parent [EventHandler] parent event handler
      # @param on_stop [Proc, nil] stop callback (fires on any termination)
      # @param after_bars [Rational, nil] delay for after callback
      # @param after [Proc, nil] after callback block (fires only on natural termination)
      #
      # @api private
      def initialize(parent, on_stop: nil, after_bars: nil, after: nil)
        super parent

        @do_on_stop = []
        @do_after = []

        @do_on_stop << on_stop if on_stop
        after(after_bars, &after) if after
      end

      # Pauses play and stores continuation state.
      #
      # Sets paused flag. Continuation must be stored separately via
      # store_continuation.
      #
      # @return [void]
      #
      # @api private
      def pause
        @paused = true
      end

      # Stores state for continue operation.
      #
      # Saves all parameters needed to resume play from current position.
      # Called automatically by _play when paused.
      #
      # @param sequencer [BaseSequencer] sequencer instance
      # @param serie [Series] series being played
      # @param neumalang_context [Object, nil] neumalang context
      # @param mode [Symbol, nil] evaluation mode
      # @param decoder [Object, nil] decoder
      # @param play_eval [PlayEval] evaluator
      # @param mode_args [Hash] mode arguments
      #
      # @return [void]
      #
      # @api private
      def store_continuation(sequencer:, serie:, neumalang_context:, mode:, decoder:, play_eval:, mode_args:)
        @continuation_sequencer = sequencer
        @continuation_parameters = {
          serie: serie,
          control: self,
          neumalang_context: neumalang_context,
          mode: mode,
          decoder: decoder,
          play_eval: play_eval,
          mode_args: mode_args }
      end

      # Continues from pause.
      #
      # Restores paused state and resumes play using stored continuation.
      #
      # @return [void]
      #
      # @api private
      def continue
        super
        @continuation_sequencer&.continuation_play(@continuation_parameters)
      end

      # Registers callback for when play stops (any reason, including manual stop).
      #
      # @yield stop callback block
      #
      # @return [void]
      #
      # @api private
      def on_stop(&block)
        # Already over: on_stop means "when it terminates", and it has. The
        # normal path calls these directly too, rather than scheduling them.
        return block.call if @finished_at

        @do_on_stop << block
      end

      # Records that the play has ended, and where.
      #
      # Only the termination branch of `_play` calls this. It exists because the
      # control can reach the caller already dead -- see {#after}.
      #
      # @param sequencer [BaseSequencer] the sequencer that was playing
      # @param position [Rational] where the play ended
      #
      # @return [void]
      #
      # @api private
      def _finished!(sequencer, position)
        @finished_sequencer = sequencer
        @finished_at = position
      end

      # Registers callback to execute after play completes naturally
      # (series exhausted). Not called on manual stop.
      #
      # @param bars [Numeric, nil] delay in bars after completion (default: 0)
      # @yield after callback block
      #
      # @return [void]
      #
      # @example Delayed callback
      #   control = seq.play(series) { |pitch:, duration:| }
      #   control.after(4r) { puts "4 bars after play ends" }
      #
      # @api private
      def after(bars = nil, &block)
        bars ||= 0

        # Already over: `after(2)` means "two bars after it ends", and it ended
        # at @finished_at, so that is where this goes. Registering it in the
        # list would be registering it after the only moment anything reads the
        # list, which is what used to happen to every play that resolved within
        # one instant -- a chord written as a serie of `forward_duration: 0`
        # elements, a lone event with no duration -- and the callback simply
        # never ran (issue #84).
        return @finished_sequencer.at(@finished_at + bars.rationalize, &block) if @finished_at

        @do_after << { bars: bars.rationalize, block: block }
      end
    end
  end
end
