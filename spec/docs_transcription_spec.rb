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

      # Verify expansion occurred (more notes than original 4 due to ornament expansion)
      expect(result.size).to be > 4

      # First note (no ornament)
      expect(result[0][:pitch]).to eq(60)  # C4
      expect(result[0][:duration]).to eq(1/4r)

      # Trill expansion (note with tr: true expands to multiple notes)
      # Second note has trill, so we should see alternating pitches
      trill_notes = result[1..6]  # Approximate range for trill expansion
      expect(trill_notes.any? { |n| n[:pitch] == 64 }).to be true  # E4 (original)
      expect(trill_notes.any? { |n| n[:pitch] == 65 }).to be true  # F4 (upper neighbor)

      # Verify all results have pitch, duration, and velocity
      result.each do |pdv|
        expect(pdv).to include(:pitch, :duration, :velocity)
      end
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
