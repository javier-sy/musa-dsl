require 'musa-dsl'

include Musa::Datasets
include Musa::Series

using Musa::Extension::InspectNice

RSpec.describe Musa::Series do

  context 'timed_serie with extra attributes flatten_timed' do
    it 'with hash values' do
      s = S( { time: 0, value: { a: 10, b: 11 }, extra1: { a: 100, b: 101 }, extra2: { a: 1000, b: 1001 } },
             { time: 1, value: { a: 20, b: 22 }, extra1: { a: 200, b: 202 }, extra2: { a: 2000, b: 2002 } },
             { time: 2, value: { a: 30, b: 33 }, extra1: { a: 300, b: 303 }, extra2: { a: 3000, b: 3003 } } )

      ft = s.flatten_timed.i

      expected = [
          { a: { time: 0, value: 10, extra1: 100, extra2: 1000 }, b: { time: 0, value: 11, extra1: 101, extra2: 1001 } },
          { a: { time: 1, value: 20, extra1: 200, extra2: 2000 }, b: { time: 1, value: 22, extra1: 202, extra2: 2002 } },
          { a: { time: 2, value: 30, extra1: 300, extra2: 3000 }, b: { time: 2, value: 33, extra1: 303, extra2: 3003 } }]

      while v = ft.next_value
        expect(v[:a]).to be_a(AbsTimed)
        expect(v[:b]).to be_a(AbsTimed)

        expect(v).to eq(expected.shift)
      end

      expect(ft.next_value).to be_nil
      expect(expected).to be_empty
    end

    it 'with array values' do
      s = S( { time: 0, value: [10, 11], extra1: [100, 101], extra2: [1000, 1001] },
             { time: 1, value: [20, 22], extra1: [200, 202], extra2: [2000, 2002] },
             { time: 2, value: [30, 33], extra1: [300, 303], extra2: [3000, 3003] } )

      ft = s.flatten_timed.i

      expected = [
          [{ time: 0, value: 10, extra1: 100, extra2: 1000 }, { time: 0, value: 11, extra1: 101, extra2: 1001 }],
          [{ time: 1, value: 20, extra1: 200, extra2: 2000 }, { time: 1, value: 22, extra1: 202, extra2: 2002 }],
          [{ time: 2, value: 30, extra1: 300, extra2: 3000 }, { time: 2, value: 33, extra1: 303, extra2: 3003 }]]

      while v = ft.next_value
        expect(v[0]).to be_a(AbsTimed)
        expect(v[1]).to be_a(AbsTimed)

        expect(v).to eq(expected.shift)
      end

      expect(ft.next_value).to be_nil
      expect(expected).to be_empty
    end

    it 'with direct values' do
      s = S( { time: 0, value: 10, extra1: 100, extra2: 1000 },
             { time: 1, value: 20, extra1: 200, extra2: 2000 },
             { time: 2, value: 30, extra1: 300, extra2: 3000 } )

      ft = s.flatten_timed.i

      expected = [
          { time: 0, value: 10, extra1: 100, extra2: 1000 },
          { time: 1, value: 20, extra1: 200, extra2: 2000 },
          { time: 2, value: 30, extra1: 300, extra2: 3000 }]

      while v = ft.next_value
        expect(v).to be_a(AbsTimed)
        expect(v).to eq(expected.shift)
      end

      expect(ft.next_value).to be_nil
      expect(expected).to be_empty
    end
  end

  context 'P to_timed_serie flatten_timed' do
    it 'with hash values' do
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

    it 'with array values' do
      p = [ [ 1, 10, 100 ].extend(V), 1 * 4,
            [ 2, 20, 200 ].extend(V), 2 * 4,
            [ 3, 30, 300 ].extend(V) ].extend(P)

      s = p.to_timed_serie.flatten_timed.instance

      expect(v = s.next_value).to eq([ { time: 0, value: 1 }, { time: 0, value: 10 }, { time: 0, value: 100 } ] )

      expect(v[0]).to be_a(AbsTimed)
      expect(v[1]).to be_a(AbsTimed)
      expect(v[2]).to be_a(AbsTimed)

      expect(s.next_value).to eq([ { time: 1, value: 2 }, { time: 1, value: 20 }, { time: 1, value: 200 } ] )
      expect(s.next_value).to eq([ { time: 3, value: 3 }, { time: 3, value: 30 }, { time: 3, value: 300 } ] )

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

  context 'UNION timed series' do
    it 'value timed_series' do
      p1 = [ 1, 1 * 4,
             2, 2 * 4,
             3, 3 * 4,
             4, 2 * 4,
             5].extend(P)

      p2 = [ 9, 1/2r * 4,
             8, (2 + 1/2r) * 4,
             7, 3 * 4,
             6].extend(P)

      pt1 = p1.to_timed_serie
      pt2 = p2.to_timed_serie

      u = TIMED_UNION(pt1, pt2).i

      expected = [{ time: 0r, value: [ 1, 9 ] },
                  { time: 1/2r, value: [ nil, 8 ] },
                  { time: 1r, value: [ 2, nil ] },
                  { time: 3r, value: [ 3, 7 ] },
                  { time: 6r, value: [ 4, 6 ] },
                  { time: 8r, value: [ 5, nil ] }]

      while v = u.next_value
        expect(v).to be_a(AbsTimed)
        expect(v).to eq(expected.shift)
      end

      expect(u.next_value).to be_nil
      expect(expected).to be_empty
    end

    it 'direct value timed_series with extra attributes' do
      s1 = S({ time: 0, value: 1, extra1: 10 },
             { time: 1, value: 2, extra1: 20 },
             { time: 2, value: 3, extra1: 30 } )

      s2 = S({ time: 0, value: 9, extra2: 90 },
             { time: 1, value: 8, extra2: 80 },
             { time: 2, value: 7, extra2: 70 } )

      u = TIMED_UNION(s1, s2).i

      expected = [{ time: 0, value: [1, 9], extra1: [10, nil], extra2: [nil, 90] },
                  { time: 1, value: [2, 8], extra1: [20, nil], extra2: [nil, 80] },
                  { time: 2, value: [3, 7], extra1: [30, nil], extra2: [nil, 70] }]

      while v = u.next_value
        expect(v).to be_a(AbsTimed)
        expect(v).to eq(expected.shift)
      end

      expect(u.next_value).to be_nil
      expect(expected).to be_empty
    end

    it 'direct value timed_series with extra attributes united with hash keys' do
      s1 = S({ time: 0, value: 1, extra1: 10 },
             { time: 1, value: 2, extra1: 20 },
             { time: 2, value: 3, extra1: 30 } )

      s2 = S({ time: 0, value: 9, extra2: 90 },
             { time: 1, value: 8, extra2: 80 },
             { time: 2, value: 7, extra2: 70 } )

      u = TIMED_UNION(s1: s1, s2: s2).i

      expected = [{ time: 0, value: { s1: 1, s2: 9 }, extra1: { s1: 10, s2: nil }, extra2: { s1: nil, s2: 90 } },
                  { time: 1, value: { s1: 2, s2: 8 }, extra1: { s1: 20, s2: nil }, extra2: { s1: nil, s2: 80 } },
                  { time: 2, value: { s1: 3, s2: 7 }, extra1: { s1: 30, s2: nil }, extra2: { s1: nil, s2: 70 } }]

      while v = u.next_value
        expect(v).to be_a(AbsTimed)
        expect(v).to eq(expected.shift)
      end

      expect(u.next_value).to be_nil
      expect(expected).to be_empty
    end

    it 'array timed_series with extra attributes' do
      s1 = S({ time: 0, value: [1, 10], extra1: [10, 100] },
             { time: 1, value: [2, 20], extra1: [20, 200] },
             { time: 2, value: [3, 30], extra1: [30, 300] } )

      s2 = S({ time: 0, value: [9, 90], extra2: [90, 900] },
             { time: 1, value: [8, 80], extra2: [80, 800] },
             { time: 2, value: [7, 70], extra2: [70, 700] } )

      u = TIMED_UNION(s1, s2).i

      expected = [{ time: 0, value: [1, 10, 9, 90], extra1: [10, 100, nil, nil], extra2: [nil, nil, 90, 900] },
                  { time: 1, value: [2, 20, 8, 80], extra1: [20, 200, nil, nil], extra2: [nil, nil, 80, 800] },
                  { time: 2, value: [3, 30, 7, 70], extra1: [30, 300, nil, nil], extra2: [nil, nil, 70, 700] }]

      while v = u.next_value
        expect(v).to be_a(AbsTimed)
        expect(v).to eq(expected.shift)
      end

      expect(u.next_value).to be_nil
      expect(expected).to be_empty
    end

    it 'hash timed_series with extra attributes' do
      s1 = S({ time: 0, value: { a: 1, b: 10 }, extra1: { a: 10, b: 100 } },
             { time: 1, value: { a: 2, b: 20 }, extra1: { a: 20, b: 200 } },
             { time: 2, value: { a: 3, b: 30 }, extra1: { a: 30, b: 300 } } )

      s2 = S({ time: 0, value: { c: 9, d: 90 }, extra2: { c: 90, d: 900 } },
             { time: 1, value: { c: 8, d: 80 }, extra2: { c: 80, d: 800 } },
             { time: 2, value: { c: 7, d: 70 }, extra2: { c: 70, d: 700 } } )

      u = TIMED_UNION(s1, s2).i

      expected = [{ time: 0,
                    value: { a: 1, b: 10, c: 9, d: 90 },
                    extra1: { a: 10, b: 100, c: nil, d: nil },
                    extra2: { a: nil, b: nil, c: 90, d: 900 } },

                  { time: 1,
                    value: { a: 2, b: 20, c: 8, d: 80 },
                    extra1: { a: 20, b: 200, c: nil, d: nil },
                    extra2: { a: nil, b: nil, c: 80, d: 800 } },

                  { time: 2,
                    value: { a: 3, b: 30, c: 7, d: 70 },
                    extra1: { a: 30, b: 300, c: nil, d: nil },
                    extra2: { a: nil, b: nil, c: 70, d: 700 } }]

      while v = u.next_value
        expect(v).to be_a(AbsTimed)
        expect(v).to eq(expected.shift)
      end

      expect(u.next_value).to be_nil
      expect(expected).to be_empty
    end

    it 'hash timed_series with repeated keys extra attributes raises runtimerror' do
      s1 = S({ time: 0, value: { a: 1, b: 10 }, extra1: { a: 10, b: 100 } },
             { time: 1, value: { a: 2, b: 20 }, extra1: { a: 20, b: 200 } },
             { time: 2, value: { a: 3, b: 30 }, extra1: { a: 30, b: 300 } } )

      s2 = S({ time: 0, value: { a: 9, d: 90 }, extra2: { c: 90, d: 900 } },
             { time: 1, value: { a: 8, d: 80 }, extra2: { c: 80, d: 800 } },
             { time: 2, value: { a: 7, d: 70 }, extra2: { c: 70, d: 700 } } )

      u = TIMED_UNION(s1, s2).i

      expect { u.next_value }.to raise_error(RuntimeError)
    end

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

      u = TIMED_UNION(pt1, pt2).i

      expected = [{ time: 0r, value: { a: 1, b: 10, c: 100, d: 9, e: 90, f: 900 } },
                  { time: 1/2r, value: { a: nil, b: nil, c: nil, d: 8, e: 80, f: 800 } },
                  { time: 1r, value: { a: 2, b: 20, c: 200, d: nil, e: nil, f: nil } },
                  { time: 3r, value: { a: 3, b: 30, c: 300, d: 7, e: 70, f: 700 } },
                  { time: 6r, value: { a: 4, b: 40, c: 400, d: 6, e: 60, f: 600 } },
                  { time: 8r, value: { a: 5, b: 50, c: 500, d: nil, e: nil, f: nil } }]

      while v = u.next_value
        expect(v).to be_a(AbsTimed)
        expect(v).to eq(expected.shift)
      end

      expect(u.next_value).to be_nil
      expect(expected).to be_empty
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

      u = TIMED_UNION(pt1, pt2).i

      expected = [{ time: 0r, value: [ 1, 10, 100, 9, 90, 900 ] },
                  { time: 1/2r, value: [ nil, nil, nil, 8, 80, 800 ] },
                  { time: 1r, value: [ 2, 20, 200, nil, nil, nil ] },
                  { time: 3r, value: [ 3, 30, 300, 7, 70, 700 ] },
                  { time: 6r, value: [ 4, 40, 400, 6, 60, 600 ] },
                  { time: 8r, value: [ 5, 50, 500, nil, nil, nil ] }]

      while v = u.next_value
        expect(v).to be_a(AbsTimed)
        expect(v).to eq(expected.shift)
      end

      expect(u.next_value).to be_nil
      expect(expected).to be_empty
    end

    it 'hash timed_serie (flattened, split) and union as hash' do
      p1 = [ { a: 1, b: 10, c: 100 }.extend(PackedV), 1 * 4,
             { a: 2, b: 20, c: 200 }.extend(PackedV), 2 * 4,
             { a: 3, b: 30, c: 300 }.extend(PackedV), 3 * 4,
             { a: 4, b: 40, c: 400 }.extend(PackedV), 2 * 4,
             { a: 5, b: 50, c: 500 }.extend(PackedV)].extend(P)

      p2 = [ { d: 9, e: 90, f: 900 }.extend(PackedV), 1/2r * 4,
             { d: 8, e: 80, f: 800 }.extend(PackedV), (2 + 1/2r) * 4,
             { d: 7, e: 70, f: 700 }.extend(PackedV), 3 * 4,
             { d: 6, e: 60, f: 600 }.extend(PackedV)].extend(P)

      pt1 = p1.to_timed_serie.flatten_timed.split.instance
      pt2 = p2.to_timed_serie.flatten_timed.split.instance

      u = TIMED_UNION(**pt1, **pt2).i

      expected = [{ time: 0r, value: { a: 1, b: 10, c: 100, d: 9, e: 90, f: 900 } },
                  { time: 1/2r, value: { a: nil, b: nil, c: nil, d: 8, e: 80, f: 800 } },
                  { time: 1r, value: { a: 2, b: 20, c: 200, d: nil, e: nil, f: nil } },
                  { time: 3r, value: { a: 3, b: 30, c: 300, d: 7, e: 70, f: 700 } },
                  { time: 6r, value: { a: 4, b: 40, c: 400, d: 6, e: 60, f: 600 } },
                  { time: 8r, value: { a: 5, b: 50, c: 500, d: nil, e: nil, f: nil } }]

      while v = u.next_value
        expect(v).to be_a(AbsTimed)
        expect(v).to eq(expected.shift)
      end

      expect(u.next_value).to be_nil
      expect(expected).to be_empty
    end
  end

  context 'timed_series + timed_union + split decomposition + compact timed + timed_union' do
    it 'timed_serie with direct value compact_timed' do
      s = S({ time: 0, value: 1 }.extend(AbsTimed),
             { time: 1, value: 2 }.extend(AbsTimed),
             { time: 2, value: nil }.extend(AbsTimed),
             { time: 3, value: 3 }.extend(AbsTimed))

      c = s.compact_timed.i

      expected = [{ time: 0, value: 1 },
                  { time: 1, value: 2 },
                  { time: 3, value: 3 }]

      while v = c.next_value
        expect(v).to be_a(AbsTimed)
        expect(v).to eq(expected.shift)
      end

      expect(c.next_value).to be_nil
      expect(expected).to be_empty
   end

    it 'timed_serie with hash values compact_timed' do
      s = S({ time: 0, value: { a: 1, b: 10 } }.extend(AbsTimed),
            { time: 1, value: { a: 2, b: 20 } }.extend(AbsTimed),
            { time: 2, value: nil }.extend(AbsTimed),
            { time: 3, value: { a: 3, b: nil } }.extend(AbsTimed),
            { time: 4, value: { a: nil, b: nil } }.extend(AbsTimed),
            { time: 5, value: { a: 4, b: 40 } }.extend(AbsTimed))

      c = s.compact_timed.i

      expected = [{ time: 0, value: { a: 1, b: 10 } },
                  { time: 1, value: { a: 2, b: 20 } },
                  { time: 3, value: { a: 3, b: nil } },
                  { time: 5, value: { a: 4, b: 40 } }]

      while v = c.next_value
        expect(v).to be_a(AbsTimed)
        expect(v).to eq(expected.shift)
      end

      expect(c.next_value).to be_nil
      expect(expected).to be_empty
    end

    it 'timed_serie with array values compact_timed' do
      s = S({ time: 0, value: [ 1, 10 ] }.extend(AbsTimed),
            { time: 1, value: [ 2, 20 ] }.extend(AbsTimed),
            { time: 2, value: nil }.extend(AbsTimed),
            { time: 3, value: [ 3, nil ] }.extend(AbsTimed),
            { time: 4, value: [ nil, nil ] }.extend(AbsTimed),
            { time: 5, value: [ 4, 40 ] }.extend(AbsTimed))

      c = s.compact_timed.i

      expected = [{ time: 0, value: [ 1, 10 ] },
                  { time: 1, value: [ 2, 20 ] },
                  { time: 3, value: [ 3, nil ] },
                  { time: 5, value: [ 4, 40 ] }]

      while v = c.next_value
        expect(v).to be_a(AbsTimed)
        expect(v).to eq(expected.shift)
      end

      expect(c.next_value).to be_nil
      expect(expected).to be_empty
    end

    it 'hash timed_serie' do
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

      u = TIMED_UNION(pt1, pt2).i

      split = u.flatten_timed.split.instance.to_h.transform_values(&:compact_timed)

      expect(split.size).to eq(6)

      u2 = TIMED_UNION(**split)

      expected = [{ time: 0r, value: { a: 1, b: 10, c: 100, d: 9, e: 90, f: 900 } },
                  { time: 1/2r, value: { a: nil, b: nil, c: nil, d: 8, e: 80, f: 800 } },
                  { time: 1r, value: { a: 2, b: 20, c: 200, d: nil, e: nil, f: nil } },
                  { time: 3r, value: { a: 3, b: 30, c: 300, d: 7, e: 70, f: 700 } },
                  { time: 6r, value: { a: 4, b: 40, c: 400, d: 6, e: 60, f: 600 } },
                  { time: 8r, value: { a: 5, b: 50, c: 500, d: nil, e: nil, f: nil } }]

      while v = u2.next_value
        expect(v).to be_a(AbsTimed)
        expect(v).to eq(expected.shift)
      end

      expect(u2.next_value).to be_nil
      expect(expected).to be_empty
    end

    it 'array timed_serie' do
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

      u = TIMED_UNION(pt1, pt2).i

      split = u.flatten_timed.split.instance.to_a.collect(&:compact_timed)

      expect(split.size).to eq(6)

      u2 = TIMED_UNION(*split)

      expected = [{ time: 0r, value: [ 1, 10, 100, 9, 90, 900 ] },
                  { time: 1/2r, value: [ nil, nil, nil, 8, 80, 800 ] },
                  { time: 1r, value: [ 2, 20, 200, nil, nil, nil ] },
                  { time: 3r, value: [ 3, 30, 300, 7, 70, 700 ] },
                  { time: 6r, value: [ 4, 40, 400, 6, 60, 600 ] },
                  { time: 8r, value: [ 5, 50, 500, nil, nil, nil ] }]

      while v = u2.next_value
        expect(v).to be_a(AbsTimed)
        expect(v).to eq(expected.shift)
      end

      expect(u2.next_value).to be_nil
      expect(expected).to be_empty
    end
  end

end