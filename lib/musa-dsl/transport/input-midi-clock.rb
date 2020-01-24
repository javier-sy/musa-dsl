require 'musa-dsl/transport/clock'
require 'nibbler'

module Musa
  module Clock
    class InputMidiClock < Clock
      def initialize(input, do_log: nil)
        do_log ||= false

        super()

        @input = input
        @do_log = do_log

        @nibbler = Nibbler.new
      end

      def run
        @run = true

        while @run
          raw_messages = @input.gets
          @input.buffer.clear

          messages = []
          stop_index = nil

          raw_messages.each do |message|
            mm = @nibbler.parse message[:data]

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

          @nibbler.processed.clear
          @nibbler.rejected.clear
          @nibbler.messages.clear

          size = messages.size
          index = 0
          while index < size
            if index == stop_index && size >= index + 3 &&
                messages[index + 1].name == 'Song Position Pointer' &&
                messages[index + 2].name == 'Continue'

              warn 'InputMidiClock: processing Stop + Song Position Pointer + Continue...' if @do_log

              process_start unless @started

              process_message messages[index + 1] do
                yield if block_given?
              end

              index += 2

              warn 'InputMidiClock: processing Stop + Song Position Pointer + Continue... done' if @do_log

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
        warn 'InputMidiClock: processing Start...' if @do_log

        @on_start.each(&:call)
        @started = true

        warn 'InputMidiClock: processing Start... done' if @do_log
      end

      def process_message(m)

        puts "input-midi-clock.process_message: m = #{m}"
        
        case m.name
        when 'Start'
          process_start

        when 'Stop'
          warn 'InputMidiClock: processing Stop...' if @do_log

          @on_stop.each(&:call)
          @started = false

          warn 'InputMidiClock: processing Stop... done' if @do_log

        when 'Continue'
          warn 'InputMidiClock: processing Continue...' if @do_log
          warn 'InputMidiClock: processing Continue... done' if @do_log

        when 'Clock'
          yield if block_given? && @started

        when 'Song Position Pointer'
          new_position_in_midi_beats =
              m.data[0] & 0x7F | ((m.data[1] & 0x7F) << 7)

          warn "InputMidiClock: processing Song Position Pointer new_position_in_midi_beats #{new_position_in_midi_beats}..." if @do_log
          @on_change_position.each { |block| block.call midi_beats: new_position_in_midi_beats }
          warn "InputMidiClock: processing Song Position Pointer new_position_in_beats #{new_position_in_midi_beats}... done" if @do_log
        end
      end
    end
  end
end
