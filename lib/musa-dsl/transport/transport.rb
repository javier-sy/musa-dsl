require 'musa-dsl/sequencer'

require 'musa-dsl/core-ext/key-parameters-procedure-binder'

module Musa
  class Transport
    attr_reader :sequencer

    def initialize(clock,
                   beats_per_bar = nil,
                   ticks_per_beat = nil,
                   before_begin: nil,
                   on_start: nil,
                   after_stop: nil,
                   before_each_tick: nil,
                   on_position_change: nil,
                   do_log: nil)

      beats_per_bar ||= 4
      ticks_per_beat ||= 24
      do_log ||= false

      @clock = clock

      @before_begin = []
      @before_begin << KeyParametersProcedureBinder.new(before_begin) if before_begin

      @on_start = []
      @on_start << KeyParametersProcedureBinder.new(on_start) if on_start

      @before_each_tick = []
      @before_each_tick << KeyParametersProcedureBinder.new(before_each_tick) if before_each_tick

      @on_position_change = []
      @on_position_change << KeyParametersProcedureBinder.new(on_position_change) if on_position_change

      @after_stop = []
      @after_stop << KeyParametersProcedureBinder.new(after_stop) if after_stop

      @do_log = do_log

      @sequencer = Sequencer.new beats_per_bar, ticks_per_beat, do_log: @do_log

      @clock.on_start do
        do_on_start
      end

      @clock.on_stop do
        do_stop
      end

      @clock.on_song_position_pointer do |midi_beat_position|
        position = Rational(midi_beat_position, 4 * beats_per_bar) + 1
        tick_before_position = position - Rational(1, beats_per_bar * ticks_per_beat)

        warn "Transport: received message position change to #{position}" if @do_log

        start_again_later = false

        if @sequencer.position > tick_before_position
          do_stop
          start_again_later = true
        end

        warn "Transport: setting sequencer position #{tick_before_position}" if @do_log
        @sequencer.position = tick_before_position

        @sequencer.raw_at position, force_first: true do
          @on_position_change.each { |block| block.call @sequencer }
        end

        do_on_start if start_again_later
      end
     end

    def before_begin(&block)
      @before_begin << KeyParametersProcedureBinder.new(block)
    end

    def on_start(&block)
      @on_start << KeyParametersProcedureBinder.new(block)
    end

    def before_each_tick(&block)
      @before_each_tick << KeyParametersProcedureBinder.new(block)
    end

    def after_stop(&block)
      @after_stop << KeyParametersProcedureBinder.new(block)
    end

    def on_position_change(&block)
      @on_position_change << KeyParametersProcedureBinder.new(block)
    end

    def start
      do_before_begin

      @clock.run do
        @before_each_tick.each { |block| block.call @sequencer }
        @sequencer.tick
      end
    end

    def stop
      @clock.terminate
      do_stop
    end

    private

    def do_before_begin
      warn 'Transport: doing before_begin initialization...' unless @before_begin.empty? || !@do_log
      @before_begin.each { |block| block.call @sequencer }
      warn 'Transport: doing before_begin initialization... done' unless @before_begin.empty? || !@do_log
    end

    def do_on_start
      warn 'Transport: starting...' unless @on_start.empty? || !@do_log
      @on_start.each { |block| block.call @sequencer }
      warn 'Transport: starting... done'  unless @on_start.empty? || !@do_log
    end

    def do_stop
      warn 'Transport: stoping...' unless @after_stop.empty? || !@do_log
      @after_stop.each { |block| block.call @sequencer }
      warn 'Transport: stoping... done' unless @after_stop.empty? || !@do_log

      warn 'Transport: resetting sequencer...' if @do_log
      @sequencer.reset
      warn 'Transport: resetting sequencer... done' if @do_log

      do_before_begin
    end
  end
end
