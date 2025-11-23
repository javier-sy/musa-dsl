require 'spec_helper'
require 'musa-dsl'

RSpec.describe 'Series shift operation' do
  include Musa::Series

  context 'Rotate left' do
    it 'rotates series left with shift(-1)' do
      s = S(1, 2, 3, 4, 5)
      shifted = s.shift(-1)
      result = shifted.i.to_a

      # Rotate left: first element moves to end
      expect(result).to eq([2, 3, 4, 5, 1])
    end

    it 'rotates series left with shift(-2)' do
      s = S(1, 2, 3, 4, 5)
      shifted = s.shift(-2)
      result = shifted.i.to_a

      # Rotate left by 2: first two elements move to end
      expect(result).to eq([3, 4, 5, 1, 2])
    end
  end

  context 'Rotate right' do
    it 'rotates series right with shift(1)' do
      s = S(1, 2, 3, 4, 5)
      shifted = s.shift(1)
      result = shifted.i.to_a

      # Rotate right: last element moves to beginning
      expect(result).to eq([5, 1, 2, 3, 4])
    end

    it 'rotates series right with shift(2)' do
      s = S(1, 2, 3, 4, 5)
      shifted = s.shift(2)
      result = shifted.i.to_a

      # Rotate right by 2: last two elements move to beginning
      expect(result).to eq([4, 5, 1, 2, 3])
    end
  end

  context 'No rotation' do
    it 'keeps series unchanged with shift(0)' do
      s = S(1, 2, 3, 4, 5)
      shifted = s.shift(0)
      result = shifted.i.to_a

      # No rotation
      expect(result).to eq([1, 2, 3, 4, 5])
    end
  end

  context 'Original series' do
    it 'verifies original series is not mutated' do
      s = S(1, 2, 3, 4, 5)
      s.shift(-1)

      # Original series should remain unchanged
      result = s.i.to_a
      expect(result).to eq([1, 2, 3, 4, 5])
    end
  end
end
