require 'spec_helper'

require 'musa-dsl'

include Musa::Series

RSpec.describe Musa::Neumalang do
  context 'Neuma simple parsing' do
    it 'Basic neuma inline parsing (only a comment)' do
      expect(Musa::Neumalang.parse('/* comentario 1 */').to_a(recursive: true)).to eq([])
    end

    it 'Basic neuma inline parsing (two comments)' do
      expect(Musa::Neumalang.parse('/* comentario 1 */ /* bla bla */').to_a(recursive: true)).to eq([])
    end

    it 'Basic neuma inline parsing (two comments with subcomments)' do
      expect(Musa::Neumalang.parse('/* comentario  /* otro comentario */ 1 */ /* bla bla */').to_a(recursive: true)).to eq([])
    end

    it 'Basic neuma inline parsing (1)' do
      expect(Musa::Neumalang.parse('2.3.4 5.6.7 /* comentario 1 */ ::evento').to_a(recursive: true)).to eq(
        [{ kind: :neuma, neuma: %w[2 3 4] }, { kind: :neuma, neuma: %w[5 6 7] }, { kind: :event, event: :evento }]
      )
    end

    it 'Basic neuma inline parsing (2)' do
      expect(Musa::Neumalang.parse('2.3.4 5.6.7 ::evento /* comentario 1 */').to_a(recursive: true)).to eq(
        [{ kind: :neuma, neuma: %w[2 3 4] }, { kind: :neuma, neuma: %w[5 6 7] }, { kind: :event, event: :evento }]
      )
    end

    it 'Basic neuma inline parsing with octaves' do
      expect(Musa::Neumalang.parse('2.o-1.3.4 5.o2.6.7 ::evento').to_a(recursive: true)).to eq(
        [{ kind: :neuma, neuma: ['2', 'o-1', '3', '4'] }, { kind: :neuma, neuma: %w[5 o2 6 7] }, { kind: :event, event: :evento }]
      )
    end

    it 'Basic neuma inline parsing with comment' do
      expect(Musa::Neumalang.parse("/* comentario (con parentesis) \n*/ 2.3.4").to_a(recursive: true)).to eq([{ kind: :neuma, neuma: %w[2 3 4] }])
    end

    it 'Basic neuma inline parsing only duration' do
      result = Musa::Neumalang.parse('0 .1/2').to_a(recursive: true)

      expect(result[0]).to eq(kind: :neuma, neuma: ['0'])
      expect(result[1]).to eq(kind: :neuma, neuma: [nil, '1/2'])
    end

    it 'Basic neuma inline parsing silence' do
      result = Musa::Neumalang.parse('0 silence.1/2').to_a(recursive: true)

      expect(result[0]).to eq(kind: :neuma, neuma: ['0'])
      expect(result[1]).to eq(kind: :neuma, neuma: ['silence', '1/2'])
    end

    it 'Basic neuma inline parsing with differential decoder' do

      differential_decoder = Musa::Datasets::GDV::NeumaDifferentialDecoder.new(base_duration: 1)

      result = Musa::Neumalang.parse('0 . +1 2.p silence silence.1/3 2.1/2.p /*comentario 1*/', decode_with: differential_decoder).to_a(recursive: true)

      expect(result[0].base_duration).to eq 1

      expect(result[0]).to eq(abs_grade: 0)
      expect(result[1]).to eq({})
      expect(result[2]).to eq(delta_grade: 1)
      expect(result[3]).to eq(abs_grade: 2, abs_velocity: -1)
      expect(result[4]).to eq(abs_grade: :silence)
      expect(result[5]).to eq(abs_grade: :silence, abs_duration: Rational(1, 3))
      expect(result[6]).to eq(abs_grade: 2, abs_duration: Rational(1, 2), abs_velocity: -1)
    end

    it 'Basic neuma file parsing with GDV differential decoder' do
      differential_decoder = Musa::Datasets::GDV::NeumaDifferentialDecoder.new

      result = Musa::Neumalang.parse_file(File.join(File.dirname(__FILE__), 'neuma_spec.neu'), decode_with: differential_decoder).to_a(recursive: true)

      c = -1

      expect(result[0].base_duration).to eq 1/4r

      expect(result[c += 1]).to eq({})
      expect(result[c += 1]).to eq(abs_grade: :II)
      expect(result[c += 1]).to eq(abs_grade: :I, abs_duration: Rational(1, 2))
      expect(result[c += 1]).to eq(abs_grade: :I, abs_duration: Rational(1, 8))
      expect(result[c += 1]).to eq(abs_grade: :I, abs_velocity: -1)

      expect(result[c += 1]).to eq(abs_grade: 0)
      expect(result[c += 1]).to eq(abs_grade: 0, abs_duration: Rational(1, 4))
      expect(result[c += 1]).to eq(abs_grade: 0, abs_duration: Rational(1, 8))
      expect(result[c += 1]).to eq(abs_grade: 0, abs_velocity: 4)

      expect(result[c += 1]).to eq(abs_grade: 0)
      expect(result[c += 1]).to eq(abs_grade: 1)
      expect(result[c += 1]).to eq(abs_grade: 2, abs_velocity: -1)
      expect(result[c += 1]).to eq(abs_grade: 2, abs_duration: Rational(1, 8), abs_velocity: 3)

      # expect(result[c+=1][:command].call).to eq(11110) # no se puede procesar como neuma simple

      expect(result[c += 1]).to eq(abs_grade: :silence)
      expect(result[c += 1]).to eq(abs_grade: 0)
      expect(result[c += 1]).to eq({})
      expect(result[c += 1]).to eq(delta_grade: 1)
      expect(result[c += 1]).to eq(delta_duration: Rational(1, 8))
      expect(result[c += 1]).to eq(factor_duration: Rational(1, 2))
      expect(result[c += 1]).to eq(abs_velocity: -1)
      expect(result[c += 1]).to eq(delta_velocity: 1)

      # expect(result[c+=1]).to eq({ event: :evento }) # no se puede procesar como neuma simple

      expect(result[c += 1]).to eq(abs_grade: :silence, factor_duration: Rational(1, 2))

      expect(result[c += 1]).to eq(delta_grade: -1)
      expect(result[c += 1]).to eq(abs_grade: :II)
    end

    it 'Basic neuma file parsing with GDV decoder' do
      scale = Musa::Scales.default_system.default_tuning.major[60]

      decoder = Musa::Datasets::GDV::NeumaDecoder.new scale, base_duration: 1, grade: 0, duration: 1, velocity: 1

      result = Musa::Neumalang.parse_file(File.join(File.dirname(__FILE__), 'neuma_spec.neu'), decode_with: decoder).to_a(recursive: true)

      c = -1

      expect(result[0].base_duration).to eq 1

      expect(result[c += 1]).to eq(grade: 0, duration: 1, velocity: 1)
      expect(result[c += 1]).to eq(grade: 1, duration: 1, velocity: 1)
      expect(result[c += 1]).to eq(grade: 0, duration: 2, velocity: 1)
      expect(result[c += 1]).to eq(grade: 0, duration: 1/2r, velocity: 1)
      expect(result[c += 1]).to eq(grade: 0, duration: 1/2r, velocity: -1)

      expect(result[c += 1]).to eq(grade: 0, duration: 1/2r, velocity: -1)
      expect(result[c += 1]).to eq(grade: 0, duration: 1, velocity: -1)
      expect(result[c += 1]).to eq(grade: 0, duration: 1/2r, velocity: -1)
      expect(result[c += 1]).to eq(grade: 0, duration: 1/2r, velocity: 4)

      expect(result[c += 1]).to eq(grade: 0, duration: 1/2r, velocity: 4)
      expect(result[c += 1]).to eq(grade: 1, duration: 1/2r, velocity: 4)
      expect(result[c += 1]).to eq(grade: 2, duration: 1/2r, velocity: -1)
      expect(result[c += 1]).to eq(grade: 2, duration: 1/2r, velocity: 3)

      # expect(result[c+=1][:command].call).to eq(11110) # no se puede procesar como neuma simple

      expect(result[c += 1]).to eq(grade: :silence, duration: 1/2r, velocity: 3)

      expect(result[c += 1]).to eq(grade: 0, duration: 1/2r, velocity: 3)
      expect(result[c += 1]).to eq(grade: 0, duration: 1/2r, velocity: 3)
      expect(result[c += 1]).to eq(grade: 1, duration: 1/2r, velocity: 3)
      expect(result[c += 1]).to eq(grade: 1, duration: 1, velocity: 3)
      expect(result[c += 1]).to eq(grade: 1, duration: 1/2r, velocity: 3)
      expect(result[c += 1]).to eq(grade: 1, duration: 1/2r, velocity: -1)
      expect(result[c += 1]).to eq(grade: 1, duration: 1/2r, velocity: 0)

      # expect(result[c+=1]).to eq({ duration: 0, event: :evento }) # no se puede procesar como neuma simple

      expect(result[c += 1]).to eq(grade: :silence, duration: 1/4r, velocity: 0)

      expect(result[c += 1]).to eq(grade: :silence, duration: 1/4r, velocity: 0)

      expect(result[c += 1]).to eq(grade: 1, duration: 1/4r, velocity: 0)
    end

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
