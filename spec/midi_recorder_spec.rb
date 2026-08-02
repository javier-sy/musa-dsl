require 'spec_helper'

require 'midi-parser'

require 'musa-dsl'

RSpec.describe Musa::MIDIRecorder do
  context 'Midi Recorder' do
    parser = MIDIParser.new

    it 'Basic midi recorder processing (raw midi)' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4
      recorder = Musa::MIDIRecorder::MIDIRecorder.new s

      s.tick
      s.tick

      recorder.record [176, 88, 114, 144, 58, 15]

      s.tick
      s.tick

      recorder.record [128, 58, 64]

      s.tick
      s.tick

      recorder.record [176, 88, 34, 144, 61, 29]

      s.tick

      recorder.record [128, 61, 64]

      s.tick
      s.tick

      recorder.record [176, 88, 94, 144, 63, 36]

      s.tick
      s.tick
      s.tick
      s.tick

      recorder.record [128, 63, 64]

      s.tick

      result = recorder.raw

      expect(result.size).to eq(9)

      c = -1

      c += 1
      expect(result[c].position).to eq(1 + Rational(1, 16))
      expect(result[c].message).to eq(parser.parse(176, 88, 114).first)
      c += 1
      expect(result[c].position).to eq(1 + Rational(1, 16))
      expect(result[c].message).to eq(parser.parse(144, 58, 15).first)

      c += 1
      expect(result[c].position).to eq(1 + Rational(3, 16))
      expect(result[c].message).to eq(parser.parse(128, 58, 64).first)

      c += 1
      expect(result[c].position).to eq(1 + Rational(5, 16))
      expect(result[c].message).to eq(parser.parse(176, 88, 34).first)
      c += 1
      expect(result[c].position).to eq(1 + Rational(5, 16))
      expect(result[c].message).to eq(parser.parse(144, 61, 29).first)

      c += 1
      expect(result[c].position).to eq(1 + Rational(6, 16))
      expect(result[c].message).to eq(parser.parse(128, 61, 64).first)

      c += 1
      expect(result[c].position).to eq(1 + Rational(8, 16))
      expect(result[c].message).to eq(parser.parse(176, 88, 94).first)
      c += 1
      expect(result[c].position).to eq(1 + Rational(8, 16))
      expect(result[c].message).to eq(parser.parse(144, 63, 36).first)

      c += 1
      expect(result[c].position).to eq(1 + Rational(12, 16))
      expect(result[c].message).to eq(parser.parse(128, 63, 64).first)

      recorder.clear

      expect(recorder.raw.size).to eq(0)
      expect(recorder.transcription.size).to eq(0)
    end

    it 'Basic midi recorder processing (transcription to PDV)' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4
      recorder = Musa::MIDIRecorder::MIDIRecorder.new s

      s.tick
      s.tick

      recorder.record [176, 88, 114, 144, 58, 15]

      s.tick
      s.tick

      recorder.record [128, 58, 64]

      s.tick
      s.tick

      recorder.record [176, 88, 34, 144, 61, 29]

      s.tick

      recorder.record [128, 61, 64]

      s.tick
      s.tick

      recorder.record [176, 88, 94, 144, 63, 36]

      s.tick
      s.tick
      s.tick
      s.tick

      recorder.record [128, 63, 64]

      s.tick

      result = recorder.transcription

      expect(result.size).to eq(5)

      c = -1

      c += 1
      expect(result[c]).to eq(position: 1 + Rational(1, 16), channel: 0, pitch: 58, duration: Rational(2, 16), velocity: 15, velocity_off: 64)

      c += 1
      expect(result[c]).to eq(position: 1 + Rational(3, 16), channel: 0, pitch: :silence, duration: Rational(2, 16))

      c += 1
      expect(result[c]).to eq(position: 1 + Rational(5, 16), channel: 0, pitch: 61, duration: Rational(1, 16), velocity: 29, velocity_off: 64)

      c += 1
      expect(result[c]).to eq(position: 1 + Rational(6, 16), channel: 0, pitch: :silence, duration: Rational(2, 16))

      c += 1
      expect(result[c]).to eq(position: 1 + Rational(8, 16), channel: 0, pitch: 63, duration: Rational(4, 16), velocity: 36, velocity_off: 64)

      recorder.clear

      expect(recorder.raw.size).to eq(0)
      expect(recorder.transcription.size).to eq(0)
    end

    # A NoteOn of velocity 0 is a NoteOff -- the running-status form, and what
    # most keyboards and sequencers actually emit. It used to be recorded as a
    # note of velocity 0 that nobody played, and the note it was releasing never
    # got its duration, because only a NoteOff closed one (issue #89).
    it 'takes a note on of velocity 0 as the note off it is' do
      sequencer = Musa::Sequencer::BaseSequencer.new 4, 4
      recorder = Musa::MIDIRecorder::MIDIRecorder.new sequencer

      sequencer.at(1) { recorder.record [0x90, 60, 100] }   # note on
      sequencer.at(2) { recorder.record [0x90, 60, 0] }     # release, running status
      sequencer.at(3) { recorder.record [0x90, 64, 90] }    # note on
      sequencer.at(4) { recorder.record [0x80, 64, 64] }    # release, explicit

      400.times { sequencer.tick }

      result = recorder.transcription

      expect(result.size).to eq(3)

      expect(result[0]).to eq(position: 1r, channel: 0, pitch: 60, velocity: 100,
                              duration: 1r, velocity_off: 0)

      # And the gap between the release and the next note is seen as a silence,
      # which it was not either: `last_note` is what marks "a note ended here",
      # and the phantom never set it.
      expect(result[1]).to eq(position: 2r, channel: 0, pitch: :silence, duration: 1r)

      expect(result[2]).to eq(position: 3r, channel: 0, pitch: 64, velocity: 90,
                              duration: 1r, velocity_off: 64)
    end

    it 'gives the same note whichever way it was released' do
      sequencer = Musa::Sequencer::BaseSequencer.new 4, 4
      recorder = Musa::MIDIRecorder::MIDIRecorder.new sequencer

      sequencer.at(1) { recorder.record [0x90, 60, 100] }
      sequencer.at(2) { recorder.record [0x90, 60, 0] }
      sequencer.at(3) { recorder.record [0x90, 60, 100] }
      sequencer.at(4) { recorder.record [0x80, 60, 0] }

      400.times { sequencer.tick }

      running_status, _silence, explicit = recorder.transcription

      expect(running_status.slice(:pitch, :velocity, :duration, :velocity_off))
        .to eq(explicit.slice(:pitch, :velocity, :duration, :velocity_off))
    end
  end
end
