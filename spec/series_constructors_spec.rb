require 'spec_helper'

require 'musa-dsl'

include Musa::Series

RSpec.describe Musa::Series do
  context 'Series constructors' do

    it 'S(1, 2, 3)' do
      s1 = S(1, 2, 3).i

      expect(s1.current_value).to eq nil

      expect(s1.next_value).to eq 1
      expect(s1.current_value).to eq 1

      expect(s1.next_value).to eq 2
      expect(s1.next_value).to eq 3
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil

      s1.restart

      expect(s1.current_value).to eq nil

      expect(s1.next_value).to eq 1
      expect(s1.current_value).to eq 1

      expect(s1.next_value).to eq 2
      expect(s1.next_value).to eq 3
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil

      s1.restart

      expect(s1.peek_next_value).to eq 1
      expect(s1.peek_next_value).to eq 1
      expect(s1.next_value).to eq 1
      expect(s1.next_value).to eq 2
      expect(s1.peek_next_value).to eq 3
      expect(s1.peek_next_value).to eq 3
      expect(s1.next_value).to eq 3
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
    end

    it 'E with one argument' do

      s1 = E(100) { |v, last_value:| (last_value ? last_value + 1 : v) unless last_value == 103 }.i

      expect(s1.next_value).to eq 100
      expect(s1.next_value).to eq 101
      expect(s1.next_value).to eq 102
      expect(s1.next_value).to eq 103
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil

      s1.restart

      expect(s1.next_value).to eq 100
      expect(s1.next_value).to eq 101
      expect(s1.next_value).to eq 102
      expect(s1.next_value).to eq 103
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil

      s1.restart

      expect(s1.peek_next_value).to eq 100
      expect(s1.peek_next_value).to eq 100
      expect(s1.next_value).to eq 100
      expect(s1.next_value).to eq 101
      expect(s1.next_value).to eq 102
      expect(s1.peek_next_value).to eq 103
      expect(s1.next_value).to eq 103
      expect(s1.peek_next_value).to eq nil
      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
    end

    it 'E() { |i| i + 1 unless i == 3 }' do
      s1 = E() { |last_value:| (last_value || 0) + 1 unless last_value == 3 }.i

      expect(s1.next_value).to eq 1
      expect(s1.next_value).to eq 2
      expect(s1.next_value).to eq 3
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil

      s1.restart

      expect(s1.next_value).to eq 1
      expect(s1.next_value).to eq 2
      expect(s1.next_value).to eq 3
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil

      s1.restart

      expect(s1.peek_next_value).to eq 1
      expect(s1.peek_next_value).to eq 1
      expect(s1.next_value).to eq 1
      expect(s1.next_value).to eq 2
      expect(s1.peek_next_value).to eq 3
      expect(s1.next_value).to eq 3
      expect(s1.peek_next_value).to eq nil
      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
    end

    it 'bugfix for E serie with parameters used as temporary value holders that had bizarre results on second instance (series instance of a prototype didn\'t restarted)' do
      array = [1, 2, 3, 4, 5]

      u = Musa::Series::E(array, context: { time: 0 }) do |p, context:|
        value = p.shift

        if value
          r = { time: context[:time], value: value } if !value.nil?

          delta_time = p.shift
          context[:time] += delta_time if delta_time

          r
        end
      end

      u1 = u.i
      au1 = []

      while v = u1.next_value
        au1 << v.clone
      end

      u2 = u.i
      au2 = []

      while v = u2.next_value
        au2 << v.clone
      end

      expect(au2.size).to eq(au1.size)
      expect(au2).to eq(au1)
    end

    it 'FOR(from: 10, to: 13, step: 1)' do
      s1 = FOR(from: 10, to: 13, step: 1).i

      expect(s1.next_value).to eq 10
      expect(s1.next_value).to eq 11
      expect(s1.next_value).to eq 12
      expect(s1.next_value).to eq 13
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil

      s1.restart

      expect(s1.next_value).to eq 10
      expect(s1.next_value).to eq 11
      expect(s1.next_value).to eq 12
      expect(s1.next_value).to eq 13
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil

      s1.restart

      expect(s1.peek_next_value).to eq 10
      expect(s1.next_value).to eq 10
      expect(s1.next_value).to eq 11
      expect(s1.next_value).to eq 12
      expect(s1.peek_next_value).to eq 13
      expect(s1.next_value).to eq 13
      expect(s1.peek_next_value).to eq nil
      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
    end

    it 'FOR(from: 10, to: 11.25, step: Rational(1, 4))' do
      s1 = FOR(from: 10, to: 11.25, step: Rational(1, 4)).i

      expect(s1.next_value).to eq 10
      expect(s1.next_value).to eq 10.25
      expect(s1.next_value).to eq 10.50
      expect(s1.next_value).to eq 10.75
      expect(s1.next_value).to eq 11
      expect(s1.next_value).to eq 11.25
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil

      s1.restart

      expect(s1.next_value).to eq 10
      expect(s1.next_value).to eq 10.25
      expect(s1.next_value).to eq 10.50
      expect(s1.next_value).to eq 10.75
      expect(s1.next_value).to eq 11
      expect(s1.next_value).to eq 11.25
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
    end

    it 'FOR(from: 10, to: 11.25, step: -Rational(1, 4))' do
      s1 = FOR(from: 10, to: 11.25, step: -Rational(1, 4)).i

      expect(s1.next_value).to eq 10
      expect(s1.next_value).to eq 10.25
      expect(s1.next_value).to eq 10.50
      expect(s1.next_value).to eq 10.75
      expect(s1.next_value).to eq 11
      expect(s1.next_value).to eq 11.25
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil

      s1.restart

      expect(s1.next_value).to eq 10
      expect(s1.next_value).to eq 10.25
      expect(s1.next_value).to eq 10.50
      expect(s1.next_value).to eq 10.75
      expect(s1.next_value).to eq 11
      expect(s1.next_value).to eq 11.25
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
    end

    it 'FOR(from: 10, to: 8.75, step: -Rational(1, 4))' do
      s1 = FOR(from: 10, to: 8.75, step: -Rational(1, 4)).i

      expect(s1.next_value).to eq 10
      expect(s1.next_value).to eq 9.75
      expect(s1.next_value).to eq 9.50
      expect(s1.next_value).to eq 9.25
      expect(s1.next_value).to eq 9
      expect(s1.next_value).to eq 8.75
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil

      s1.restart

      expect(s1.next_value).to eq 10
      expect(s1.next_value).to eq 9.75
      expect(s1.next_value).to eq 9.50
      expect(s1.next_value).to eq 9.25
      expect(s1.next_value).to eq 9
      expect(s1.next_value).to eq 8.75
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
    end

    it 'MERGE S(1, 2, 3), S(4, 5, 6), S(7, 8, 9)' do
      s = MERGE(S(1, 2, 3), S(4, 5, 6), S(7, 8, 9)).i

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

    it 'FOR(from: 10, to: 8.75, step: Rational(1, 4))' do
      s1 = FOR(from: 10, to: 8.75, step: Rational(1, 4)).i

      expect(s1.infinite?).to eq false

      expect(s1.next_value).to eq 10
      expect(s1.next_value).to eq 9.75
      expect(s1.next_value).to eq 9.50
      expect(s1.next_value).to eq 9.25
      expect(s1.next_value).to eq 9
      expect(s1.next_value).to eq 8.75
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil

      s1.restart

      expect(s1.next_value).to eq 10
      expect(s1.next_value).to eq 9.75
      expect(s1.next_value).to eq 9.50
      expect(s1.next_value).to eq 9.25
      expect(s1.next_value).to eq 9
      expect(s1.next_value).to eq 8.75
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
    end

    it 'FOR(from: 10, step: Rational(1, 4))' do
      s1 = FOR(from: 10, step: -Rational(1, 4)).i

      expect(s1.infinite?).to eq true

      expect(s1.next_value).to eq 10
      expect(s1.next_value).to eq 9.75
      expect(s1.next_value).to eq 9.50
      expect(s1.next_value).to eq 9.25
      expect(s1.next_value).to eq 9
      expect(s1.next_value).to eq 8.75

      s1.restart

      expect(s1.next_value).to eq 10
      expect(s1.next_value).to eq 9.75
      expect(s1.next_value).to eq 9.50
      expect(s1.next_value).to eq 9.25
      expect(s1.next_value).to eq 9
      expect(s1.next_value).to eq 8.75
      expect(s1.next_value).to eq 8.50
      expect(s1.next_value).to eq 8.25
      expect(s1.next_value).to eq 8.0

    end

    it 'RND(8.75, 9, 9.25, 9.50, 9.75, 10)' do
      s1 = RND(8.75, 9, 9.25, 9.50, 9.75, 10).i

      r = []
      while v = s1.next_value
        r << v
      end

      expect(s1.peek_next_value).to eq nil
      expect(s1.peek_next_value).to eq nil
      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.peek_next_value).to eq nil

      expect(r.size).to eq 6
      expect(r.sort).to eq [8.75, 9, 9.25, 9.50, 9.75, 10]

      s1.restart

      r = []
      while v = s1.next_value
        r << v
      end

      expect(r.size).to eq 6
      expect(r.sort).to eq [8.75, 9, 9.25, 9.50, 9.75, 10]
    end

    it 'RND(from: 10, to: 8.75, step: -Rational(1, 4))' do
      s1 = RND(from: 10, to: 8.75, step: -Rational(1, 4)).i

      r = []
      while v = s1.next_value
        r << v
      end

      expect(s1.peek_next_value).to eq nil
      expect(s1.peek_next_value).to eq nil
      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.peek_next_value).to eq nil

      expect(r.size).to eq 6
      expect(r.sort).to eq [8.75, 9, 9.25, 9.50, 9.75, 10]

      s1.restart

      r = []
      while v = s1.next_value
        r << v
      end

      expect(r.size).to eq 6
      expect(r.sort).to eq [8.75, 9, 9.25, 9.50, 9.75, 10]
    end

    it 'RND(from: 10, to: 8.75, step: Rational(1, 4))' do
      s1 = RND(from: 10, to: 8.75, step: Rational(1, 4)).i

      r = []
      while v = s1.next_value
        r << v
      end

      expect(s1.peek_next_value).to eq nil
      expect(s1.peek_next_value).to eq nil
      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.peek_next_value).to eq nil

      expect(r.size).to eq 6
      expect(r.sort).to eq [8.75, 9, 9.25, 9.50, 9.75, 10]

      s1.restart

      r = []
      while v = s1.next_value
        r << v
      end

      expect(r.size).to eq 6
      expect(r.sort).to eq [8.75, 9, 9.25, 9.50, 9.75, 10]
    end

    it 'RND1(8.75, 9, 9.25, 9.50, 9.75, 10)' do
      s1 = RND1(8.75, 9, 9.25, 9.50, 9.75, 10).i

      r = []
      while v = s1.next_value
        r << v
      end

      expect(s1.peek_next_value).to eq nil
      expect(s1.peek_next_value).to eq nil
      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.peek_next_value).to eq nil

      expect(r.size).to eq 1

      99.times do
        s1.restart
        r << s1.next_value
      end

      expect(r.size).to eq 100

      expect(r.sort.uniq).to eq [8.75, 9, 9.25, 9.50, 9.75, 10]
    end

    it 'RND1(from: 10, to: 8.75, step: -Rational(1, 4))' do
      s1 = RND1(from: 10, to: 8.75, step: -Rational(1, 4)).i

      r = []
      while v = s1.next_value
        r << v
      end

      expect(s1.peek_next_value).to eq nil
      expect(s1.peek_next_value).to eq nil
      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.peek_next_value).to eq nil

      expect(r.size).to eq 1

      99.times do
        s1.restart
        r << s1.next_value
      end

      expect(r.size).to eq 100

      expect(r.sort.uniq).to eq [8.75, 9, 9.25, 9.50, 9.75, 10]
    end

    it 'RND1(from: 10, to: 8.75, step: Rational(1, 4))' do
      s1 = RND1(from: 10, to: 8.75, step: Rational(1, 4)).i

      r = []
      while v = s1.next_value
        r << v
      end

      expect(s1.peek_next_value).to eq nil
      expect(s1.peek_next_value).to eq nil
      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.peek_next_value).to eq nil

      expect(r.size).to eq 1

      99.times do
        s1.restart
        r << s1.next_value
      end

      expect(r.size).to eq 100

      expect(r.sort.uniq).to eq [8.75, 9, 9.25, 9.50, 9.75, 10]
    end

    it 'H(x: S(1,2,3), y: S(:a, :b, :c, :d))' do
      s1 = H(x: S(1, 2, 3), y: S(:a, :b, :c, :d)).i

      expect(s1.current_value).to eq nil

      expect(s1.next_value).to eq(x: 1, y: :a)
      expect(s1.next_value).to eq(x: 2, y: :b)
      expect(s1.peek_next_value).to eq(x: 3, y: :c)
      expect(s1.peek_next_value).to eq(x: 3, y: :c)
      expect(s1.next_value).to eq(x: 3, y: :c)
      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil

      s1.restart

      expect(s1.next_value).to eq(x: 1, y: :a)
      expect(s1.next_value).to eq(x: 2, y: :b)
      expect(s1.peek_next_value).to eq(x: 3, y: :c)
      expect(s1.peek_next_value).to eq(x: 3, y: :c)
      expect(s1.next_value).to eq(x: 3, y: :c)
      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
    end

    it 'HC(x: S(1,2), y: S(:a, :b, :c))' do
      s1 = HC(x: S(1, 2), y: S(:a, :b, :c)).i

      expect(s1.current_value).to eq nil

      expect(s1.next_value).to eq(x: 1, y: :a)
      expect(s1.next_value).to eq(x: 2, y: :b)
      expect(s1.next_value).to eq(x: 1, y: :c)
      expect(s1.next_value).to eq(x: 2, y: :a)
      expect(s1.next_value).to eq(x: 1, y: :b)
      expect(s1.next_value).to eq(x: 2, y: :c)
      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil

      s1.restart

      expect(s1.next_value).to eq(x: 1, y: :a)
      expect(s1.next_value).to eq(x: 2, y: :b)
      expect(s1.next_value).to eq(x: 1, y: :c)
      expect(s1.next_value).to eq(x: 2, y: :a)
      expect(s1.next_value).to eq(x: 1, y: :b)
      expect(s1.next_value).to eq(x: 2, y: :c)
      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
    end

    it 'HC(x: S(1,2), y: S(:a, :b, :c), z: S(1, 2, 3, 4))' do
      s1 = HC(x: S(1,2), y: S(:a, :b, :c), z: S(1, 2, 3, 4)).i

      expect(s1.current_value).to eq nil

      expect(s1.next_value).to eq(x: 1, y: :a, z: 1)
      expect(s1.next_value).to eq(x: 2, y: :b, z: 2)
      expect(s1.next_value).to eq(x: 1, y: :c, z: 3)
      expect(s1.next_value).to eq(x: 2, y: :a, z: 4)
      expect(s1.next_value).to eq(x: 1, y: :b, z: 1)
      expect(s1.next_value).to eq(x: 2, y: :c, z: 2)
      expect(s1.next_value).to eq(x: 1, y: :a, z: 3)
      expect(s1.next_value).to eq(x: 2, y: :b, z: 4)
      expect(s1.next_value).to eq(x: 1, y: :c, z: 1)
      expect(s1.next_value).to eq(x: 2, y: :a, z: 2)
      expect(s1.next_value).to eq(x: 1, y: :b, z: 3)
      expect(s1.next_value).to eq(x: 2, y: :c, z: 4)
      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil

      s1.restart

      expect(s1.next_value).to eq(x: 1, y: :a, z: 1)
      expect(s1.next_value).to eq(x: 2, y: :b, z: 2)
      expect(s1.next_value).to eq(x: 1, y: :c, z: 3)
      expect(s1.next_value).to eq(x: 2, y: :a, z: 4)
      expect(s1.next_value).to eq(x: 1, y: :b, z: 1)
      expect(s1.next_value).to eq(x: 2, y: :c, z: 2)
      expect(s1.next_value).to eq(x: 1, y: :a, z: 3)
      expect(s1.next_value).to eq(x: 2, y: :b, z: 4)
      expect(s1.next_value).to eq(x: 1, y: :c, z: 1)
      expect(s1.next_value).to eq(x: 2, y: :a, z: 2)
      expect(s1.next_value).to eq(x: 1, y: :b, z: 3)
      expect(s1.next_value).to eq(x: 2, y: :c, z: 4)
      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
    end

    it 'A(S(1,2,3), S(:a, :b, :c, :d))' do
      s1 = A(S(1, 2, 3), S(:a, :b, :c, :d)).i

      expect(s1.current_value).to eq nil

      expect(s1.next_value).to eq([1, :a])
      expect(s1.next_value).to eq([2, :b])
      expect(s1.peek_next_value).to eq([3, :c])
      expect(s1.peek_next_value).to eq([3, :c])
      expect(s1.next_value).to eq([3, :c])
      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil

      s1.restart

      expect(s1.next_value).to eq([1, :a])
      expect(s1.next_value).to eq([2, :b])
      expect(s1.next_value).to eq([3, :c])
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
    end

    it 'AC(S(1,2),S(:a, :b, :c))' do
      s1 = AC(S(1, 2), S(:a, :b, :c)).i

      expect(s1.current_value).to eq nil

      expect(s1.next_value).to eq([1, :a])
      expect(s1.next_value).to eq([2, :b])
      expect(s1.next_value).to eq([1, :c])
      expect(s1.next_value).to eq([2, :a])
      expect(s1.next_value).to eq([1, :b])
      expect(s1.next_value).to eq([2, :c])
      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil

      s1.restart

      expect(s1.next_value).to eq([1, :a])
      expect(s1.next_value).to eq([2, :b])
      expect(s1.next_value).to eq([1, :c])
      expect(s1.next_value).to eq([2, :a])
      expect(s1.next_value).to eq([1, :b])
      expect(s1.next_value).to eq([2, :c])
      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
    end

    it 'Complex E extraction' do
      perm = [1, 2, 3].permutation.to_a

      values = S(*perm).i

      values_serie = E() { S(*values.next_value) }.i

      expect(values_serie.next_value.to_a).to eq perm[0]
      expect(values_serie.next_value.to_a).to eq perm[1]
      expect(values_serie.next_value.to_a).to eq perm[2]
    end

    it 'SIN(start_value: 1, steps: 27, amplitude: 10, center: 0)' do
      s1 = SIN(start_value: 1, steps: 27, amplitude: 10, center: 0).i

      c = 0
      while v = s1.next_value
        expect(v).to eq 1.0 if c == 0
        c += 1
      end
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil

      expect(c).to eq 27
    end

    it 'FIBO()' do
      s = FIBO().i

      expect(s.infinite?).to eq true

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
    end

    it 'HARMO().max_size(10)' do
      s = HARMO().i

      expect(s.infinite?).to eq true

      expect(s.next_value).to eq 0
      expect(s.next_value).to eq 12
      expect(s.next_value).to eq 19
      expect(s.next_value).to eq 24
      expect(s.next_value).to eq 28
      expect(s.next_value).to eq 31
      expect(s.next_value).to eq 34
      expect(s.next_value).to eq 36
      expect(s.next_value).to eq 38
      expect(s.next_value).to eq 40
    end
  end
end
