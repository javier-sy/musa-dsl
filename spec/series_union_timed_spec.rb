require 'musa-dsl'

include Musa::Datasets
include Musa::Series

using Musa::Extension::InspectNice

RSpec.describe Musa::Series do
  context 'UNION timed series' do
    it 'timed_series' do

      p1 = [ { a: 1, b: 10, c: 100 }.extend(PackedV), 1 * 4,
             { a: 2, b: 20, c: 200 }.extend(PackedV), 2 * 4,
             { a: 3, b: 30, c: 300 }.extend(PackedV), 3 * 4,
             { a: 4, b: 40, c: 400 }.extend(PackedV), 2 * 4,
             { a: 5, b: 50, c: 500 }.extend(PackedV)].extend(P)

      p2 = [ { d: 9, e: 90, f: 900 }.extend(PackedV), 1/2r * 4,
             { d: 8, e: 80, f: 800 }.extend(PackedV), (2 + 1/2r) * 4,
             { d: 7, e: 70, f: 700 }.extend(PackedV), 3 * 4,
             { d: 6, e: 60, f: 600 }.extend(PackedV)].extend(P)

      pt1 = p1.to_timed_serie
      pt2 = p2.to_timed_serie

      u = UNION(pt1, pt2).i

      expected = [{ time: 0r, value: { a: 1, b: 10, c: 100, d: 9, e: 90, f: 900 } },
                  { time: 1/2r, value: { d: 8, e: 80, f: 800 } },
                  { time: 1r, value: { a: 2, b: 20, c: 200 } },
                  { time: 3r, value: { a: 3, b: 30, c: 300, d: 7, e: 70, f: 700 } },
                  { time: 6r, value: { a: 4, b: 40, c: 400, d: 6, e: 60, f: 600 } },
                  { time: 8r, value: { a: 5, b: 50, c: 500 } }]

      while v = u.next_value
        expect(v).to eq(expected.shift)
      end

      expect(u.next_value).to be_nil
      expect(expected).to be_empty
    end
  end
end