require 'musa-dsl'

RSpec.describe Musa::Datasets::P do
  context 'Dataset P transformations' do
    it 'to timed serie' do
      p = [ { a: 1, b: 10, c: 100 }.extend(Musa::Datasets::PackedV), 1 * 4,
            { a: 2, b: 20, c: 200 }.extend(Musa::Datasets::PackedV), 2 * 4,
            { a: 3, b: 30, c: 300 }.extend(Musa::Datasets::PackedV) ].extend(Musa::Datasets::P)

      s = p.to_timed_serie.i

      expect(v = s.next_value).to eq( { time: 0, value: { a: 1, b: 10, c: 100 } } )

      expect(v[:value]).to be_a(Musa::Datasets::PackedV)
      expect(v).to be_a(Musa::Datasets::AbsTimed)

      expect(s.next_value).to eq( { time: 1, value: { a: 2, b: 20, c: 200 } } )

      expect(v[:value]).to be_a(Musa::Datasets::PackedV)
      expect(v).to be_a(Musa::Datasets::AbsTimed)

      expect(s.next_value).to eq( { time: 3, value: { a: 3, b: 30, c: 300 } } )

      expect(v[:value]).to be_a(Musa::Datasets::PackedV)
      expect(v).to be_a(Musa::Datasets::AbsTimed)

      expect(s.next_value).to be_nil
    end

    it 'to timed serie starting at time 10' do
      p = [ { a: 1, b: 10, c: 100 }.extend(Musa::Datasets::PackedV), 1 * 4,
            { a: 2, b: 20, c: 200 }.extend(Musa::Datasets::PackedV), 2 * 4,
            { a: 3, b: 30, c: 300 }.extend(Musa::Datasets::PackedV) ].extend(Musa::Datasets::P)

      s = p.to_timed_serie(time_start: 10).i

      expect(v = s.next_value).to eq( { time: 10, value: { a: 1, b: 10, c: 100 } } )

      expect(v[:value]).to be_a(Musa::Datasets::PackedV)
      expect(v).to be_a(Musa::Datasets::AbsTimed)

      expect(s.next_value).to eq( { time: 11, value: { a: 2, b: 20, c: 200 } } )

      expect(v[:value]).to be_a(Musa::Datasets::PackedV)
      expect(v).to be_a(Musa::Datasets::AbsTimed)

      expect(s.next_value).to eq( { time: 13, value: { a: 3, b: 30, c: 300 } } )

      expect(v[:value]).to be_a(Musa::Datasets::PackedV)
      expect(v).to be_a(Musa::Datasets::AbsTimed)

      expect(s.next_value).to be_nil
    end

    it 'to timed serie starting with time of a component' do
      p = [ { a: 1, b: 10, c: 100 }.extend(Musa::Datasets::PackedV), 1 * 4,
            { a: 2, b: 20, c: 200 }.extend(Musa::Datasets::PackedV), 2 * 4,
            { a: 3, b: 30, c: 300 }.extend(Musa::Datasets::PackedV) ].extend(Musa::Datasets::P)

      s = p.to_timed_serie(time_start_component: :c).i

      expect(v = s.next_value).to eq( { time: 100, value: { a: 1, b: 10, c: 100 } } )

      expect(v[:value]).to be_a(Musa::Datasets::PackedV)
      expect(v).to be_a(Musa::Datasets::AbsTimed)

      expect(s.next_value).to eq( { time: 101, value: { a: 2, b: 20, c: 200 } } )

      expect(v[:value]).to be_a(Musa::Datasets::PackedV)
      expect(v).to be_a(Musa::Datasets::AbsTimed)

      expect(s.next_value).to eq( { time: 103, value: { a: 3, b: 30, c: 300 } } )

      expect(v[:value]).to be_a(Musa::Datasets::PackedV)
      expect(v).to be_a(Musa::Datasets::AbsTimed)

      expect(s.next_value).to be_nil
    end

    it 'to timed serie starting with time of a component plus time start offset' do
      p = [ { a: 1, b: 10, c: 100 }.extend(Musa::Datasets::PackedV), 1 * 4,
            { a: 2, b: 20, c: 200 }.extend(Musa::Datasets::PackedV), 2 * 4,
            { a: 3, b: 30, c: 300 }.extend(Musa::Datasets::PackedV) ].extend(Musa::Datasets::P)

      s = p.to_timed_serie(time_start: 10, time_start_component: :c).i

      expect(v = s.next_value).to eq( { time: 110, value: { a: 1, b: 10, c: 100 } } )

      expect(v[:value]).to be_a(Musa::Datasets::PackedV)
      expect(v).to be_a(Musa::Datasets::AbsTimed)

      expect(s.next_value).to eq( { time: 111, value: { a: 2, b: 20, c: 200 } } )

      expect(v[:value]).to be_a(Musa::Datasets::PackedV)
      expect(v).to be_a(Musa::Datasets::AbsTimed)

      expect(s.next_value).to eq( { time: 113, value: { a: 3, b: 30, c: 300 } } )

      expect(v[:value]).to be_a(Musa::Datasets::PackedV)
      expect(v).to be_a(Musa::Datasets::AbsTimed)

      expect(s.next_value).to be_nil
    end

  end
end

