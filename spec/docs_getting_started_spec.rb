require 'docs_helper'

using Musa::Extension::Neumas
using Musa::Extension::Matrix

RSpec.describe 'Getting Started Documentation Examples' do

  context 'Quick Start' do
    include Musa::All

    it 'demonstrates sequencer DSL with multiple interactive voice lines' do
      # Create scale for composition
      scale = Scales.et12[440.0].major[60]  # C major starting at middle C

      # Create sequencer (4 beats per bar, 24 ticks per beat)
      sequencer = Musa::Sequencer::Sequencer.new(4, 24)

      # Track events for verification
      beat_events = []
      melody_events = []
      harmony_events = []

      # Shared state: current melody note (so harmony can follow)
      current_melody_note = nil

      # Program the sequencer using DSL
      sequencer.with do
        # Line 1: Beat every 4 bars (for 32 bars total)
        at 1 do
          every 4, duration: 32 do
            beat_events << { position: position, pitch: 36 }
          end
        end

        # Line 2: Ascending melody (bars 1-16) then descending (bars 17-32)
        at 1 do
          # Ascending: move from grade 0 to grade 14 over 16 bars
          move(from: 0, to: 14, duration: 16, every: 1/4r) do |grade|
            pitch = scale[grade.round].pitch
            current_melody_note = grade.round
            melody_events << { position: position, grade: grade.round, pitch: pitch }
          end
        end

        at 17 do
          # Descending: move from grade 14 to grade 0 over 16 bars
          move(from: 14, to: 0, duration: 16, every: 1/4r) do |grade|
            pitch = scale[grade.round].pitch
            current_melody_note = grade.round
            melody_events << { position: position, grade: grade.round, pitch: pitch }
          end
        end

        # Line 3: Harmony playing 3rd or 5th every 2 bars (for 32 bars total)
        at 1 do
          use_third = true

          every 2, duration: 32 do
            if current_melody_note
              harmony_grade = current_melody_note + (use_third ? 2 : 4)
              harmony_pitch = scale[harmony_grade].pitch
              harmony_events << {
                position: position,
                melody_grade: current_melody_note,
                harmony_grade: harmony_grade,
                pitch: harmony_pitch,
                interval: use_third ? :third : :fifth
              }
              use_third = !use_third
            end
          end
        end
      end

      # Execute sequencer
      sequencer.run

      # Verify beat events
      expect(beat_events.size).to be > 0
      expect(beat_events.first[:position]).to eq(1)  # First beat at bar 1
      expect(beat_events.first[:pitch]).to eq(36)    # Kick drum pitch

      # Verify spacing between beats (every 4 bars)
      if beat_events.size > 1
        expect(beat_events[1][:position]).to eq(5)  # Second beat at bar 5
      end

      # Verify melody events
      expect(melody_events.size).to be > 0

      # First melody note should be at grade 0
      expect(melody_events.first[:grade]).to eq(0)
      expect(melody_events.first[:pitch]).to eq(60)  # C4

      # Melody should ascend in first 16 bars
      first_half = melody_events.select { |e| e[:position] <= 16 }
      expect(first_half.last[:grade]).to be > first_half.first[:grade]

      # Melody should descend in bars 17-32
      second_half = melody_events.select { |e| e[:position] >= 17 && e[:position] <= 32 }
      if second_half.size > 1
        expect(second_half.last[:grade]).to be < second_half.first[:grade]
      end

      # Verify harmony events
      expect(harmony_events.size).to be > 0

      # First harmony should be at bar 1
      expect(harmony_events.first[:position]).to eq(1)

      # Verify harmony intervals (alternating 3rd and 5th)
      expect(harmony_events.first[:interval]).to eq(:third)
      if harmony_events.size > 1
        expect(harmony_events[1][:interval]).to eq(:fifth)
      end

      # Verify harmony follows melody
      harmony_events.each do |h|
        if h[:interval] == :third
          expect(h[:harmony_grade]).to eq(h[:melody_grade] + 2)
        else  # :fifth
          expect(h[:harmony_grade]).to eq(h[:melody_grade] + 4)
        end
      end

      # Verify spacing between harmony notes (every 2 bars)
      if harmony_events.size > 1
        expect(harmony_events[1][:position]).to eq(3)  # Second harmony at bar 3
      end
    end
  end

  context 'Not So Quick Start' do
    include Musa::All

    it 'creates melody using neuma notation, decodes to GDV events, and schedules with sequencer' do
      # Create a decoder with a major scale
      scale = Scales.et12[440.0].major[60]
      decoder = Decoders::NeumaDecoder.new(
        scale,
        base_duration: 1r  # Base duration for explicit duration values
      )

      # Define melody with duration and velocity
      melody = "(0 1/4 p) (+2 1/4 mp) (+2 1/4 mf) (-1 1/2 f) " \
               "(0 1/4 mf) (+4 1/4 mp) (+5 1/2 f) (+7 1/4 ff) " \
               "(+5 1/4 f) (+4 1/4 mf) (+2 1/4 mp) (0 1 p)"

      # Decode to GDV (Grade-Duration-Velocity) events
      gdv_notes = Neumalang.parse(melody, decode_with: decoder)

      # Verify GDV notes structure
      gdv_array = gdv_notes.to_a(recursive: true)
      expect(gdv_array).to be_an(Array)
      expect(gdv_array.size).to eq(12)

      gdv_array.each do |note|
        expect(note).to be_a(Hash)
        expect(note).to include(:grade, :duration, :velocity)
        expect(note[:grade]).to be_an(Integer)
        expect(note[:duration]).to be_a(Rational)
        expect(note[:velocity]).to be_a(Float).or be_a(Integer)
      end

      # Verify first note has specified duration and velocity
      expect(gdv_array[0][:grade]).to eq(0)
      expect(gdv_array[0][:duration]).to eq(1/4r)
      expect(gdv_array[0][:velocity]).to eq(-1)  # p = piano = -1

      # Verify fourth note has different duration (half note)
      expect(gdv_array[3][:duration]).to eq(1/2r)

      # Verify last note has longer duration (whole note)
      expect(gdv_array[11][:duration]).to eq(1r)

      # Convert GDV to PDV (Pitch-Duration-Velocity) for playback
      pdv_notes = gdv_notes.map { |note| note.to_pdv(scale) }

      # Verify PDV conversion
      pdv_array = pdv_notes.to_a(recursive: true)
      expect(pdv_array).to be_an(Array)
      expect(pdv_array.size).to eq(12)

      pdv_array.each do |note|
        expect(note).to be_a(Hash)
        expect(note).to include(:pitch, :duration)
        expect(note[:pitch]).to be_an(Integer)
        expect(note[:duration]).to be_a(Rational)
      end

      # Verify first PDV note preserves duration from GDV
      expect(pdv_array[0][:pitch]).to eq(60)  # C4 (grade 0 in C major scale)
      expect(pdv_array[0][:duration]).to eq(1/4r)
      # PDV velocity is converted to MIDI scale (0-127), different from GDV scale
      expect(pdv_array[0][:velocity]).to be_a(Numeric)
      expect(pdv_array[0][:velocity]).to be > 0

      # Verify different durations are preserved
      expect(pdv_array[3][:duration]).to eq(1/2r)  # Half note
      expect(pdv_array[11][:duration]).to eq(1r)   # Whole note

      # Verify velocity increases from p (piano) to ff (fortissimo)
      expect(pdv_array[7][:velocity]).to be > pdv_array[0][:velocity]

      # Verify sequencer.play API compatibility
      sequencer = Musa::Sequencer::BaseSequencer.new(4, 24)
      expect(sequencer).to be_a(Musa::Sequencer::BaseSequencer)

      # Test that sequencer.play can be called with PDV series
      played_notes = []
      sequencer.play(pdv_notes) do |note|
        played_notes << { pitch: note[:pitch], duration: note[:duration], velocity: note[:velocity] }
        # In real usage: voice.note pitch: note[:pitch], velocity: note[:velocity], duration: note[:duration]
      end

      # Execute sequencer to process scheduled events
      sequencer.run

      # Verify all notes were played
      expect(played_notes.size).to eq(12)

      # Verify first note (C4, quarter, piano)
      expect(played_notes[0][:pitch]).to eq(60)  # Grade 0 = C
      expect(played_notes[0][:duration]).to eq(1/4r)
      expect(played_notes[0][:velocity]).to be_a(Numeric)

      # Verify second note (E4, quarter, mezzo-piano) - +2 from grade 0
      expect(played_notes[1][:pitch]).to eq(64)  # Grade 2 = E
      expect(played_notes[1][:duration]).to eq(1/4r)

      # Verify fourth note has half duration (forte)
      expect(played_notes[3][:duration]).to eq(1/2r)

      # Verify last note (C4, whole, piano)
      expect(played_notes[11][:pitch]).to eq(60)
      expect(played_notes[11][:duration]).to eq(1r)

      # Verify velocity dynamics: ff (fortissimo) is louder than p (piano)
      expect(played_notes[7][:velocity]).to be > played_notes[0][:velocity]
    end
  end
end
