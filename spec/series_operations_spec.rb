require 'spec_helper'

require 'musa-dsl'

include Musa::Series

RSpec.describe Musa::Serie do
  context 'Series operations' do

    it 'Length: FOR(from: 1, to: 100).max_size(3)' do
      s = FOR(from: 1, to: 100).max_size(3)

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
      s = FOR(from: 1, to: 100).max_size(0)

      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil

      s.restart

      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
    end

    it 'Length: FOR(from: 1, to: 3).max_size(5)' do
      s = FOR(from: 1, to: 3).max_size(5)

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

    it 'Skip: FOR(from: 1, to: 100).skip(3).max_size(3)' do
      s = FOR(from: 1, to: 100).skip(3).max_size(3)

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

    it 'Duplicate: S(1, 2, 3, 4, 5, 6).duplicate' do
      s1 = S(1, 2, 3, 4, 5, 6)

      s2 = s1.duplicate

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

    it 'Autorestart: S(1, 2, 3).autorestart' do
      s1 = S(1, 2, 3).autorestart

      expect(s1.current_value).to eq nil

      expect(s1.next_value).to eq 1
      expect(s1.current_value).to eq 1

      expect(s1.next_value).to eq 2
      expect(s1.current_value).to eq 2

      expect(s1.next_value).to eq 3

      expect(s1.next_value).to eq nil
      expect(s1.current_value).to eq nil

      expect(s1.next_value).to eq 1
      expect(s1.next_value).to eq 2
      expect(s1.next_value).to eq 3
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq 1

      s1.restart

      expect(s1.next_value).to eq 1
      expect(s1.next_value).to eq 2
      expect(s1.next_value).to eq 3
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq 1
      expect(s1.next_value).to eq 2
      expect(s1.next_value).to eq 3
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq 1

      s1.restart

      expect(s1.current_value).to eq nil

      expect(s1.peek_next_value).to eq 1
      expect(s1.peek_next_value).to eq 1
      expect(s1.next_value).to eq 1
      expect(s1.next_value).to eq 2
      expect(s1.peek_next_value).to eq 3
      expect(s1.peek_next_value).to eq 3
      expect(s1.next_value).to eq 3
      expect(s1.peek_next_value).to eq nil
      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.peek_next_value).to eq 1
      expect(s1.peek_next_value).to eq 1
      expect(s1.next_value).to eq 1
      expect(s1.next_value).to eq 2
      expect(s1.next_value).to eq 3
    end

    it 'Autorestart: S(1, 2, 3).autorestart(skip_nil: true)' do
      s1 = S(1, 2, 3).autorestart(skip_nil: true)

      expect(s1.current_value).to eq nil

      expect(s1.next_value).to eq 1
      expect(s1.current_value).to eq 1

      expect(s1.next_value).to eq 2
      expect(s1.current_value).to eq 2

      expect(s1.next_value).to eq 3

      expect(s1.next_value).to eq 1
      expect(s1.next_value).to eq 2
      expect(s1.next_value).to eq 3
      expect(s1.next_value).to eq 1
      expect(s1.next_value).to eq 2

      s1.restart

      expect(s1.next_value).to eq 1
      expect(s1.next_value).to eq 2
      expect(s1.next_value).to eq 3
      expect(s1.next_value).to eq 1
      expect(s1.next_value).to eq 2
      expect(s1.next_value).to eq 3
      expect(s1.next_value).to eq 1

      s1.restart

      expect(s1.current_value).to eq nil

      expect(s1.peek_next_value).to eq 1
      expect(s1.peek_next_value).to eq 1
      expect(s1.next_value).to eq 1
      expect(s1.next_value).to eq 2
      expect(s1.peek_next_value).to eq 3
      expect(s1.peek_next_value).to eq 3
      expect(s1.next_value).to eq 3
      expect(s1.peek_next_value).to eq 1
      expect(s1.peek_next_value).to eq 1
      expect(s1.next_value).to eq 1
      expect(s1.next_value).to eq 2
      expect(s1.next_value).to eq 3
    end

    it 'Repeat: S(1, 2, 3).repeat 3' do
      s1 = S(1, 2, 3)

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

      s3 = (s1 + s2).repeat 3

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

      s3 = (s1 + s2).repeat 3

      s4 = s3 + S(10, 11, 12)

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

      s3 = s1.after(s2)

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

      s3 = s1 + s2

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

      ss = s.cut 3

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

      ss = s.cut 3

      sss = ss.merge

      expect(sss.to_a).to eq [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
    end

    it 'Remove: s = S(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12); ss = s.remove 3' do
      s = S 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12

      ss = s.remove 3

      r = []

      while value = ss.next_value
        r << value
      end

      expect(r).to eq [4, 5, 6, 7, 8, 9, 10, 11, 12]
      expect(ss.next_value).to eq nil
      expect(ss.next_value).to eq nil
      expect(ss.next_value).to eq nil
    end

    it 'Multiplex' do
      s = S(0, 1, 2).multiplex(S(100, 200, 300, 400, 500), S(1000, 2000, 3000, 4000, 5000), S(10000, 20000, 30000, 40000, 50000))

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
      expect(s.deterministic?).to eq true
    end


    it '.flatten(serie_of_series: true): S(S(1, 2, 3), S(4, 5, 6), S(7, 8, 9))' do
      s = S(S(1, 2, 3), S(4, 5, 6), S(7, 8, 9)).flatten(serie_of_series: true)

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

    it '.flatten: S(S(1, 2, 3), 33, S(4, 5, 6), S(7, 8, 9))' do
      s = S(S(1, 2, 3), 33, S(4, 5, 6), S(7, 8, 9)).flatten

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

    it 'Complex .flatten(serie_of_series: true) extraction I' do
      perm = [1, 2, 3].permutation.to_a

      values = S(*perm)

      values_serie = E() { S(*values.next_value) }

      s = values_serie.flatten(serie_of_series: true)

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

    it 'Complex .flatten(serie_of_series: true) extraction II' do
      perm = [1, 2, 3].permutation.to_a

      values = S(*perm)

      values_serie = E() { S(*values.next_value) }

      s = values_serie.flatten(serie_of_series: true)

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
      end

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

  end
end
