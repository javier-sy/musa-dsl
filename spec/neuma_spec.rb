require 'spec_helper'

require 'musa-dsl'

include Musa::Neumalang
include Musa::Series
include Musa::Scales
include Musa::Datasets
include Musa::Neumas

RSpec.describe Musa::Neumalang do
  context 'Neuma simple parsing' do

    it 'Basic neumas inline parsing (empty)' do
      expect(Neumalang.parse('').to_a(recursive: true)).to eq([])
      expect(Neumalang.parse(' ').to_a(recursive: true)).to eq([])
      expect(Neumalang.parse('  ').to_a(recursive: true)).to eq([])
      expect(Neumalang.parse('   ').to_a(recursive: true)).to eq([])
    end

    it 'Basic neumas inline parsing (only a comment)' do
      expect(Musa::Neumalang::Neumalang.parse('/* comentario 1 */').to_a(recursive: true)).to eq([])
    end

    it 'Basic neumas inline parsing (two comments)' do
      expect(Neumalang.parse('/* comentario 1 */ /* bla bla */').to_a(recursive: true)).to eq([])
    end

    it 'Basic neumas inline parsing (two comments with subcomments)' do
      expect(Neumalang.parse('/* comentario  /* otro comentario */ 1 */ /* bla bla */').to_a(recursive: true)).to eq([])
    end

    it 'Basic neumas inline parsing (1)' do
      expect(Neumalang.parse('2.3 5.6 /* comentario 1 */ ::evento').to_a(recursive: true)).to eq(
        [{ kind: :gdvd, gdvd: { abs_grade: 2, abs_duration: 3 } },
         { kind: :gdvd, gdvd: { abs_grade: 5, abs_duration: 6 } },
         { kind: :event, event: :evento }]
      )
    end

    it 'Basic neumas inline parsing (2)' do
      expect(Neumalang.parse('2.3 5.6 ::evento /* comentario 1 */').to_a(recursive: true)).to eq(
        [{ kind: :gdvd, gdvd: { abs_grade: 2, abs_duration: 3 } },
         { kind: :gdvd, gdvd: { abs_grade: 5, abs_duration: 6 } },
         { kind: :event, event: :evento }]
      )
    end

    it 'Basic neumas inline parsing with comment' do
      expect(Neumalang.parse("/* comentario (con parentesis) \n*/ 2.3").to_a(recursive: true)).to eq(
        [{ kind: :gdvd, gdvd: { abs_grade: 2, abs_duration: 3 } }])
    end

    it 'Basic neumas inline parsing only duration' do
      result = Neumalang.parse('0 .1/2').to_a(recursive: true)

      expect(result[0]).to eq(kind: :gdvd, gdvd: { abs_grade: 0 })
      expect(result[1]).to eq(kind: :gdvd, gdvd: { abs_duration: 1/2r } )
    end

    it 'Basic neumas inline parsing silence' do
      result = '0 silence.1/2'.to_neumas.to_a(recursive: true)

      expect(result[0]).to eq(kind: :gdvd, gdvd: { abs_grade: 0 })
      expect(result[1]).to eq(kind: :gdvd, gdvd: { abs_grade: :silence, abs_duration: 1/2r })
    end

    it 'Basic neumas inline event with parameters' do
      result = '::evento([100], 100)'.to_neumas.to_a(recursive: true)
      expect(result).to eq([{kind: :event,
                             event: :evento,
                             value_parameters:
                                 [{kind: :serie, serie: [{kind: :gdvd, gdvd: {abs_grade: 100}}]},
                                  {kind: :gdvd, gdvd: {abs_grade: 100}}]}])
    end

    it 'Basic neumas inline event with complex parameters' do
      result = '::event_with_value_and_key_parameters(1, [2 3 4], a: 5, b: 6)'.to_neumas.to_a(recursive: true)

      expect(result).to eq([{kind: :event,
                             event: :event_with_value_and_key_parameters,
                             value_parameters:
                                 [{ kind: :gdvd, gdvd: {abs_grade: 1}},
                                  { kind: :serie,
                                    serie:
                                       [{ kind: :gdvd, gdvd: {abs_grade: 2}},
                                        { kind: :gdvd, gdvd: {abs_grade: 3}},
                                        { kind: :gdvd, gdvd: {abs_grade: 4}}]}],
                             key_parameters:
                                 { a: { kind: :gdvd, gdvd: {abs_grade: 5}},
                                   b: { kind: :gdvd, gdvd: {abs_grade: 6}}}}])
    end

    it 'Basic neumas inline parsing with differential decoder' do

      differential_decoder = Decoders::NeumaDifferentialDecoder.new(base_duration: 1)

      result = Neumalang.parse('0 . +1 2.p silence silence.1/3 2.1/2.p /*comentario 1*/', decode_with: differential_decoder).to_a(recursive: true)

      expect(result[0].base_duration).to eq 1

      expect(result[0]).to eq(abs_grade: 0)
      expect(result[1]).to eq({})
      expect(result[2]).to eq(delta_grade: 1)
      expect(result[3]).to eq(abs_grade: 2, abs_velocity: -1)
      expect(result[4]).to eq(abs_grade: :silence)
      expect(result[5]).to eq(abs_grade: :silence, abs_duration: Rational(1, 3))
      expect(result[6]).to eq(abs_grade: 2, abs_duration: Rational(1, 2), abs_velocity: -1)
    end

    it 'Basic neumas file parsing with GDV differential decoder' do
      differential_decoder = Decoders::NeumaDifferentialDecoder.new

      result = Neumalang.parse_file(File.join(File.dirname(__FILE__), 'neuma_spec.neu'), decode_with: differential_decoder).to_a(recursive: true)

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

      # expect(result[c+=1][:command].call).to eq(11110) # no se puede procesar como neumas simple

      expect(result[c += 1]).to eq(abs_grade: :silence)
      expect(result[c += 1]).to eq(abs_grade: 0)
      expect(result[c += 1]).to eq({})
      expect(result[c += 1]).to eq(delta_grade: 1)
      expect(result[c += 1]).to eq(delta_duration: Rational(1, 8))
      expect(result[c += 1]).to eq(factor_duration: Rational(1, 2))
      expect(result[c += 1]).to eq(abs_velocity: -1)
      expect(result[c += 1]).to eq(delta_velocity: 1)

      # expect(result[c+=1]).to eq({ event: :evento }) # no se puede procesar como neumas simple

      expect(result[c += 1]).to eq(abs_grade: :silence, factor_duration: Rational(1, 2))

      expect(result[c += 1]).to eq(delta_grade: 2)

      expect(result[c += 1]).to eq(delta_grade: -1)
      expect(result[c += 1]).to eq(abs_grade: :II)
    end

    it 'Basic neumas file parsing with GDV decoder' do
      scale = Scales.default_system.default_tuning.major[60]

      decoder = Decoders::NeumaDecoder.new scale, base: { grade: 0, duration: 1, velocity: 1 }

      result = Neumalang.parse_file(File.join(File.dirname(__FILE__), 'neuma_spec.neu'), decode_with: decoder).to_a(recursive: true)

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

      # expect(result[c+=1][:command].call).to eq(11110) # no se puede procesar como neumas simple

      expect(result[c += 1]).to eq(grade: 2, duration: 1/2r, velocity: 3, silence: true)

      expect(result[c += 1]).to eq(grade: 0, duration: 1/2r, velocity: 3)
      expect(result[c += 1]).to eq(grade: 0, duration: 1/2r, velocity: 3)
      expect(result[c += 1]).to eq(grade: 1, duration: 1/2r, velocity: 3)
      expect(result[c += 1]).to eq(grade: 1, duration: 1, velocity: 3)
      expect(result[c += 1]).to eq(grade: 1, duration: 1/2r, velocity: 3)
      expect(result[c += 1]).to eq(grade: 1, duration: 1/2r, velocity: -1)
      expect(result[c += 1]).to eq(grade: 1, duration: 1/2r, velocity: 0)

      # expect(result[c+=1]).to eq({ duration: 0, event: :evento }) # no se puede procesar como neumas simple

      expect(result[c += 1]).to eq(grade: 1, duration: 1/4r, velocity: 0, silence: true)

      expect(result[c += 1]).to eq(grade: 3, duration: 1/4r, velocity: 0)

      expect(result[c += 1]).to eq(grade: 2, duration: 1/4r, velocity: 0)

      expect(result[c += 1]).to eq(grade: 1, duration: 1/4r, velocity: 0)
    end

    it 'Array of strings to neumas conversion' do
      neumas = ['1.2.f a.2.f', '2.3.z x.4.z.y'].n.to_a

      c = -1

      expect(neumas[c += 1]).to eq(kind: :gdvd, gdvd: { abs_grade: 1, abs_duration: 2, abs_velocity: 2 } )
      expect(neumas[c += 1]).to eq(kind: :gdvd, gdvd: { abs_grade: :a, abs_duration: 2, abs_velocity: 2 } )
      expect(neumas[c += 1]).to eq(kind: :gdvd, gdvd: { abs_grade: 2, abs_duration: 3, modifiers: { z: true } } )
      expect(neumas[c += 1]).to eq(kind: :gdvd, gdvd: { abs_grade: :x, abs_duration: 4, modifiers: { z: true, y: true } } )
    end

    it 'Array of neumas to neumas serie conversion' do
      neumas = ['1.2.f a.2.f'.n, '2.3.z x.4.z.y'.n].n.to_a

      c = -1

      expect(neumas[c += 1]).to eq(kind: :gdvd, gdvd: { abs_grade: 1, abs_duration: 2, abs_velocity: 2 } )
      expect(neumas[c += 1]).to eq(kind: :gdvd, gdvd: { abs_grade: :a, abs_duration: 2, abs_velocity: 2 } )
      expect(neumas[c += 1]).to eq(kind: :gdvd, gdvd: { abs_grade: 2, abs_duration: 3, modifiers: { z: true } } )
      expect(neumas[c += 1]).to eq(kind: :gdvd, gdvd: { abs_grade: :x, abs_duration: 4, modifiers: { z: true, y: true } } )
    end

    it 'Neumas strings parallelized via Ruby |' do
      neumas = '1.2.f a.2.c' | '2.3.f x.2.z' | '3.4.f a.1.c'

      expect(neumas).to be_a(Neuma)
      expect(neumas).to be_a(Neuma::Parallel)

      expect(neumas[:parallel].length).to eq 3
    end

    it '2 neumas strings parallelized via internal neumalang parallelization are equal to Ruby parallelization' do
      neumas_a = ['1.2.f a.4.c' | '2.3.ff x.2.z'].n
      neumas_b = '[1.2.f a.4.c | 2.3.ff x.2.z]'.n

      expect(neumas_a.to_a(recursive: true)).to eq(neumas_b.to_a(recursive: true))
    end

    it '3 neumas strings parallelized via internal neumalang parallelization are equal to Ruby parallelization' do
      neumas_a = ['1.2.f a.4.c' | '2.3.p x.//.z' | '3.4.f a.2.c'].n
      neumas_b = '[ 1.2.f a.4.c | 2.3.p x.//.z | 3.4.f a.2.c ]'.n

      expect(neumas_a.to_a(recursive: true)).to eq(neumas_b.to_a(recursive: true))
    end

  end
end
