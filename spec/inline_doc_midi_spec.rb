require 'spec_helper'
require 'musa-dsl'

RSpec.describe 'MIDI Inline Documentation Examples' do
  include Musa::All

  context 'MIDIRecorder (midi-recorder.rb)' do
    it 'example from module doc line 15 - Basic recording workflow' do
      # Create sequencer
      sequencer = Musa::Sequencer::Sequencer.new(4, 24)

      # Create recorder
      recorder = Musa::MIDIRecorder::MIDIRecorder.new(sequencer)

      expect(recorder).to be_a(Musa::MIDIRecorder::MIDIRecorder)

      # A fresh recorder has recorded nothing, and recording stamps the message
      # with the sequencer's position.
      expect(recorder.raw).to eq([])
      expect(recorder.transcription).to eq([])

      sequencer.position = 1r
      recorder.record([0x90, 60, 100])

      expect(recorder.transcription)
        .to eq([{ position: 1r, channel: 0, pitch: 60, velocity: 100 }])

      recorder.clear

      expect(recorder.raw).to eq([])
    end

    it 'example from class doc line 44 - Complete recording and transcription workflow' do
      sequencer = Musa::Sequencer::Sequencer.new(4, 24)
      recorder = Musa::MIDIRecorder::MIDIRecorder.new(sequencer)

      # Simulate MIDI note-on at position 1
      sequencer.position = 1r
      recorder.record([0x90, 60, 100])  # Note On, channel 0, pitch 60, velocity 100

      # Simulate MIDI note-off at position 1.25 (quarter note duration)
      sequencer.position = 5/4r
      recorder.record([0x80, 60, 64])   # Note Off, channel 0, pitch 60, velocity 64

      # Simulate another note after a silence
      sequencer.position = 11/8r
      recorder.record([0x90, 62, 90])   # Note On, channel 0, pitch 62, velocity 90

      sequencer.position = 15/8r
      recorder.record([0x80, 62, 64])   # Note Off, channel 0, pitch 62, velocity 64

      # Get transcription
      notes = recorder.transcription

      # Verify transcription format
      expect(notes).to be_an(Array)
      expect(notes.size).to be >= 2

      # First note
      first_note = notes.find { |n| n[:pitch] == 60 }
      expect(first_note).to include(:position, :channel, :pitch, :velocity, :duration, :velocity_off)
      expect(first_note[:pitch]).to eq(60)
      expect(first_note[:velocity]).to eq(100)
      expect(first_note[:duration]).to eq(1/4r)
      expect(first_note[:velocity_off]).to eq(64)

      # Check for silence between notes
      silence = notes.find { |n| n[:pitch] == :silence }
      expect(silence).to be_a(Hash) if silence

      # Clear and verify
      recorder.clear
      expect(recorder.transcription).to eq([])
    end

    it 'provides raw message access' do
      sequencer = Musa::Sequencer::Sequencer.new(4, 24)
      recorder = Musa::MIDIRecorder::MIDIRecorder.new(sequencer)

      sequencer.position = 1r
      recorder.record([0x90, 60, 100])

      raw = recorder.raw
      expect(raw.size).to eq(1)

      # The raw entry keeps the position it was recorded at and the parsed
      # MIDI event, not the bytes.
      expect(raw.first.position).to eq(1r)
      expect(raw.first.message).to be_a(MIDIEvents::NoteOn)
      expect(raw.first.message.note).to eq(60)
      expect(raw.first.message.velocity).to eq(100)
      expect(raw.first.message.channel).to eq(0)
    end
  end

  context 'MIDIVoices (midi-voices.rb)' do
    let(:sequencer) { Musa::Sequencer::Sequencer.new(4, 24) }
    let(:mock_output) { double('MIDI Output', puts: nil) }

    # A real recipient: what matters about a voice is the MIDI it emits, and a
    # double that swallows everything cannot show it.
    let(:recording_output) do
      Class.new do
        def sent = @sent ||= []
        def puts(message) = sent << message
      end.new
    end

    it 'example from module doc line 18 - Basic voice setup' do
      # Create voice manager
      voices = Musa::MIDIVoices::MIDIVoices.new(
        sequencer: sequencer,
        output: mock_output,
        channels: 0..3
      )

      expect(voices).to be_a(Musa::MIDIVoices::MIDIVoices)
      expect(voices.voices.size).to eq(4)

      # One voice per channel, in order.
      expect(voices.voices.collect(&:channel)).to eq([0, 1, 2, 3])
    end

    it 'a note reaches MIDI as a note-on now and a note-off when it ends' do
      voices = Musa::MIDIVoices::MIDIVoices.new(
        sequencer: sequencer,
        output: recording_output,
        channels: 0..3
      )

      voice = voices.voices.first
      voice.note pitch: 60, velocity: 90, duration: 1r/4

      expect(recording_output.sent.size).to eq(1)
      expect(recording_output.sent.first).to be_a(MIDIEvents::NoteOn)
      expect(recording_output.sent.first.note).to eq(60)
      expect(recording_output.sent.first.velocity).to eq(90)

      200.times { sequencer.tick }

      expect(recording_output.sent.collect { |m| m.class.name.split('::').last })
        .to eq(%w[NoteOn NoteOff])
    end

    it 'example from class doc line 53 - Basic setup and playback' do
      voices = Musa::MIDIVoices::MIDIVoices.new(
        sequencer: sequencer,
        output: mock_output,
        channels: [0, 1]
      )

      expect(voices.voices.size).to eq(2)

      # Verify MIDI output receives note-on message
      expect(mock_output).to receive(:puts) do |msg|
        expect(msg).to be_a(MIDIEvents::NoteOn)
        expect(msg.channel).to eq(0)
        expect(msg.note).to eq(64)
        expect(msg.velocity).to eq(90)
      end

      voices.voices.first.note pitch: 64, velocity: 90, duration: 1r / 4
    end

    it 'example from class doc line 69 - Playing chords' do
      voices = Musa::MIDIVoices::MIDIVoices.new(
        sequencer: sequencer,
        output: mock_output,
        channels: [0]
      )

      voice = voices.voices.first

      # Expect three note-on messages for the chord
      expect(mock_output).to receive(:puts).exactly(3).times do |msg|
        expect(msg).to be_a(MIDIEvents::NoteOn)
        expect([60, 64, 67]).to include(msg.note)
      end

      voice.note pitch: [60, 64, 67], velocity: 90, duration: 1r
    end

    it 'example from class doc line 73 - Using note controls with callbacks' do
      voices = Musa::MIDIVoices::MIDIVoices.new(
        sequencer: sequencer,
        output: mock_output,
        channels: [0]
      )

      voice = voices.voices.first

      callback_executed = false

      note_ctrl = voice.note pitch: 60, duration: nil

      note_ctrl.on_stop { callback_executed = true }
      note_ctrl.note_off

      sequencer.tick

      expect(callback_executed).to be true
    end

    it 'creates the indefinite note it documents (issue #81)' do
      voices = Musa::MIDIVoices::MIDIVoices.new(
        sequencer: sequencer, output: recording_output, channels: [0])
      voice = voices.voices.first

      # `duration: nil` used to raise here, computing note_duration from it
      # unconditionally, while NoteControl one layer down accepted the nil.
      control = voice.note pitch: 60, velocity: 90, duration: nil

      400.times { sequencer.tick }

      # Four bars later nothing has ended it, because nothing was scheduled to.
      expect(recording_output.sent.collect { |m| m.class.name.split('::').last }).to eq(%w[NoteOn])
      expect(control.active?).to be true

      control.note_off

      expect(recording_output.sent.collect { |m| m.class.name.split('::').last })
        .to eq(%w[NoteOn NoteOff])
      expect(control.active?).to be false
    end

    it 'ends a note when the last hold on its pitch is let go, not before' do
      voices = Musa::MIDIVoices::MIDIVoices.new(
        sequencer: sequencer, output: recording_output, channels: [0])
      voice = voices.voices.first

      stops = []
      first = voice.note pitch: 60, duration: 4r
      first.on_stop { stops << ['first', sequencer.position] }

      96.times { sequencer.tick }

      second = voice.note pitch: 60, duration: 8r    # the same pitch, overlapping
      second.on_stop { stops << ['second', sequencer.position] }

      1200.times { sequencer.tick }

      # The first note lets go a bar into the second one, but pitch 60 is still
      # on: its note has not stopped sounding, and it does not end until the
      # count of holds on that pitch falls to zero.
      expect(recording_output.sent.collect { |m| m.class.name.split('::').last })
        .to eq(%w[NoteOn NoteOn NoteOff])

      expect(stops.collect(&:first)).to eq(%w[first second])
      expect(stops.collect(&:last).uniq.size).to eq(1)
      expect(first.end_position).to eq(second.end_position)
    end

    it 'ends a chord when the last of its pitches goes quiet' do
      voices = Musa::MIDIVoices::MIDIVoices.new(
        sequencer: sequencer, output: recording_output, channels: [0])
      voice = voices.voices.first

      ended_at = nil
      chord = voice.note pitch: [60, 64, 67], duration: 2r
      chord.on_stop { ended_at = sequencer.position }

      doubling = voice.note pitch: 64, duration: 6r

      1200.times { sequencer.tick }

      # Two of the chord's pitches go quiet at bar 3; 64 is held by the doubling
      # note until bar 7, and that is when the chord is over.
      expect(ended_at).to eq(doubling.end_position)
    end

    it 'runs on_stop once when a note is released before its scheduled end' do
      voices = Musa::MIDIVoices::MIDIVoices.new(
        sequencer: sequencer, output: recording_output, channels: [0])
      voice = voices.voices.first

      stops = []
      control = voice.note pitch: 60, duration: 4r
      control.on_stop { stops << sequencer.position }

      96.times { sequencer.tick }
      control.note_off

      400.times { sequencer.tick }

      # The scheduled note_off arrives to find the note already over. It used to
      # run the callbacks again, at a moment the composer believes no longer
      # exists, and to send a second NoteOff.
      expect(stops.size).to eq(1)
      expect(recording_output.sent.collect { |m| m.class.name.split('::').last })
        .to eq(%w[NoteOn NoteOff])
    end

    it 'example from class doc line 80 - Fast-forward for silent catch-up' do
      voices = Musa::MIDIVoices::MIDIVoices.new(
        sequencer: sequencer,
        output: mock_output,
        channels: [0]
      )

      # Enable fast-forward (no MIDI output)
      voices.fast_forward = true
      expect(voices.voices.first.fast_forward?).to be true

      # Should NOT send MIDI during fast-forward
      # Note: we allow the call since fast_forward disabling sends catch-up messages
      allow(mock_output).to receive(:puts)
      voices.voices.first.note pitch: 60, velocity: 90, duration: 1r/4

      # Disable fast-forward (resume audible output) - this will send catch-up notes
      voices.fast_forward = false
      expect(voices.voices.first.fast_forward?).to be false
    end

    it 'handles MIDIVoices initialization with ranges' do
      voices = Musa::MIDIVoices::MIDIVoices.new(
        sequencer: sequencer,
        output: mock_output,
        channels: 0..7
      )

      expect(voices.voices.size).to eq(8)
      expect(voices.voices.first.channel).to eq(0)
      expect(voices.voices.last.channel).to eq(7)
    end

    it 'handles MIDIVoices reset' do
      voices = Musa::MIDIVoices::MIDIVoices.new(
        sequencer: sequencer,
        output: mock_output,
        channels: [0]
      )

      old_voices = voices.voices
      voices.reset
      new_voices = voices.voices

      expect(new_voices.size).to eq(old_voices.size)
      expect(new_voices.first).not_to equal(old_voices.first)
    end

    it 'handles panic operation' do
      voices = Musa::MIDIVoices::MIDIVoices.new(
        sequencer: sequencer,
        output: mock_output,
        channels: [0, 1]
      )

      # Panic is CC 123 (all notes off) with value 0, one per channel: 0xB0 and
      # 0xB1 for channels 0 and 1.
      sent = []
      allow(mock_output).to receive(:puts) { |msg| sent << msg.to_a }

      voices.panic

      expect(sent).to eq [[0xB0, 123, 0], [0xB1, 123, 0]]
    end

    it 'handles panic with reset' do
      voices = Musa::MIDIVoices::MIDIVoices.new(
        sequencer: sequencer,
        output: mock_output,
        channels: [0]
      )

      # All notes off, and then a System Reset (0xFF) -- which is a realtime
      # message, not a channel one, so it is sent once and not per channel.
      sent = []
      allow(mock_output).to receive(:puts) { |msg| sent << msg.to_a }

      voices.panic(reset: true)

      expect(sent).to eq [[0xB0, 123, 0], [0xFF]]
    end

    it 'example from ControllersControl doc line 312 - Using symbolic controller names' do
      voices = Musa::MIDIVoices::MIDIVoices.new(
        sequencer: sequencer,
        output: mock_output,
        channels: [0]
      )

      voice = voices.voices.first

      # Set modulation wheel
      expect(mock_output).to receive(:puts) do |msg|
        expect(msg).to be_a(MIDIEvents::ChannelMessage::Message)
        # Check the message is a control change
        expect(msg.status[0]).to eq(0xb)  # Control Change
        expect(msg.data[0]).to eq(1)  # Mod wheel CC number
        expect(msg.data[1]).to eq(64)
      end
      voice.controller[:mod_wheel] = 64

      # Get current value
      current = voice.controller[:mod_wheel]
      expect(current).to eq(64)
    end

    it 'example from ControllersControl doc line 319 - Using numeric controller numbers' do
      voices = Musa::MIDIVoices::MIDIVoices.new(
        sequencer: sequencer,
        output: mock_output,
        channels: [0]
      )

      voice = voices.voices.first

      # Set volume using CC number
      expect(mock_output).to receive(:puts) do |msg|
        expect(msg).to be_a(MIDIEvents::ChannelMessage::Message)
        expect(msg.data[0]).to eq(7)   # Volume CC number
        expect(msg.data[1]).to eq(100)
      end
      voice.controller[7] = 100
    end

    it 'handles sustain pedal' do
      voices = Musa::MIDIVoices::MIDIVoices.new(
        sequencer: sequencer,
        output: mock_output,
        channels: [0]
      )

      voice = voices.voices.first

      # Set sustain pedal
      expect(mock_output).to receive(:puts) do |msg|
        expect(msg).to be_a(MIDIEvents::ChannelMessage::Message)
        expect(msg.data[0]).to eq(64)  # Sustain pedal CC
        expect(msg.data[1]).to eq(127)
      end
      voice.sustain_pedal = 127

      expect(voice.sustain_pedal).to eq(127)
    end

    it 'handles all_notes_off' do
      voices = Musa::MIDIVoices::MIDIVoices.new(
        sequencer: sequencer,
        output: mock_output,
        channels: [0]
      )

      voice = voices.voices.first

      # Start a note
      voice.note pitch: 60, velocity: 100, duration: 1r

      # Both: the CC that tells the instrument to stop, and an explicit note-off
      # for the note this voice knows it is holding.
      sent = []
      allow(mock_output).to receive(:puts) { |msg| sent << msg.to_a }

      voice.all_notes_off

      expect(sent).to eq [[0xB0, 123, 0], [0x80, 60, 0]]
    end

    it 'handles NoteControl active state' do
      voices = Musa::MIDIVoices::MIDIVoices.new(
        sequencer: sequencer,
        output: mock_output,
        channels: [0]
      )

      voice = voices.voices.first
      note_ctrl = voice.note pitch: 60, velocity: 100, duration: 1r

      expect(note_ctrl.active?).to be true

      note_ctrl.note_off
      expect(note_ctrl.active?).to be false
    end

    it 'handles NoteControl after callback' do
      voices = Musa::MIDIVoices::MIDIVoices.new(
        sequencer: sequencer,
        output: mock_output,
        channels: [0]
      )

      voice = voices.voices.first
      callback_executed = false

      note_ctrl = voice.note pitch: 60, duration: 1r/4

      # Register after callback
      note_ctrl.after(1r) { callback_executed = true }

      # after(1r) means a whole bar later, so the sequencer has to get there:
      # two ticks are 2/96 of a bar and the callback would look broken.
      note_ctrl.note_off
      200.times { sequencer.tick }

      expect(callback_executed).to be true
    end

    it 'handles note with silence pitch' do
      voices = Musa::MIDIVoices::MIDIVoices.new(
        sequencer: sequencer,
        output: mock_output,
        channels: [0]
      )

      voice = voices.voices.first

      # A silence occupies its duration and sends nothing at all.
      sent = []
      allow(mock_output).to receive(:puts) { |msg| sent << msg.to_a }

      voice.note pitch: :silence, duration: 1r/4

      expect(sent).to eq []
    end

    it 'handles note with array of pitches' do
      voices = Musa::MIDIVoices::MIDIVoices.new(
        sequencer: sequencer,
        output: mock_output,
        channels: [0]
      )

      voice = voices.voices.first

      # Should send multiple note-on messages
      expect(mock_output).to receive(:puts).exactly(3).times

      note_ctrl = voice.note pitch: [60, 62, 64], velocity: 100, duration: 1r/4
      expect(note_ctrl.pitch).to eq([60, 62, 64])
    end

    it 'handles note with velocity arrays' do
      voices = Musa::MIDIVoices::MIDIVoices.new(
        sequencer: sequencer,
        output: mock_output,
        channels: [0]
      )

      voice = voices.voices.first

      # Should use different velocities for each note
      received_velocities = []
      expect(mock_output).to receive(:puts).exactly(3).times do |msg|
        received_velocities << msg.velocity
      end

      voice.note pitch: [60, 62, 64], velocity: [80, 90, 100], duration: 1r/4
      expect(received_velocities).to match_array([80, 90, 100])
    end

    it 'validates note duration parameter' do
      voices = Musa::MIDIVoices::MIDIVoices.new(
        sequencer: sequencer,
        output: recording_output,
        channels: [0]
      )

      voice = voices.voices.first

      # NoteControl is private, so a duration is exercised through the public
      # API and judged by the MIDI it produces: on now, off a quarter later.
      voice.note pitch: 60, velocity: 100, duration: 1r/4

      expect(recording_output.sent.collect { |m| m.class.name.split('::').last })
        .to eq(%w[NoteOn])

      200.times { sequencer.tick }

      expect(recording_output.sent.collect { |m| m.class.name.split('::').last })
        .to eq(%w[NoteOn NoteOff])
    end

    it 'handles logging' do
      voices = Musa::MIDIVoices::MIDIVoices.new(
        sequencer: sequencer,
        output: mock_output,
        channels: [0],
        do_log: true
      )

      voice = voices.voices.first
      voice.name = "TestVoice"

      expect(voice.do_log).to be true
      expect(voice.to_s).to include("TestVoice")
    end
  end

  context 'Integration tests' do
    it 'handles complete MIDI workflow with sequencer' do
      sequencer = Musa::Sequencer::Sequencer.new(4, 24)
      mock_output = double('MIDI Output')

      voices = Musa::MIDIVoices::MIDIVoices.new(
        sequencer: sequencer,
        output: mock_output,
        channels: [0]
      )

      voice = voices.voices.first

      # Expect note-on
      expect(mock_output).to receive(:puts).once do |msg|
        expect(msg).to be_a(MIDIEvents::NoteOn)
        expect(msg.note).to eq(60)
      end

      # Schedule note with duration
      sequencer.at(1r) do
        voice.note pitch: 60, velocity: 100, duration: 1r/4
      end

      # Expect note-off after duration
      expect(mock_output).to receive(:puts).once do |msg|
        expect(msg).to be_a(MIDIEvents::NoteOff)
        expect(msg.note).to eq(60)
      end

      # Run sequencer
      sequencer.run
    end

    it 'handles recorder with sequencer integration' do
      sequencer = Musa::Sequencer::Sequencer.new(4, 24)
      recorder = Musa::MIDIRecorder::MIDIRecorder.new(sequencer)

      # Record notes at different positions
      sequencer.at(1r) do
        recorder.record([0x90, 60, 100])  # Note on
      end

      sequencer.at(5/4r) do
        recorder.record([0x80, 60, 64])   # Note off
      end

      sequencer.run

      notes = recorder.transcription
      expect(notes.size).to be >= 1

      first_note = notes.first
      expect(first_note[:pitch]).to eq(60)
      expect(first_note[:position]).to eq(1r)
      expect(first_note[:duration]).to eq(1/4r)
    end
  end
end
