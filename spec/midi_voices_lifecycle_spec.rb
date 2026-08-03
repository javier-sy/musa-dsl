require 'spec_helper'
require 'musa-dsl'

RSpec.describe 'MIDI Inline Documentation Examples' do
  include Musa::All

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

  end

end
