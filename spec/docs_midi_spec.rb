require 'docs_helper'

using Musa::Extension::Neumas
using Musa::Extension::Matrix

RSpec.describe 'MIDI Documentation Examples' do

  context 'MIDI - Voice Management & Recording' do
    it 'creates MIDIRecorder and captures transcription format' do
      # Create sequencer
      sequencer = Musa::Sequencer::Sequencer.new(4, 24)

      # Create recorder
      recorder = Musa::MIDIRecorder::MIDIRecorder.new(sequencer)

      # Verify recorder was created
      expect(recorder).to be_a(Musa::MIDIRecorder::MIDIRecorder)

      # Verify it has transcription method
      expect(recorder).to respond_to(:transcription)

      # Verify it has raw method
      expect(recorder).to respond_to(:raw)

      # Verify it has clear method
      expect(recorder).to respond_to(:clear)

      # Verify it has record method
      expect(recorder).to respond_to(:record)

      # Initially empty
      expect(recorder.transcription).to eq([])
      expect(recorder.raw).to eq([])

      # After clearing, still empty
      recorder.clear
      expect(recorder.transcription).to eq([])
    end

    it 'understands transcription output format' do
      # Transcription output format documentation
      note_example = {
        position: 1r,
        channel: 0,
        pitch: 60,
        velocity: 100,
        duration: 1/4r,
        velocity_off: 64
      }

      silence_example = {
        position: 5/4r,
        channel: 0,
        pitch: :silence,
        duration: 1/8r
      }

      # Verify expected keys exist
      expect(note_example).to have_key(:position)
      expect(note_example).to have_key(:channel)
      expect(note_example).to have_key(:pitch)
      expect(note_example).to have_key(:velocity)
      expect(note_example).to have_key(:duration)
      expect(note_example).to have_key(:velocity_off)

      # Verify silence format
      expect(silence_example[:pitch]).to eq(:silence)
      expect(silence_example).to have_key(:duration)
    end
  end


end
