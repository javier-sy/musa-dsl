require 'spec_helper'
require 'musa-dsl'

using Musa::Extension::Neumas

RSpec.describe Musa::Neumalang do
  context 'Neuma process parsing' do

    it 'Basic process of packed vectors' do
      s = <<~string
        (a: 1 b: 2 c: 3) |4| (a: 3 b: 5 c: 7) | 8 | (a: 1 b: 2 c: 0)
      string

      a = s.to_neumas.to_a(recursive: true)

      expect(a).to eq([{ kind: :p, p: [{ a: 1, b: 2, c: 3 }, 4, { a: 3, b: 5, c: 7 }, 8, { a: 1, b: 2, c: 0 }]}])

      expect(a[0]).to be_a Musa::Neumas::Neuma

      expect(a[0][:p][0]).to be_a Musa::Datasets::PackedV
      expect(a[0][:p][1]).to be_a Numeric
      expect(a[0][:p][2]).to be_a Musa::Datasets::PackedV
    end

    it 'Basic process of vectors' do
      s = <<~string
        (1 2 3)| 4 |(3 5 7) |8| (1 2 0)
      string

      a = s.to_neumas.to_a(recursive: true)

      expect(a).to eq([{ kind: :p, p: [[ 1, 2, 3 ], 4, [ 3, 5, 7 ], 8, [ 1, 2, 0 ]]}])

      expect(a[0]).to be_a Musa::Neumas::Neuma

      expect(a[0][:p][0]).to be_a Musa::Datasets::V
      expect(a[0][:p][1]).to be_a Numeric
      expect(a[0][:p][2]).to be_a Musa::Datasets::V
    end

    it 'process to process steps' do
      s = <<~string
        (a: 1 b: 2 c: 3) |2| (a: 3 b: 5 c: 7) | 3 | (a: 1 b: 2 c: 0)
      string

      serie = s.to_neumas

      p = serie.i.next_value

      pp = p[:p].to_ps_serie.i

      expect(pp.next_value).to eq({from: {a: 1, b: 2, c: 3}, to: {a: 3, b: 5, c: 7}, duration: 1/2r, right_open: true})
      expect(pp.next_value).to eq({from: {a: 3, b: 5, c: 7}, to: {a: 1, b: 2, c: 0}, duration: 3/4r, right_open: false})

      expect(pp.next_value).to be_nil
      expect(pp.next_value).to be_nil
    end

    it 'process to process step executed with sequencer' do
      s = <<~string
        (a: 1 b: 2 c: 3) |2| (a: 3 b: 5 c: 7) | 2 | (a: 1 b: 2 c: 0)
      string

      debug = false
      #debug = true

      scale = Musa::Scales::Scales.default_system.default_tuning.major[60]
      gdv_decoder = Musa::Neumas::Decoders::NeumaDecoder.new scale

      serie = s.to_neumas

      if debug
        puts
        puts 'SERIE'
        puts '-----'
        pp serie.duplicate.i.restart.to_a(recursive: true)
        puts
      end

      played = {} if debug
      played = [] unless debug
      ps_array = []

      context = Object.new
      context.instance_variable_set :@debug, debug

      sequencer = Musa::Sequencer::Sequencer.new 4, 4 do
        at 1 do
          play serie, mode: :neumalang, decoder: gdv_decoder, context: context do |thing|
            played[position] ||= [] if debug
            played[position] << thing if debug # .to_pdv(scale)

            played << { position: position } unless debug
            played << thing unless debug

            ps_array << thing

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
        ps_array.each do |ps|
          expect(ps).to be_a(Musa::Datasets::PS)
          expect(ps[:from]).to be_a(Musa::Datasets::PackedV)
          expect(ps[:to]).to be_a(Musa::Datasets::PackedV)
        end

        expect(played).to eq [
          {:position=>1},
          {:from=>{ a: 1, b: 2, c: 3 }, :duration=>1/2r, :to=>{ a: 3, b: 5, c: 7 }, :right_open=>true},
          {:position=>3/2r},
          {:from=>{ a: 3, b: 5, c: 7 }, :duration=>1/2r, :to=>{ a: 1, b: 2, c: 0 }, :right_open=>false} ]
      end
    end

    it 'process and gdv in parallel' do
      s = <<~string
        [ (0 1 f) (+1) (+1) (+1) (+1) (0 p) ||
          (0 1/2 pp) (+1) (+1) (+1) (+1) (+1) (0 f) ||
          (a: 1 b: 2 c: 3) |3| (a: 3 b: 5 c: 7) | 8 | (a: 1 b: 2 c: 0) ]
      string

      debug = false
      #debug = true

      scale = Musa::Scales::Scales.default_system.default_tuning.major[60]
      gdv_decoder = Musa::Neumas::Decoders::NeumaDecoder.new scale
      serie = s.to_neumas

      if debug
        puts
        puts 'SERIE'
        puts '-----'
        pp serie.duplicate.i.restart.to_a(recursive: true)
        puts
      end

      played = {} if debug
      played = [] unless debug

      ps_array = []
      gdv_array = []

      context = Object.new
      context.instance_variable_set :@debug, debug

      last_position = nil
      sequencer = Musa::Sequencer::Sequencer.new 4, 4 do
        at 1 do
          play serie, decoder: gdv_decoder, mode: :neumalang, context: context do |thing|
            played[position] ||= [] if debug
            played[position] << thing if debug # .to_pdv(scale)

            played << { position: position } if position != last_position unless debug
            played << thing unless debug
            last_position = position

            ps_array << thing if thing.is_a?(Musa::Datasets::PS)
            gdv_array << thing if thing.is_a?(Musa::Datasets::GDV)
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
        expect(ps_array.size).to eq 2
        expect(gdv_array.size).to eq 13

        expect(played).to eq [
          {:position=>1},
            {:grade=>0, :octave=>0, :duration=>1/4r, :velocity=>2},
            {:grade=>0, :octave=>0, :duration=>1/8r, :velocity=>-2},
            {:from=>{ a: 1, b: 2, c: 3 }, :duration=>3/4r, :to=>{ a: 3, b: 5, c: 7 }, :right_open=>true},
          {:position=>1 + 1/8r},
            {:grade=>1, :octave=>0, :duration=>1/8r, :velocity=>-2},
          {:position=>1 + 1/4r},
            {:grade=>1, :octave=>0, :duration=>1/4r, :velocity=>2},
            {:grade=>2, :octave=>0, :duration=>1/8r, :velocity=>-2},
          {:position=>1 + 3/8r},
            {:grade=>3, :octave=>0, :duration=>1/8r, :velocity=>-2},
          {:position=>1 + 1/2r},
            {:grade=>2, :octave=>0, :duration=>1/4r, :velocity=>2},
            {:grade=>4, :octave=>0, :duration=>1/8r, :velocity=>-2},
          {:position=>1 + 5/8r},
            {:grade=>5, :octave=>0, :duration=>1/8r, :velocity=>-2},
          {:position=>1 + 3/4r},
            {:from=>{ a: 3, b: 5, c: 7 }, :duration=>2, :to=>{ a: 1, b: 2, c: 0 }, :right_open=>false},
            {:grade=>3, :octave=>0, :duration=>1/4r, :velocity=>2},
            {:grade=>0, :octave=>0, :duration=>1/8r, :velocity=>2},
          {:position=>2},
            {:grade=>4, :octave=>0, :duration=>1/4r, :velocity=>2},
          {:position=>2 + 1/4r},
            {:grade=>0, :octave=>0, :duration=>1/4r, :velocity=>-1} ]
      end
    end

    it 'process executed with move' do
      s = <<~string
        (a: 0 b: 1 c: 2) |16| (a: 4 b: 4 c: 4) | 16 | (a: 8 b: 9 c: 10)
      string

      scale = Musa::Scales::Scales.default_system.default_tuning.major[60]
      gdv_decoder = Musa::Neumas::Decoders::NeumaDecoder.new scale
      serie = s.to_neumas

      mapper = {a: 0, b: 0, c: 0}
      played = {}

      sequencer = Musa::Sequencer::Sequencer.new 4, 4 do
        at 1 do
          play serie, decoder: gdv_decoder, mode: :neumalang do |thing|
            move from: thing[:from].to_V(mapper),
                 to: thing[:to].to_V(mapper),
                 duration: thing[:duration],
                 right_open: thing[:right_open] do |v|

              played[position] = v
            end
          end
        end
      end

      sequencer.tick until sequencer.empty?

      expect(played[1r]).to eq([0, 1, 2])
      expect(played[5r]).to eq([4, 4, 4])
      expect(played[9 - 1/16r]).to eq([8, 9, 10])

      pre = nil
      checked = 0

      played.keys.each do |p|
        if pre
          expect(played[p][0]).to be > played[pre][0]
          expect(played[p][1]).to be > played[pre][1]
          expect(played[p][2]).to be > played[pre][2]

          checked += 1
        end
        pre = p
      end

      expect(checked).to eq 16 * 4 * 2 - 1
    end

  end

end
