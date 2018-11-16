require 'midi-message'

require 'musa-dsl/mods/array-apply-get'
require 'musa-dsl/mods/arrayfy'

module Musa
  class MIDIVoices
    attr_accessor :log

    def initialize(sequencer:, output:, channels:, do_log: nil)
      do_log ||= false

      @sequencer = sequencer
      @output = output
      @channels = channels.arrayfy.explode_ranges
      @do_log = do_log

      reset
    end

    def reset
      @voices = @channels.collect { |channel| MIDIVoice.new sequencer: @sequencer, output: @output, channel: channel, log: @do_log }
    end

    def voice(index)
      @voices[index]
    end

    def size
      @voices.size
    end

    def fast_forward=(enabled)
      @voices.apply :fast_forward=, enabled
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
    attr_reader :sequencer, :output, :channel, :used_pitches, :tick_duration

    def initialize(sequencer:, output:, channel:, name: nil, log: nil)
      log ||= false

      @sequencer = sequencer
      @output = output
      @channel = channel
      @name = name
      @do_log = log

      @tick_duration = Rational(1, @sequencer.ticks_per_bar)

      @used_pitches = []
      fill_used_pitches @used_pitches

      @controller = {}

      log 'Warning: voice without output' unless @output

      self
    end

    def fast_forward=(enabled)
      if @fast_forward && !enabled
        (0..127).each do |pitch|
          @output.puts MIDIMessage::NoteOn.new(@channel, pitch, @used_pitches[pitch][:velocity]) if @used_pitches[pitch][:counter] > 0
        end
      end

      @fast_forward = enabled
    end

    def fast_forward?
      @fast_forward
    end

    def note(pitchvalue = nil, pitch: nil, velocity: nil, duration: nil, velocity_off: 63)
      pitch ||= pitchvalue
      velocity ||= 63
      NoteControl.new self, pitch: pitch, velocity: velocity, duration: duration, velocity_off: velocity_off
    end

    def note_off(pitchvalue = nil, pitch: nil, velocity_off: nil, force: nil)
      pitch ||= pitchvalue
      velocity_off ||= 63

      NoteControl.new(self, pitch: pitch, velocity_off: velocity_off, play: false).note_off force: force
      nil
    end

    def sustain_pedal=(value)
      @controller[:sustain_pedal] = value
      @output.puts MIDIMessage::ChannelMessage.new(0xb, @channel, 0x40, value % 128)
      nil
    end

    def sustain_pedal
      @controller[:sustain_pedal]
    end

    def all_notes_off
      @used_pitches.clear
      fill_used_pitches @used_pitches

      @output.puts MIDIMessage::ChannelMessage.new(0xb, @channel, 0x7b, 0)
    end

    def log(msg)
      @sequencer.log "voice #{name || @channel}: #{msg}" if @do_log
    end

    def to_s
      "voice #{@name} output: #{@output} channel: #{@channel}"
      end

    private

    def fill_used_pitches(pitches)
      (0..127).each do |pitch|
        pitches[pitch] = { counter: 0, velocity: 0 }
      end
    end

    class NoteControl
      def initialize(voice, pitch:, velocity: nil, duration: nil, velocity_off: nil, play: true)
        raise ArgumentError, "MIDIVoice: note duration should be nil or Numeric: #{duration} (#{duration.class})" unless duration.nil? || duration.is_a?(Numeric)

        @voice = voice

        @pitch = pitch.arrayfy.explode_ranges
        @velocity = velocity.arrayfy.explode_ranges
        @velocity_off = velocity_off.arrayfy.explode_ranges

        @do_on_stop = []
        @do_after = []

        if play
          @pitch.each_index do |i|
            pitch = @pitch[i]
            velocity = @velocity[i % @velocity.size]
            velocity_off = @velocity_off[i % @velocity_off.size]

            if !silence?(pitch)
              @voice.used_pitches[pitch][:counter] += 1
              @voice.used_pitches[pitch][:velocity] = velocity

              msg = MIDIMessage::NoteOn.new(@voice.channel, pitch, velocity)
              @voice.log "#{msg.verbose_name} velocity: #{velocity} duration: #{duration}"
              @voice.output.puts msg if @voice.output && !@voice.fast_forward?
            else
              @voice.log "silence duration: #{duration}"
            end
          end

          if duration
            this = self
            @voice.sequencer.wait duration - @voice.tick_duration do
              this.note_off velocity: velocity_off
            end
          end
        end

        self
      end

      def note_off(velocity: nil, force: nil)
        velocity ||= @velocity_off
        force ||= false

        velocity = velocity.arrayfy.explode_ranges

        @pitch.each_index do |i|
          pitch = @pitch[i]
          velocity_off = velocity[i % velocity.size]

          next if silence?(pitch)

          @voice.used_pitches[pitch][:counter] = 1 if force

          @voice.used_pitches[pitch][:counter] -= 1
          @voice.used_pitches[pitch][:counter] = 0 if @voice.used_pitches[pitch][:counter] < 0

          next unless @voice.used_pitches[pitch][:counter] == 0

          msg = MIDIMessage::NoteOff.new(@voice.channel, pitch, velocity)
          @voice.log msg.verbose_name.to_s
          @voice.output.puts msg if @voice.output && !@voice.fast_forward?
        end

        @do_on_stop.each do |do_on_stop|
          @voice.sequencer.wait 0, &do_on_stop
        end

        @do_after.each do |do_after|
          @voice.sequencer.wait @voice.tick_duration + do_after[:bars], &do_after[:block]
        end

        nil
      end

      def silence?(pitch)
        pitch.nil? || pitch == :silence
      end

      def on_stop(&block)
        @do_on_stop << block
        nil
      end

      def after(bars = 0, &block)
        @do_after << { bars: bars.rationalize, block: block }
        nil
      end
    end
  end
end
