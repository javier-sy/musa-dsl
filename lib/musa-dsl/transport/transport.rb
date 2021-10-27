require_relative '../core-ext/smart-proc-binder'
require_relative '../core-ext/inspect-nice'
require_relative '../sequencer'

module Musa
  module Transport
    class Transport
      using Musa::Extension::InspectNice

      attr_reader :sequencer

      def initialize(clock,
                     beats_per_bar = nil,
                     ticks_per_beat = nil,
                     sequencer: nil,
                     before_begin: nil,
                     on_start: nil,
                     after_stop: nil,
                     on_position_change: nil,
                     logger: nil,
                     do_log: nil)

        beats_per_bar ||= 4
        ticks_per_beat ||= 24
        do_log ||= false

        @clock = clock

        @before_begin = []
        @before_begin << Musa::Extension::SmartProcBinder::SmartProcBinder.new(before_begin) if before_begin

        @on_start = []
        @on_start << Musa::Extension::SmartProcBinder::SmartProcBinder.new(on_start) if on_start

        @on_change_position = []
        @on_change_position << Musa::Extension::SmartProcBinder::SmartProcBinder.new(on_position_change) if on_position_change

        @after_stop = []
        @after_stop << Musa::Extension::SmartProcBinder::SmartProcBinder.new(after_stop) if after_stop

        @do_log = do_log

        @sequencer ||= Musa::Sequencer::Sequencer.new beats_per_bar, ticks_per_beat, logger: logger, do_log: @do_log

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
        @before_begin << Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)
      end

      def on_start(&block)
        @on_start << Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)
      end

      def after_stop(&block)
        @after_stop << Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)
      end

      def on_change_position(&block)
        @on_change_position << Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)
      end

      def start
        do_before_begin unless @before_begin_already_done

        @clock.run do
          @before_begin_already_done = false
          @sequencer.tick
        end
      end

      def change_position_to(bars: nil, beats: nil, midi_beats: nil)
        logger.debug('Transport') do
          "asked to change position to #{"#{bars} bars " if bars}#{"#{beats} beats " if beats}" \
          "#{"#{midi_beats} midi beats " if midi_beats}"
        end

        position = bars&.rationalize || 1r
        position += Rational(midi_beats, 4 * @sequencer.beats_per_bar) if midi_beats
        position += Rational(beats, @sequencer.beats_per_bar) if beats

        position -= @sequencer.tick_duration

        raise ArgumentError, "undefined new position" unless position

        logger.debug('Transport') { "received message position change to #{position.inspect}" }

        start_again_later = false

        if @sequencer.position > position
          do_stop
          start_again_later = true
        end

        logger.debug('Transport') { "setting sequencer position #{position.inspect}" }

        @sequencer.raw_at position, force_first: true do
          @on_change_position.each { |block| block.call @sequencer }
        end

        @sequencer.position = position

        do_on_start if start_again_later
      end

      def stop
        @clock.terminate
      end

      def logger
        @sequencer.logger
      end

      private

      def do_before_begin
        logger.debug('Transport') { 'doing before_begin initialization...' } unless @before_begin.empty?
        @before_begin.each { |block| block.call @sequencer }
        logger.debug('Transport') { 'doing before_begin initialization... done' } unless @before_begin.empty?
      end

      def do_on_start
        logger.debug('Transport') { 'starting...' } unless @on_start.empty?
        @on_start.each { |block| block.call @sequencer }
        logger.debug('Transport') { 'starting... done' } unless @on_start.empty?
      end

      def do_stop
        logger.debug('Transport') { 'stopping...' } unless @after_stop.empty?
        @after_stop.each { |block| block.call @sequencer }
        logger.debug('Transport') { 'stopping... done' } unless @after_stop.empty?

        logger.debug('Transport') { 'resetting sequencer...' }
        @sequencer.reset
        logger.debug('Transport') { 'resetting sequencer... done' }

        do_before_begin
        @before_begin_already_done = true
      end
    end
  end
end
