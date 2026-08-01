require 'docs_helper'

using Musa::Extension::Neumas
using Musa::Extension::Matrix

RSpec.describe 'Transcription Documentation Examples' do

  context 'Transcription - MIDI & MusicXML Output' do
    using Musa::Extension::Neumas

    it 'expands neuma ornaments (trill and mordent) to PDV note sequences for MIDI' do
      # Neuma notation with ornaments: trill (.tr) and mordent (.mor)
      neumas = "(0 1 mf) (+2 1 tr) (+4 1 mor) (+5 1)"

      # Create scale and decoder
      scale = Musa::Scales::Scales.et12[440.0].major[60]
      decoder = Musa::Neumas::Decoders::NeumaDecoder.new(scale, base_duration: 1/4r)

      # Create MIDI transcriptor with ornament expansion
      transcriptor = Musa::Transcription::Transcriptor.new(
        Musa::Transcriptors::FromGDV::ToMIDI.transcription_set(duration_factor: 1/6r),
        base_duration: 1/4r,
        tick_duration: 1/96r
      )

      # Parse and expand ornaments to PDV
      result = Musa::Neumalang::Neumalang.parse(neumas, decode_with: decoder)
                                         .process_with { |gdv| transcriptor.transcript(gdv) }
                                         .map { |gdv| gdv.to_pdv(scale) }
                                         .to_a(recursive: true)

      # Four neumas become eleven notes, and where each one goes is exact.
      expect(result.size).to eq(11)

      # The plain note keeps its quarter.
      expect(result[0]).to eq({ pitch: 60, duration: 1/4r, velocity: 80 })

      # The trill fills its quarter with six alternations of a 1/24 each
      # (duration_factor: 1/6r), starting on the upper neighbour F4 rather than
      # on the written E4.
      expect(result[1..6].collect { |n| n[:pitch] }).to eq([65, 64, 65, 64, 65, 64])
      expect(result[1..6].collect { |n| n[:duration] }).to eq([1/24r] * 6)
      expect(result[1..6].sum { |n| n[:duration] }).to eq(1/4r)

      # The mordent is auxiliary and back, and then holds the rest of the note.
      expect(result[7..9]).to eq([{ pitch: 71, duration: 1/24r, velocity: 80 },
                                  { pitch: 72, duration: 1/24r, velocity: 80 },
                                  { pitch: 71, duration: 1/6r, velocity: 80 }])

      expect(result[10]).to eq({ pitch: 79, duration: 1/4r, velocity: 80 })
    end

    it 'generates MusicXML with ornaments preserved as notation symbols' do
      # Same phrase as MIDI example (ornaments preserved as symbols)
      neumas = "(0 1 mf) (+2 1 tr) (+4 1 mor) (+5 1)"

      # Create scale and decoder
      scale = Musa::Scales::Scales.et12[440.0].major[60]
      decoder = Musa::Neumas::Decoders::NeumaDecoder.new(scale, base_duration: 1/4r)

      # Create MusicXML transcriptor (preserves ornaments as symbols)
      transcriptor = Musa::Transcription::Transcriptor.new(
        Musa::Transcriptors::FromGDV::ToMusicXML.transcription_set,
        base_duration: 1/4r,
        tick_duration: 1/96r
      )

      # Parse and convert to GDV with preserved ornament markers
      serie = Musa::Neumalang::Neumalang.parse(neumas, decode_with: decoder)
                                         .process_with { |gdv| transcriptor.transcript(gdv) }

      # Create Score and use sequencer to fill it
      score = Musa::Datasets::Score.new
      sequencer = Musa::Sequencer::Sequencer.new(4, 24)

      sequencer.at 1 do
        play serie, decoder: decoder, mode: :neumalang do |gdv|
          pdv = gdv.to_pdv(scale)
          score.at(position, add: pdv)  # position is automatically tracked by sequencer
        end
      end

      sequencer.run

      # Convert to MusicXML
      mxml = score.to_mxml(
        4, 24,  # 4 beats per bar, 24 ticks per beat
        bpm: 120,
        title: 'Ornaments Example',
        creators: { composer: 'MusaDSL' },
        parts: { piano: { name: 'Piano', clefs: { g: 2 } } }
      )

      # Verify MusicXML structure
      xml_string = mxml.to_xml.string

      expect(xml_string).to include('Ornaments Example')
      expect(xml_string).to include('MusaDSL')

      # Verify ornaments preserved as XML notation symbols (not expanded)
      expect(xml_string).to include('<trill-mark />')
      expect(xml_string).to include('<inverted-mordent />')

      # Verify only 4 notes (not 11 like MIDI expansion)
      # Count <note> tags that aren't rests
      pitched_notes = xml_string.scan(/<note>.*?<pitch>.*?<\/note>/m)
      expect(pitched_notes.size).to eq(4)
    end
  end


end
