require 'set'
require 'midi-events'

require_relative '../core-ext/arrayfy'
require_relative '../core-ext/array-explode-ranges'

module Musa
  # High-level MIDI channel management synchronized with sequencer timeline.
  #
  # Provides voice abstraction for controlling MIDI channels with sequencer-aware
  # note scheduling, duration tracking, sustain pedal management, and fast-forward
  # support for silent timeline catch-up.
  #
  # Each voice represents the state of a MIDI channel (active notes, controllers,
  # sustain pedal) and ties all musical events to the sequencer clock. This ensures
  # correct timing even when running in fast-forward mode or with quantization.
  #
  # @example Basic voice setup
  #   require 'musa-dsl'
  #   require 'midi-communications'
  #
  #   clock = Musa::Clock::TimerClock.new bpm: 120
  #   transport = Musa::Transport::Transport.new clock
  #   output = MIDICommunications::Output.all.first
  #
  #   voices = Musa::MIDIVoices::MIDIVoices.new(
  #     sequencer: transport.sequencer,
  #     output: output,
  #     channels: 0..3
  #   )
  #
  #   voice = voices.voices.first
  #   voice.note pitch: 60, velocity: 90, duration: 1r/4
  #
  # @see MIDIVoices Voice collection manager
  # @see Musa::Sequencer::Sequencer Timeline and scheduling
  # @see https://github.com/arirusso/midi-communications midi-communications gem
  # @see https://github.com/javier-sy/midi-events midi-events gem
  module MIDIVoices
    using Musa::Extension::Arrayfy
    using Musa::Extension::ExplodeRanges

    # High level helpers to drive one or more MIDI channels from a {Musa::Sequencer::Sequencer}.
    #
    # A *voice* represents the state of a given MIDI channel (active notes,
    # controllers, sustain pedal, etc.). {MIDIVoices} ties the life‑cycle of those
    # voices to the sequencer clock so that note durations, waits and callbacks
    # stay in the musical timeline even when running in fast-forward or quantized
    # sessions.
    #
    # Typical usage:
    #
    # @example Basic setup and playback
    #   require 'musa-dsl'
    #   require 'midi-communications'
    #
    #   clock     = Musa::Clock::TimerClock.new bpm: 120
    #   transport = Musa::Transport::Transport.new clock
    #   output    = MIDICommunications::Output.all.first
    #
    #   voices = Musa::MIDIVoices::MIDIVoices.new(
    #     sequencer: transport.sequencer,
    #     output:    output,
    #     channels:  [0, 1] # also accepts ranges such as 0..7
    #   )
    #
    #   voices.voices.first.note pitch: 64, velocity: 90, duration: 1r / 4
    #
    # @example Playing chords
    #   voice = voices.voices.first
    #   voice.note pitch: [60, 64, 67], velocity: 90, duration: 1r
    #
    # @example Using note controls with callbacks
    #   voice = voices.voices.first
    #   note_ctrl = voice.note pitch: 60, duration: nil  # indefinite
    #   note_ctrl.on_stop { puts "Note ended!" }
    #   # ... later:
    #   note_ctrl.note_off
    #
    # @example Fast-forward for silent catch-up
    #   voices.fast_forward = true
    #   # ... replay past events ...
    #   voices.fast_forward = false  # resumes audible output
    #
    # @see Musa::Sequencer::Sequencer
    # @see https://github.com/arirusso/midi-communications MIDICommunications documentation
    # @see https://github.com/javier-sy/midi-events MIDIEvents documentation
    # @note All durations are expressed as Rational numbers representing bars.
    # @note MIDI channels are zero-indexed (0-15), not 1-16.
    class MIDIVoices
      # @return [Boolean] whether verbose logging is enabled.
      attr_accessor :do_log

      # Builds the voice container for one or many MIDI channels.
      #
      # @param sequencer [Musa::Sequencer::Sequencer] sequencer that schedules waits and callbacks.
      # @param output [#puts, nil] anything responding to `puts` that accepts `MIDIEvents::Event`s (typically a MIDICommunications output).
      # @param channels [Array<Numeric>, Range, Numeric] list of MIDI channels to control. Ranges are expanded automatically.
      # @param do_log [Boolean] enables info level logs per emitted message.
      #
      # @return [void]
      def initialize(sequencer:, output:, channels:, do_log: nil)
        do_log ||= false

        @sequencer = sequencer
        @output = output
        @channels = channels.arrayfy.explode_ranges
        @do_log = do_log

        reset
      end

      # Resets the collection recreating every {MIDIVoice}. Useful when the MIDI
      # output has changed or after a panic.
      #
      # @return [void]
      def reset
        @voices = @channels.collect { |channel| MIDIVoice.new(sequencer: @sequencer, output: @output, channel: channel, do_log: @do_log) }.freeze
      end

      # @return [Array<MIDIVoice>] read-only list of per-channel voices.
      attr_reader :voices

      # Enables or disables the fast-forward mode on every voice.
      #
      # When enabled, notes are registered internally but their MIDI messages are
      # not emitted, allowing the sequencer to catch up silently (e.g. when
      # loading a snapshot).
      #
      # @param enabled [Boolean] true to enable fast-forward, false to disable.
      # @return [void]
      def fast_forward=(enabled)
        @voices.each { |voice| voice.fast_forward = enabled }
      end

      # Sends all-notes-off on every channel and (optionally) a MIDI reset.
      #
      # @param reset [Boolean] whether to emit an FF SystemRealtime (panic) message.
      # @return [void]
      def panic(reset: nil)
        reset ||= false

        @voices.each(&:all_notes_off)

        @output.puts MIDIEvents::SystemRealtime.new(0xff) if reset
      end
    end

    private

    # Individual MIDI channel voice with sequencer-synchronized note management.
    #
    # Manages the state of a single MIDI channel including active notes, controller
    # values, and sustain pedal. All note scheduling is tied to the sequencer clock,
    # ensuring proper timing in fast-forward mode or during quantized playback.
    #
    # Supports indefinite notes (manual note-off), automatic note-off scheduling,
    # callbacks on note stop, and fast-forward mode for silent state updates.
    #
    # @example Playing notes
    #   voice = voices.voices.first
    #   voice.note pitch: 60, velocity: 90, duration: 1r/4
    #   voice.note pitch: [60, 64, 67], velocity: 100, duration: 1r  # chord
    #
    # @example Indefinite notes with manual control
    #   note_ctrl = voice.note pitch: 60, duration: nil
    #   note_ctrl.on_stop { puts "Note ended!" }
    #   # ... later:
    #   note_ctrl.note_off
    #
    # @example Controller and sustain pedal
    #   voice.controller[:mod_wheel] = 64
    #   voice.sustain_pedal = 127
    #   voice.controller[:expression] = 100
    #
    # @see MIDIVoices Parent voice collection
    # @see NoteControl Note lifecycle controller
    # @api private
    class MIDIVoice
      # @return [String, nil] optional name used in log messages.
      attr_accessor :name

      # @return [Boolean] whether this voice logs every emitted message.
      attr_accessor :do_log

      # @return [Musa::Sequencer::Sequencer] sequencer driving this voice.
      attr_reader :sequencer

      # @return [#puts, nil] MIDI destination. When nil the voice becomes silent.
      attr_reader :output

      # @return [Integer] MIDI channel number (0-15).
      attr_reader :channel

      # @return [Array<Hash>] metadata for each of the 128 MIDI pitches. Mainly used internally.
      attr_reader :active_pitches

      # @return [Rational] duration (in bars) of a sequencer tick; used to schedule note offs.
      attr_reader :tick_duration

      # @param sequencer [Musa::Sequencer::Sequencer]
      # @param output [#puts, nil]
      # @param channel [Integer] MIDI channel number (0-15).
      # @param name [String, nil] human friendly identifier.
      #
      # @return [void]
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

      # Turns fast-forward on/off for this voice.
      #
      # When disabling it, pending notes that were held silently are sent again
      # so the synth is in sync with the sequencer state.
      #
      # @param enabled [Boolean] true to enable fast-forward, false to disable.
      # @return [void]
      def fast_forward=(enabled)
        if @fast_forward && !enabled
          (0..127).each do |pitch|
            @output.puts MIDIEvents::NoteOn.new(@channel, pitch, @active_pitches[pitch][:velocity]) unless @active_pitches[pitch][:note_controls].empty?
          end
        end

        @fast_forward = enabled
      end

      # @return [Boolean] true when in fast-forward mode (notes registered but not emitted).
      def fast_forward?
        @fast_forward
      end

      # Plays one or several MIDI notes.
      #
      # @param pitchvalue [Numeric, Array<Numeric>, nil] optional shorthand for +pitch+.
      # @param pitch [Numeric, Symbol, Array<Numeric, Symbol>] MIDI note numbers or :silence. Arrays/ranges expand to multiple notes.
      # @param velocity [Numeric, Array<Numeric>] raw velocity (0-127). Defaults to 63.
      # @param duration [Numeric, nil] musical duration in bars. When nil the note stays on until {NoteControl#note_off} is called manually.
      # @param duration_offset [Numeric] offset applied when scheduling the note-off inside the sequencer.
      # @param note_duration [Numeric, nil] alternative duration in bars for legato control.
      # @param velocity_off [Numeric, Array<Numeric>] release velocity (defaults to 63).
      # @return [NoteControl, nil] handler that can be used to attach callbacks.
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

      # @return [ControllersControl] MIDI CC manager for this voice.
      def controller
        @controllers_control
      end

      # Sets the sustain pedal state.
      #
      # @param value [Integer] pedal value (0-127, typically 0 or 127).
      def sustain_pedal=(value)
        @controllers_control[:sustain_pedal] = value
      end

      # @return [Integer, nil] current sustain pedal value.
      def sustain_pedal
        @controllers_control[:sustain_pedal]
      end

      # Sends immediate note-off messages for all active pitches and an all-notes-off message on this channel and resets internal state.
      #
      # @return [void]
      def all_notes_off
        @output.puts MIDIEvents::ChannelMessage.new(0xb, @channel, 0x7b, 0)

        @active_pitches.each do |pitch|
          msg = MIDIEvents::NoteOff.new(@channel, pitch, 0)
          @output&.puts msg unless @fast_forward
        end

        @active_pitches.clear
        fill_active_pitches @active_pitches
      end

      # Logs a message tagging the current voice.
      #
      # @param msg [String] the message to log.
      # @return [void]
      def log(msg)
        @sequencer.logger.info('MIDIVoice') { "voice #{name || @channel}: #{msg}" } if @do_log
      end

      # @return [String] human-readable voice description.
      def to_s
        "voice #{@name} output: #{@output} channel: #{@channel}"
      end

      private

      def fill_active_pitches(pitches)
        (0..127).each do |pitch|
          pitches[pitch] = { note_controls: Set[], velocity: 0 }
        end
      end

      # Manages MIDI Continuous Controller messages for a single channel.
      #
      # Provides a simple hash-like interface mapping controller numbers or
      # symbolic names to values. All values are clamped to 0-127 automatically.
      #
      # @example Using symbolic controller names
      #   voice = voices.voices.first
      #   voice.controller[:mod_wheel] = 64        # Set modulation wheel
      #   voice.controller[:volume] = 100          # Set volume (CC 7)
      #   voice.controller[:expression] = 90       # Set expression (CC 11)
      #   current = voice.controller[:mod_wheel]   # Get current value
      #
      # @example Using numeric controller numbers
      #   voice.controller[1] = 64    # Modulation wheel (CC 1)
      #   voice.controller[7] = 100   # Volume (CC 7)
      #   voice.controller[11] = 90   # Expression (CC 11)
      #
      # @see #sustain_pedal= Dedicated sustain pedal helper
      class ControllersControl
        # @param output [#puts] MIDI output.
        # @param channel [Integer] MIDI channel number.
        #
        # @return [void]
        def initialize(output, channel)
          @output = output
          @channel = channel

          @controller_map = { mod_wheel: 1,
                              breath: 2,
                              volume: 7,
                              expression: 11,
                              general_purpose_1: 16,
                              general_purpose_2: 17,
                              general_purpose_3: 18,
                              general_purpose_4: 19,

                              mod_wheel_lsb: 1 + 32,
                              breath_lsb: 2 + 32,
                              volume_lsb: 7 + 32,
                              expression_lsb: 11 + 32,
                              general_purpose_1_lsb: 16 + 32,
                              general_purpose_2_lsb: 17 + 32,
                              general_purpose_3_lsb: 18 + 32,
                              general_purpose_4_lsb: 19 + 32,

                              sustain_pedal: 64,
                              portamento: 65 }
          @controller = []
        end

        # Sets a controller value, emitting the corresponding Control Change message.
        #
        # @param controller_number_or_symbol [Integer, Symbol] CC number or well-known alias (see +@controller_map+).
        # @param value [Integer] byte value that will be clamped to 0-127.
        #
        # @return [Integer] clamped value
        def []=(controller_number_or_symbol, value)
          number = number_of(controller_number_or_symbol)
          value ||= 0

          @controller[number] = [[0, value].max, 0xff].min
          @output.puts MIDIEvents::ChannelMessage.new(0xb, @channel, number, @controller[number])
        end

        # @return [Integer, nil] last value assigned to the controller.
        def get(controller_number_or_symbol)
          @controller[number_of(controller_number_or_symbol)]
        end

        alias_method :[], :get

        # Resolves a controller reference to its MIDI CC number.
        #
        # @param controller_number_or_symbol [Integer, Symbol] CC number or alias.
        # @return [Integer] MIDI CC number (0-127).
        # @raise [ArgumentError] if the parameter is neither Numeric nor Symbol.
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
        # @return [MIDIVoice] voice that scheduled this control.
        attr_reader :voice

        # @return [Array<Numeric>, Symbol] collection of MIDI note numbers (or :silence entries) handled by the control.
        attr_reader :pitch

        # @return [Array<Numeric>] per-note on velocities.
        attr_reader :velocity

        # @return [Array<Numeric>] per-note off velocities.
        attr_reader :velocity_off

        # @return [Numeric, nil] duration in bars or nil for indefinite notes.
        attr_reader :duration

        # @return [Rational, nil] sequencer position at which the note began.
        attr_reader :start_position

        # @return [Rational, nil] sequencer position of the note-off, if already executed.
        attr_reader :end_position

        # Wraps the state of pedal or note events scheduled by {MIDIVoice#note}.
        #
        # @param voice [MIDIVoice] owning voice.
        # @param pitch [Array<Numeric>, Numeric, Symbol] notes or :silence.
        # @param velocity [Numeric, Array<Numeric>] on velocity (can be per-note).
        # @param duration [Numeric, nil] duration in bars or nil for infinite.
        # @param velocity_off [Numeric, Array<Numeric>] release velocity.
        #
        # @return [void]
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

        # Emits the NoteOn messages and schedules the note-off when applicable.
        #
        # @return [NoteControl]
        def note_on
          @start_position = @voice.sequencer.position
          @end_position = nil

          @pitch.each_index do |i|
            pitch = @pitch[i]
            velocity = @velocity[i % @velocity.size]

            if !silence?(pitch)
              @voice.active_pitches[pitch][:note_controls] << self
              @voice.active_pitches[pitch][:velocity] = velocity

              msg = MIDIEvents::NoteOn.new(@voice.channel, pitch, velocity)
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

        # Stops the note, sending the proper NoteOffs and executing registered callbacks.
        #
        # @param velocity [Numeric, Array<Numeric>] optional override for the release velocity.
        # @return [void]
        def note_off(velocity: nil)
          velocity ||= @velocity_off

          velocity = velocity.arrayfy.explode_ranges

          @pitch.each_index do |i|
            pitch = @pitch[i]
            velocity_off = velocity[i % velocity.size]

            next if silence?(pitch)

            @voice.active_pitches[pitch][:note_controls].delete self

            next unless @voice.active_pitches[pitch][:note_controls].empty?

            msg = MIDIEvents::NoteOff.new(@voice.channel, pitch, velocity_off)
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

        # @return [Boolean] true while the note is sounding (NoteOn sent, NoteOff pending).
        def active?
          @start_position && !@end_position
        end

        # Registers a block to be executed when the note stops.
        #
        # @yield Block to execute when note-off occurs
        # @yieldparam sequencer [Musa::Sequencer::Sequencer]
        # @return [void]
        def on_stop(&block)
          @do_on_stop << block
          nil
        end

        # Registers a block to be executed a number of bars after the note has ended.
        #
        # Useful for scheduling continuations or cleanup logic once the note fully
        # decays in the musical timeline.
        #
        # @param bars [Numeric] delay in bars (can be rational). Defaults to 0.
        # @yieldparam sequencer [Musa::Sequencer::Sequencer]
        # @return [void]
        def after(bars = 0, &block)
          @do_after << { bars: bars.rationalize, block: block }
          nil
        end

        private

        # @return [Boolean] true if the pitch represents a rest/gap.
        # @api private
        def silence?(pitch)
          pitch.nil? || pitch == :silence
        end
      end

      private_constant :NoteControl
    end
  end
end
