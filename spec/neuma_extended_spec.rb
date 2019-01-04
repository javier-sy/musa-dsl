require 'spec_helper'

require 'musa-dsl'

include Musa::Series

RSpec.describe Musa::Neumalang do
  context 'Neuma extended parsing' do
    it 'Neuma parsing with extended notation' do
      result = Musa::Neumalang.parse(
          '[ 0 	.	+1.+·.tr 	+1./
                         1.// 	-2 		-1.2
                         0.1.o-1 	.+1 		-1.//
                         1./// -1 -1.*2 +1./2 -1 -1./// 	-1.2 ]').to_a(recursive: true)

      c = -1

      expect(result[0][:serie][c += 1]).to eq(kind: :neuma, neuma: ['0'])
      expect(result[0][:serie][c += 1]).to eq(kind: :neuma, neuma: [])
      expect(result[0][:serie][c += 1]).to eq(kind: :neuma, neuma: ['+1', '+·', 'tr'])
      expect(result[0][:serie][c += 1]).to eq(kind: :neuma, neuma: ['+1', '/'])

      expect(result[0][:serie][c += 1]).to eq(kind: :neuma, neuma: ['1', '//'])
      expect(result[0][:serie][c += 1]).to eq(kind: :neuma, neuma: ['-2'])
      expect(result[0][:serie][c += 1]).to eq(kind: :neuma, neuma: ['-1', '2'])

      expect(result[0][:serie][c += 1]).to eq(kind: :neuma, neuma: ['0', '1', 'o-1'])
      expect(result[0][:serie][c += 1]).to eq(kind: :neuma, neuma: [nil, '+1'])
      expect(result[0][:serie][c += 1]).to eq(kind: :neuma, neuma: ['-1', '//'])

      expect(result[0][:serie][c += 1]).to eq(kind: :neuma, neuma: ['1', '///'])
      expect(result[0][:serie][c += 1]).to eq(kind: :neuma, neuma: ['-1'])
      expect(result[0][:serie][c += 1]).to eq(kind: :neuma, neuma: ['-1', '*2'])
      expect(result[0][:serie][c += 1]).to eq(kind: :neuma, neuma: ['+1', '/2'])
      expect(result[0][:serie][c += 1]).to eq(kind: :neuma, neuma: ['-1'])
      expect(result[0][:serie][c += 1]).to eq(kind: :neuma, neuma: ['-1', '///'])
      expect(result[0][:serie][c += 1]).to eq(kind: :neuma, neuma: ['-1', '2'])
    end

    it 'Neuma parsing with extended notation and differential decoder' do
      differential_decoder = Musa::Datasets::GDV::NeumaDifferentialDecoder.new

      result = Musa::Neumalang.parse('0 . +1.1· 2.+/·.p silence silence./· 2./.p', decode_with: differential_decoder).to_a(recursive: true)

      expect(result[0].base_duration).to eq 1/4r

      expect(result[0]).to eq(abs_grade: 0)
      expect(result[1]).to eq({})
      expect(result[2]).to eq(delta_grade: 1, abs_duration: 1.5/4r)
      expect(result[3]).to eq(abs_grade: 2, delta_duration: 3/16r, abs_velocity: -1)
      expect(result[4]).to eq(abs_grade: :silence)
      expect(result[5]).to eq(abs_grade: :silence, abs_duration: 3/16r)
      expect(result[6]).to eq(abs_grade: 2, abs_duration: 1/8r, abs_velocity: -1)
    end

  end
end
