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

    it 'Neuma parsing with extended notation (2): sharps and flats' do
      result = Musa::Neumalang.parse(
          '[ 0.1 . 1./ 1#./ 2_./ ]').to_a(recursive: true)

      c = -1

      expect(result[0][:serie][c += 1]).to eq(kind: :neuma, neuma: ['0', '1'])
      expect(result[0][:serie][c += 1]).to eq(kind: :neuma, neuma: [])
      expect(result[0][:serie][c += 1]).to eq(kind: :neuma, neuma: ['1', '/'])
      expect(result[0][:serie][c += 1]).to eq(kind: :neuma, neuma: ['1#', '/'])
      expect(result[0][:serie][c += 1]).to eq(kind: :neuma, neuma: ['2_', '/'])
    end

    it 'Neuma parsing with extended notation (2): sharps and flats with differential decoder' do
      differential_decoder = Musa::Datasets::GDVd::NeumaDifferentialDecoder.new

      result = Musa::Neumalang.parse('0.1 . 1./ 1#./ 2_./', decode_with: differential_decoder).to_a(recursive: true)

      expect(result[0].base_duration).to eq 1/4r

      c = -1

      expect(result[c += 1]).to eq(abs_grade: 0, abs_duration: 1/4r)
      expect(result[c += 1]).to eq({})
      expect(result[c += 1]).to eq(abs_grade: 1, abs_duration: 1/8r)
      expect(result[c += 1]).to eq(abs_grade: 1, abs_sharps: 1, abs_duration: 1/8r)
      expect(result[c += 1]).to eq(abs_grade: 2, abs_sharps: -1, abs_duration: 1/8r)
    end

    it 'Neuma parsing with extended notation and differential decoder' do
      differential_decoder = Musa::Datasets::GDVd::NeumaDifferentialDecoder.new

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

    it 'Neuma parsing with extended notation: GDV decoding' do
      scale = Musa::Scales.et12[440.0].major[60]

      neumas = '0   1.2.ppp   2.tr   3.tr(100)  4.tr(100/1, 400/2)   5.tr("hola").st(1,2,3).xy(1,2,3)   6.tr(up) +1 +1.+o1.+2.+ff'

      decoder = Musa::Datasets::GDV::NeumaDecoder.new scale

      result = Musa::Neumalang.parse(neumas, decode_with: decoder).to_a(recursive: true)

      c = -1

      expect(result[c += 1]).to eq(grade: 0, octave: 0, duration: 1/4r, velocity: 1)
      expect(result[c += 1]).to eq(grade: 1, octave: 0, duration: 1/2r, velocity: -3)
      expect(result[c += 1]).to eq(grade: 2, octave: 0, duration: 1/2r, velocity: -3, tr: true)
      expect(result[c += 1]).to eq(grade: 3, octave: 0, duration: 1/2r, velocity: -3, tr: 100)
      expect(result[c += 1]).to eq(grade: 4, octave: 0, duration: 1/2r, velocity: -3, tr: [100, 200])
      expect(result[c += 1]).to eq(grade: 5, octave: 0, duration: 1/2r, velocity: -3, tr: "hola", st: [1,2,3], xy: [1, 2, 3])
      expect(result[c += 1]).to eq(grade: 6, octave: 0, duration: 1/2r, velocity: -3, tr: :up)
      expect(result[c += 1]).to eq(grade: 7, octave: 0, duration: 1/2r, velocity: -3)
      expect(result[c += 1]).to eq(grade: 8, octave: 1, duration: 1, velocity: -1)
    end

    it 'Neuma parsing with extended notation: GDV decoding, to PDV conversion, and back to GDVd' do
      scale = Musa::Scales.et12[440.0].major[60]

      neumas    = '0   1.2.ppp   2.tr   3.tr(100)  4.tr(100, 200)   5.tr("hola").st(1,2,3).xy(1,2,3)   6.tr(up) +1 +1.+o1.+2.+ff'

      neumas_ok = '0.1.mf +1.+1.-ffff +1.tr +1.tr(100) +1.tr(100, 200) +1.tr("hola").st(1, 2, 3).xy(1, 2, 3) +1.tr(up) +1 +8.+2.+ff'

      decoder = Musa::Datasets::GDV::NeumaDecoder.new scale

      result_gdv = Musa::Neumalang.parse(neumas, decode_with: decoder).to_a(recursive: true)

      result_pdv = result_gdv.collect { |gdv| gdv.to_pdv(scale) }

      result_gdv2 = result_pdv.collect { |pdv| pdv.to_gdv(scale) }

      previous = current = nil

      result_gdvd2 = result_gdv2.collect { |gdv| previous = current; current = gdv; gdv.to_gdvd(scale, previous: previous) }

      neumas2 = result_gdvd2.collect(&:to_neuma)

      expect(neumas2.join ' ').to eq neumas_ok

    end

    it 'Neuma parsing with staccato extended notation' do
      scale = Musa::Scales.et12[440.0].major[60]

      neumas    = '0.1.mf +1.st .st(1) .st(2) .st(3) .st(4)'

      decoder = Musa::Datasets::GDV::NeumaDecoder.new scale

      decorators = Musa::Neuma::Dataset::Decorators.new \
        Musa::Datasets::GDV::StaccatoDecorator.new(min_duration_factor: 1/6r)

      result_gdv = Musa::Neumalang.parse(neumas, decode_with: decoder).process_with { |gdv| decorators.process(gdv) }.to_a(recursive: true)

      c = -1

      expect(result_gdv[c += 1]).to eq(grade: 0, octave: 0, duration: 1/4r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 1, octave: 0, duration: 1/4r, velocity: 1, effective_duration: 1/8r)
      expect(result_gdv[c += 1]).to eq(grade: 1, octave: 0, duration: 1/4r, velocity: 1, effective_duration: 1/8r)
      expect(result_gdv[c += 1]).to eq(grade: 1, octave: 0, duration: 1/4r, velocity: 1, effective_duration: 1/16r)
      expect(result_gdv[c += 1]).to eq(grade: 1, octave: 0, duration: 1/4r, velocity: 1, effective_duration: 1/24r)
      expect(result_gdv[c += 1]).to eq(grade: 1, octave: 0, duration: 1/4r, velocity: 1, effective_duration: 1/24r)
    end

    it 'Neuma parsing with basic trill extended notation' do
      scale = Musa::Scales.et12[440.0].major[60]

      neumas    = '0.1.mf +1.tr'

      decoder = Musa::Datasets::GDV::NeumaDecoder.new scale

      decorators = Musa::Neuma::Dataset::Decorators.new \
        Musa::Datasets::GDV::StaccatoDecorator.new,
        Musa::Datasets::GDV::TrillDecorator.new(duration_factor: 1/6r),
        base_duration: 1/4r,
        tick_duration: 1/96r

        result_gdv = Musa::Neumalang.parse(neumas, decode_with: decoder).process_with { |gdv| decorators.process(gdv) }.to_a(recursive: true)

      c = -1

      expect(result_gdv[c += 1]).to eq(grade: 0, octave: 0, duration: 1/4r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 2, octave: 0, duration: 1/24r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 1, octave: 0, duration: 1/24r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 2, octave: 0, duration: 1/24r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 1, octave: 0, duration: 1/24r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 2, octave: 0, duration: 1/24r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 1, octave: 0, duration: 1/24r, velocity: 1)
    end

    it 'Neuma parsing with mordent extended notation' do
      scale = Musa::Scales.et12[440.0].major[60]

      neumas = '0.1.mf +1.mor +3.+1.mor(low)'

      decoder = Musa::Datasets::GDV::NeumaDecoder.new scale

      decorators = Musa::Neuma::Dataset::Decorators.new \
        Musa::Datasets::GDV::StaccatoDecorator.new,
        Musa::Datasets::GDV::TrillDecorator.new,
        Musa::Datasets::GDV::MordentDecorator.new(duration_factor: 1/6r),
        base_duration: 1/4r,
        tick_duration: 1/96r

      result_gdv = Musa::Neumalang.parse(neumas, decode_with: decoder).process_with { |gdv| decorators.process(gdv) }.to_a(recursive: true)

      c = -1

      expect(result_gdv[c += 1]).to eq(grade: 0, octave: 0, duration: 1/4r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 1, octave: 0, duration: 1/24r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 2, octave: 0, duration: 1/24r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 1, octave: 0, duration: 4/24r, velocity: 1)

      expect(result_gdv[c += 1]).to eq(grade: 4, octave: 0, duration: 1/24r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 3, octave: 0, duration: 1/24r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 4, octave: 0, duration: 10/24r, velocity: 1)
    end

    it 'Modifiers extended neuma parsing with sequencer play' do
      debug = false
      #debug = true

      scale = Musa::Scales.et12[440.0].major[60]

      neumas = '0.1.mf +1.mor +3.+1.mor(low) -2'

      decorators = Musa::Neuma::Dataset::Decorators.new \
        Musa::Datasets::GDV::StaccatoDecorator.new,
        Musa::Datasets::GDV::TrillDecorator.new,
        Musa::Datasets::GDV::MordentDecorator.new(duration_factor: 1/8r),
        base_duration: 1/4r,
        tick_duration: 1/96r

      gdv_decoder = Musa::Datasets::GDV::NeumaDecoder.new scale, processor: decorators, base_duration: 1/4r

      serie = Musa::Neumalang.parse(neumas)

      if debug
        puts
        puts 'SERIE'
        puts '-----'
        pp serie.to_a(recursive: true)
        puts
      end

      played = {} if debug
      played = [] unless debug

      sequencer = Musa::Sequencer.new 4, 24 do
        at 1 do
          handler = play serie, decoder: gdv_decoder, mode: :neumalang do |gdv|
            if debug
              played[position] ||= []
              played[position] << gdv
            else
              played << { position: position }
              played << gdv
            end
          end

          handler.on :event do
            if debug
              played[position] ||= []
              played[position] << [:event]
            else
              played << { position: position }
              played << [:event]
            end
          end
        end
      end

      sequencer.tick until sequencer.empty?

      if debug
        puts
        puts 'PLAYED'
        puts '------'
        pp played
      end

      unless debug
        expect(played).to eq(
        [{ position: 1 },
         { grade: 0, octave: 0, duration: 1/4r, velocity: 1 },
         { position: 1+1/4r },
         { grade: 1, octave: 0, duration: 1/32r, velocity: 1 },
         { position: 1+9/32r },
         { grade: 2, octave: 0, duration: 1/32r, velocity: 1 },
         { position: 1+5/16r },
         { grade: 1, octave: 0, duration: 3/16r, velocity: 1 },
         { position: 1+1/2r },
         { grade: 4, octave: 0, duration: 1/32r, velocity: 1 },
         { position: 1+17/32r },
         { grade: 3, octave: 0, duration: 1/32r, velocity: 1 },
         { position: 1+9/16r },
         { grade: 4, octave: 0, duration: 14/32r, velocity: 1 },
         { position: 2 },
         { grade: 2, octave: 0, duration: 1/2r, velocity: 1 }])
      end
    end

    it 'Neuma parsing with apoggiatura extended notation' do
      scale = Musa::Scales.et12[440.0].major[60]

      neumas = '0.1.mf +1 (+2.//)+3 0'

      result = Musa::Neumalang.parse(neumas).to_a(recursive: true)

      decoder = Musa::Datasets::GDV::NeumaDecoder.new scale

      decorators = Musa::Neuma::Dataset::Decorators.new \
        Musa::Datasets::GDV::StaccatoDecorator.new,
        Musa::Datasets::GDV::TrillDecorator.new,
        Musa::Datasets::GDV::MordentDecorator.new,
        appogiatura_decorator: Musa::Datasets::GDV::AppogiaturaDecorator.new,
        base_duration: 1/4r,
        tick_duration: 1/96r

      result_gdv = Musa::Neumalang.parse(neumas, decode_with: decoder).process_with { |gdv| decorators.process(gdv) }.to_a(recursive: true)

      c = -1

      expect(result_gdv[c += 1]).to eq(grade: 0, octave: 0, duration: 1/4r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 1, octave: 0, duration: 1/4r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 3, octave: 0, duration: 1/16r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 4, octave: 0, duration: 3/16r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 0, octave: 0, duration: 1/4r, velocity: 1)
    end

    it 'Appogiatura extended neuma parsing with sequencer play' do
      debug = false
      #debug = true

      scale = Musa::Scales.et12[440.0].major[60]

      neumas = '0.1.mf +1 (+2.//)+3 0 +1'

      decorators = Musa::Neuma::Dataset::Decorators.new \
        Musa::Datasets::GDV::StaccatoDecorator.new,
        Musa::Datasets::GDV::TrillDecorator.new,
        Musa::Datasets::GDV::MordentDecorator.new,
        appogiatura_decorator: Musa::Datasets::GDV::AppogiaturaDecorator.new,
        base_duration: 1/4r,
        tick_duration: 1/96r

      gdv_decoder = Musa::Datasets::GDV::NeumaDecoder.new scale, processor: decorators, base_duration: 1/4r

      serie = Musa::Neumalang.parse(neumas)

      if debug
        puts
        puts 'SERIE'
        puts '-----'
        pp serie.to_a(recursive: true)
        puts
      end

      played = {} if debug
      played = [] unless debug

      sequencer = Musa::Sequencer.new 4, 24 do
        at 1 do
          handler = play serie, decoder: gdv_decoder, mode: :neumalang do |gdv|
            if debug
              played[position] ||= []
              played[position] << gdv
            else
              played << { position: position }
              played << gdv
            end
          end

          handler.on :event do
            if debug
              played[position] ||= []
              played[position] << [:event]
            else
              played << { position: position }
              played << [:event]
            end
          end
        end
      end

      sequencer.tick until sequencer.empty?

      if debug
        puts
        puts 'PLAYED'
        puts '------'
        pp played
      end

      unless debug
        expect(played).to eq(
                              [{ position: 1 },
                               { grade: 0, octave: 0, duration: 1/4r, velocity: 1 },
                               { position: 1+1/4r },
                               { grade: 1, octave: 0, duration: 1/4r, velocity: 1 },
                               { position: 1+1/2r },
                               { grade: 3, octave: 0, duration: 1/16r, velocity: 1 },
                               { position: 1+9/16r },
                               { grade: 4, octave: 0, duration: 3/16r, velocity: 1 },
                               { position: 1+3/4r },
                               { grade: 0, octave: 0, duration: 1/4r, velocity: 1 },
                               { position: 2 },
                               { grade: 1, octave: 0, duration: 1/4r, velocity: 1 }])
      end
    end

  end
end
