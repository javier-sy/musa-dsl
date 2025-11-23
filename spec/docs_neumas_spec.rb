require 'docs_helper'

using Musa::Extension::Neumas
using Musa::Extension::Matrix

RSpec.describe 'Neumas Documentation Examples' do

  context 'Neumas & Neumalang - Musical Notation' do
    using Musa::Extension::Neumas

    it 'parses neuma notation with durations' do
      # Test individual examples from README
      melody = "(0) (+2) (+2) (-1) (0)"
      rhythm = "(+2 1) (+2 2) (+1 1/2) (+2 1)"

      # Parse simple melody
      melody_neumas = melody.to_neumas
      expect(melody_neumas).to respond_to(:i)
      expect(melody_neumas.i.to_a.size).to eq(5)

      # Parse rhythm with durations
      rhythm_neumas = rhythm.to_neumas
      rhythm_array = rhythm_neumas.i.to_a
      expect(rhythm_array.size).to eq(4)
      expect(rhythm_array[0][:gdvd][:abs_duration]).to eq(1)
      expect(rhythm_array[1][:gdvd][:abs_duration]).to eq(2)
      expect(rhythm_array[2][:gdvd][:abs_duration]).to eq(1/2r)
    end

    it 'parses complete song example with parallel voices using | operator' do
      # Complete example from README - parallel voices using | operator
      song = "(0 1 mf) (+2 1 mp) (+4 2 p) (+5 1/2 mf) (+7 1 f)" |
             "(+7 2 p) (+5 1 mp) (+7 1 mf) (+9 1/2 f) (+12 2 ff)"

      # Verify it's a parallel structure
      expect(song).to be_a(Hash)
      expect(song[:kind]).to eq(:parallel)
      expect(song[:parallel].size).to eq(2)

      # Test Voice 1 directly from parallel structure
      voice1_serie = song[:parallel][0][:serie]
      voice1_array = voice1_serie.i.to_a

      expect(voice1_array.size).to eq(5)

      # First note: grade 0, duration 1, velocity mf
      expect(voice1_array[0][:gdvd][:abs_grade]).to eq(0)
      expect(voice1_array[0][:gdvd][:abs_duration]).to eq(1)
      expect(voice1_array[0][:gdvd][:abs_velocity]).to eq(1)  # mf = 1

      # Third note: grade +4, duration 2, velocity p
      expect(voice1_array[2][:gdvd][:delta_grade]).to eq(4)
      expect(voice1_array[2][:gdvd][:abs_duration]).to eq(2)
      expect(voice1_array[2][:gdvd][:abs_velocity]).to eq(-1)  # p = -1

      # Fourth note: grade +5, duration 1/2, velocity mf
      expect(voice1_array[3][:gdvd][:delta_grade]).to eq(5)
      expect(voice1_array[3][:gdvd][:abs_duration]).to eq(1/2r)
      expect(voice1_array[3][:gdvd][:abs_velocity]).to eq(1)  # mf = 1

      # Test Voice 2 directly from parallel structure
      voice2_serie = song[:parallel][1][:serie]
      voice2_array = voice2_serie.i.to_a

      expect(voice2_array.size).to eq(5)

      # First note: grade +7, duration 2, velocity p
      expect(voice2_array[0][:gdvd][:delta_grade]).to eq(7)
      expect(voice2_array[0][:gdvd][:abs_duration]).to eq(2)
      expect(voice2_array[0][:gdvd][:abs_velocity]).to eq(-1)  # p = -1

      # Last note: grade +12, duration 2, velocity ff
      expect(voice2_array[4][:gdvd][:delta_grade]).to eq(12)
      expect(voice2_array[4][:gdvd][:abs_duration]).to eq(2)
      expect(voice2_array[4][:gdvd][:abs_velocity]).to eq(3)  # ff = 3
    end

    it 'plays parallel neumas with sequencer handling voices automatically' do
      # Create parallel structure
      song = "(0 1 mf) (+2 1 mp) (+4 2 p)" |
             "(+7 2 p) (+5 1 mp) (+7 1 mf)"

      # Wrap in serie outside DSL context
      song_serie = Musa::Series::Constructors.S(song)

      # Create decoder
      scale = Musa::Scales::Scales.et12[440.0].major[60]
      decoder = Musa::Neumas::Decoders::NeumaDecoder.new(scale, base_duration: 1r)

      # Track played notes
      played = []

      # Create sequencer and play parallel structure
      sequencer = Musa::Sequencer::Sequencer.new(4, 24) do
        at 1 do
          play song_serie, decoder: decoder, mode: :neumalang do |gdv|
            played << { position: position, gdv: gdv }
          end
        end
      end

      # Run sequencer
      sequencer.tick until sequencer.empty?

      # Verify notes were played
      expect(played.size).to eq(6)  # 3 notes from each voice

      # Verify parallel execution: first notes from both voices at same position
      expect(played[0][:position]).to eq(played[1][:position])
      expect(played[0][:gdv][:grade]).to eq(0)   # Voice 1 first note
      expect(played[1][:gdv][:grade]).to eq(7)   # Voice 2 first note

      # Verify durations were decoded
      expect(played[0][:gdv][:duration]).to eq(1)
      expect(played[1][:gdv][:duration]).to eq(2)

      # Verify velocities were decoded
      expect(played[0][:gdv][:velocity]).to eq(1)   # mf
      expect(played[1][:gdv][:velocity]).to eq(-1)  # p
    end
  end


end
