class Musa::BaseSequencer
  class EventHandler
    attr_reader :stdout, :stderr

    @@counter = 0

    def initialize(parent = nil, capture_stdout: nil)
      capture_stdout ||= false

      @id = (@@counter += 1)

      @parent = parent
      @handlers = {}

      if capture_stdout || !parent
        @stdout = $stdout
        @stderr = $stderr
      else
        @stdout = @parent.stdout
        @stderr = @parent.stderr
      end
    end

    def on(event, only_once: nil, &block)
      only_once ||= false

      @handlers[event] ||= []
      # TODO: add on_rescue: proc { |e| _rescue_block_error(e) } [this method is on Sequencer, not in EventHandler]
      @handlers[event] << { block: KeyParametersProcedureBinder.new(block), only_once: only_once }
    end

    def launch(event, *value_parameters, **key_parameters)
      _launch event, value_parameters, key_parameters
    end

    def _launch(event, value_parameters = nil, key_parameters = nil)
      processed = false

      if @handlers.key? event
        @handlers[event].each_index do |i|
          handler = @handlers[event][i]
          next unless handler

          handler[:block]._call value_parameters, key_parameters
          @handlers[event][i] = nil if handler[:only_once]
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
        "#{@parent.id}.#{@id}"
      else
        @id.to_s
      end
    end

    alias to_s inspect
  end

  private_constant :EventHandler

  class PlayControl < EventHandler
    attr_reader :do_after

    def initialize(parent, capture_stdout: nil, after: nil)
      super parent, capture_stdout: capture_stdout

      @do_after = []

      self.after &after if after

      @stop = false
    end

    def stop
      @stop = true
    end

    def stopped?
      @stop
    end

    def after(_bars = nil, &block)
      @do_after << block
    end
  end

  private_constant :PlayControl

  class EveryControl < EventHandler
    attr_reader :duration_value, :till_value, :condition_block, :do_on_stop, :do_after

    attr_accessor :_start

    def initialize(parent, capture_stdout: nil, duration: nil, till: nil, condition: nil, on_stop: nil, after_bars: nil, after: nil)
      super parent, capture_stdout: capture_stdout

      @duration_value = duration
      @till_value = till
      @condition_block = condition

      @do_on_stop = []
      @do_after = []

      @do_on_stop << on_stop if on_stop

      self.after after_bars, &after if after

      @stop = false
    end

    def stop
      @stop = true
    end

    def stopped?
      @stop
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

    def_delegators :@every_control, :stdout, :stderr, :on_stop, :after, :on, :launch, :stop
  end

  private_constant :MoveControl
end
