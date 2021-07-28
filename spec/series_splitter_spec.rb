require 'spec_helper'

require 'musa-dsl'

include Musa::Series

using Musa::Extension::Matrix

RSpec.describe Musa::Series do
  context 'Series splitter handles' do
    it 'prototype / instance management' do
      s = S([1, 10, 100], [2, 20, 200], [3, 30, 300])

      expect(s.prototype?).to eq true
      expect(s.instance?).to eq false

      ss = s.split

      expect(ss.prototype?).to eq true
      expect(ss.instance?).to eq false

      expect { ss[0] }.to raise_error(RuntimeError)

      ssi = ss.instance

      ssi0i = ssi[0]

      expect(ssi0i.prototype?).to eq false
      expect(ssi0i.instance?).to eq true

      expect(ssi0i.next_value).to eq 1


      ssi0i2 = ssi[0].instance

      expect(ssi0i2.prototype?).to eq false
      expect(ssi0i2.instance?).to eq true

      expect(ssi0i2.next_value).to eq 2
      expect(ssi0i2.next_value).to eq 3

      expect(ssi0i.next_value).to be_nil

    end

    it 'serie of array elements (instancing split components)' do
      s = S([1, 10, 100], [2, 20, 200], [3, 30, 300])
      ss = s.split.instance

      ss_a = ss[0]
      ss_b = ss[1]
      ss_c = ss[2]

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
      ss = h.split.instance

      ss_a = ss[:a]
      ss_b = ss[:b]
      ss_c = ss[:c]

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

    it 'serie of hash elements (instancing split components) with restart on one split component [!!!!]', pending: true do
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

    it 'serie of hash elements (instancing split components) with restart on three split component should really restart when all 3 components are restarted [!!!!]', pending: true do
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

    it 'serie of hash elements (instancing split components) with restart on three split component [!!!!]', pending: true do
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
      ss = h.split.instance

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
      ss = s.split.instance

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
      ss = h.split.instance


      s2 = H(**ss.collect.to_h)

      s2i = s2.instance

      expect(s2i.next_value).to eq( { a: 1, b: 10, c: 100 } )
      expect(s2i.next_value).to eq( { a: 2, b: 20, c: 200 } )
      expect(s2i.next_value).to eq( { a: 3, b: 30, c: 300 } )

      expect(s2i.next_value).to be_nil
    end

    it 'serie of array elements split collected merges to array serie again' do
      s = S([1, 10, 100], [2, 20, 200], [3, 30, 300])
      ss = s.split.instance

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

      series = TIMED_UNION(**line.to_timed_serie.flatten_timed.split.instance).flatten_timed.split.instance.to_h

      series_a = series[:a].instance

      # due to new .split that generates a
      expect(series[:a].instance?).to eq true
      expect(series_a.instance?).to eq true

      expect(series_a.next_value).to eq({ time: 0, value: 1})
    end

    it 'bugfix: restarting a joined series of a split serie when peeked_next_value and restarted generates a stack overflow' do
      s = S([1, 10], [2, 20], [3, 30])
      ss = s.split.instance

      s2 = A(*ss)
      s2i = s2

      s2i.peek_next_value
      s2i.restart

      expect(s2i.next_value).to eq [1, 10]
      expect(s2i.next_value).to eq [2, 20]
      expect(s2i.next_value).to eq [3, 30]

      expect(s2i.next_value).to be_nil
    end

  end
end
