require 'spec_helper'

require 'musa-dsl'

RSpec.describe Musa::MIDIRecorder do
  context 'Midi Recorder' do
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
      expect(result[c].message.data).to eq(MIDIMessage::Parser.parse(176, 88, 114).data)
      c += 1
      expect(result[c].position).to eq(1 + Rational(1, 16))
      expect(result[c].message.data).to eq(MIDIMessage::Parser.parse(144, 58, 15).data)

      c += 1
      expect(result[c].position).to eq(1 + Rational(3, 16))
      expect(result[c].message.data).to eq(MIDIMessage::Parser.parse(128, 58, 64).data)

      c += 1
      expect(result[c].position).to eq(1 + Rational(5, 16))
      expect(result[c].message.data).to eq(MIDIMessage::Parser.parse(176, 88, 34).data)
      c += 1
      expect(result[c].position).to eq(1 + Rational(5, 16))
      expect(result[c].message.data).to eq(MIDIMessage::Parser.parse(144, 61, 29).data)

      c += 1
      expect(result[c].position).to eq(1 + Rational(6, 16))
      expect(result[c].message.data).to eq(MIDIMessage::Parser.parse(128, 61, 64).data)

      c += 1
      expect(result[c].position).to eq(1 + Rational(8, 16))
      expect(result[c].message.data).to eq(MIDIMessage::Parser.parse(176, 88, 94).data)
      c += 1
      expect(result[c].position).to eq(1 + Rational(8, 16))
      expect(result[c].message.data).to eq(MIDIMessage::Parser.parse(144, 63, 36).data)

      c += 1
      expect(result[c].position).to eq(1 + Rational(12, 16))
      expect(result[c].message.data).to eq(MIDIMessage::Parser.parse(128, 63, 64).data)

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
  end
end
