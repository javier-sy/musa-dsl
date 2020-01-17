require 'musa-dsl/sequencer'

require 'musa-dsl/core-ext/key-parameters-procedure-binder'

module Musa
  module Transport
    class Transport
      attr_reader :sequencer

      def initialize(clock,
                     beats_per_bar = nil,
                     ticks_per_beat = nil,
                     before_begin: nil,
                     on_start: nil,
                     after_stop: nil,
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

        @on_change_position = []
        @on_change_position << KeyParametersProcedureBinder.new(on_position_change) if on_position_change

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

        @clock.on_change_position do |bars: nil, beats: nil, midi_beats: nil|
          change_position_to bars: bars, beats: beats, midi_beats: midi_beats
        end
      end

      def before_begin(&block)
        @before_begin << KeyParametersProcedureBinder.new(block)
      end

      def on_start(&block)
        @on_start << KeyParametersProcedureBinder.new(block)
      end

      def after_stop(&block)
        @after_stop << KeyParametersProcedureBinder.new(block)
      end

      def on_change_position(&block)
        @on_change_position << KeyParametersProcedureBinder.new(block)
      end

      def start
        do_before_begin unless @before_begin_already_done

        @clock.run do
          @before_begin_already_done = false
          @sequencer.tick
        end
      end

      def change_position_to(bars: nil, beats: nil, midi_beats: nil)
        position = bars.rationalize || 1r
        position += Rational(midi_beats, 4 * @sequencer.beats_per_bar) if midi_beats
        position += Rational(beats, @sequencer.beats_per_bar) if beats

        raise ArgumentError, "undefined new position" unless position

        warn "Transport: received message position change to #{position}" if @do_log

        start_again_later = false

        if @sequencer.position > position
          do_stop
          start_again_later = true
        end

        warn "Transport: setting sequencer position #{position}" if @do_log

        @sequencer.raw_at position, force_first: true do
          @on_change_position.each { |block| block.call @sequencer }
        end

        @sequencer.position = position

        do_on_start if start_again_later
      end

      def stop
        @clock.terminate
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
        @before_begin_already_done = true
      end
    end
  end
end
