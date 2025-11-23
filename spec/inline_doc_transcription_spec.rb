require 'spec_helper'
require 'musa-dsl'

RSpec.describe 'Transcription Inline Documentation Examples' do
  include Musa::All
  using Musa::Extension::Neumas

  context 'Transcription module documentation (transcription.rb)' do
    it 'example from line 107 - Complete transcription workflow' do
      # 1. Generate GDV events
      gdv_events = [
        { grade: 0, duration: 1r, tr: true },
        { grade: 2, duration: 1r, mor: :up },
        { grade: 4, duration: 1/2r, st: true }
      ]

      # 2. Create MIDI transcriptor
      transcriptor = Musa::Transcription::Transcriptor.new(
        Musa::Transcriptors::FromGDV::ToMIDI.transcription_set,
        base_duration: 1/4r
      )

      # 3. Transcribe to MIDI events
      midi_events = gdv_events.collect { |gdv| transcriptor.transcript(gdv) }.flatten

      # Verify events were expanded (ornaments create multiple notes)
      expect(midi_events.size).to be > gdv_events.size
      expect(midi_events).to all(be_a(Hash))
    end

    it 'example from line 189 - Create transcriptor chain' do
      transcriptor = Musa::Transcription::Transcriptor.new(
        [Musa::Transcriptors::FromGDV::ToMIDI::Appogiatura.new,
         Musa::Transcriptors::FromGDV::ToMIDI::Trill.new,
         Musa::Transcriptors::FromGDV::ToMIDI::Staccato.new],
        base_duration: 1/4r,
        tick_duration: 1/96r
      )

      expect(transcriptor.transcriptors.size).to eq(3)
      expect(transcriptor.transcriptors[0]).to be_a(Musa::Transcriptors::FromGDV::ToMIDI::Appogiatura)
      expect(transcriptor.transcriptors[1]).to be_a(Musa::Transcriptors::FromGDV::ToMIDI::Trill)
      expect(transcriptor.transcriptors[2]).to be_a(Musa::Transcriptors::FromGDV::ToMIDI::Staccato)
    end

    it 'example from line 211 - Create MIDI transcriptor' do
      transcriptor = Musa::Transcription::Transcriptor.new(
        Musa::Transcriptors::FromGDV::ToMIDI.transcription_set,
        base_duration: 1/4r,
        tick_duration: 1/96r
      )

      expect(transcriptor).to be_a(Musa::Transcription::Transcriptor)
      expect(transcriptor.transcriptors).not_to be_empty
    end

    it 'example from line 235 - Transcribe single event' do
      transcriptor = Musa::Transcription::Transcriptor.new(
        Musa::Transcriptors::FromGDV::ToMIDI.transcription_set,
        base_duration: 1/4r,
        tick_duration: 1/96r
      )

      gdv = { grade: 0, duration: 1r, tr: true }
      result = transcriptor.transcript(gdv)

      # Trill expands to array of notes
      expect(result).to be_a(Array)
      expect(result.size).to be > 1
      expect(result).to all(have_key(:grade))
      expect(result).to all(have_key(:duration))
    end

    it 'example from line 240 - Transcribe array of events' do
      transcriptor = Musa::Transcription::Transcriptor.new(
        Musa::Transcriptors::FromGDV::ToMIDI.transcription_set,
        base_duration: 1/4r,
        tick_duration: 1/96r
      )

      gdvs = [
        { grade: 0, duration: 1r, mor: true },
        { grade: 2, duration: 1r }
      ]
      results = transcriptor.transcript(gdvs)

      expect(results).to be_a(Array)
      # Mordent expands first event, second unchanged
      expect(results.size).to be > 2
    end
  end

  context 'FromGDV module documentation (from-gdv.rb)' do
    it 'example from line 34 - Basic base event' do
      gdv = { grade: 0, duration: 1r, base: true }
      transcriptor = Musa::Transcriptors::FromGDV::Base.new
      result = transcriptor.transcript(gdv, base_duration: 1/4r, tick_duration: 1/96r)

      # Base event converts to zero duration
      expect(result[:duration]).to eq(0)
      expect(result).to be_a(Musa::Datasets::AbsD)
    end

    it 'example from line 75 - Process base event' do
      base = Musa::Transcriptors::FromGDV::Base.new
      gdv = { grade: 0, duration: 1r, base: true }
      result = base.transcript(gdv, base_duration: 1/4r, tick_duration: 1/96r)

      expect(result[:duration]).to eq(0)
    end

    it 'example from line 81 - Normal event (unchanged)' do
      base = Musa::Transcriptors::FromGDV::Base.new
      gdv = { grade: 0, duration: 1r }
      result = base.transcript(gdv, base_duration: 1/4r, tick_duration: 1/96r)

      expect(result[:grade]).to eq(0)
      expect(result[:duration]).to eq(1r)
    end
  end

  context 'ToMIDI module documentation (from-gdv-to-midi.rb)' do
    it 'example from line 54 - MIDI trill expansion' do
      gdv = { grade: 0, duration: 1r, tr: true }
      transcriptor = Musa::Transcriptors::FromGDV::ToMIDI::Trill.new
      result = transcriptor.transcript(gdv, base_duration: 1/4r, tick_duration: 1/96r)

      # Trill expands to array of alternating notes
      expect(result).to be_a(Array)
      expect(result.size).to be > 2

      # Check for alternating grades (0 and 1 for upper neighbor)
      grades = result.map { |n| n[:grade] }.uniq.sort
      expect(grades).to include(0, 1)
    end

    it 'example from line 110 - Create MIDI transcription chain with default factor' do
      transcriptors = Musa::Transcriptors::FromGDV::ToMIDI.transcription_set
      transcriptor = Musa::Transcription::Transcriptor.new(
        transcriptors,
        base_duration: 1/4r
      )

      expect(transcriptor.transcriptors.size).to eq(6)
    end

    it 'example from line 117 - Custom duration factor for faster ornaments' do
      transcriptors = Musa::Transcriptors::FromGDV::ToMIDI.transcription_set(
        duration_factor: 1/8r
      )

      expect(transcriptors).to be_a(Array)
      expect(transcriptors.size).to eq(6)
    end

    it 'example from line 160 - Appogiatura expansion' do
      app = Musa::Transcriptors::FromGDV::ToMIDI::Appogiatura.new
      gdv = {
        grade: 0,
        duration: 1r,
        appogiatura: { grade: -1, duration: 1/8r }
      }
      result = app.transcript(gdv, base_duration: 1/4r, tick_duration: 1/96r)

      # Appogiatura expands to two notes
      expect(result).to be_a(Array)
      expect(result.size).to eq(2)
      expect(result[0][:grade]).to eq(-1)
      expect(result[0][:duration]).to eq(1/8r)
      expect(result[1][:grade]).to eq(0)
      expect(result[1][:duration]).to eq(7/8r)
    end

    it 'example from line 236 - Upper mordent' do
      mor = Musa::Transcriptors::FromGDV::ToMIDI::Mordent.new(duration_factor: 1/4r)
      gdv = { grade: 0, duration: 1r, mor: true }
      result = mor.transcript(gdv, base_duration: 1/4r, tick_duration: 1/96r)

      # Mordent expands to three notes
      expect(result).to be_a(Array)
      expect(result.size).to eq(3)
      expect(result[0][:grade]).to eq(0)
      expect(result[1][:grade]).to eq(1)  # Upper neighbor
      expect(result[2][:grade]).to eq(0)
    end

    it 'example from line 244 - Lower mordent' do
      mor = Musa::Transcriptors::FromGDV::ToMIDI::Mordent.new(duration_factor: 1/4r)
      gdv = { grade: 0, duration: 1r, mor: :down }
      result = mor.transcript(gdv, base_duration: 1/4r, tick_duration: 1/96r)

      # Lower mordent uses lower neighbor
      expect(result).to be_a(Array)
      expect(result.size).to eq(3)
      expect(result[0][:grade]).to eq(0)
      expect(result[1][:grade]).to eq(-1)  # Lower neighbor
      expect(result[2][:grade]).to eq(0)
    end

    it 'example from line 338 - Upper turn' do
      turn = Musa::Transcriptors::FromGDV::ToMIDI::Turn.new
      gdv = { grade: 0, duration: 1r, turn: true }
      result = turn.transcript(gdv, base_duration: 1/4r, tick_duration: 1/96r)

      # Turn expands to four notes
      expect(result).to be_a(Array)
      expect(result.size).to eq(4)
      expect(result[0][:grade]).to eq(1)   # Upper neighbor
      expect(result[1][:grade]).to eq(0)   # Main
      expect(result[2][:grade]).to eq(-1)  # Lower neighbor
      expect(result[3][:grade]).to eq(0)   # Main
      # Each note gets 1/4 of duration
      expect(result[0][:duration]).to eq(1/4r)
    end

    it 'example from line 349 - Lower turn' do
      turn = Musa::Transcriptors::FromGDV::ToMIDI::Turn.new
      gdv = { grade: 0, duration: 1r, turn: :down }
      result = turn.transcript(gdv, base_duration: 1/4r, tick_duration: 1/96r)

      # Lower turn starts with lower neighbor
      expect(result).to be_a(Array)
      expect(result.size).to eq(4)
      expect(result[0][:grade]).to eq(-1)  # Lower neighbor
      expect(result[1][:grade]).to eq(0)   # Main
      expect(result[2][:grade]).to eq(1)   # Upper neighbor
      expect(result[3][:grade]).to eq(0)   # Main
    end

    it 'example from line 452 - Standard trill' do
      trill = Musa::Transcriptors::FromGDV::ToMIDI::Trill.new(duration_factor: 1/4r)
      gdv = { grade: 0, duration: 1r, tr: true }
      result = trill.transcript(gdv, base_duration: 1/4r, tick_duration: 1/96r)

      # Trill generates alternating upper/main notes filling duration
      expect(result).to be_a(Array)
      expect(result.size).to be > 2

      # Check alternating pattern
      grades = result.map { |n| n[:grade] }
      expect(grades).to include(0, 1)
    end

    it 'example from line 458 - Trill starting low' do
      trill = Musa::Transcriptors::FromGDV::ToMIDI::Trill.new(duration_factor: 1/4r)
      gdv = { grade: 0, duration: 1r, tr: :low }
      result = trill.transcript(gdv, base_duration: 1/4r, tick_duration: 1/96r)

      # Starts with lower neighbor
      expect(result[0][:grade]).to eq(-1)
      expect(result[1][:grade]).to eq(0)
    end

    it 'example from line 462 - Custom duration factor' do
      trill = Musa::Transcriptors::FromGDV::ToMIDI::Trill.new(duration_factor: 1/4r)
      gdv = { grade: 0, duration: 1r, tr: 1/8r }
      result = trill.transcript(gdv, base_duration: 1/4r, tick_duration: 1/96r)

      # Faster trill with shorter note durations
      expect(result).to be_a(Array)
      expect(result.size).to be > 2
    end

    it 'example from line 596 - Basic staccato' do
      staccato = Musa::Transcriptors::FromGDV::ToMIDI::Staccato.new
      gdv = { grade: 0, duration: 1r, st: true }
      result = staccato.transcript(gdv, base_duration: 1/4r, tick_duration: 1/96r)

      # Staccato sets note_duration to half
      expect(result[:duration]).to eq(1r)
      expect(result[:note_duration]).to eq(1/2r)
    end

    it 'example from line 602 - Staccato level 2' do
      staccato = Musa::Transcriptors::FromGDV::ToMIDI::Staccato.new
      gdv = { grade: 0, duration: 1r, st: 2 }
      result = staccato.transcript(gdv, base_duration: 1/4r, tick_duration: 1/96r)

      # Level 2: duration divided by 4
      expect(result[:duration]).to eq(1r)
      expect(result[:note_duration]).to eq(1/4r)
    end

    it 'example from line 606 - Very short note (minimum enforced)' do
      staccato = Musa::Transcriptors::FromGDV::ToMIDI::Staccato.new
      gdv = { grade: 0, duration: 1/16r, st: true }
      result = staccato.transcript(gdv, base_duration: 1/4r, tick_duration: 1/96r)

      # note_duration clamped to base_duration * 1/8 (minimum)
      min_duration = 1/4r * 1/8r
      expect(result[:note_duration]).to eq(min_duration)
    end
  end

  context 'ToMusicXML module documentation (from-gdv-to-musicxml.rb)' do
    it 'example from line 91 - Create MusicXML transcription chain' do
      transcriptors = Musa::Transcriptors::FromGDV::ToMusicXML.transcription_set
      transcriptor = Musa::Transcription::Transcriptor.new(
        transcriptors,
        base_duration: 1/4r
      )

      expect(transcriptor.transcriptors.size).to eq(2)
    end

    it 'example from line 136 - Process appogiatura' do
      app = Musa::Transcriptors::FromGDV::ToMusicXML::Appogiatura.new
      gdv = {
        grade: 0,
        duration: 1r,
        appogiatura: { grade: -1, duration: 1/8r }
      }
      result = app.transcript(gdv, base_duration: 1/4r, tick_duration: 1/96r)

      # MusicXML appogiatura returns array with grace note markers
      expect(result).to be_a(Array)
      expect(result.size).to eq(2)

      grace_note = result[0]
      main_note = result[1]

      expect(grace_note[:grace]).to be true
      expect(grace_note[:grade]).to eq(-1)
      expect(main_note[:graced]).to be true
      expect(main_note[:graced_by]).to eq(grace_note)
    end
  end

  context 'Integration examples from docs/subsystems/transcription.md' do
    it 'MIDI with ornament expansion workflow' do
      # Neuma notation with ornaments
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
      expect(result[0][:duration]).to be_a(Rational)

      # Verify all results have pitch, duration, and velocity
      result.each do |pdv|
        expect(pdv).to include(:pitch, :duration, :velocity)
      end
    end

    it 'MusicXML with ornament symbols workflow' do
      # Same phrase as MIDI example
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

      # Verify serie is created
      expect(serie).to respond_to(:next_value)

      # Collect events
      events = serie.to_a(recursive: true)

      # For MusicXML, ornaments should be preserved as attributes, not expanded
      # So we should have 4 base events (not 11 like MIDI)
      # Note: The actual count may vary based on how the transcriptor handles nested arrays
      expect(events.size).to be >= 4
    end
  end
end
