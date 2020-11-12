require 'musa-dsl'

include Musa::Datasets
include Musa::Series

using Musa::Extension::InspectNice

RSpec.describe Musa::Series do
  context 'UNION timed series' do
    it 'hash timed_series' do

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
                  { time: 1/2r, value: { a: nil, b: nil, c: nil, d: 8, e: 80, f: 800 } },
                  { time: 1r, value: { a: 2, b: 20, c: 200, d: nil, e: nil, f: nil } },
                  { time: 3r, value: { a: 3, b: 30, c: 300, d: 7, e: 70, f: 700 } },
                  { time: 6r, value: { a: 4, b: 40, c: 400, d: 6, e: 60, f: 600 } },
                  { time: 8r, value: { a: 5, b: 50, c: 500, d: nil, e: nil, f: nil } }]

      while v = u.next_value
        expect(v).to eq(expected.shift)
      end

      expect(u.next_value).to be_nil
      expect(expected).to be_empty
    end
  end

  it 'array timed_series' do

    p1 = [ [ 1, 10, 100 ].extend(V), 1 * 4,
           [ 2, 20, 200 ].extend(V), 2 * 4,
           [ 3, 30, 300 ].extend(V), 3 * 4,
           [ 4, 40, 400 ].extend(V), 2 * 4,
           [ 5, 50, 500 ].extend(V)].extend(P)

    p2 = [ [ 9, 90, 900 ].extend(V), 1/2r * 4,
           [ 8, 80, 800 ].extend(V), (2 + 1/2r) * 4,
           [ 7, 70, 700 ].extend(V), 3 * 4,
           [ 6, 60, 600 ].extend(V)].extend(P)

    pt1 = p1.to_timed_serie
    pt2 = p2.to_timed_serie

    u = UNION(pt1, pt2).i

    expected = [{ time: 0r, value: [ 1, 10, 100, 9, 90, 900 ] },
                { time: 1/2r, value: [ nil, nil, nil, 8, 80, 800 ] },
                { time: 1r, value: [ 2, 20, 200, nil, nil, nil ] },
                { time: 3r, value: [ 3, 30, 300, 7, 70, 700 ] },
                { time: 6r, value: [ 4, 40, 400, 6, 60, 600 ] },
                { time: 8r, value: [ 5, 50, 500, nil, nil, nil ] }]

    while v = u.next_value
      expect(v).to eq(expected.shift)
    end

    expect(u.next_value).to be_nil
    expect(expected).to be_empty
  end
end
