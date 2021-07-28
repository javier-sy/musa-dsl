require 'set'
require 'midi-message'

require_relative '../core-ext/arrayfy'
require_relative '../core-ext/array-explode-ranges'

using Musa::Extension::Arrayfy
using Musa::Extension::ExplodeRanges

module Musa
  module MIDIVoices
    class MIDIVoices
      attr_accessor :do_log

      def initialize(sequencer:, output:, channels:, do_log: nil)
        do_log ||= false

        @sequencer = sequencer
        @output = output
        @channels = channels.arrayfy.explode_ranges
        @do_log = do_log

        reset
      end

      def reset
        @voices = @channels.collect { |channel| MIDIVoice.new(sequencer: @sequencer, output: @output, channel: channel, do_log: @do_log) }.freeze
      end

      attr_reader :voices

      def fast_forward=(enabled)
        @voices.each { |voice| voice.fast_forward = enabled }
      end

      def panic(reset: nil)
        reset ||= false

        @voices.each(&:all_notes_off)

        @output.puts MIDIMessage::SystemRealtime.new(0xff) if reset
      end
    end

    private

    class MIDIVoice
      attr_accessor :name, :do_log
      attr_reader :sequencer, :output, :channel, :active_pitches, :tick_duration

      def initialize(sequencer:, output:, channel:, name: nil, do_log: nil)
        do_log ||= false

        @sequencer = sequencer
        @output = output
        @channel = channel
        @name = name
        @do_log = do_log

        @tick_duration = Rational(1, @sequencer.ticks_per_bar)

        @controllers_control = ControllersControl.new(@output, @channel)

        @active_pitches = []
        fill_active_pitches @active_pitches

        @sequencer.logger.warn 'voice without output' unless @output

        self
      end

      def fast_forward=(enabled)
        if @fast_forward && !enabled
          (0..127).each do |pitch|
            @output.puts MIDIMessage::NoteOn.new(@channel, pitch, @active_pitches[pitch][:velocity]) unless @active_pitches[pitch][:note_controls].empty?
          end
        end

        @fast_forward = enabled
      end

      def fast_forward?
        @fast_forward
      end

      def note(pitchvalue = nil, pitch: nil, velocity: nil, duration: nil, duration_offset: nil, note_duration: nil, velocity_off: nil)
        pitch ||= pitchvalue

        if pitch
          velocity ||= 63

          duration_offset ||= -@tick_duration
          note_duration ||= [0, duration + duration_offset].max

          velocity_off ||= 63

          NoteControl.new(self, pitch: pitch, velocity: velocity, duration: note_duration, velocity_off: velocity_off).note_on
        end
      end

      def controller
        @controllers_control
      end

      def sustain_pedal=(value)
        @controllers_control[:sustain_pedal] = value
      end

      def sustain_pedal
        @controllers_control[:sustain_pedal]
      end

      def all_notes_off
        @active_pitches.clear
        fill_active_pitches @active_pitches

        @output.puts MIDIMessage::ChannelMessage.new(0xb, @channel, 0x7b, 0)
      end

      def log(msg)
        @sequencer.logger.info('MIDIVoice') { "voice #{name || @channel}: #{msg}" } if @do_log
      end

      def to_s
        "voice #{@name} output: #{@output} channel: #{@channel}"
      end

      private

      def fill_active_pitches(pitches)
        (0..127).each do |pitch|
          pitches[pitch] = { note_controls: Set[], velocity: 0 }
        end
      end

      class ControllersControl
        def initialize(output, channel)
          @output = output
          @channel = channel

          @controller_map = { sustain_pedal: 0x40 }
          @controller = []
        end

        def []=(controller_number_or_symbol, value)
          number = number_of(controller_number_or_symbol)
          value ||= 0

          @controller[number] = [[0, value].max, 0xff].min
          @output.puts MIDIMessage::ChannelMessage.new(0xb, @channel, number, @controller[number])
        end

        def [](controller_number_or_symbol)
          @controller[number_of(controller_number_or_symbol)]
        end

        def number_of(controller_number_or_symbol)
          case controller_number_or_symbol
          when Numeric
            controller_number_or_symbol.to_i
          when Symbol
            @controller_map[controller_number_or_symbol]
          else
            raise ArgumentError, "#{controller_number_or_symbol} is not a Numeric nor a Symbol. Only MIDI controller numbers are allowed"
          end
        end
      end

      private_constant :ControllersControl

      class NoteControl
        attr_reader :voice, :pitch, :velocity, :velocity_off, :duration
        attr_reader :start_position, :end_position

        def initialize(voice, pitch:, velocity: nil, duration: nil, velocity_off: nil)
          raise ArgumentError, "MIDIVoice: note duration should be nil or Numeric: #{duration} (#{duration.class})" unless duration.nil? || duration.is_a?(Numeric)

          @voice = voice

          @pitch = pitch.arrayfy.explode_ranges

          @velocity = velocity.arrayfy.explode_ranges
          @velocity_off = velocity_off.arrayfy.explode_ranges

          @duration = duration

          @do_on_stop = []
          @do_after = []

          @start_position = @end_position = nil
        end

        def note_on
          @start_position = @voice.sequencer.position
          @end_position = nil

          @pitch.each_index do |i|
            pitch = @pitch[i]
            velocity = @velocity[i % @velocity.size]

            if !silence?(pitch)
              @voice.active_pitches[pitch][:note_controls] << self
              @voice.active_pitches[pitch][:velocity] = velocity

              msg = MIDIMessage::NoteOn.new(@voice.channel, pitch, velocity)
              @voice.log "#{msg.verbose_name} velocity: #{velocity} duration: #{@duration}"
              @voice.output.puts msg if @voice.output && !@voice.fast_forward?
            else
              @voice.log "silence duration: #{@duration}"
            end
          end

          return self unless @duration

          this = self
          @voice.sequencer.wait @duration do
            this.note_off velocity: @velocity_off
          end

          self
        end

        def note_off(velocity: nil)
          velocity ||= @velocity_off

          velocity = velocity.arrayfy.explode_ranges

          @pitch.each_index do |i|
            pitch = @pitch[i]
            velocity_off = velocity[i % velocity.size]

            next if silence?(pitch)

            @voice.active_pitches[pitch][:note_controls].delete self

            next unless @voice.active_pitches[pitch][:note_controls].empty?

            msg = MIDIMessage::NoteOff.new(@voice.channel, pitch, velocity_off)
            @voice.log msg.verbose_name.to_s
            @voice.output.puts msg if @voice.output && !@voice.fast_forward?
          end

          @end_position = @voice.sequencer.position

          @do_on_stop.each do |do_on_stop|
            @voice.sequencer.wait 0, &do_on_stop
          end

          @do_after.each do |do_after|
            @voice.sequencer.wait @voice.tick_duration + do_after[:bars], &do_after[:block]
          end

          nil
        end

        def active?
          @start_position && !@end_position
        end

        def on_stop(&block)
          @do_on_stop << block
          nil
        end

        def after(bars = 0, &block)
          @do_after << { bars: bars.rationalize, block: block }
          nil
        end

        private

        def silence?(pitch)
          pitch.nil? || pitch == :silence
        end
      end

      private_constant :NoteControl
    end
  end
end
