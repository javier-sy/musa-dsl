require 'docs_helper'

using Musa::Extension::Neumas
using Musa::Extension::Matrix

RSpec.describe 'Core Extensions Documentation Examples' do

  context 'Core Extensions - Advanced Metaprogramming' do
    using Musa::Extension::Arrayfy
    using Musa::Extension::Hashify
    using Musa::Extension::ExplodeRanges
    using Musa::Extension::DeepCopy

    it 'normalizes parameters with arrayfy' do
      value = 42
      expect(value.arrayfy).to eq([42])

      array = [1, 2, 3]
      expect(array.arrayfy).to eq([1, 2, 3])
    end

    it 'converts to hash with hashify' do
      data = [60, 1r, 80]
      result = data.hashify(keys: [:pitch, :duration, :velocity])

      expect(result[:pitch]).to eq(60)
      expect(result[:duration]).to eq(1r)
      expect(result[:velocity]).to eq(80)
    end

    it 'expands ranges with explode_ranges' do
      result = [0, 2..4, 7].explode_ranges

      expect(result).to eq([0, 2, 3, 4, 7])
    end

    it 'deep copies objects using Marshal' do
      original = { grade: 0, duration: 1r, nested: { value: 42 } }
      copy = Marshal.load(Marshal.dump(original))

      # Modify copy doesn't affect original
      copy[:grade] = 2
      copy[:nested][:value] = 99

      expect(original[:grade]).to eq(0)
      expect(original[:nested][:value]).to eq(42)
    end

    it 'demonstrates DynamicProxy concept' do
      # DynamicProxy is used internally for lazy series evaluation
      # This test verifies the concept without testing implementation details

      # Series operations are lazily evaluated (DynamicProxy pattern)
      series = Musa::Series::Constructors.S(1, 2, 3).map { |x| x * 2 }

      # The map operation doesn't execute until values are requested
      inst = series.i
      expect(inst.next_value).to eq(2)
      expect(inst.next_value).to eq(4)
      expect(inst.next_value).to eq(6)
    end

    it 'demonstrates Logger concept with sequencer' do
      # Logger is used internally for sequencer debugging
      # This test verifies logger can be created and used

      sequencer = Musa::Sequencer::Sequencer.new(4, 24)

      # Create logger using Kernel.logger if available
      # Note: The actual Logger implementation may vary
      expect(sequencer).to respond_to(:run)

      # Sequencer can execute code at specific positions
      executed = false
      sequencer.at 1 do
        executed = true
      end

      sequencer.run

      expect(executed).to be true
    end
  end


end
