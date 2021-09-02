require 'spec_helper'
require 'musa-dsl'

RSpec.describe Musa::Series do
  context 'Series autorestart' do

    include Musa::Series

    it 'Autorestart: S(1, 2, 3).autorestart' do
      s1 = S(1, 2, 3).autorestart.i

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

    it 'Autorestart: S(1, 2, 3).repeat' do
      s1 = S(1, 2, 3).repeat.i

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

    it 'H(x: S(1,2,3), y: S(:a, :b, :c, :d)).autorestart' do
      s1 = H(x: S(1, 2, 3), y: S(:a, :b, :c, :d)).autorestart.i

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

    it 'H(x: S(1,2), y: S(:a, :b, :c)).repeat' do
      s1 = H(x: S(1, 2), y: S(:a, :b, :c)).repeat.i

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
      s1 = H(x: S(1, 2, 3).autorestart, y: S(:a, :b, :c, :d).autorestart).i

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
      s1 = H(x: S(1, 2, 3).autorestart, y: S(:a, :b, :c, :d).autorestart).autorestart.i

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

    it 'HC(x: S(1,2), y: S(:a, :b, :c)).autorestart' do
      s1 = HC(x: S(1, 2), y: S(:a, :b, :c)).autorestart.i

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

    it 'HC(x: S(1,2), y: S(:a, :b, :c)).repeat' do
      s1 = HC(x: S(1, 2), y: S(:a, :b, :c)).repeat.i

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

    it 'A(S(1,2,3), S(:a, :b, :c, :d)).autorestart' do
      s1 = A(S(1, 2, 3), S(:a, :b, :c, :d)).autorestart.i

      expect(s1.current_value).to eq nil

      expect(s1.next_value).to eq([1, :a])
      expect(s1.next_value).to eq([2, :b])
      expect(s1.peek_next_value).to eq([3, :c])
      expect(s1.peek_next_value).to eq([3, :c])
      expect(s1.next_value).to eq([3, :c])
      expect(s1.peek_next_value).to eq nil
      expect(s1.next_value).to eq nil

      expect(s1.next_value).to eq([1, :a])
      expect(s1.next_value).to eq([2, :b])
      expect(s1.next_value).to eq([3, :c])
      expect(s1.next_value).to eq nil

      expect(s1.next_value).to eq([1, :a])
      expect(s1.next_value).to eq([2, :b])
      expect(s1.next_value).to eq([3, :c])
      expect(s1.next_value).to eq nil
    end

    it 'A(S(1,2,3).autorestart, S(:a, :b, :c, :d).autorestart)' do
      s1 = A(S(1, 2, 3).autorestart, S(:a, :b, :c, :d).autorestart).i

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

      s1.restart

      expect(s1.next_value).to eq([1, :a])
      expect(s1.next_value).to eq([2, :b])
      expect(s1.next_value).to eq([3, :c])
      expect(s1.next_value).to eq nil
    end

    it 'AC(S(1,2), S(:a, :b, :c)).autorestart' do
      s1 = AC(S(1, 2), S(:a, :b, :c)).autorestart.i

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

    it 'AC(S(1,2), S(:a, :b, :c)).repeat' do
      s1 = AC(S(1, 2), S(:a, :b, :c)).repeat.i

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

    it 'SIN(start_value: 1, steps: 27, amplitude: 10, center: 0).autorestart' do
      s1 = SIN(start_value: 1, steps: 27, amplitude: 10, center: 0).autorestart.i

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

    it 'SIN(start_value: 1, steps: 27, amplitude: 10, center: 0).repeat' do
      s1 = SIN(start_value: 1, steps: 27, amplitude: 10, center: 0).repeat.i

      c = 0
      while (v = s1.next_value) && c < 100
        expect(v).to eq 1.0 if c == 0
        expect(v).to eq 1.0 if c == 27
        c += 1
      end
      expect(c).to eq 100
    end
  end
end
