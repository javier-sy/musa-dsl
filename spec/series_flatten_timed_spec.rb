require 'musa-dsl'

include Musa::Datasets

RSpec.describe Musa::Series do
  context 'Dataset P series transformations handles' do
    it 'flatten timed serie' do
      p = [ { a: 1, b: 10, c: 100 }.extend(PackedV), 1 * 4,
            { a: 2, b: 20, c: 200 }.extend(PackedV), 2 * 4,
            { a: 3, b: 30, c: 300 }.extend(PackedV) ].extend(P)

      s = p.to_timed_serie.flatten_timed.instance

      expect(v = s.next_value).to eq({ a: { time: 0, value: 1 }, b: { time: 0, value: 10 }, c: { time: 0, value: 100 } } )

      expect(v[:a]).to be_a(AbsTimed)
      expect(v[:b]).to be_a(AbsTimed)
      expect(v[:c]).to be_a(AbsTimed)

      expect(s.next_value).to eq({ a: { time: 1, value: 2 }, b: { time: 1, value: 20 }, c: { time: 1, value: 200 } } )
      expect(s.next_value).to eq({ a: { time: 3, value: 3 }, b: { time: 3, value: 30 }, c: { time: 3, value: 300 } } )

      expect(s.next_value).to be_nil

    end

    it 'prototype / instance management' do
      p = [ { a: 1, b: 10, c: 100 }.extend(PackedV), 1 * 4,
            { a: 2, b: 20, c: 200 }.extend(PackedV), 2 * 4,
            { a: 3, b: 30, c: 300 }.extend(PackedV) ].extend(P)

      s = p.to_timed_serie.flatten_timed.instance

      expect(s.next_value[:a][:value]).to eq 1
      expect(s.next_value[:a][:value]).to eq 2

      s2 = p.to_timed_serie.flatten_timed.instance

      expect(s2.next_value[:a][:value]).to eq 1
      expect(s2.next_value[:a][:value]).to eq 2

      expect(s.next_value[:a][:value]).to eq 3
      expect(s2.next_value[:a][:value]).to eq 3

      expect(s.next_value).to be_nil
      expect(s2.next_value).to be_nil
    end

  end
end