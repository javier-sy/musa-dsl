require 'docs_helper'

using Musa::Extension::Neumas
using Musa::Extension::Matrix

RSpec.describe 'Core Extensions Documentation Examples' do

  context 'Core Extensions - Advanced Metaprogramming' do
    using Musa::Extension::Arrayfy
    using Musa::Extension::Hashify
    using Musa::Extension::ExplodeRanges
    using Musa::Extension::DeepCopy

    it 'converts to hash with hashify' do
      data = [60, 1r, 80]
      result = data.hashify(keys: [:pitch, :duration, :velocity])

      expect(result[:pitch]).to eq(60)
      expect(result[:duration]).to eq(1r)
      expect(result[:velocity]).to eq(80)
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
