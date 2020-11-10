require 'spec_helper'

require 'musa-dsl'

include Musa::Series

RSpec.describe Musa::Series do
  context 'Series holders' do
    it 'Basic HOLDER series substitution' do
      s = HOLDER()
      expect(s.next_value).to eq nil

      s << S(1, 2, 3)

      expect(s.next_value).to eq 1
      expect(s.current_value).to eq 1

      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3
      expect(s.next_value).to eq nil

      s.restart

      expect(s.next_value).to eq 1
      expect(s.next_value).to eq 2

      s.hold = S(5, 6, 7)

      expect(s.next_value).to eq 5
      expect(s.next_value).to eq 6
      expect(s.next_value).to eq 7

      expect(s.next_value).to eq nil
    end

    it 'Basic HOLDER series queuing' do
      s = HOLDER()

      expect(s.next_value).to eq nil

      s << S(1, 2, 3)
      s << S(4, 5, 6)
      s << S(7, 8, 9)

      expect(s.next_value).to eq 1
      expect(s.current_value).to eq 1

      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3
      expect(s.next_value).to eq nil

      s.restart

      expect(s.next_value).to eq 4
      expect(s.next_value).to eq 5
      expect(s.next_value).to eq 6
      expect(s.next_value).to eq nil

      s.restart

      expect(s.next_value).to eq 7
      expect(s.next_value).to eq 8
      expect(s.next_value).to eq 9

      expect(s.next_value).to eq nil

      s.restart

      expect(s.next_value).to eq 7
      expect(s.next_value).to eq 8
      expect(s.next_value).to eq 9

      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
    end

    it 'Basic HOLDER series queuing with restart and skip nil' do
      h = HOLDER()
      s = h.repeat

      expect(s.next_value).to eq nil

      h << S(1, 2, 3)
      h << S(4, 5, 6)
      h << S(7, 8, 9)

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

      expect(s.next_value).to eq 7
      expect(s.next_value).to eq 8
      expect(s.next_value).to eq 9

      expect(s.next_value).to eq 7
      expect(s.next_value).to eq 8
      expect(s.next_value).to eq 9
    end

    it 'HOLDER(S(1, 2, 3))' do
      s1 = HOLDER(S(1, 2, 3))

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

    it 'HOLDER(HC(x: S(1,2), y: S(:a, :b, :c), z: S(1, 2, 3, 4)))' do
      s1 = HOLDER(HC(x: S(1,2), y: S(:a, :b, :c), z: S(1, 2, 3, 4)))

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

    it 'HOLDER(HC(x: S(1,2), y: S(:a, :b, :c)).autorestart)' do
      s1 = HOLDER(HC(x: S(1, 2), y: S(:a, :b, :c)).autorestart)

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

    it 'HOLDER(HC(x: S(1,2), y: S(:a, :b, :c)).autorestart(skip_nil: true))' do
      s1 = HOLDER(HC(x: S(1, 2), y: S(:a, :b, :c)).repeat)

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
  end
end
