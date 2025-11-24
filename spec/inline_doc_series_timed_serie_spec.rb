require 'spec_helper'
require 'musa-dsl'

RSpec.describe 'Series Timed Serie Inline Documentation Examples' do
  include Musa::All

  context 'TIMED_UNION constructor' do
    it 'example from line 99 - Array mode with direct values' do
      s1 = S({ time: 0r, value: 1 }, { time: 1r, value: 2 })
      s2 = S({ time: 0r, value: 10 }, { time: 2r, value: 20 })

      union = TIMED_UNION(s1, s2).i
      result = union.to_a

      expect(result).to eq([
        { time: 0r, value: [1, 10] }.extend(Musa::Datasets::AbsTimed),
        { time: 1r, value: [2, nil] }.extend(Musa::Datasets::AbsTimed),
        { time: 2r, value: [nil, 20] }.extend(Musa::Datasets::AbsTimed)
      ])
    end

    it 'example from line 109 - Hash mode with named sources' do
      melody = S({ time: 0r, value: 60 }, { time: 1r, value: 64 })
      bass = S({ time: 0r, value: 36 }, { time: 2r, value: 40 })

      union = TIMED_UNION(melody: melody, bass: bass).i
      result = union.to_a

      expect(result).to eq([
        { time: 0r, value: { melody: 60, bass: 36 } }.extend(Musa::Datasets::AbsTimed),
        { time: 1r, value: { melody: 64, bass: nil } }.extend(Musa::Datasets::AbsTimed),
        { time: 2r, value: { melody: nil, bass: 40 } }.extend(Musa::Datasets::AbsTimed)
      ])
    end

    it 'example from line 119 - Hash values with polyphonic events' do
      s1 = S({ time: 0r, value: { a: 1, b: 2 } })
      s2 = S({ time: 0r, value: { c: 10, d: 20 } })

      union = TIMED_UNION(s1, s2).i
      result = union.next_value

      expect(result[:time]).to eq(0r)
      expect(result[:value]).to eq({ a: 1, b: 2, c: 10, d: 20 })
    end

    it 'example from line 126 - Extra attributes synchronization' do
      s1 = S({ time: 0r, value: 1, velocity: 80, duration: 1r })
      s2 = S({ time: 0r, value: 10, velocity: 90 })

      union = TIMED_UNION(s1, s2).i
      result = union.next_value

      expect(result[:time]).to eq(0r)
      expect(result[:value]).to eq([1, 10])
      expect(result[:velocity]).to eq([80, 90])
      expect(result[:duration]).to eq([1r, nil])
    end

    it 'example from line 137 - Key conflict detection' do
      s1 = S({ time: 0r, value: { a: 1, b: 2 } })
      s2 = S({ time: 0r, value: { a: 10 } })  # 'a' already used!

      union = TIMED_UNION(s1, s2).i

      expect { union.next_value }.to raise_error(RuntimeError, /key a already used/)
    end
  end

  context 'flatten_timed operation' do
    it 'example from line 501 - Hash values to individual voices' do
      s = S({ time: 0r, value: { a: 60, b: 64 }, velocity: { a: 80, b: 90 } })

      flat = s.flatten_timed.i
      result = flat.next_value

      expect(result).to be_a(Hash)
      expect(result[:a]).to eq({ time: 0r, value: 60, velocity: 80 }.extend(Musa::Datasets::AbsTimed))
      expect(result[:b]).to eq({ time: 0r, value: 64, velocity: 90 }.extend(Musa::Datasets::AbsTimed))
    end

    it 'example from line 509 - Array values to indexed events' do
      s = S({ time: 0r, value: [60, 64], velocity: [80, 90] })

      flat = s.flatten_timed.i
      result = flat.next_value

      expect(result).to be_an(Array)
      expect(result[0]).to eq({ time: 0r, value: 60, velocity: 80 }.extend(Musa::Datasets::AbsTimed))
      expect(result[1]).to eq({ time: 0r, value: 64, velocity: 90 }.extend(Musa::Datasets::AbsTimed))
    end

    it 'example from line 517 - Direct values pass through' do
      s = S({ time: 0r, value: 60, velocity: 80 })

      flat = s.flatten_timed.i
      result = flat.next_value

      expect(result[:time]).to eq(0r)
      expect(result[:value]).to eq(60)
      expect(result[:velocity]).to eq(80)
    end
  end

  context 'compact_timed operation' do
    it 'example from line 545 - Remove direct nil events' do
      s = S({ time: 0r, value: 1 },
            { time: 1r, value: nil },
            { time: 2r, value: 3 })

      result = s.compact_timed.i.to_a

      expect(result).to eq([
        { time: 0r, value: 1 }.extend(Musa::Datasets::AbsTimed),
        { time: 2r, value: 3 }.extend(Musa::Datasets::AbsTimed)
      ])
    end

    it 'example from line 554 - Remove all-nil hash events' do
      s = S({ time: 0r, value: { a: 1, b: 2 } },
            { time: 1r, value: { a: nil, b: nil } },
            { time: 2r, value: { a: 3, b: nil } })

      result = s.compact_timed.i.to_a

      expect(result).to eq([
        { time: 0r, value: { a: 1, b: 2 } }.extend(Musa::Datasets::AbsTimed),
        { time: 2r, value: { a: 3, b: nil } }.extend(Musa::Datasets::AbsTimed)
      ])
    end

    it 'example from line 563 - Clean sparse union results' do
      s1 = S({ time: 0r, value: 1 }, { time: 2r, value: 3 })
      s2 = S({ time: 1r, value: 10 })

      union = TIMED_UNION(melody: s1, bass: s2).i.to_a

      expect(union).to eq([
        { time: 0r, value: { melody: 1, bass: nil } }.extend(Musa::Datasets::AbsTimed),
        { time: 1r, value: { melody: nil, bass: 10 } }.extend(Musa::Datasets::AbsTimed),
        { time: 2r, value: { melody: 3, bass: nil } }.extend(Musa::Datasets::AbsTimed)
      ])

      # All events have at least one non-nil, so none removed by compact_timed
      compacted = TIMED_UNION(melody: s1, bass: s2).compact_timed.i.to_a
      expect(compacted.size).to eq(3)
    end
  end

  context 'union_timed method' do
    it 'example from line 598 - Array mode' do
      melody = S({ time: 0r, value: 60 })
      bass = S({ time: 0r, value: 36 })

      result = melody.union_timed(bass).i.next_value

      expect(result[:time]).to eq(0r)
      expect(result[:value]).to eq([60, 36])
    end

    it 'example from line 605 - Hash mode' do
      melody = S({ time: 0r, value: 60 })
      bass = S({ time: 0r, value: 36 })
      drums = S({ time: 0r, value: 38 })

      result = melody.union_timed(key: :melody, bass: bass, drums: drums).i.next_value

      expect(result[:time]).to eq(0r)
      expect(result[:value]).to eq({ melody: 60, bass: 36, drums: 38 })
    end
  end
end
