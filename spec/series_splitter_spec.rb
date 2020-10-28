require 'spec_helper'

require 'musa-dsl'

include Musa::Series

RSpec.describe Musa::Series do
  context 'Series splitter handles' do
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

    it 'serie of hash elements (instancing split components) with restart on one split component' do
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

    it 'serie of hash elements (instancing split components) with restart on three split component' do
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
end
