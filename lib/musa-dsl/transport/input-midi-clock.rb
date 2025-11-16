require 'midi-parser'

require_relative 'clock'

module Musa
  module Clock
    # Clock synchronized to external MIDI Clock messages.
    #
    # InputMidiClock receives MIDI Clock, Start, Stop, Continue, and Song Position
    # messages from an external source (typically a DAW or hardware sequencer) and
    # generates ticks synchronized to that source.
    #
    # ## MIDI Clock Protocol
    #
    # - **Clock (0xF8)**: Sent 24 times per quarter note
    # - **Start (0xFA)**: Begin playing from start
    # - **Stop (0xFC)**: Stop playing
    # - **Continue (0xFB)**: Resume from current position
    # - **Song Position Pointer (0xF2)**: Jump to specific position
    #
    # ## Features
    #
    # - Automatic synchronization to external MIDI Clock
    # - Position changes via Song Position Pointer
    # - Start/Stop/Continue handling
    # - Performance monitoring (time_table for tick processing times)
    # - Graceful handling of missing input (waits until assigned)
    #
    # ## Special Sequences
    #
    # The clock handles the common sequence: Stop + Song Position + Continue
    # as a position change while running, avoiding unnecessary stop/start cycles.
    #
    # ## Performance Monitoring
    #
    # The time_table tracks processing time per tick in milliseconds, useful
    # for detecting performance issues.
    #
    # @example Basic setup
    #   input = MIDICommunications::Input.all.first
    #   clock = InputMidiClock.new(input, logger: logger)
    #   transport = Transport.new(clock)
    #   transport.start  # Waits for MIDI Clock Start
    #
    # @example Dynamic input assignment
    #   clock = InputMidiClock.new  # No input yet
    #   transport = Transport.new(clock)
    #   transport.start  # Waits for input to be assigned
    #
    #   # Later:
    #   clock.input = MIDICommunications::Input.all.first
    #
    # @example Checking performance
    #   clock.time_table  # => [0 => 1543, 1 => 234, 2 => 12, ...]
    #   # Shows histogram: X ms took Y ticks
    #
    # @see Transport Connects clock to sequencer
    # @see MIDICommunications::Input MIDI input ports
    class InputMidiClock < Clock
      # Creates a new MIDI Clock synchronized clock.
      #
      # @param input [MIDICommunications::Input, nil] MIDI input port.
      #   Can be nil; clock will wait for assignment.
      # @param logger [Logger, nil] logger for messages
      # @param do_log [Boolean, nil] enable debug logging
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

        @time_table = []
        @midi_parser = MIDIParser.new
      end

      # Current MIDI input port.
      #
      # @return [MIDICommunications::Input, nil] the input port
      attr_reader :input

      # Performance timing histogram.
      #
      # Maps processing time in milliseconds to tick count.
      #
      # @return [Array<Integer>] histogram indexed by milliseconds
      #
      # @example
      #   time_table[5]  # => 123 (123 ticks took 5ms)
      attr_reader :time_table

      # Assigns a MIDI input port.
      #
      # If the clock is waiting for input (sleeping), wakes it up.
      #
      # @param input_midi_port [MIDICommunications::Input] MIDI input port
      # @return [MIDICommunications::Input] the assigned input
      def input=(input_midi_port)
        @input = input_midi_port
        @waiting_for_input&.wakeup
      end

      # Runs the MIDI Clock processing loop.
      #
      # This method blocks and processes incoming MIDI messages, generating ticks
      # in response to MIDI Clock messages. If no input is assigned, it waits
      # until one is assigned via {#input=}.
      #
      # ## Message Handling
      #
      # - **Clock**: Yields (generates tick) if started
      # - **Start**: Triggers on_start callbacks
      # - **Stop**: Triggers on_stop callbacks
      # - **Continue**: Resumes (typically after Stop)
      # - **Song Position**: Triggers on_change_position
      #
      # @yield Called once per MIDI Clock message (24 ppqn)
      # @return [void]
      #
      # @note This method blocks until {#terminate} is called
      # @note Waits if no input assigned
      def run
        @run = true

        while @run
          if @input
            # Read raw MIDI messages from input port
            raw_messages = @input.gets
          else
            # No input assigned yet - wait for assignment
            @logger.warn('InputMidiClock') { 'Waiting for clock input MIDI port' }

            @waiting_for_input = Thread.current
            sleep  # Wait until input= wakes us
            @waiting_for_input = nil

            if @input
              @logger.info('InputMidiClock') { "Assigned clock input MIDI port '#{@input.name}'" }
            else
              @logger.warn('InputMidiClock') { 'Clock input MIDI port not found' }
            end
          end

          # Parse raw MIDI bytes into message objects
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

      # Terminates the MIDI Clock processing loop.
      #
      # @return [void]
      def terminate
        @run = false
      end

      private

      # Processes MIDI Start message.
      #
      # Calls registered on_start callbacks and marks as started.
      #
      # @api private
      def process_start
        @logger.debug('InputMidiClock') { 'processing Start...' }

        @on_start.each(&:call)
        @started = true

        @logger.debug('InputMidiClock') { 'processing Start... done' }
      end

      # Processes individual MIDI Clock protocol messages.
      #
      # Handles Start, Stop, Continue, Clock, and Song Position Pointer messages.
      # For Clock messages, yields and tracks processing time.
      #
      # @param m [MIDIEvents::Event] parsed MIDI message
      # @yield Called for Clock messages if started
      # @return [void]
      #
      # @api private
      def process_message(m)
        case m.name
        when 'Start'
          process_start
          @time_table.clear

        when 'Stop'
          @logger.debug('InputMidiClock') { 'processing Stop...' }

          @on_stop.each(&:call)
          @started = false

          @logger.debug('InputMidiClock') { 'processing Stop... done' }

        when 'Continue'
          @logger.debug('InputMidiClock') { 'processing Continue...' }
          @logger.debug('InputMidiClock') { 'processing Continue... done' }

        when 'Clock'
          if block_given? && @started
            start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
            yield
            finish_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)

            duration = finish_time - start_time
            @time_table[duration] ||= 0
            @time_table[duration] += 1
          end

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
