require 'midi-parser'

module Musa
  module MIDIRecorder
    # Collects raw MIDI bytes alongside the sequencer position and transforms
    # them into note events. It is especially useful when capturing phrases from
    # an external controller that is clocked by the sequencer timeline.
    #
    # @example Complete usage
    #   sequencer = Musa::Sequencer::Sequencer.new(...)
    #   recorder = Musa::MIDIRecorder::MIDIRecorder.new(sequencer)
    #
    #   # During recording:
    #   recorder.record(midi_bytes_from_controller)
    #
    #   # After recording:
    #   notes = recorder.transcription
    #   notes.each { |n| puts "Note: #{n}" }
    #
    #   # Clear for next recording:
    #   recorder.clear
    #
    # @see Musa::Sequencer::Sequencer
    class MIDIRecorder
      # @param sequencer [Musa::Sequencer::Sequencer] provides the musical position for each recorded message.
      def initialize(sequencer)
        @sequencer = sequencer
        @midi_parser = MIDIParser.new

        clear
      end

      # Clears all stored events.
      #
      # @return [void]
      def clear
        @messages = []
      end

      # Records one MIDI packet.
      #
      # @param midi_bytes [String, Array<Integer>] bytes as provided by the MIDI driver.
      # @return [void]
      def record(midi_bytes)
        m = @midi_parser.parse midi_bytes
        m = [m] unless m.is_a? Array

        m.each do |mm|
          @messages << Message.new(@sequencer.position, mm)
        end
      end

      # @return [Array<Message>] unprocessed recorded messages.
      def raw
        @messages
      end

      # Converts the message buffer into a list of note hashes.
      #
      # Each note hash contains the keys :position, :channel, :pitch, :velocity
      # and, when appropriate, :duration and :velocity_off. Silences (gaps between
      # notes on the same channel) are expressed as `pitch: :silence`.
      #
      # @return [Array<Hash>] list of events suitable for Musa transcription pipelines.
      # @example Output format
      #   [
      #     { position: Rational(0,1), channel: 0, pitch: 60, velocity: 100, duration: Rational(1,4), velocity_off: 64 },
      #     { position: Rational(1,4), channel: 0, pitch: :silence, duration: Rational(1,8) },
      #     { position: Rational(3,8), channel: 0, pitch: 62, velocity: 90, duration: Rational(1,4), velocity_off: 64 }
      #   ]
      def transcription
        note_on = {}
        last_note = {}

        notes = []

        @messages.each do |m|
          mm = m.message

          case mm
          when MIDIEvents::NoteOn
            if last_note[mm.channel]
              notes << { position: last_note[mm.channel], channel: mm.channel, pitch: :silence, duration: m.position - last_note[mm.channel] }
              last_note.delete mm.channel
            end

            note = { position: m.position, channel: mm.channel, pitch: mm.note, velocity: mm.velocity }

            note_on[mm.channel] ||= {}
            note_on[mm.channel][mm.note] = note

            notes << note

          when MIDIEvents::NoteOff
            note_on[mm.channel] ||= {}

            note = note_on[mm.channel][mm.note]

            if note
              note_on[mm.channel].delete mm.note

              note[:duration] = m.position - note[:position]
              note[:velocity_off] = mm.velocity
            end

            last_note[mm.channel] = m.position
          end
        end

        notes
      end

      # Internal representation of a captured MIDI message linked to its sequencer position.
      # @api private
      class Message
        # @return [Rational] sequencer position where the message was captured.
        attr_reader :position

        # @return [MIDIEvents::Event] parsed MIDI event.
        attr_reader :message

        # Creates a new message entry.
        #
        # @param position [Rational] sequencer position when captured.
        # @param message [MIDIEvents::Event] parsed MIDI event.
        def initialize(position, message)
          @position = position
          @message = message
        end
      end

      private_constant :Message
    end
  end
end
