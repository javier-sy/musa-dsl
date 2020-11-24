require 'spec_helper'

require 'musa-dsl'

include Musa::Series

using Musa::Extension::DeepCopy
using Musa::Extension::Neumas

RSpec.describe Musa::Series do
  context 'Series operations' do

    it 'reverse' do
      s = S(1, 2, 3).reverse.i

      expect(s.next_value).to eq 3
      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 1
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil

      s.restart

      expect(s.next_value).to eq 3
      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 1
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
    end

    it 'Length: FOR(from: 1, to: 100).max_size(3)' do
      s = FOR(from: 1, to: 100).max_size(3).i

      expect(s.next_value).to eq 1
      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil

      s.restart

      expect(s.next_value).to eq 1
      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
    end

    it 'Length: FOR(from: 1, to: 100).max_size(0)' do
      s = FOR(from: 1, to: 100).max_size(0).i

      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil

      s.restart

      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
    end

    it 'Length: FOR(from: 1, to: 3).max_size(5)' do
      s = FOR(from: 1, to: 3).max_size(5).i

      expect(s.next_value).to eq 1
      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil

      s.restart

      expect(s.next_value).to eq 1
      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
    end

    it 'FIBO().max_size(10)' do
      s = FIBO().max_size(10).i

      expect(s.infinite?).to eq false

      expect(s.current_value).to eq nil
      expect(s.next_value).to eq 1
      expect(s.next_value).to eq 1
      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3
      expect(s.next_value).to eq 5
      expect(s.next_value).to eq 8
      expect(s.next_value).to eq 13
      expect(s.next_value).to eq 21
      expect(s.next_value).to eq 34
      expect(s.next_value).to eq 55

      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil

      s.restart

      expect(s.current_value).to eq nil
      expect(s.next_value).to eq 1
      expect(s.next_value).to eq 1
      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3
      expect(s.next_value).to eq 5
      expect(s.next_value).to eq 8
      expect(s.next_value).to eq 13
      expect(s.next_value).to eq 21
      expect(s.next_value).to eq 34
      expect(s.next_value).to eq 55

      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
    end

    it 'HARMO(error: 0.1).max_size(10)' do
      s = HARMO(error: 0.1).max_size(10).i

      expect(s.infinite?).to eq false

      expect(s.to_a).to eq [0, 12, 19, 24, 31, 36, 38, 43, 48, 49]
    end

    it 'Skip: FOR(from: 1, to: 100).skip(3).max_size(3)' do
      s = FOR(from: 1, to: 100).skip(3).max_size(3).i

      expect(s.next_value).to eq 4
      expect(s.next_value).to eq 5
      expect(s.next_value).to eq 6
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil

      s.restart

      expect(s.next_value).to eq 4
      expect(s.next_value).to eq 5
      expect(s.next_value).to eq 6
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
    end

    it 'Remove: remove repeated elements' do
      s = S(1, 2, 3, 3, 3, 4, 5, 5, 5, 5, 6, 7, 8, 9, 10).remove { |v, history| v == history.last }.i

      expect(s.next_value).to eq 1
      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3
      expect(s.next_value).to eq 4
      expect(s.next_value).to eq 5
      expect(s.next_value).to eq 6
      expect(s.next_value).to eq 7
      expect(s.next_value).to eq 8
      expect(s.next_value).to eq 9
      expect(s.next_value).to eq 10
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil

      s.restart

      expect(s.next_value).to eq 1
      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3
      expect(s.next_value).to eq 4
      expect(s.next_value).to eq 5
      expect(s.next_value).to eq 6
      expect(s.next_value).to eq 7
      expect(s.next_value).to eq 8
      expect(s.next_value).to eq 9
      expect(s.next_value).to eq 10
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
    end


    it 'Duplicate: S(1, 2, 3, 4, 5, 6).dup' do
      s1 = S(1, 2, 3, 4, 5, 6).i

      s2 = s1.dup

      expect(s1.next_value).to eq 1
      expect(s1.next_value).to eq 2
      expect(s1.next_value).to eq 3

      expect(s2.next_value).to eq 1
      expect(s2.next_value).to eq 2
      expect(s2.next_value).to eq 3

      expect(s1.next_value).to eq 4
      expect(s1.next_value).to eq 5

      expect(s2.next_value).to eq 4
      expect(s2.next_value).to eq 5
      expect(s2.next_value).to eq 6

      expect(s2.next_value).to eq nil
      expect(s2.next_value).to eq nil

      expect(s1.next_value).to eq 6

      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
    end

    it 'Repeat: S(1, 2, 3).repeat 3' do
      s1 = S(1, 2, 3).i

      s2 = s1.repeat 3

      r = []

      while value = s2.next_value
        r << value
      end

      expect(r).to eq [1, 2, 3, 1, 2, 3, 1, 2, 3]
      expect(s2.next_value).to eq nil
      expect(s2.next_value).to eq nil
      expect(s2.next_value).to eq nil
    end

    it 'Repeat and +: s1 = S(1, 2, 3); s2 = S(4, 5, 6); (s1 + s2).repeat 3' do
      s1 = S(1, 2, 3)
      s2 = S(4, 5, 6)

      s3 = (s1 + s2).repeat(3).i

      r = []

      while value = s3.next_value
        r << value
      end

      expect(r).to eq [1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6]
      expect(s3.next_value).to eq nil
      expect(s3.next_value).to eq nil
      expect(s3.next_value).to eq nil
    end

    it 'Repeat and +: s1 = S(1, 2, 3); s2 = S(4, 5, 6); s3 = (s1 + s2).repeat 3; s4 = s3 + S(10, 11, 12)' do
      s1 = S(1, 2, 3)
      s2 = S(4, 5, 6)

      s3 = (s1 + s2).repeat(3)

      s4 = (s3 + S(10, 11, 12)).i

      r = []

      while value = s4.next_value
        r << value
      end

      expect(r).to eq [1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 10, 11, 12]
      expect(s4.next_value).to eq nil
      expect(s4.next_value).to eq nil
      expect(s4.next_value).to eq nil
    end

    it 'After: s1 = S(1, 2, 3, 4); s2 = S(5, 6, 7, 8); s3 = s1.after(s2)' do
      s1 = S(1, 2, 3, 4)
      s2 = S(5, 6, 7, 8)

      s3 = s1.after(s2).i

      r = []

      while value = s3.next_value
        r << value
      end

      expect(r).to eq [1, 2, 3, 4, 5, 6, 7, 8]
      expect(s3.next_value).to eq nil
      expect(s3.next_value).to eq nil
      expect(s3.next_value).to eq nil
    end

    it '+: s1 = S(1, 2, 3, 4); s2 = S(5, 6, 7, 8); s3 = s1 + s2' do
      s1 = S(1, 2, 3, 4)
      s2 = S(5, 6, 7, 8)

      s3 = (s1 + s2).i

      r = []

      while value = s3.next_value
        r << value
      end

      expect(r).to eq [1, 2, 3, 4, 5, 6, 7, 8]
      expect(s3.next_value).to eq nil
      expect(s3.next_value).to eq nil
      expect(s3.next_value).to eq nil
    end

    it 'Cut: s = S(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12); ss = s.cut 3' do
      s = S 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12

      ss = s.cut(3).i

      sss1 = ss.next_value

      expect(sss1.to_a).to eq [1, 2, 3]

      sss2 = ss.next_value
      sss3 = ss.next_value
      sss4 = ss.next_value

      expect(sss2.to_a).to eq [4, 5, 6]
      expect(sss3.to_a).to eq [7, 8, 9]
      expect(sss4.to_a).to eq [10, 11, 12]

      sss5 = ss.next_value

      expect(sss5.to_a).to eq []
    end

    it 'Cut and Merge: s = S(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12); ss = s.cut 3; sss = ss.merge' do
      s = S 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12

      ss = s.cut(3)


      sss = ss.merge.i

      expect(sss.to_a).to eq [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
    end

    it 'Multiplex' do
      s = S(0, 1, 2).multiplex(
            S(100, 200, 300, 400, 500),
            S(1000, 2000, 3000, 4000, 5000),
            S(10000, 20000, 30000, 40000, 50000)).i

      expect(s.next_value).to eq 100
      expect(s.next_value).to eq 2000
      expect(s.next_value).to eq 30000
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil

      s.restart

      expect(s.next_value).to eq 100
      expect(s.next_value).to eq 2000
      expect(s.next_value).to eq 30000
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil

      expect(s.infinite?).to eq false
    end


    it '.merge: S(S(1, 2, 3), S(4, 5, 6), S(7, 8, 9))' do
      s = S(S(1, 2, 3), S(4, 5, 6), S(7, 8, 9)).merge.i

      expect(s.current_value).to eq nil

      expect(s.next_value).to eq 1
      expect(s.current_value).to eq 1
      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3
      expect(s.next_value).to eq 4
      expect(s.next_value).to eq 5
      expect(s.next_value).to eq 6
      expect(s.next_value).to eq 7
      expect(s.next_value).to eq 8
      expect(s.next_value).to eq 9

      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil

      s.restart

      expect(s.current_value).to eq nil

      expect(s.next_value).to eq 1
      expect(s.current_value).to eq 1
      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3
      expect(s.next_value).to eq 4
      expect(s.next_value).to eq 5
      expect(s.next_value).to eq 6
      expect(s.next_value).to eq 7
      expect(s.next_value).to eq 8
      expect(s.next_value).to eq 9

      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil

      s.restart

      expect(s.current_value).to eq nil

      expect(s.next_value).to eq 1
      expect(s.current_value).to eq 1
      expect(s.next_value).to eq 2

      s.restart

      expect(s.next_value).to eq 1
      expect(s.current_value).to eq 1
      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3
      expect(s.next_value).to eq 4
      expect(s.next_value).to eq 5
      expect(s.next_value).to eq 6
      expect(s.next_value).to eq 7
      expect(s.next_value).to eq 8
      expect(s.next_value).to eq 9

      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil

      s.restart

      expect(s.next_value).to eq 1
      expect(s.current_value).to eq 1
      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3
      expect(s.next_value).to eq 4

      s.restart

      expect(s.next_value).to eq 1
      expect(s.current_value).to eq 1
      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3
      expect(s.next_value).to eq 4
      expect(s.next_value).to eq 5
      expect(s.next_value).to eq 6
      expect(s.next_value).to eq 7
      expect(s.next_value).to eq 8
      expect(s.next_value).to eq 9

      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
    end

    it '.with (I)' do
      s = S(1, 2, 3).with(
        b: S(100, 200, 300, 400),
        c: S(1000, 2000, 3000, 4000, 5000)) { |a, b:, c: | { a: a, b: b, c: c } }.i

      expect(s.next_value).to eq({ a: 1, b: 100, c: 1000 })
      expect(s.next_value).to eq({ a: 2, b: 200, c: 2000 })
      expect(s.next_value).to eq({ a: 3, b: 300, c: 3000 })
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil

      s.restart

      expect(s.next_value).to eq({ a: 1, b: 100, c: 1000 })
      expect(s.next_value).to eq({ a: 2, b: 200, c: 2000 })
      expect(s.next_value).to eq({ a: 3, b: 300, c: 3000 })
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil

      expect(s.infinite?).to eq false
    end

    it '.with (II)' do
      s = S(1, 2, 3, 4, 5, 6).with(
          b: S(100, 200, 300),
          c: S(1000, 2000, 3000, 4000, 5000)) { |a, b:, c: | { a: a, b: b, c: c } }.i

      expect(s.next_value).to eq({ a: 1, b: 100, c: 1000 })
      expect(s.next_value).to eq({ a: 2, b: 200, c: 2000 })
      expect(s.next_value).to eq({ a: 3, b: 300, c: 3000 })
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil

      s.restart

      expect(s.next_value).to eq({ a: 1, b: 100, c: 1000 })
      expect(s.next_value).to eq({ a: 2, b: 200, c: 2000 })
      expect(s.next_value).to eq({ a: 3, b: 300, c: 3000 })
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil

      expect(s.infinite?).to eq false
    end

    it '.with (III)' do
      s = S(1, 2, 3, 4, 5, 6).with(
          b: S(100, 200, 300),
          c: S(1000, 2000, 3000, 4000, 5000)).i

      expect(s.next_value).to eq([1, { b: 100, c: 1000 }])
      expect(s.next_value).to eq([2, { b: 200, c: 2000 }])
      expect(s.next_value).to eq([3, { b: 300, c: 3000 }])
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil

      s.restart

      expect(s.next_value).to eq([1, { b: 100, c: 1000 }])
      expect(s.next_value).to eq([2, { b: 200, c: 2000 }])
      expect(s.next_value).to eq([3, { b: 300, c: 3000 }])
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil

      expect(s.infinite?).to eq false
    end

    it '.merge: S(S(1, 2, 3).i, S(4, 5, 6).i, S(7, 8, 9).i)' do
      ss = S(S(1, 2, 3).i, S(4, 5, 6).i, S(7, 8, 9).i)

      expect { ss.flatten.next_value }.to raise_error(Serie::PrototypingSerieError)
      expect { ss.merge.next_value }.to raise_error(Serie::PrototypingSerieError)

      s = ss.instance.merge

      expect(s.current_value).to eq nil

      expect(s.next_value).to eq 1
      expect(s.current_value).to eq 1
      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3
      expect(s.next_value).to eq 4
      expect(s.next_value).to eq 5
      expect(s.next_value).to eq 6
      expect(s.next_value).to eq 7
      expect(s.next_value).to eq 8
      expect(s.next_value).to eq 9

      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
    end

    it '.flatten: S(S(1, 2, 3), 33, S(4, 5, 6), S(7, 8, 9))' do
      s = S(S(1, 2, 3), 33, S(4, 5, 6), S(7, 8, 9)).flatten.i

      expect(s.current_value).to eq nil

      expect(s.next_value).to eq 1
      expect(s.current_value).to eq 1
      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3
      expect(s.next_value).to eq 33
      expect(s.next_value).to eq 4
      expect(s.next_value).to eq 5
      expect(s.next_value).to eq 6
      expect(s.next_value).to eq 7
      expect(s.next_value).to eq 8
      expect(s.next_value).to eq 9

      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil

      s.restart

      expect(s.current_value).to eq nil

      expect(s.next_value).to eq 1
      expect(s.current_value).to eq 1
      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3
      expect(s.next_value).to eq 33
      expect(s.next_value).to eq 4
      expect(s.next_value).to eq 5
      expect(s.next_value).to eq 6
      expect(s.next_value).to eq 7
      expect(s.next_value).to eq 8
      expect(s.next_value).to eq 9

      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil

      s.restart

      expect(s.current_value).to eq nil

      expect(s.next_value).to eq 1
      expect(s.current_value).to eq 1
      expect(s.next_value).to eq 2

      s.restart

      expect(s.next_value).to eq 1
      expect(s.current_value).to eq 1
      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3
      expect(s.next_value).to eq 33
      expect(s.next_value).to eq 4
      expect(s.next_value).to eq 5
      expect(s.next_value).to eq 6
      expect(s.next_value).to eq 7
      expect(s.next_value).to eq 8
      expect(s.next_value).to eq 9

      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil

      s.restart

      expect(s.next_value).to eq 1
      expect(s.current_value).to eq 1
      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3
      expect(s.next_value).to eq 33
      expect(s.next_value).to eq 4

      s.restart

      expect(s.next_value).to eq 1
      expect(s.current_value).to eq 1
      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3
      expect(s.next_value).to eq 33
      expect(s.next_value).to eq 4
      expect(s.next_value).to eq 5
      expect(s.next_value).to eq 6
      expect(s.next_value).to eq 7
      expect(s.next_value).to eq 8
      expect(s.next_value).to eq 9

      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
    end

    it '.flatten: S(S(1, 2, 3).p, 33, S(4, 5, 6).p, S(7, 8, 9).p).prototype' do
      s = S(S(1, 2, 3).p, 33, S(4, 5, 6).p, S(7, 8, 9).p).prototype

      expect { s.flatten.next_value }.to raise_error(Serie::PrototypingSerieError)
      expect { s.merge.next_value }.to raise_error(Serie::PrototypingSerieError)

      ss = s.instance.flatten

      expect(ss.current_value).to eq nil

      expect(ss.next_value).to eq 1
      expect(ss.current_value).to eq 1
      expect(ss.next_value).to eq 2
      expect(ss.next_value).to eq 3
      expect(ss.next_value).to eq 33
      expect(ss.next_value).to eq 4
      expect(ss.next_value).to eq 5
      expect(ss.next_value).to eq 6
      expect(ss.next_value).to eq 7
      expect(ss.next_value).to eq 8
      expect(ss.next_value).to eq 9

      expect(ss.next_value).to eq nil
      expect(ss.next_value).to eq nil
      expect(ss.next_value).to eq nil
    end

    it 'Complex .merge extraction I' do
      perm = [1, 2, 3].permutation.to_a

      values = S(*perm).i

      values_serie = E() {
        S(*values.next_value)
      }

      s = values_serie.merge.i

      expect(s.next_value).to eq perm[0][0]
      expect(s.next_value).to eq perm[0][1]
      expect(s.next_value).to eq perm[0][2]

      expect(s.next_value).to eq perm[1][0]
      expect(s.next_value).to eq perm[1][1]
      expect(s.next_value).to eq perm[1][2]

      expect(s.next_value).to eq perm[2][0]
      expect(s.next_value).to eq perm[2][1]
      expect(s.next_value).to eq perm[0][2]
    end

    it 'Complex .merge extraction II' do
      perm = [1, 2, 3].permutation.to_a

      values = S(*perm).i

      values_serie = E() { S(*values.next_value) }

      s = values_serie.merge

      expect(s.max_size(3).to_a).to eq perm[0]
      expect(s.max_size(3).to_a).to eq perm[1]
      expect(s.max_size(3).to_a).to eq perm[2]
    end

    it 'Serie process_with' do
      s = S(1, 2, 3, 4, 5, 6)

      ss = s.process_with do |i|
        if i.even?
          [100 + i, 200 + i]
        else
          i
        end
      end.i

      expect(ss.next_value).to eq 1
      expect(ss.next_value).to eq 102
      expect(ss.next_value).to eq 202
      expect(ss.next_value).to eq 3
      expect(ss.next_value).to eq 104
      expect(ss.next_value).to eq 204
      expect(ss.next_value).to eq 5
      expect(ss.next_value).to eq 106
      expect(ss.next_value).to eq 206

      expect(ss.next_value).to eq nil
      expect(ss.next_value).to eq nil
      expect(ss.next_value).to eq nil

      ss.restart

      expect(ss.next_value).to eq 1
      expect(ss.next_value).to eq 102
      expect(ss.next_value).to eq 202
      expect(ss.next_value).to eq 3
      expect(ss.next_value).to eq 104
      expect(ss.next_value).to eq 204
      expect(ss.next_value).to eq 5
      expect(ss.next_value).to eq 106
      expect(ss.next_value).to eq 206

      expect(ss.next_value).to eq nil
      expect(ss.next_value).to eq nil
      expect(ss.next_value).to eq nil
    end

    it 'Serie select' do
      s = S(1, 2, 3, 4, 5, 6)

      ss = s.select { |i| i % 2 == 0 }.i

      expect(ss.next_value).to eq 2
      expect(ss.next_value).to eq 4
      expect(ss.next_value).to eq 6

      expect(ss.next_value).to eq nil
      expect(ss.next_value).to eq nil
      expect(ss.next_value).to eq nil

      ss.restart

      expect(ss.next_value).to eq 2
      expect(ss.next_value).to eq 4
      expect(ss.next_value).to eq 6

      expect(ss.next_value).to eq nil
      expect(ss.next_value).to eq nil
      expect(ss.next_value).to eq nil
    end

    it 'Serie anticipate' do
      s = S(1, 2, 3, 4, 5, 6)

      ss = s.anticipate do |previous, current, next_v|
        if next_v
          [previous, current + next_v * 10]
        else
          [previous, current]
        end
      end

      expect(ss.to_a).to eq [[nil, 21], [1, 32], [2, 43], [3, 54], [4, 65], [5, 6]]
    end

    it 'Generative grammar nodes of series to serie' do
      a = N(1)
      b = N(2)

      s = (a + b | b)

      expect(a.to_serie.to_a).to eq [1]
      expect(s.to_serie.to_a).to eq [1, 2, 2]
    end

    it 'Serie to generative grammar node' do
      a = S(1, 2).to_node
      b = S(3, 4).to_node

      s = (a + b | b).options.to_serie(of_series: true)

      expect(s.to_a(recursive: true).flatten).to eq [1, 2, 3, 4, 3, 4]
    end

    include Musa::GenerativeGrammar

    it 'Generative grammar nodes of series to serie' do
      a = S(1, 2).node
      b = S(3, 4).node

      s = (a + b | b)

      expect(a.to_serie.to_a).to eq [1, 2]

      expect(s.to_serie.to_a).to eq [1, 2, 3, 4, 3, 4]
    end

    it 'Generative grammar nodes and series interoperability' do
      a = '(1)'.neumas.node
      b = '(2)'.nn

      s = a + b

      expect(s.s.a).to eq [{ kind: :gdvd, gdvd: { abs_grade: 1} }, { kind: :gdvd, gdvd: { abs_grade: 2 } }]
    end

  end
end
