require 'spec_helper'

require 'musa-dsl'

RSpec.describe Array do
  context 'Array' do
    it 'Single object' do
      expect(1.arrayfy).to eq [1]
    end

    it 'nil object' do
      expect(nil.arrayfy).to eq []
    end

    it 'Single object repeated' do
      expect(1.arrayfy(size: 3)).to eq [1, 1, 1]
    end

    it 'nil object repeated' do
      expect(nil.arrayfy(size: 3)).to eq [nil, nil, nil]
    end

    it 'Array shorter than asked' do
      expect([1, 2, 3].arrayfy(size: 8)).to eq [1, 2, 3, 1, 2, 3, 1, 2]
    end

    it 'Array longer than asked' do
      expect([1, 2, 3, 4, 5].arrayfy(size: 3)).to eq [1, 2, 3]
    end

  end
end
