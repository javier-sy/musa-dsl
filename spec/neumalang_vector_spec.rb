require 'spec_helper'

require 'musa-dsl'

include Musa::Neumalang
include Musa::Datasets
include Musa::Neumas

RSpec.describe Musa::Neumalang do
  context 'Neuma packed vectors parsing' do
    it 'Basic packed vector' do

      result = '(a: 1 b: 2 c: 3)'.to_neumas.to_a(recursive: true)

      expect(result[0]).to eq({kind: :packed_v, packed_v: { a: 1, b: 2, c: 3 }})

      expect(result[0][:packed_v]).not_to be_a V
      expect(result[0][:packed_v]).to be_a PackedV
      expect(result[0][:packed_v]).to be_a AbsI
      expect(result[0][:packed_v]).to be_a Abs
      expect(result[0][:packed_v]).to be_a E
      expect(result[0][:packed_v]).to be_a Dataset
    end

    it 'More than one basic packed vector' do

      result = '(a: 1 b: 2 c: 3) (a: 10 b: 20 c: 30)'.to_neumas.to_a(recursive: true)

      expect(result[0]).to eq({kind: :packed_v, packed_v: { a: 1, b: 2, c: 3 }})
      expect(result[1]).to eq({kind: :packed_v, packed_v: { a: 10, b: 20, c: 30 }})
    end
  end

  context 'Neuma unpacked vectors parsing' do
    it 'Basic unpacked vector' do

      result = '(1 2 3)'.to_neumas.to_a(recursive: true)

      expect(result[0]).to eq({kind: :v, v: [1, 2, 3]})

      expect(result[0][:v]).to be_a V
      expect(result[0][:v]).not_to be_a PackedV
      expect(result[0][:v]).not_to be_a AbsI
      expect(result[0][:v]).not_to be_a Abs
      expect(result[0][:v]).not_to be_a E
      expect(result[0][:v]).to be_a Dataset
    end

    it 'More than one basic unpacked vector' do

      result = '(1 2 3) (10 20 30)'.to_neumas.to_a(recursive: true)

      expect(result[0]).to eq({kind: :v, v: [1, 2, 3]})
      expect(result[1]).to eq({kind: :v, v: [10, 20, 30]})
    end
  end
end
