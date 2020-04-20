require 'spec_helper'

require 'musa-dsl'

include Musa::Datasets

RSpec.describe Musa::Datasets::V do
  context 'Dataset PackedV to V transformations' do
    it 'with array mapper (complete)' do
      pv = { a: 1, b: 2, c: 3 }.extend(PackedV)

      v = pv.to_V([:c, :b, :a])

      expect(v).to eq [3, 2, 1]
      expect(v).to be_a V
    end

    it 'with array mapper (missing mappers)' do
      pv = { a: 1, b: 2, c: 3 }.extend(PackedV)

      v = pv.to_V([:c, :b])

      expect(v).to eq [3, 2]
      expect(v).to be_a V
    end

    it 'with array mapper (missing values)' do
      pv = { a: 1, b: 2, c: 3 }.extend(PackedV)

      v = pv.to_V([:c, :b, :a, :d])

      expect(v).to eq [3, 2, 1, nil]
      expect(v).to be_a V
    end

    it 'with hash mapper (complete, no defaults)' do
      pv = { a: 1, b: 2, c: 3 }.extend(PackedV)

      v = pv.to_V({ c: nil, b: nil, a: nil })

      expect(v).to eq [3, 2, 1]
      expect(v).to be_a V
    end

    it 'with hash mapper (missing mappers, no defaults)' do
      pv = { a: 1, b: 2, c: 3 }.extend(PackedV)

      v = pv.to_V({ c: nil, b: nil })

      expect(v).to eq [3, 2]
      expect(v).to be_a V
    end

    it 'with hash mapper (missing values, no defaults)' do
      pv = { a: 1, b: 2, c: 3 }.extend(PackedV)

      v = pv.to_V({ c: nil, b: nil, a: nil, d: nil })

      expect(v).to eq [3, 2, 1, nil]
      expect(v).to be_a V
    end

    it 'with hash mapper (missing values, with defaults)' do
      pv = { a: 1, b: 2, c: 3 }.extend(PackedV)

      v = pv.to_V({ c: 100, b: 200, a: 300, d: 400 })

      expect(v).to eq [3, 2, 1, 400]
      expect(v).to be_a V
    end

    it 'hash mapper (missing values and nil values, with defaults)' do
      pv = { a: 1, b: nil, c: 3 }.extend(PackedV)

      v = pv.to_V({ c: 100, b: 200, a: 300, d: 400 })

      expect(v).to eq [3, 200, 1, 400]
      expect(v).to be_a V
    end
  end

  context 'Dataset V to PackedV transformations' do
    it 'with array mapper (complete)' do
      v = [3, 2, 1].extend(V)

      pv = v.to_packed_V([:c, :b, :a])

      expect(pv).to eq({ a: 1, b: 2, c: 3 })
      expect(pv).to be_a PackedV
    end

    it 'with array mapper (missing mappers)' do
      v = [3, 2, 1].extend(V)

      pv = v.to_packed_V([:c, :b])

      expect(pv).to eq({ b: 2, c: 3 })
      expect(pv).to be_a PackedV
    end

    it 'with array mapper (nil mapper)' do
      v = [3, 2, 1].extend(V)

      pv = v.to_packed_V([:c, nil, :a])

      expect(pv).to eq({ a: 1, c: 3 })
      expect(pv).to be_a PackedV
    end

    it 'with array mapper (missing values)' do
      v = [3, 2, 1, nil].extend(V)

      pv = v.to_packed_V([:c, :b, :a, :d])

      expect(pv).to eq({ a: 1, b: 2, c: 3 })
      expect(pv).to be_a PackedV

      vv = pv.to_V([:c, :b, :a, :d])

      expect(vv).to eq([3, 2, 1, nil])
      expect(vv).to be_a V
    end

    it 'with hash mapper (complete, no defaults)' do
      v = [3, 2, 1].extend(V)

      pv = v.to_packed_V({ c: nil, b: nil, a: nil })

      expect(pv).to eq({ a: 1, b: 2, c: 3 })
      expect(pv).to be_a PackedV
    end

    it 'with hash mapper (missing values, no defaults)' do
      v = [3, 2].extend(V)

      pv = v.to_packed_V({ c: nil, b: nil, a: nil })

      expect(pv).to eq({ b: 2, c: 3 })
      expect(pv).to be_a PackedV
    end

    it 'with hash mapper (missing values, with defaults)' do
      v = [3, 2].extend(V)

      pv = v.to_packed_V({ c: 100, b: 200, a: 300 })

      expect(pv).to eq({ b: 2, c: 3 })
      expect(pv).to be_a PackedV

      vv = pv.to_V({ c: 100, b: 200, a: 300 })

      expect(vv).to eq [3, 2, 300]
      expect(vv).to be_a V
    end

    it 'with hash mapper (values with nil, no defaults)' do
      v = [3, 2, 1, nil].extend(V)

      pv = v.to_packed_V({ c: nil, b: nil, a: nil, d: nil })

      expect(pv).to eq({ a: 1, b: 2, c: 3 })
      expect(pv).to be_a PackedV

      vv = pv.to_V({ c: nil, b: nil, a: nil, d: nil })
      expect(vv).to eq [3, 2, 1, nil]
      expect(vv).to be_a V
    end

    it 'with hash mapper (values as defaults, with defaults)' do
      v = [3, 2, 1, 400].extend(V)

      pv = v.to_packed_V({ c: 100, b: 200, a: 300, d: 400 })

      expect(pv).to eq({ a: 1, b: 2, c: 3 })
      expect(pv).to be_a PackedV

      vv = pv.to_V({ c: 100, b: 200, a: 300, d: 400 })

      expect(vv).to eq([3, 2, 1, 400])
      expect(vv).to be_a V
    end
  end
end
