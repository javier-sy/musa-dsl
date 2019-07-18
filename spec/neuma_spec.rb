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
      expect(Musa::Neumalang.parse('2.o-1.3.4 5.o+2.6.7 ::evento').to_a(recursive: true)).to eq(
        [{ kind: :neuma, neuma: ['2', 'o-1', '3', '4'] }, { kind: :neuma, neuma: %w[5 o+2 6 7] }, { kind: :event, event: :evento }]
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
      result = '0 silence.1/2'.to_neumas.to_a(recursive: true)

      expect(result[0]).to eq(kind: :neuma, neuma: ['0'])
      expect(result[1]).to eq(kind: :neuma, neuma: ['silence', '1/2'])
    end

    it 'Basic neuma inline parsing with differential decoder' do

      differential_decoder = Musa::Datasets::GDVd::NeumaDifferentialDecoder.new(base_duration: 1)

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
      differential_decoder = Musa::Datasets::GDVd::NeumaDifferentialDecoder.new

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

      expect(result[c += 1]).to eq(delta_grade: 2)

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

      expect(result[c += 1]).to eq(grade: 2, duration: 1/2r, velocity: 3, silence: true)

      expect(result[c += 1]).to eq(grade: 0, duration: 1/2r, velocity: 3)
      expect(result[c += 1]).to eq(grade: 0, duration: 1/2r, velocity: 3)
      expect(result[c += 1]).to eq(grade: 1, duration: 1/2r, velocity: 3)
      expect(result[c += 1]).to eq(grade: 1, duration: 1, velocity: 3)
      expect(result[c += 1]).to eq(grade: 1, duration: 1/2r, velocity: 3)
      expect(result[c += 1]).to eq(grade: 1, duration: 1/2r, velocity: -1)
      expect(result[c += 1]).to eq(grade: 1, duration: 1/2r, velocity: 0)

      # expect(result[c+=1]).to eq({ duration: 0, event: :evento }) # no se puede procesar como neuma simple

      expect(result[c += 1]).to eq(grade: 1, duration: 1/4r, velocity: 0, silence: true)

      expect(result[c += 1]).to eq(grade: 3, duration: 1/4r, velocity: 0)

      expect(result[c += 1]).to eq(grade: 2, duration: 1/4r, velocity: 0)

      expect(result[c += 1]).to eq(grade: 1, duration: 1/4r, velocity: 0)
    end

    it 'Array of strings to neuma conversion' do
      neumas = ['1.2.3 a.b.c', '2.3.4 x.y.z'].n.to_a

      c = -1

      expect(neumas[c += 1]).to eq(kind: :neuma, neuma: ["1", "2", "3"])
      expect(neumas[c += 1]).to eq(kind: :neuma, neuma: ["a", { modifier: :b }, { modifier: :c }])
      expect(neumas[c += 1]).to eq(kind: :neuma, neuma: ["2", "3", "4"])
      expect(neumas[c += 1]).to eq(kind: :neuma, neuma: ["x", { modifier: :y }, { modifier: :z }])
    end

    it 'Array of neumas to neumas serie conversion' do
      neumas = ['1.2.3 a.b.c'.n, '2.3.4 x.y.z'.n].n.to_a

      c = -1

      expect(neumas[c += 1]).to eq(kind: :neuma, neuma: ["1", "2", "3"])
      expect(neumas[c += 1]).to eq(kind: :neuma, neuma: ["a", { modifier: :b }, { modifier: :c }])
      expect(neumas[c += 1]).to eq(kind: :neuma, neuma: ["2", "3", "4"])
      expect(neumas[c += 1]).to eq(kind: :neuma, neuma: ["x", { modifier: :y }, { modifier: :z }])
    end

    it 'Neumas strings parallelized via Ruby |' do
      neumas = '1.2.3 a.b.c' | '2.3.4 x.y.z' | '3.4.5 a.b.c'

      expect(neumas).to be_a(Musa::Neumalang::Neuma)
      expect(neumas).to be_a(Musa::Neumalang::Neuma::Parallel)

      expect(neumas[:parallel].length).to eq 3
    end

    it '2 neumas strings parallelized via internal neumalang parallelization are equal to Ruby parallelization' do
      neumas_a = ['1.2.3 a.b.c' | '2.3.4 x.y.z'].n
      neumas_b = '[1.2.3 a.b.c | 2.3.4 x.y.z]'.n

      expect(neumas_a.to_a(recursive: true)).to eq(neumas_b.to_a(recursive: true))
    end

    it '3 neumas strings parallelized via internal neumalang parallelization are equal to Ruby parallelization' do
      neumas_a = ['1.2.3 a.b.c' | '2.3.4 x.y.z' | '3.4.5 a.b.c'].n
      neumas_b = '[ 1.2.3 a.b.c | 2.3.4 x.y.z | 3.4.5 a.b.c ]'.n

      expect(neumas_a.to_a(recursive: true)).to eq(neumas_b.to_a(recursive: true))
    end
  end
end
