require_relative '../core-ext/inspect-nice'
require_relative 'base-sequencer-implementation-play-helper'

using Musa::Extension::InspectNice

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
# ## Evaluation Modes
#
# Different modes interpret series elements differently:
#
# - **nil**: Default mode (varies by series type)
# - **:neumalang**: Neumalang DSL syntax
# - Custom modes via PlayEval subclasses
#
# ## Musical Applications
#
# - Play note sequences from series
# - Schedule events from algorithmic generators
# - Nested polyphonic structures
# - Complex timing patterns
# - Event-driven composition
#
# @example Basic series playback
#   require 'musa-dsl'
#
#   clock = Musa::Clock::TimerClock.new bpm: 120
#   transport = Musa::Transport::Transport.new clock
#   output = MIDICommunications::Output.all.first
#   voices = Musa::MIDIVoices::MIDIVoices.new(
#     sequencer: transport.sequencer,
#     output: output,
#     channels: [0]
#   )
#   voice = voices.voices.first
#   sequencer = transport.sequencer
#
#   notes = Musa::Series.from_array([{pitch: 60, duration: 1r}, {pitch: 64, duration: 1r}])
#   sequencer.play(notes) { |note| voice.note pitch: note[:pitch], duration: note[:duration] }
#
# @example Parallel plays
#   require 'musa-dsl'
#
#   clock = Musa::Clock::TimerClock.new bpm: 120
#   transport = Musa::Transport::Transport.new clock
#   output = MIDICommunications::Output.all.first
#   voices = Musa::MIDIVoices::MIDIVoices.new(
#     sequencer: transport.sequencer,
#     output: output,
#     channels: [0, 1]
#   )
#   sequencer = transport.sequencer
#
#   melody = Musa::Series.from_array([60, 62, 64])
#   harmony = Musa::Series.from_array([48, 52, 55])
#   sequencer.play([melody, harmony]) do |pitch|
#     # pitch will be array [melody_pitch, harmony_pitch]
#     voices.voices[0].note pitch: pitch[0], duration: 1r
#     voices.voices[1].note pitch: pitch[1], duration: 1r
#   end
#
# @api private
module Musa::Sequencer
  class BaseSequencer
    # Plays series by iterating elements and scheduling events.
    #
    # Recursively consumes series, evaluating each element to determine
    # operation and scheduling continuation. Supports pause/continue,
    # nested plays, parallel plays, and event-driven continuation.
    #
    # ## PlayEval System
    #
    # PlayEval.create builds appropriate evaluator based on mode parameter.
    # Evaluator's run_operation method returns hash with:
    # - current_operation: what to do now (:block, :event, :play, etc.)
    # - current_parameter: data for current operation
    # - continue_operation: when to continue (:now, :at, :wait, :on)
    # - continue_parameter: data for continue operation
    #
    # @param serie [Series] series to play
    # @param control [PlayControl] control object for lifecycle
    # @param neumalang_context [Object, nil] context for neumalang evaluation
    # @param mode [Symbol, nil] evaluation mode
    # @param decoder [Object, nil] custom decoder
    # @param __play_eval [PlayEval, nil] evaluator (internal, created if nil)
    # @param mode_args [Hash] additional mode-specific arguments
    # @yield block to call for each element (mode-dependent)
    #
    # @return [nil]
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
          __play_eval.block_procedure_binder.call operation[:current_parameter],
                                                  **operation[:current_parameter],
                                                  control: control

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
          _numeric_at operation[:continue_parameter], control do
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
        control2 = EventHandler.new control

        control.do_after.each do |do_after|
          _numeric_at position + do_after[:bars], control2, &do_after[:block]
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
    #   require 'musa-dsl'
    #
    #   clock = Musa::Clock::TimerClock.new bpm: 120
    #   transport = Musa::Transport::Transport.new clock
    #   output = MIDICommunications::Output.all.first
    #   voices = Musa::MIDIVoices::MIDIVoices.new(
    #     sequencer: transport.sequencer,
    #     output: output,
    #     channels: [0]
    #   )
    #   voice = voices.voices.first
    #   sequencer = transport.sequencer
    #
    #   series = Musa::Series::S(60, 62, 64, 65, 67)
    #   control = sequencer.play(series) { |note| voice.note pitch: note, duration: 1r }
    #   control.after(2r) { puts "2 bars after play ends" }
    #   control.pause  # Pause playback
    #   control.continue  # Resume from pause
    #   control.stop  # Stop playback
    #
    # @api private
    class PlayControl < EventHandler
      # @return [Array<Hash>] after callbacks with delays
      attr_reader :do_after

      # Creates play control with optional after callback.
      #
      # @param parent [EventHandler] parent event handler
      # @param after_bars [Rational, nil] delay for after callback
      # @param after [Proc, nil] after callback block
      #
      # @api private
      def initialize(parent, after_bars: nil, after: nil)
        super parent

        @do_after = []

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

      # Registers callback to execute after play completes.
      #
      # @param bars [Numeric, nil] delay in bars after completion (default: 0)
      # @yield after callback block
      #
      # @return [void]
      #
      # @example Delayed callback
      #   control.after(4r) { puts "4 bars after play ends" }
      #
      # @api private
      def after(bars = nil, &block)
        bars ||= 0
        @do_after << { bars: bars.rationalize, block: block }
      end
    end

    private_constant :PlayControl
  end
end
