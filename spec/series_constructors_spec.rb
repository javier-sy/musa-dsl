require 'spec_helper'

require 'musa-dsl'

include Musa::Series

RSpec.describe Musa::Serie do
  context 'Series constructors' do
    it 'S(1, 2, 3)' do
      s1 = S(1, 2, 3)

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

    it 'E(start: 100) { |v| v + 1 unless v == 103 }' do
      s1 = E(start: 100) { |v| v + 1 unless v == 103 }

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

    it 'E(start: nil) { |v| v ? v + 1 : 1 }' do
      s1 = E(start: nil) { |v| v ? v + 1 : 1 }

      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil

      s1.restart

      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil

      s1.restart

      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil
    end

    it 'E() { |i| i + 1 unless i == 3 }' do
      s1 = E() { |i| i + 1 unless i == 3 }

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

    it 'FOR(from: 10, to: 13, step: 1)' do
      s1 = FOR(from: 10, to: 13, step: 1)

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
      s1 = FOR(from: 10, to: 11.25, step: Rational(1, 4))

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
      s1 = FOR(from: 10, to: 11.25, step: -Rational(1, 4))

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
      s1 = FOR(from: 10, to: 8.75, step: -Rational(1, 4))

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

    it 'FOR(from: 10, to: 8.75, step: Rational(1, 4))' do
      s1 = FOR(from: 10, to: 8.75, step: Rational(1, 4))

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
      s1 = FOR(from: 10, step: -Rational(1, 4))

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
      s1 = RND(8.75, 9, 9.25, 9.50, 9.75, 10)

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
      s1 = RND(from: 10, to: 8.75, step: -Rational(1, 4))

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
      s1 = RND(from: 10, to: 8.75, step: Rational(1, 4))

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
      s1 = RND1(8.75, 9, 9.25, 9.50, 9.75, 10)

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
      s1 = RND1(from: 10, to: 8.75, step: -Rational(1, 4))

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
      s1 = RND1(from: 10, to: 8.75, step: Rational(1, 4))

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
      s1 = H(x: S(1, 2, 3), y: S(:a, :b, :c, :d))

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

    it 'H(x: S(1,2,3), y: S(:a, :b, :c, :d)).autorestart' do
      s1 = H(x: S(1, 2, 3), y: S(:a, :b, :c, :d)).autorestart

      expect(s1.current_value).to eq nil

      expect(s1.next_value).to eq(x: 1, y: :a)
      expect(s1.next_value).to eq(x: 2, y: :b)
      expect(s1.peek_next_value).to eq(x: 3, y: :c)
      expect(s1.peek_next_value).to eq(x: 3, y: :c)
      expect(s1.next_value).to eq(x: 3, y: :c)
      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil

      expect(s1.next_value).to eq(x: 1, y: :a)
      expect(s1.next_value).to eq(x: 2, y: :b)
      expect(s1.peek_next_value).to eq(x: 3, y: :c)
      expect(s1.peek_next_value).to eq(x: 3, y: :c)
      expect(s1.next_value).to eq(x: 3, y: :c)
      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil
    end

    it 'H(x: S(1,2), y: S(:a, :b, :c)).autorestart(skip_nil: true)' do
      s1 = H(x: S(1, 2), y: S(:a, :b, :c)).autorestart(skip_nil: true)

      expect(s1.current_value).to eq nil

      expect(s1.next_value).to eq(x: 1, y: :a)
      expect(s1.next_value).to eq(x: 2, y: :b)
      expect(s1.next_value).to eq(x: 1, y: :a)
      expect(s1.next_value).to eq(x: 2, y: :b)
      expect(s1.next_value).to eq(x: 1, y: :a)
      expect(s1.next_value).to eq(x: 2, y: :b)
      expect(s1.next_value).to eq(x: 1, y: :a)
      expect(s1.next_value).to eq(x: 2, y: :b)
    end

    it 'H(x: S(1,2,3).autorestart, y: S(:a, :b, :c, :d).autorestart)' do
      s1 = H(x: S(1, 2, 3).autorestart, y: S(:a, :b, :c, :d).autorestart)

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

    it 'H(x: S(1,2,3).autorestart, y: S(:a, :b, :c, :d).autorestart).autorestart' do
      s1 = H(x: S(1, 2, 3).autorestart, y: S(:a, :b, :c, :d).autorestart).autorestart

      expect(s1.current_value).to eq nil

      expect(s1.next_value).to eq(x: 1, y: :a)
      expect(s1.next_value).to eq(x: 2, y: :b)
      expect(s1.peek_next_value).to eq(x: 3, y: :c)
      expect(s1.peek_next_value).to eq(x: 3, y: :c)
      expect(s1.next_value).to eq(x: 3, y: :c)
      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil

      expect(s1.next_value).to eq(x: 1, y: :a)
      expect(s1.next_value).to eq(x: 2, y: :b)
      expect(s1.peek_next_value).to eq(x: 3, y: :c)
      expect(s1.peek_next_value).to eq(x: 3, y: :c)
      expect(s1.next_value).to eq(x: 3, y: :c)
      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil
    end

    it 'HC(x: S(1,2), y: S(:a, :b, :c))' do
      s1 = HC(x: S(1, 2), y: S(:a, :b, :c))

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
      s1 = HC(x: S(1,2), y: S(:a, :b, :c), z: S(1, 2, 3, 4))

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

    it 'HC(x: S(1,2), y: S(:a, :b, :c)).autorestart' do
      s1 = HC(x: S(1, 2), y: S(:a, :b, :c)).autorestart

      expect(s1.current_value).to eq nil

      expect(s1.next_value).to eq(x: 1, y: :a)
      expect(s1.next_value).to eq(x: 2, y: :b)
      expect(s1.next_value).to eq(x: 1, y: :c)
      expect(s1.next_value).to eq(x: 2, y: :a)
      expect(s1.next_value).to eq(x: 1, y: :b)
      expect(s1.next_value).to eq(x: 2, y: :c)
      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil

      expect(s1.current_value).to eq nil

      expect(s1.next_value).to eq(x: 1, y: :a)
      expect(s1.next_value).to eq(x: 2, y: :b)
      expect(s1.next_value).to eq(x: 1, y: :c)
      expect(s1.next_value).to eq(x: 2, y: :a)
      expect(s1.next_value).to eq(x: 1, y: :b)
      expect(s1.next_value).to eq(x: 2, y: :c)

      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq(x: 1, y: :a)
    end

    it 'HC(x: S(1,2), y: S(:a, :b, :c)).autorestart(skip_nil: true)' do
      s1 = HC(x: S(1, 2), y: S(:a, :b, :c)).autorestart(skip_nil: true)

      expect(s1.current_value).to eq nil

      expect(s1.next_value).to eq(x: 1, y: :a)
      expect(s1.next_value).to eq(x: 2, y: :b)
      expect(s1.next_value).to eq(x: 1, y: :c)
      expect(s1.next_value).to eq(x: 2, y: :a)
      expect(s1.next_value).to eq(x: 1, y: :b)
      expect(s1.next_value).to eq(x: 2, y: :c)

      expect(s1.next_value).to eq(x: 1, y: :a)
      expect(s1.next_value).to eq(x: 2, y: :b)
      expect(s1.next_value).to eq(x: 1, y: :c)
      expect(s1.next_value).to eq(x: 2, y: :a)
      expect(s1.next_value).to eq(x: 1, y: :b)
      expect(s1.next_value).to eq(x: 2, y: :c)

      expect(s1.next_value).to eq(x: 1, y: :a)
    end

    it 'A(S(1,2,3), S(:a, :b, :c, :d))' do
      s1 = A(S(1, 2, 3), S(:a, :b, :c, :d))

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

      expect(s1.peek_next_value).to eq([1, :d])
      expect(s1.next_value).to eq([1, :d])

      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil

      s1.restart

      expect(s1.current_value).to eq nil
      expect(s1.peek_next_value).to eq([2, :a])
      expect(s1.next_value).to eq([2, :a])
      expect(s1.next_value).to eq([3, :b])
      expect(s1.current_value).to eq([3, :b])
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil

      s1.restart

      expect(s1.current_value).to eq nil
      expect(s1.peek_next_value).to eq([1, :c])
      expect(s1.next_value).to eq([1, :c])
      expect(s1.next_value).to eq([2, :d])
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
    end

    it 'A(S(1,2,3), S(:a, :b, :c, :d)).autorestart' do
      s1 = A(S(1, 2, 3), S(:a, :b, :c, :d)).autorestart

      expect(s1.current_value).to eq nil

      expect(s1.next_value).to eq([1, :a])
      expect(s1.next_value).to eq([2, :b])
      expect(s1.peek_next_value).to eq([3, :c])
      expect(s1.peek_next_value).to eq([3, :c])
      expect(s1.next_value).to eq([3, :c])
      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil

      expect(s1.peek_next_value).to eq([1, :d])
      expect(s1.next_value).to eq([1, :d])

      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil

      expect(s1.current_value).to eq nil
      expect(s1.peek_next_value).to eq([2, :a])
      expect(s1.next_value).to eq([2, :a])
      expect(s1.next_value).to eq([3, :b])
      expect(s1.current_value).to eq([3, :b])
      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil

      expect(s1.current_value).to eq nil
      expect(s1.peek_next_value).to eq([1, :c])
      expect(s1.next_value).to eq([1, :c])
      expect(s1.next_value).to eq([2, :d])
      expect(s1.next_value).to eq nil
    end

    it 'A(S(1,2,3).autorestart, S(:a, :b, :c, :d).autorestart)' do
      s1 = A(S(1, 2, 3).autorestart, S(:a, :b, :c, :d).autorestart)

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

      expect(s1.peek_next_value).to eq([1, :d])
      expect(s1.next_value).to eq([1, :d])

      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil

      s1.restart

      expect(s1.current_value).to eq nil
      expect(s1.peek_next_value).to eq([2, :a])
      expect(s1.next_value).to eq([2, :a])
      expect(s1.next_value).to eq([3, :b])
      expect(s1.current_value).to eq([3, :b])
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil

      s1.restart

      expect(s1.current_value).to eq nil
      expect(s1.peek_next_value).to eq([1, :c])
      expect(s1.next_value).to eq([1, :c])
      expect(s1.next_value).to eq([2, :d])
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq nil
    end

    it 'A(S(1,2,3).autorestart, S(:a, :b, :c, :d).autorestart).autorestart' do
      s1 = A(S(1, 2, 3).autorestart, S(:a, :b, :c, :d).autorestart).autorestart

      expect(s1.current_value).to eq nil

      expect(s1.next_value).to eq([1, :a])
      expect(s1.next_value).to eq([2, :b])
      expect(s1.peek_next_value).to eq([3, :c])
      expect(s1.peek_next_value).to eq([3, :c])
      expect(s1.next_value).to eq([3, :c])
      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil

      expect(s1.peek_next_value).to eq([1, :d])
      expect(s1.next_value).to eq([1, :d])

      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil

      expect(s1.current_value).to eq nil
      expect(s1.peek_next_value).to eq([2, :a])
      expect(s1.next_value).to eq([2, :a])
      expect(s1.next_value).to eq([3, :b])
      expect(s1.current_value).to eq([3, :b])
      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil

      expect(s1.current_value).to eq nil
      expect(s1.peek_next_value).to eq([1, :c])
      expect(s1.next_value).to eq([1, :c])
      expect(s1.next_value).to eq([2, :d])
      expect(s1.next_value).to eq nil
    end

    it 'AC(S(1,2),S(:a, :b, :c))' do
      s1 = AC(S(1, 2), S(:a, :b, :c))

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

    it 'AC(S(1,2), S(:a, :b, :c)).autorestart' do
      s1 = AC(S(1, 2), S(:a, :b, :c)).autorestart

      expect(s1.current_value).to eq nil

      expect(s1.next_value).to eq([1, :a])
      expect(s1.next_value).to eq([2, :b])
      expect(s1.next_value).to eq([1, :c])
      expect(s1.next_value).to eq([2, :a])
      expect(s1.next_value).to eq([1, :b])
      expect(s1.next_value).to eq([2, :c])
      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil

      expect(s1.current_value).to eq nil

      expect(s1.next_value).to eq([1, :a])
      expect(s1.next_value).to eq([2, :b])
      expect(s1.next_value).to eq([1, :c])
      expect(s1.next_value).to eq([2, :a])
      expect(s1.next_value).to eq([1, :b])
      expect(s1.next_value).to eq([2, :c])

      expect(s1.next_value).to eq nil
      expect(s1.next_value).to eq([1, :a])
    end

    it 'AC(S(1,2), S(:a, :b, :c)).autorestart(skip_nil: true)' do
      s1 = AC(S(1, 2), S(:a, :b, :c)).autorestart(skip_nil: true)

      expect(s1.current_value).to eq nil

      expect(s1.next_value).to eq([1, :a])
      expect(s1.next_value).to eq([2, :b])
      expect(s1.next_value).to eq([1, :c])
      expect(s1.next_value).to eq([2, :a])
      expect(s1.next_value).to eq([1, :b])
      expect(s1.next_value).to eq([2, :c])

      expect(s1.next_value).to eq([1, :a])
      expect(s1.next_value).to eq([2, :b])
      expect(s1.next_value).to eq([1, :c])
      expect(s1.next_value).to eq([2, :a])
      expect(s1.next_value).to eq([1, :b])
      expect(s1.next_value).to eq([2, :c])

      expect(s1.next_value).to eq([1, :a])
    end

    it 'SS(S(S(1, 2, 3), S(4, 5, 6), S(7, 8, 9)))' do
      s = SS(S(S(1, 2, 3), S(4, 5, 6), S(7, 8, 9)))

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


    it 'Complex E extraction' do
      perm = [1, 2, 3].permutation.to_a

      values = S(*perm)

      values_serie = E() { S(*values.next_value) }

      expect(values_serie.next_value.to_a).to eq perm[0]
      expect(values_serie.next_value.to_a).to eq perm[1]
      expect(values_serie.next_value.to_a).to eq perm[2]
    end

    it 'Complex SS extraction I' do
      perm = [1, 2, 3].permutation.to_a

      values = S(*perm)

      values_serie = E() { S(*values.next_value) }

      s = SS values_serie

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

    it 'Complex SS extraction II' do
      perm = [1, 2, 3].permutation.to_a

      values = S(*perm)

      values_serie = E() { S(*values.next_value) }

      s = SS values_serie

      expect(s.max_size(3).to_a).to eq perm[0]
      expect(s.max_size(3).to_a).to eq perm[1]
      expect(s.max_size(3).to_a).to eq perm[2]
    end

    it 'SIN(start_value: 1, steps: 27, amplitude: 10, center: 0)' do
      s1 = SIN(start_value: 1, steps: 27, amplitude: 10, center: 0)

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

    it 'SIN(start_value: 1, steps: 27, amplitude: 10, center: 0).autorestart' do
      s1 = SIN(start_value: 1, steps: 27, amplitude: 10, center: 0).autorestart

      c = 0
      while v = s1.next_value
        expect(v).to eq 1.0 if c == 0
        c += 1
      end
      expect(c).to eq 27

      c = 0
      while v = s1.next_value
        expect(v).to eq 1.0 if c == 0
        c += 1
      end
      expect(c).to eq 27
    end

    it 'SIN(start_value: 1, steps: 27, amplitude: 10, center: 0).autorestart(skip_nil: true)' do
      s1 = SIN(start_value: 1, steps: 27, amplitude: 10, center: 0).autorestart(skip_nil: true)

      c = 0
      while (v = s1.next_value) && c < 100
        expect(v).to eq 1.0 if c == 0
        expect(v).to eq 1.0 if c == 27
        c += 1
      end
      expect(c).to eq 100
    end

    it 'FIBO()' do
      s = FIBO()

      expect(s.infinite?).to eq true
      expect(s.deterministic?).to eq true

      expect(s.current_value).to eq nil
      expect(s.next_value).to eq 1
      expect(s.next_value).to eq 1
      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3
      expect(s.next_value).to eq 5
      expect(s.next_value).to eq 8
      expect(s.next_value).to eq 13
    end

    it 'FIBO().max_size(10)' do
      s = FIBO().max_size(10)

      expect(s.infinite?).to eq false
      expect(s.deterministic?).to eq true

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
      s = HARMO(error: 0.1).max_size(10)

      expect(s.infinite?).to eq false
      expect(s.deterministic?).to eq true

      expect(s.to_a).to eq [0, 12, 19, 24, 31, 36, 38, 43, 48, 49]
    end

    it 'HARMO().max_size(10)' do
      s = HARMO().max_size(10)

      expect(s.infinite?).to eq false
      expect(s.deterministic?).to eq true

      expect(s.to_a).to eq [0, 12, 19, 24, 28, 31, 34, 36, 38, 40]
    end
  end
end
