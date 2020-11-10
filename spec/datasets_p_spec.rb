require 'musa-dsl'

include Musa::Datasets

RSpec.describe Musa::Datasets::P do
  context 'Dataset P transformations' do
    it 'to timed serie' do
      p = [ { a: 1, b: 10, c: 100 }.extend(PackedV), 1 * 4,
            { a: 2, b: 20, c: 200 }.extend(PackedV), 2 * 4,
            { a: 3, b: 30, c: 300 }.extend(PackedV) ].extend(P)

      s = p.to_timed_serie.i

      expect(v = s.next_value).to eq( { time: 0, value: { a: 1, b: 10, c: 100 } } )

      expect(v[:value]).to be_a(PackedV)
      expect(v).to be_a(AbsTimed)

      expect(s.next_value).to eq( { time: 1, value: { a: 2, b: 20, c: 200 } } )

      expect(v[:value]).to be_a(PackedV)
      expect(v).to be_a(AbsTimed)

      expect(s.next_value).to eq( { time: 3, value: { a: 3, b: 30, c: 300 } } )

      expect(v[:value]).to be_a(PackedV)
      expect(v).to be_a(AbsTimed)

      expect(s.next_value).to be_nil
    end

    it 'to timed serie starting at time 10' do
      p = [ { a: 1, b: 10, c: 100 }.extend(PackedV), 1 * 4,
            { a: 2, b: 20, c: 200 }.extend(PackedV), 2 * 4,
            { a: 3, b: 30, c: 300 }.extend(PackedV) ].extend(P)

      s = p.to_timed_serie(10).i

      expect(v = s.next_value).to eq( { time: 10, value: { a: 1, b: 10, c: 100 } } )

      expect(v[:value]).to be_a(PackedV)
      expect(v).to be_a(AbsTimed)

      expect(s.next_value).to eq( { time: 11, value: { a: 2, b: 20, c: 200 } } )

      expect(v[:value]).to be_a(PackedV)
      expect(v).to be_a(AbsTimed)

      expect(s.next_value).to eq( { time: 13, value: { a: 3, b: 30, c: 300 } } )

      expect(v[:value]).to be_a(PackedV)
      expect(v).to be_a(AbsTimed)

      expect(s.next_value).to be_nil
    end

  end
end

