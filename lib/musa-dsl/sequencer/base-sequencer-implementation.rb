require_relative '../core-ext/arrayfy'
require_relative '../core-ext/smart-proc-binder'

using Musa::Extension::Arrayfy
using Musa::Extension::DeepCopy

module Musa; module Sequencer
  class BaseSequencer
    include Musa::Extension::SmartProcBinder
    include Musa::Extension::DeepCopy

    private def _tick(position_to_run)
      @before_tick.each { |block| block.call position_to_run }
      queue = @timeslots[position_to_run]

      if queue
        until queue.empty?
          command = queue.shift
          @timeslots.delete position_to_run if queue.empty?

          if command.key?(:parent_control) && !command[:parent_control].stopped?
            @event_handlers.push command[:parent_control]

            @tick_mutex.synchronize do
              command[:block].call *command[:value_parameters], **command[:key_parameters] if command[:block]
            end

            @event_handlers.pop
          else
            @tick_mutex.synchronize do
              command[:block].call *command[:value_parameters], **command[:key_parameters] if command[:block]
            end
          end
        end
      end

      Thread.pass
    end

    private def _raw_numeric_at(at_position, force_first: nil, &block)
      force_first ||= false

      if at_position == @position
        begin
          yield
        rescue StandardError, ScriptError => e
          _rescue_error e
        end

      elsif at_position > @position
        @timeslots[at_position] ||= []

        value = { block: block, value_parameters: [], key_parameters: {} }
        if force_first
          @timeslots[at_position].insert 0, value
        else
          @timeslots[at_position] << value
        end
      else
        @logger.warn('BaseSequencer') { "._raw_numeric_at: ignoring past at command for #{at_position}" }
      end

      nil
    end

    private def _numeric_at(at_position, control, with: nil, debug: nil, &block)
      raise ArgumentError, "'at_position' parameter cannot be nil" if at_position.nil?
      raise ArgumentError, 'Yield block is mandatory' unless block

      at_position = _quantize_position(at_position)

      value_parameters = []
      value_parameters << with if !with.nil? && !with.is_a?(Hash)

      block_key_parameters_binder =
          SmartProcBinder.new block, on_rescue: proc { |e| _rescue_error(e) }

      key_parameters = {}
      key_parameters.merge! block_key_parameters_binder._apply(nil, with).last if with.is_a?(Hash)

      key_parameters[:control] = control if block_key_parameters_binder.key?(:control)

      if at_position == @position
        @on_debug_at.each { |c| c.call } if @logger.sev_threshold >= ::Logger::Severity::DEBUG

        begin
          locked = @tick_mutex.try_lock
          block_key_parameters_binder._call(value_parameters, key_parameters)
        ensure
          @tick_mutex.unlock if locked
        end

      elsif @position.nil? || at_position > @position

        @timeslots[at_position] ||= []

        if @logger.sev_threshold <= ::Logger::Severity::DEBUG
          @on_debug_at.each do |block|
            @timeslots[at_position] << { parent_control: control, block: block }
          end
        end

        @timeslots[at_position] << { parent_control: control, block: block_key_parameters_binder,
                                     value_parameters: value_parameters,
                                     key_parameters: key_parameters }
      else
        @logger.warn('BaseSequencer') { "._numeric_at: ignoring past 'at' command for #{at_position}" }
      end

      nil
    end

    private def _serie_at(bar_position_serie, control, with: nil, debug: nil, &block)
      bar_position = bar_position_serie.next_value

      with_value = if with.respond_to? :next_value
                     with.next_value
                   else
                     with
                   end

      if bar_position
        _numeric_at bar_position, control, with: with_value, debug: debug, &block

        _numeric_at bar_position, control, debug: false do
          _serie_at bar_position_serie, control, with: with, debug: debug, &block
        end
      else
        # serie finalizada
      end

      nil
    end

    def _rescue_error(e)
      @logger.error('BaseSequencer') { e.to_s }
      @logger.error('BaseSequencer') { e.full_message(highlight: true, order: :top) }

      @on_error.each do |block|
        block.call e
      end
    end

    class EventHandler
      include Musa::Extension::SmartProcBinder

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
        @handlers[event][name] = { block: SmartProcBinder.new(block), only_once: only_once }
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
  end
end; end

require_relative 'base-sequencer-implementation-every'
require_relative 'base-sequencer-implementation-move'
require_relative 'base-sequencer-implementation-play'
require_relative 'base-sequencer-implementation-play-timed'
