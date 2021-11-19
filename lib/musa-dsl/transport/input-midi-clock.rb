require 'midi-parser'

require_relative 'clock'

module Musa
  module Clock
    class InputMidiClock < Clock
      def initialize(input = nil, logger: nil, do_log: nil)
        do_log ||= false

        super()

        @logger = logger

        self.input = input

        if logger
          @logger = logger
        else
          @logger = Musa::Logger::Logger.new
          @logger.debug! if do_log
        end

        @midi_parser = MIDIParser.new
      end

      attr_reader :input

      def input=(input_midi_port)
        @input = input_midi_port
        @waiting_for_input&.wakeup
      end

      def run
        @run = true

        while @run
          if @input
            raw_messages = @input.gets
          else
            @logger.warn('InputMidiClock') { 'Waiting for clock input MIDI port' }

            @waiting_for_input = Thread.current
            sleep
            @waiting_for_input = nil

            @logger.info('InputMidiClock') { "Assigned clock input MIDI port '#{@input.name}'" }
          end

          messages = []
          stop_index = nil

          raw_messages&.each do |message|
            mm = @midi_parser.parse message[:data]

            if mm
              if mm.is_a? Array
                mm.each do |m|
                  stop_index = messages.size if m.name == 'Stop' && !stop_index
                  messages << m
                end
              else
                stop_index = messages.size if mm.name == 'Stop' && !stop_index
                messages << mm
              end
            end
          end

          size = messages.size
          index = 0
          while index < size
            if index == stop_index && size >= index + 3 &&
                messages[index + 1].name == 'Song Position Pointer' &&
                messages[index + 2].name == 'Continue'

              @logger.debug('InputMidiClock') { 'processing Stop + Song Position Pointer + Continue...' }

              process_start unless @started

              process_message messages[index + 1] do
                yield if block_given?
              end

              index += 2

              @logger.debug('InputMidiClock') { 'processing Stop + Song Position Pointer + Continue... done' }

            else
              process_message messages[index] do
                yield if block_given?
              end
            end

            index += 1
          end

          Thread.pass
        end
      end

      def terminate
        @run = false
      end

      private

      def process_start
        @logger.debug('InputMidiClock') { 'processing Start...' }

        @on_start.each(&:call)
        @started = true

        @logger.debug('InputMidiClock') { 'processing Start... done' }
      end

      def process_message(m)
        case m.name
        when 'Start'
          process_start

        when 'Stop'
          @logger.debug('InputMidiClock') { 'processing Stop...' }

          @on_stop.each(&:call)
          @started = false

          @logger.debug('InputMidiClock') { 'processing Stop... done' }

        when 'Continue'
          @logger.debug('InputMidiClock') { 'processing Continue...' }
          @logger.debug('InputMidiClock') { 'processing Continue... done' }

        when 'Clock'
          yield if block_given? && @started

        when 'Song Position Pointer'
          new_position_in_midi_beats = m.data[0] & 0x7F | ((m.data[1] & 0x7F) << 7)

          @logger.debug('InputMidiClock') do
            "processing Song Position Pointer new_position_in_midi_beats #{new_position_in_midi_beats}..."
          end
          @on_change_position.each { |block| block.call midi_beats: new_position_in_midi_beats }
          @logger.debug('InputMidiClock') do
            "processing Song Position Pointer new_position_in_beats #{new_position_in_midi_beats}... done"
          end
        end
      end
    end
  end
end
