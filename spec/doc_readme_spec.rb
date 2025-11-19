require 'spec_helper'

require 'musa-dsl'

using Musa::Extension::Neumas
using Musa::Extension::Matrix

RSpec.describe 'README.md Documentation Examples' do
  context 'Quick Start' do
    it 'creates melody using neuma notation and decodes to GDV events (CORRECTED FROM README)' do
      # NOTE: README syntax is simplified; real syntax requires parentheses
      # README shows: "0 +2 +2 -1 0"
      # Real syntax:  "(0) (+2) (+2) (-1) (0)"

      # Create a decoder with a major scale
      scale = Musa::Scales::Scales.et12[440.0].major[60]
      decoder = Musa::Neumas::Decoders::NeumaDecoder.new(
        scale,
        base_duration: 1/4r
      )

      melody = "(0) (+2) (+2) (-1) (0) (+4) (+5) (+7) (+5) (+4) (+2) (0)"

      # Decode to GDV (Grade-Duration-Velocity) events
      notes = Musa::Neumalang::Neumalang.parse(melody, decode_with: decoder).to_a(recursive: true)

      # Verify notes are GDV hashes with expected keys
      expect(notes).to be_an(Array)
      expect(notes.size).to eq(12)

      notes.each do |note|
        expect(note).to be_a(Hash)
        expect(note).to include(:grade, :duration, :velocity)
        expect(note[:grade]).to be_an(Integer)
        expect(note[:duration]).to be_a(Rational)
        expect(note[:velocity]).to be_a(Float).or be_a(Integer)
      end

      # Verify first note
      expect(notes[0][:grade]).to eq(0)
      expect(notes[0][:duration]).to eq(1/4r)
    end
  end

  context 'Series - Sequence Generators' do
    include Musa::Series

    it 'creates melodic series using operations' do
      # Create a melodic series using operations
      melody = S(0, 2, 4, 5, 7)
        .repeat(2)

      result = melody.to_a

      expect(result).to be_an(Array)
      expect(result.size).to eq(10)  # 5 notes × 2 repeats
      expect(result).to eq([0, 2, 4, 5, 7, 0, 2, 4, 5, 7])
    end

    it 'combines multiple series using zip on arrays (CORRECTED FROM README)' do
      # NOTE: Series don't have .zip or .cycle methods in README style
      # Using arrays instead

      rhythm = [1/4r, 1/8r, 1/8r, 1/4r]
      pitches = [60, 62, 64, 65]
      dynamics = [0.5, 0.7, 0.9, 0.7]

      notes = pitches.zip(rhythm, dynamics).map do |p, r, d|
        { pitch: p, duration: r, velocity: d }
      end

      expect(notes).to be_an(Array)
      expect(notes.size).to eq(4)
      expect(notes[0]).to eq({ pitch: 60, duration: 1/4r, velocity: 0.5 })
      expect(notes[1]).to eq({ pitch: 62, duration: 1/8r, velocity: 0.7 })
    end
  end

  context 'Transcription - MIDI & MusicXML Output' do
    it 'creates MIDI transcriptor with ornament expansion' do
      # Create MIDI transcriptor with ornament expansion
      transcriptor = Musa::Transcription::Transcriptor.new(
        Musa::Transcriptors::FromGDV::ToMIDI.transcription_set,
        base_duration: 1/4r
      )

      expect(transcriptor).to be_a(Musa::Transcription::Transcriptor)
      expect(transcriptor.transcriptors).to be_an(Array)
      expect(transcriptor.transcriptors).not_to be_empty
    end

    it 'expands trill ornament to multiple rapid notes' do
      # Create MIDI transcriptor with ornament expansion
      transcriptor = Musa::Transcription::Transcriptor.new(
        Musa::Transcriptors::FromGDV::ToMIDI.transcription_set,
        base_duration: 1/4r
      )

      # Transcode GDV event with ornament to expanded GDV events
      gdv_event = { grade: 2, octave: 0, duration: 1/4r, velocity: 0.7, tr: true }
      expanded_events = transcriptor.transcript(gdv_event)

      # Trill expanded to multiple rapid notes
      expect(expanded_events).to be_an(Array)
      expect(expanded_events.size).to be > 1

      expanded_events.each do |event|
        expect(event).to be_a(Hash)
        expect(event).to include(:grade, :octave, :duration, :velocity)
      end
    end

    it 'creates MusicXML transcriptor (preserves ornaments as symbols)' do
      # Create MusicXML transcriptor (preserves ornaments as symbols)
      xml_transcriptor = Musa::Transcription::Transcriptor.new(
        Musa::Transcriptors::FromGDV::ToMusicXML.transcription_set
      )

      expect(xml_transcriptor).to be_a(Musa::Transcription::Transcriptor)
      expect(xml_transcriptor.transcriptors).to be_an(Array)
    end
  end

  context 'Generative - Algorithmic Composition' do
    it 'creates Markov chain for probabilistic sequence generation (CORRECTED FROM README)' do
      # NOTE: README shows Musa::Generative::Markov with DSL syntax
      # Real API is Musa::Markov::Markov with hash-based transitions

      markov = Musa::Markov::Markov.new(
        start: 0,
        finish: :end,
        transitions: {
          0 => { 2 => 0.5, 4 => 0.3, 7 => 0.2 },
          2 => { 0 => 0.3, 4 => 0.5, 5 => 0.2 },
          4 => { 2 => 0.4, 5 => 0.4, 7 => 0.2 },
          5 => { 0 => 0.5, :end => 0.5 },
          7 => { 0 => 0.6, :end => 0.4 }
        }
      ).i

      melody = []
      16.times do
        value = markov.next_value
        break unless value
        melody << value
      end

      expect(melody).to be_an(Array)
      expect(melody.size).to be > 0
      expect([0, 2, 4, 5, 7]).to include(melody[0])
    end

    it 'uses Variatio for Cartesian product of parameter variations' do
      # Variatio - Cartesian product of parameter variations
      # Generates ALL combinations of field values
      variatio = Musa::Variatio::Variatio.new :chord do
        field :root, [60, 64, 67]     # C, E, G
        field :type, [:major, :minor]

        constructor do |root:, type:|
          { root: root, type: type }
        end
      end

      all_chords = variatio.run

      # 3 roots × 2 types = 6 variations
      expect(all_chords).to be_an(Array)
      expect(all_chords.size).to eq(6)

      expect(all_chords).to include({ root: 60, type: :major })
      expect(all_chords).to include({ root: 60, type: :minor })
      expect(all_chords).to include({ root: 64, type: :major })
      expect(all_chords).to include({ root: 64, type: :minor })
      expect(all_chords).to include({ root: 67, type: :major })
      expect(all_chords).to include({ root: 67, type: :minor })
    end
  end

  context 'Music - Scales & Chords' do
    it 'gets scales from equal temperament 12-tone system (CORRECTED FROM README)' do
      # NOTE: README shows .dorian which doesn't exist in this scale system
      # Using .minor instead

      major = Musa::Scales::Scales.et12[440.0].major[60]      # C major
      minor = Musa::Scales::Scales.et12[440.0].minor[62]      # D minor

      expect(major).to be_a(Musa::Scales::Scale)
      expect(minor).to be_a(Musa::Scales::Scale)
    end

    it 'creates chord definitions from scale' do
      # Chord definitions from scale
      major = Musa::Scales::Scales.et12[440.0].major[60]

      c_major = major.tonic.chord

      expect(c_major).to be_a(Musa::Chords::Chord)

      # Get chord note pitches
      note_pitches = c_major.notes.map { |n| n.note.pitch }

      expect(note_pitches).to eq([60, 64, 67])  # C, E, G
    end
  end

  context 'Datasets - Musical Data Structures' do
    it 'creates GDV (Grade, Duration, Velocity) absolute structure' do
      # GDV - Grade, Duration, Velocity (absolute)
      gdv = { grade: 2, duration: 1/4r, velocity: 0.7 }

      expect(gdv).to be_a(Hash)
      expect(gdv[:grade]).to eq(2)
      expect(gdv[:duration]).to eq(1/4r)
      expect(gdv[:velocity]).to eq(0.7)
    end

    it 'creates GDVd (Grade, Duration, Velocity) differential structure' do
      # GDVd - Grade, Duration, Velocity (differential)
      gdvd = { grade_diff: +2, duration_factor: 2, velocity_factor: 1.2 }

      expect(gdvd).to be_a(Hash)
      expect(gdvd[:grade_diff]).to eq(2)
      expect(gdvd[:duration_factor]).to eq(2)
      expect(gdvd[:velocity_factor]).to eq(1.2)
    end

    it 'creates PDV (Pitch, Duration, Velocity) structure' do
      # PDV - Pitch, Duration, Velocity
      pdv = { pitch: 64, duration: 1/4r, velocity: 100 }

      expect(pdv).to be_a(Hash)
      expect(pdv[:pitch]).to eq(64)
      expect(pdv[:duration]).to eq(1/4r)
      expect(pdv[:velocity]).to eq(100)
    end
  end

  context 'Matrix - Musical Gesture Conversion' do
    it 'converts matrix to P format for sequencer playback' do
      # Matrix representing a melodic gesture: [time, pitch]
      melody_matrix = Matrix[[0, 60], [1, 62], [2, 64]]

      # Convert to P format for sequencer playback
      p_sequence = melody_matrix.to_p(time_dimension: 0)

      expect(p_sequence).to be_an(Array)
      expect(p_sequence.size).to eq(1)

      # Result format: [[pitch1], duration1, [pitch2], duration2, [pitch3]]
      first_p = p_sequence[0]
      expect(first_p).to eq([[60], 1, [62], 1, [64]])
    end

    it 'converts multi-parameter matrix (time, pitch, velocity) to P format' do
      # Multi-parameter example: [time, pitch, velocity]
      gesture = Matrix[[0, 60, 100], [0.5, 62, 110], [1, 64, 120]]
      p_with_velocity = gesture.to_p(time_dimension: 0)

      expect(p_with_velocity).to be_an(Array)
      expect(p_with_velocity.size).to eq(1)

      # Result: [[pitch, velocity], duration, [pitch, velocity], duration, [pitch, velocity]]
      first_p = p_with_velocity[0]
      expect(first_p).to eq([[60, 100], 0.5, [62, 110], 0.5, [64, 120]])
    end

    it 'condenses connected gestures that share endpoints' do
      # Two phrases that connect at [1, 62]
      phrase1 = Matrix[[0, 60], [1, 62]]
      phrase2 = Matrix[[1, 62], [2, 64], [3, 65]]

      # Matrices that share endpoints are automatically merged
      merged = [phrase1, phrase2].to_p(time_dimension: 0)

      expect(merged).to be_an(Array)
      expect(merged.size).to eq(1)

      # Both phrases merged into continuous sequence
      first_p = merged[0]
      expect(first_p).to eq([[[60], 1, [62], 1, [64], 1, [65]]])
    end
  end
end
