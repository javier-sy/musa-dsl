require 'spec_helper'

require 'musa-dsl'

include Musa::Series

using Musa::Extension::Matrix

RSpec.describe Musa::Series do
  context 'Series splitter handles' do
    it 'prototype / instance management and split series independence' do
      s = S([1, 10, 100], [2, 20, 200], [3, 30, 300])

      expect(s.prototype?).to eq true
      expect(s.instance?).to eq false

      ss = s.split

      expect(ss[0].prototype?).to eq true
      expect(ss[0].instance?).to eq false

      ss0i = ss[0].instance

      expect(ss0i.prototype?).to eq false
      expect(ss0i.instance?).to eq true

      expect(ss[0].prototype?).to eq true
      expect(ss[0].instance?).to eq false

      expect(ss0i.next_value).to eq 1

      expect(ss0i.prototype?).to eq false
      expect(ss0i.instance?).to eq true

      expect(ss[0].prototype?).to eq true
      expect(ss[0].instance?).to eq false

      ss0i2 = ss[0].instance

      expect(ss0i2.next_value).to eq 1
      expect(ss0i2.next_value).to eq 2
      expect(ss0i2.next_value).to eq 3

      expect(ss0i.next_value).to eq 2

      expect(ss0i2.next_value).to be_nil

      expect(ss0i.next_value).to eq 3
      expect(ss0i.next_value).to be_nil
    end

    it 'serie of array elements (instancing split components)' do
      s = S([1, 10, 100], [2, 20, 200], [3, 30, 300])
      ss = s.split

      ss_a = ss[0].instance
      ss_b = ss[1].instance
      ss_c = ss[2].instance

      expect(ss_a.next_value).to eq 1
      expect(ss_b.next_value).to eq 10
      expect(ss_c.next_value).to eq 100

      expect(ss_a.next_value).to eq 2
      expect(ss_b.next_value).to eq 20

      expect(ss_a.next_value).to eq 3
      expect(ss_b.next_value).to eq 30

      expect(ss_c.next_value).to eq 200

      expect(ss_a.next_value).to be_nil
      expect(ss_b.next_value).to be_nil

      expect(ss_a.next_value).to be_nil
      expect(ss_b.next_value).to be_nil

      expect(ss_c.next_value).to eq 300

      expect(ss_a.next_value).to be_nil
      expect(ss_a.next_value).to be_nil

      expect(ss_b.next_value).to be_nil
      expect(ss_b.next_value).to be_nil

      expect(ss_c.next_value).to be_nil
      expect(ss_c.next_value).to be_nil
    end

    it 'serie of hash elements (instancing split components)' do
      s = S([1, 10, 100], [2, 20, 200], [3, 30, 300])
      h = s.hashify(:a, :b, :c)
      ss = h.split

      ss_a = ss[:a].instance
      ss_b = ss[:b].instance
      ss_c = ss[:c].instance

      expect(ss_a.next_value).to eq 1
      expect(ss_b.next_value).to eq 10
      expect(ss_c.next_value).to eq 100

      expect(ss_a.next_value).to eq 2
      expect(ss_b.next_value).to eq 20

      expect(ss_a.next_value).to eq 3
      expect(ss_b.next_value).to eq 30

      expect(ss_c.next_value).to eq 200

      expect(ss_a.next_value).to be_nil
      expect(ss_b.next_value).to be_nil

      expect(ss_a.next_value).to be_nil
      expect(ss_b.next_value).to be_nil

      expect(ss_c.next_value).to eq 300

      expect(ss_a.next_value).to be_nil
      expect(ss_a.next_value).to be_nil

      expect(ss_b.next_value).to be_nil
      expect(ss_b.next_value).to be_nil

      expect(ss_c.next_value).to be_nil
      expect(ss_c.next_value).to be_nil
    end

    it 'serie of hash elements (instancing split components) with restart on one split component [!!!!]' do
      s = S([1, 10, 100], [2, 20, 200], [3, 30, 300])
      h = s.hashify(:a, :b, :c)
      ss = h.split

      ss_a = ss[:a].instance
      ss_b = ss[:b].instance
      ss_c = ss[:c].instance

      expect(ss_a.next_value).to eq 1
      expect(ss_b.next_value).to eq 10
      expect(ss_c.next_value).to eq 100

      expect(ss_a.next_value).to eq 2
      expect(ss_b.next_value).to eq 20

      expect(ss_a.next_value).to eq 3
      expect(ss_b.next_value).to eq 30

      expect(ss_c.next_value).to eq 200

      expect(ss_a.next_value).to be_nil
      expect(ss_b.next_value).to be_nil

      expect(ss_a.next_value).to be_nil
      expect(ss_b.next_value).to be_nil

      expect(ss_c.next_value).to eq 300

      expect(ss_a.next_value).to be_nil
      expect(ss_a.next_value).to be_nil

      expect(ss_b.next_value).to be_nil
      expect(ss_b.next_value).to be_nil

      expect(ss_c.next_value).to be_nil
      expect(ss_c.next_value).to be_nil

      ss_a.restart

      expect(ss_a.next_value).to eq 1
      expect(ss_a.next_value).to eq 2
      expect(ss_a.next_value).to eq 3

      expect(ss_a.next_value).to be_nil
      expect(ss_a.next_value).to be_nil

      expect(ss_b.next_value).to be_nil
      expect(ss_b.next_value).to be_nil

      expect(ss_c.next_value).to be_nil
      expect(ss_c.next_value).to be_nil
    end

    it 'serie of hash elements (instancing split components) with restart on three split component should really restart when all 3 components are restarted [!!!!]' do
      s = S([1, 10, 100], [2, 20, 200], [3, 30, 300])
      h = s.hashify(:a, :b, :c)
      ss = h.split

      ss_a = ss[:a].instance
      ss_b = ss[:b].instance
      ss_c = ss[:c].instance

      expect(ss_a.next_value).to eq 1
      expect(ss_b.next_value).to eq 10
      expect(ss_c.next_value).to eq 100

      expect(ss_a.next_value).to eq 2
      expect(ss_b.next_value).to eq 20

      expect(ss_a.next_value).to eq 3
      expect(ss_b.next_value).to eq 30

      expect(ss_c.next_value).to eq 200

      expect(ss_a.next_value).to be_nil
      expect(ss_b.next_value).to be_nil

      expect(ss_a.next_value).to be_nil
      expect(ss_b.next_value).to be_nil

      expect(ss_c.next_value).to eq 300

      expect(ss_a.next_value).to be_nil
      expect(ss_a.next_value).to be_nil

      expect(ss_b.next_value).to be_nil
      expect(ss_b.next_value).to be_nil

      expect(ss_c.next_value).to be_nil
      expect(ss_c.next_value).to be_nil

      ss_a.restart

      expect(ss_a.next_value).to be_nil
      expect(ss_a.next_value).to be_nil

      ss_b.restart

      expect(ss_a.next_value).to be_nil

      expect(ss_b.next_value).to be_nil
      expect(ss_b.next_value).to be_nil

      ss_c.restart

      expect(ss_a.next_value).to eq 1
      expect(ss_b.next_value).to eq 10
      expect(ss_c.next_value).to eq 100

      expect(ss_a.next_value).to eq 2
      expect(ss_a.next_value).to eq 3
      expect(ss_a.next_value).to be_nil

      expect(ss_b.next_value).to eq 20
      expect(ss_b.next_value).to eq 30
      expect(ss_b.next_value).to be_nil

      expect(ss_c.next_value).to eq 200
      expect(ss_c.next_value).to eq 300

      expect(ss_c.next_value).to be_nil
    end

    it 'serie of hash elements (instancing split components) with restart on three split component [!!!!]' do
      s = S([1, 10, 100], [2, 20, 200], [3, 30, 300])
      h = s.hashify(:a, :b, :c)
      ss = h.split

      ss_a = ss[:a].instance
      ss_b = ss[:b].instance
      ss_c = ss[:c].instance

      expect(ss_a.next_value).to eq 1
      expect(ss_b.next_value).to eq 10
      expect(ss_c.next_value).to eq 100

      expect(ss_a.next_value).to eq 2
      expect(ss_b.next_value).to eq 20

      expect(ss_a.next_value).to eq 3
      expect(ss_b.next_value).to eq 30

      expect(ss_c.next_value).to eq 200

      expect(ss_a.next_value).to be_nil
      expect(ss_b.next_value).to be_nil

      expect(ss_a.next_value).to be_nil
      expect(ss_b.next_value).to be_nil

      expect(ss_c.next_value).to eq 300

      expect(ss_a.next_value).to be_nil
      expect(ss_a.next_value).to be_nil

      expect(ss_b.next_value).to be_nil
      expect(ss_b.next_value).to be_nil

      expect(ss_c.next_value).to be_nil
      expect(ss_c.next_value).to be_nil

      ss_a.restart

      expect(ss_a.next_value).to eq 1
      expect(ss_a.next_value).to eq 2

      ss_b.restart

      expect(ss_a.next_value).to eq 3

      expect(ss_b.next_value).to eq 10
      expect(ss_b.next_value).to eq 20

      expect(ss_a.next_value).to be_nil


      ss_c.restart

      expect(ss_c.next_value).to eq 100

      expect(ss_b.next_value).to eq 30
      expect(ss_b.next_value).to be_nil

      expect(ss_c.next_value).to eq 200
      expect(ss_c.next_value).to eq 300

      expect(ss_c.next_value).to be_nil
    end
  end

  context 'Series split and merged cases:' do
    it 'serie of hash elements split merges to hash serie again' do
      s = S([1, 10, 100], [2, 20, 200], [3, 30, 300])
      h = s.hashify(:a, :b, :c)
      ss = h.split

      ss_a = ss[:a]
      ss_b = ss[:b]
      ss_c = ss[:c]

      s2 = H(a: ss_a, b: ss_b, c: ss_c)

      s2i = s2.instance

      expect(s2i.next_value).to eq( { a: 1, b: 10, c: 100 } )
      expect(s2i.next_value).to eq( { a: 2, b: 20, c: 200 } )
      expect(s2i.next_value).to eq( { a: 3, b: 30, c: 300 } )

      expect(s2i.next_value).to be_nil
    end

    it 'serie of array elements split merges to array serie again' do
      s = S([1, 10, 100], [2, 20, 200], [3, 30, 300])
      ss = s.split

      ss_a = ss[0]
      ss_b = ss[1]
      ss_c = ss[2]

      s2 = A(ss_a, ss_b, ss_c)

      s2i = s2.instance

      expect(s2i.next_value).to eq( [ 1, 10, 100 ] )
      expect(s2i.next_value).to eq( [ 2, 20, 200 ] )
      expect(s2i.next_value).to eq( [ 3, 30, 300 ] )

      expect(s2i.next_value).to be_nil
    end
  end

  context 'Series split and collected:' do

    it 'serie of hash elements split collected merges to hash serie again' do
      s = S([1, 10, 100], [2, 20, 200], [3, 30, 300])
      h = s.hashify(:a, :b, :c)
      ss = h.split


      s2 = H(**ss.collect.to_h)

      s2i = s2.instance

      expect(s2i.next_value).to eq( { a: 1, b: 10, c: 100 } )
      expect(s2i.next_value).to eq( { a: 2, b: 20, c: 200 } )
      expect(s2i.next_value).to eq( { a: 3, b: 30, c: 300 } )

      expect(s2i.next_value).to be_nil
    end

    it 'serie of array elements split collected merges to array serie again' do
      s = S([1, 10, 100], [2, 20, 200], [3, 30, 300])
      ss = s.split

      s2 = A(*ss.collect)

      s2i = s2.instance

      expect(s2i.next_value).to eq( [ 1, 10, 100 ] )
      expect(s2i.next_value).to eq( [ 2, 20, 200 ] )
      expect(s2i.next_value).to eq( [ 3, 30, 300 ] )

      expect(s2i.next_value).to be_nil
    end

    it 'bugfix for complex split of a timed_union of a split p.timed_serie skipping values on next_value' do
      line = [ { a: 1, b: 10, c: 100 }.extend(Musa::Datasets::PackedV), 1 * 4,
               { a: 2, b: 20, c: 200 }.extend(Musa::Datasets::PackedV), 2 * 4,
               { a: 3, b: 30, c: 300 }.extend(Musa::Datasets::PackedV), 1 * 4,
               { a: 4, b: 40, c: 400 }.extend(Musa::Datasets::PackedV)].extend(Musa::Datasets::P)

      series = TIMED_UNION(**line.to_timed_serie.flatten_timed.split).flatten_timed.split.to_h

      series_a = series[:a].instance

      expect(series[:a].prototype?).to eq true
      expect(series_a.instance?).to eq true

      expect(series_a.next_value).to eq({ time: 0, value: 1})
    end
  end
end
