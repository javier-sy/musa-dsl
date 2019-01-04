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
      expect(result[0][:serie][c += 1]).to eq(kind: :neuma, neuma: ['+1', '+·', { modifier: :tr }])
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

    it 'Neuma parsing with extended notation with GDV decoding' do
      scale = Musa::Scales.et12[440.0].major[60]

      neumas = '0   1.2.ppp   2.tr   3.tr(100)  4.tr(100, 200)   5.tr("hola").st(1,2,3).xy(1,2,3)   6.tr(up) +1 +1.+o1.+2.+ff'

      decoder = Musa::Datasets::GDV::NeumaDecoder.new scale

      result = Musa::Neumalang.parse(neumas, decode_with: decoder).to_a(recursive: true)

      c = -1

      expect(result[c += 1]).to eq(grade: 0, octave: 0, duration: 1/4r, velocity: 1)
      expect(result[c += 1]).to eq(grade: 1, octave: 0, duration: 1/2r, velocity: -3)
      expect(result[c += 1]).to eq(grade: 2, octave: 0, duration: 1/2r, velocity: -3, tr: true)
      expect(result[c += 1]).to eq(grade: 3, octave: 0, duration: 1/2r, velocity: -3, tr: [100])
      expect(result[c += 1]).to eq(grade: 4, octave: 0, duration: 1/2r, velocity: -3, tr: [100, 200])
      expect(result[c += 1]).to eq(grade: 5, octave: 0, duration: 1/2r, velocity: -3, tr: ["hola"], st: [1,2,3], xy: [1, 2, 3])
      expect(result[c += 1]).to eq(grade: 6, octave: 0, duration: 1/2r, velocity: -3, tr: [:up])
      expect(result[c += 1]).to eq(grade: 7, octave: 0, duration: 1/2r, velocity: -3)
      expect(result[c += 1]).to eq(grade: 8, octave: 1, duration: 1, velocity: -1)
    end

  end
end
