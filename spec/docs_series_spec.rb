require 'docs_helper'

using Musa::Extension::Neumas
using Musa::Extension::Matrix

RSpec.describe 'Series Documentation Examples' do

  context 'Series - Sequence Generators' do
    include Musa::Series

    it 'creates melodic series using basic operations' do
      # S constructor with repeat
      melody = S(0, 2, 4, 5, 7).repeat(2)
      result = melody.i.to_a

      expect(result).to be_an(Array)
      expect(result.size).to eq(10)
      expect(result).to eq([0, 2, 4, 5, 7, 0, 2, 4, 5, 7])

      # Transform with map
      transposed = S(60, 64, 67).map { |n| n + 12 }
      expect(transposed.i.to_a).to eq([72, 76, 79])

      # Filter with select
      evens = S(1, 2, 3, 4, 5, 6).select { |n| n.even? }
      expect(evens.i.to_a).to eq([2, 4, 6])
    end

    it 'combines multiple parameters with .with' do
      pitches = S(60, 64, 67, 72)
      durations = S(1r, 1/2r, 1/2r, 1r)
      velocities = S(96, 80, 90, 100)

      notes = pitches.with(dur: durations, vel: velocities) do |p, dur:, vel:|
        { pitch: p, duration: dur, velocity: vel }
      end

      result = notes.i.to_a

      expect(result).to be_an(Array)
      expect(result.size).to eq(4)
      expect(result[0]).to eq({ pitch: 60, duration: 1r, velocity: 96 })
      expect(result[1]).to eq({ pitch: 64, duration: 1/2r, velocity: 80 })
      expect(result[2]).to eq({ pitch: 67, duration: 1/2r, velocity: 90 })
      expect(result[3]).to eq({ pitch: 72, duration: 1r, velocity: 100 })
    end

    it 'creates PDV with H() and HC()' do
      # Create PDV from series of different sizes
      pitches = S(60, 62, 64, 65, 67)      # 5 notes
      durations = S(1r, 1/2r, 1/4r)        # 3 durations
      velocities = S(96, 80, 90, 100)      # 4 velocities

      # H: Stop when shortest series exhausts
      notes = H(pitch: pitches, duration: durations, velocity: velocities)

      result = notes.i.to_a
      expect(result).to be_an(Array)
      expect(result.size).to eq(3)  # Limited by shortest (durations)
      expect(result[0]).to eq({ pitch: 60, duration: 1r, velocity: 96 })
      expect(result[1]).to eq({ pitch: 62, duration: 1/2r, velocity: 80 })
      expect(result[2]).to eq({ pitch: 64, duration: 1/4r, velocity: 90 })

      # HC: Continue cycling all series
      pitches2 = S(60, 62, 64, 65, 67)
      durations2 = S(1r, 1/2r, 1/4r)
      velocities2 = S(96, 80, 90, 100)

      notes_cycling = HC(pitch: pitches2, duration: durations2, velocity: velocities2)
        .max_size(7)

      result_cycling = notes_cycling.i.to_a
      expect(result_cycling).to be_an(Array)
      expect(result_cycling.size).to eq(7)
      expect(result_cycling[0]).to eq({ pitch: 60, duration: 1r, velocity: 96 })
      expect(result_cycling[1]).to eq({ pitch: 62, duration: 1/2r, velocity: 80 })
      expect(result_cycling[2]).to eq({ pitch: 64, duration: 1/4r, velocity: 90 })
      expect(result_cycling[3]).to eq({ pitch: 65, duration: 1r, velocity: 100 })
      expect(result_cycling[4]).to eq({ pitch: 67, duration: 1/2r, velocity: 96 })
      expect(result_cycling[5]).to eq({ pitch: 60, duration: 1/4r, velocity: 80 })
      expect(result_cycling[6]).to eq({ pitch: 62, duration: 1r, velocity: 90 })
    end

    it 'merges melodic phrases with MERGE' do
      phrase1 = S(60, 64, 67)
      phrase2 = S(72, 69, 65)
      phrase3 = S(60, 62, 64)

      melody = MERGE(phrase1, phrase2, phrase3)
      expect(melody.i.to_a).to eq([60, 64, 67, 72, 69, 65, 60, 62, 64])

      # Repeat merged structure
      section = MERGE(S(1, 2, 3), S(4, 5, 6)).repeat(2)
      expect(section.i.to_a).to eq([1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6])
    end

    it 'uses numeric generators FOR, FIBO, HARMO' do
      # FOR: ascending
      ascending = FOR(from: 0, to: 7, step: 1)
      expect(ascending.i.to_a).to eq([0, 1, 2, 3, 4, 5, 6, 7])

      # FOR: descending
      descending = FOR(from: 10, to: 0, step: 2)
      expect(descending.i.to_a).to eq([10, 8, 6, 4, 2, 0])

      # FIBO: Fibonacci rhythmic proportions
      rhythm = FIBO().max_size(8).map { |n| Rational(n, 16) }
      result = rhythm.i.to_a
      expect(result).to eq([1/16r, 1/16r, 1/8r, 3/16r, 5/16r, 1/2r, 13/16r, 21/16r])

      # HARMO: Harmonic series
      harmonics = HARMO(error: 0.5).max_size(10)
      result = harmonics.i.to_a
      expect(result).to be_an(Array)
      expect(result.size).to eq(10)
      expect(result.first).to eq(0)
      expect(result[1]).to eq(12)  # Octave
    end

    it 'uses structural transformations: reverse, merge, chaining' do
      # Reverse
      melody = S(60, 64, 67, 72)
      retrograde = melody.reverse
      expect(retrograde.i.to_a).to eq([72, 67, 64, 60])

      # merge operation on serie of series
      chunks = S(1, 2, 3, 4, 5, 6).cut(2)  # Split into pairs (serie of series)

      # Each chunk is a serie, use .merge to flatten
      reconstructed = chunks.merge
      expect(reconstructed.i.to_a).to eq([1, 2, 3, 4, 5, 6])

      # Verify chunks structure by converting each chunk to array
      chunks_inst = S(1, 2, 3, 4, 5, 6).cut(2).i
      chunk_arrays = []
      while (chunk = chunks_inst.next_value)
        chunk_arrays << chunk.i.to_a
      end
      expect(chunk_arrays).to eq([[1, 2], [3, 4], [5, 6]])

      # Chaining operations
      result = S(60, 62, 64, 65, 67, 69, 71, 72)
        .select { |n| n.even? }  # [60, 62, 64, 72]
        .map { |n| n + 12 }      # [72, 74, 76, 84]
        .reverse                  # [84, 76, 74, 72]
        .repeat(2)                # Repeat twice

      expect(result.i.to_a).to eq([84, 76, 74, 72, 84, 76, 74, 72])
    end

    it 'creates buffered series for multiple independent readers' do
      # Create buffered melody for canon
      melody = S(60, 64, 67, 72, 76).buffered

      # Create independent readers (voices)
      voice1 = melody.buffer.i
      voice2 = melody.buffer.i

      # Each voice progresses independently
      expect(voice1.next_value).to eq(60)
      expect(voice1.next_value).to eq(64)

      expect(voice2.next_value).to eq(60)  # Independent of voice1
      expect(voice2.next_value).to eq(64)

      expect(voice1.next_value).to eq(67)
      expect(voice2.next_value).to eq(67)
    end

    it 'quantizes continuous values to discrete steps' do
      # Quantize continuous pitch bend to semitones
      pitch_bend = S({ time: 0r, value: 60.3 }.extend(Musa::Datasets::AbsTimed),
                     { time: 1r, value: 61.8 }.extend(Musa::Datasets::AbsTimed),
                     { time: 2r, value: 63.1 }.extend(Musa::Datasets::AbsTimed))

      quantized = pitch_bend.quantize(step: 1)

      result = quantized.i.to_a

      # Values should be quantized to integers
      expect(result.size).to be > 0
      expect(result[0][:value]).to eq(60)  # First value quantized to 60
      expect(result[0][:time]).to eq(0r)

      # Verify values are integers (quantized)
      result.each do |r|
        expect(r[:value]).to be_a(Integer).or be_a(Rational)
      end
    end

    it 'merges timed series by time using TIMED_UNION' do
      # Create independent melodic lines with timing
      melody = S({ time: 0r, value: 60 }.extend(Musa::Datasets::AbsTimed),
                 { time: 1r, value: 64 }.extend(Musa::Datasets::AbsTimed))

      bass = S({ time: 0r, value: 36 }.extend(Musa::Datasets::AbsTimed),
               { time: 2r, value: 38 }.extend(Musa::Datasets::AbsTimed))

      # Merge by time
      combined = TIMED_UNION(melody: melody, bass: bass)

      inst = combined.i

      # First event at time 0
      first = inst.next_value
      expect(first[:time]).to eq(0r)
      expect(first[:value][:melody]).to eq(60)
      expect(first[:value][:bass]).to eq(36)

      # Second event at time 1
      second = inst.next_value
      expect(second[:time]).to eq(1r)
      expect(second[:value][:melody]).to eq(64)
      expect(second[:value][:bass]).to be_nil
    end
  end


end
