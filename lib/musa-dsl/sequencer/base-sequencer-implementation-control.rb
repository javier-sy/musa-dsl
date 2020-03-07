require 'forwardable'

module Musa
  module Sequencer
    class BaseSequencer
      class EventHandler
        attr_accessor :continue_parameters

        @@counter = 0

        def initialize(parent = nil)
          @id = (@@counter += 1)

          @parent = parent
          @handlers = {}

          @stop = false
        end

        def stop
          @stop = true
        end

        def stopped?
          @stop
        end

        def pause
          raise NotImplementedError
        end

        def continue
          @paused = false
        end

        def paused?
          @paused
        end

        def on(event, name: nil, only_once: nil, &block)
          only_once ||= false

          @handlers[event] ||= {}

          # TODO: add on_rescue: proc { |e| _rescue_block_error(e) } [this method is on Sequencer, not in EventHandler]
          @handlers[event][name] = { block: KeyParametersProcedureBinder.new(block), only_once: only_once }
        end

        def launch(event, *value_parameters, **key_parameters)
          _launch event, value_parameters, key_parameters
        end

        def _launch(event, value_parameters = nil, key_parameters = nil)
          value_parameters ||= []
          key_parameters ||= {}
          processed = false

          if @handlers.key? event
            @handlers[event].each do |name, handler|
              handler[:block].call *value_parameters, **key_parameters
              @handlers[event].delete name if handler[:only_once]
              processed = true
            end
          end

          @parent._launch event, value_parameters, key_parameters if @parent && !processed
        end

        def inspect
          "EventHandler #{id}"
        end

        def id
          if @parent
            "#{@parent.id}.#{self.class.name.split('::').last}-#{@id}"
          else
            "#{self.class.name.split('::').last}-#{@id.to_s}"
          end
        end

        alias to_s inspect
      end

      private_constant :EventHandler

      class PlayControl < EventHandler
        attr_reader :do_after

        def initialize(parent, after: nil)
          super parent

          @do_after = []

          self.after &after if after
        end

        def pause
          @paused = true
        end

        def store_continuation(sequencer:, serie:, nl_context:, mode:, decoder:, play_eval:, mode_args:)
          @continuation_sequencer = sequencer
          @continuation_parameters = {
              serie: serie,
              control: self,
              nl_context: nl_context,
              mode: mode,
              decoder: decoder,
              play_eval: play_eval,
              mode_args: mode_args
          }
        end

        def continue
          super
          @continuation_sequencer.continuation_play(@continuation_parameters) if @continuation_sequencer
        end

        def after(_bars = nil, &block)
          # TODO implementar parámetro _bars (?)
          @do_after << block
        end
      end

      private_constant :PlayControl

      class EveryControl < EventHandler
        attr_reader :duration_value, :till_value, :condition_block, :do_on_stop, :do_after

        attr_accessor :_start

        def initialize(parent, duration: nil, till: nil, condition: nil, on_stop: nil, after_bars: nil, after: nil)
          super parent

          @duration_value = duration
          @till_value = till
          @condition_block = condition

          @do_on_stop = []
          @do_after = []

          @do_on_stop << on_stop if on_stop

          self.after after_bars, &after if after
        end

        def duration(value)
          @duration_value = value.rationalize
        end

        def till(value)
          @till_value = value.rationalize
        end

        def condition(&block)
          @condition_block = block
        end

        def on_stop(&block)
          @do_on_stop << block
        end

        def after(bars = nil, &block)
          bars ||= 0
          @do_after << { bars: bars.rationalize, block: block }
        end
      end

      private_constant :EveryControl

      class MoveControl
        extend Forwardable

        def initialize(every_control)
          @every_control = every_control
        end

        def_delegators :@every_control, :on_stop, :after, :on, :launch, :stop
      end

      private_constant :MoveControl
    end
  end
end

