require_relative '../core-ext/inspect-nice'
require_relative 'base-sequencer-implementation-play-helper'

using Musa::Extension::InspectNice

module Musa::Sequencer
  class BaseSequencer
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
                          operation[:current_key_parameters]

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
            _play serie, control, __play_eval: __play_eval, **mode_args if counter == 0
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

    class PlayControl < EventHandler
      attr_reader :do_after

      def initialize(parent, after_bars: nil, after: nil)
        super parent

        @do_after = []

        after(after_bars, &after) if after
      end

      def pause
        @paused = true
      end

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

      def continue
        super
        @continuation_sequencer.continuation_play(@continuation_parameters) if @continuation_sequencer
      end

      def after(bars = nil, &block)
        bars ||= 0
        @do_after << { bars: bars.rationalize, block: block }
      end
    end

    private_constant :PlayControl
  end
end
