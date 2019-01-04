require 'spec_helper'

require 'pp'

require 'musa-dsl'

include Musa::Series

RSpec.describe Musa::Neumalang do
  context 'Neuma with neumalang advanced parsing' do
    scale = Musa::Scales.default_system.default_tuning.major[60]

    it 'Simple file neuma parsing' do
      debug = false
      # debug = true

      gdv_decoder = Musa::Datasets::GDV::NeumaDecoder.new scale, base_duration: 1
      serie = Musa::Neumalang.parse_file File.join(File.dirname(__FILE__), 'neuma3a_spec.neu')

      if debug
        puts
        puts 'SERIE'
        puts '-----'
        pp serie.to_a(true)
        puts
      end

      played = {} if debug
      played = [] unless debug

      sequencer = Musa::Sequencer.new 4, 4 do
        at 1 do
          handler = play serie, decoder: gdv_decoder, mode: :neumalang do |gdv|
            played[position] ||= [] if debug
            played[position] << gdv if debug # .to_pdv(scale)

            played << { position: position } unless debug
            played << gdv unless debug # .to_pdv(scale)
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
           { grade: 0, octave: 0, duration: 1, velocity: 1 },
           { position: 2 },
           { grade: 1, octave: 0, duration: 1, velocity: 1 },
           { position: 3 },
           { grade: 2, octave: 0, duration: 1, velocity: 1 },
           { position: 4 },
           { grade: 3, octave: 0, duration: 1, velocity: 1 },
           { position: 5 },
           { grade: 4, octave: 0, duration: 4, velocity: 1 },
           { position: 9 },
           { grade: 5, octave: 0, duration: 2, velocity: 1 },
           { position: 11 },
           { grade: 5, octave: 0, duration: 2, velocity: 1 },
           { position: 13 },
           { grade: 4, octave: 0, duration: 4, velocity: 1 },
           { position: 17 },
           { grade: 3, octave: 0, duration: 1, velocity: 1 },
           { position: 18 },
           { grade: 6, octave: 0, duration: 1, velocity: 1 },
           { position: 19 },
           { grade: 7, octave: 0, duration: 1, velocity: 1 },
           { position: 20 },
           { grade: 8, octave: 0, duration: 1, velocity: 1 }]
        )
      end
    end

    it 'Simple file neuma parsing with parallel series and call methods' do
      debug = false
      # debug = true

      gdv_decoder = Musa::Datasets::GDV::NeumaDecoder.new scale, base_duration: 1
      serie = Musa::Neumalang.parse_file File.join(File.dirname(__FILE__), 'neuma3b_spec.neu')

      if debug
        puts
        puts 'SERIE'
        puts '-----'
        pp serie.to_a(true)
        puts
      end

      played = {} if debug
      played = [] unless debug

      sequencer = Musa::Sequencer.new 4, 4 do
        at 1 do
          handler = play serie, decoder: gdv_decoder, mode: :neumalang do |gdv|
            played[position] ||= [] if debug
            played[position] << gdv if debug # .to_pdv(scale)

            played << { position: position } unless debug
            played << gdv unless debug # .to_pdv(scale)
          end

          handler.on :event do
            played[position] ||= [] if debug
            played[position] << [:event] if debug

            played << { position: position } unless debug
            played << [:event] unless debug
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
           { grade: 4, octave: 0, duration: 1, velocity: 1 },
           { position: 1 },
           { grade: 5, octave: 0, duration: 1, velocity: 1 },
           { position: 2 },
           { grade: 2, octave: 0, duration: 1, velocity: 1 },
           { position: 2 },
           { grade: 3, octave: 0, duration: 1, velocity: 1 },
           { position: 3 },
           { grade: 0, octave: 0, duration: 1, velocity: 1 },
           { position: 3 },
           { grade: 1, octave: 0, duration: 1, velocity: 1 }]
        )
      end
    end

    it 'Simple file neuma parsing with call_methods on simple serie' do
      debug = false
      # debug = true

      gdv_decoder = Musa::Datasets::GDV::NeumaDecoder.new scale, base_duration: 1
      serie = Musa::Neumalang.parse_file File.join(File.dirname(__FILE__), 'neuma3c_spec.neu')

      if debug
        puts
        puts 'SERIE'
        puts '-----'
        pp serie.to_a(true)
        puts
      end

      played = {} if debug
      played = [] unless debug

      sequencer = Musa::Sequencer.new 4, 4 do
        at 1 do
          handler = play serie, decoder: gdv_decoder, mode: :neumalang do |gdv|
            played[position] ||= [] if debug
            played[position] << gdv if debug # .to_pdv(scale)

            played << { position: position } unless debug
            played << gdv unless debug # .to_pdv(scale)
          end

          handler.on :event do
            played[position] ||= [] if debug
            played[position] << [:event] if debug

            played << { position: position } unless debug
            played << [:event] unless debug
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
           { grade: 0, octave: 0, duration: 1, velocity: 1 },
           { position: 2 },
           [:event],
           { position: 2 },
           { grade: 1, octave: 0, duration: 1, velocity: 1 },
           { position: 3 },
           { grade: 2, octave: 0, duration: 1, velocity: 1 },
           { position: 4 },
           { grade: 6, octave: 0, duration: 1, velocity: 1 },
           { position: 5 },
           { grade: 4, octave: 0, duration: 1, velocity: 1 },
           { position: 6 },
           { grade: 5, octave: 0, duration: 1, velocity: 1 },
           { position: 7 },
           { grade: 3, octave: 0, duration: 1, velocity: 1 },
           { position: 8 },
           { grade: 0, octave: 0, duration: 1, velocity: 1 },
           { position: 9 },
           [:event],
           { position: 9 },
           { grade: 1, octave: 0, duration: 1, velocity: 1 },
           { position: 10 },
           { grade: 2, octave: 0, duration: 1, velocity: 1 },
           { position: 11 },
           { grade: 6, octave: 0, duration: 1, velocity: 1 },
           { position: 12 },
           { grade: 4, octave: 0, duration: 1, velocity: 1 },
           { position: 13 },
           { grade: 5, octave: 0, duration: 1, velocity: 1 },
           { position: 14 },
           { grade: 3, octave: 0, duration: 1, velocity: 1 }]
        )
      end
    end

    it 'Advanced neumalang indirection features' do
      debug = false
      # debug = true

      gdv_decoder = Musa::Datasets::GDV::NeumaDecoder.new scale
      serie = Musa::Neumalang.parse_file File.join(File.dirname(__FILE__), 'neuma3d_spec.neu')

      if debug
        puts
        puts 'SERIE'
        puts '-----'
        pp serie.duplicate.restart.to_a(true)
        puts
      end

      played = {} if debug
      played = [] unless debug

      context = Object.new
      context.instance_variable_set :@debug, debug

      sequencer = Musa::Sequencer.new 4, 4 do
        at 1 do
          handler = play serie, decoder: gdv_decoder, mode: :neumalang, context: context do |gdv|
            played[position] ||= [] if debug
            played[position] << gdv if debug # .to_pdv(scale)

            played << { position: position } unless debug
            played << gdv unless debug # .to_pdv(scale)
          end

          handler.on :event do
            played[position] ||= [] if debug
            played[position] << [:event] if debug

            played << { position: position } unless debug
            played << [:event] unless debug
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
        expect(context.instance_variable_get(:@n)).to eq(
          grade: 3, octave: 0, duration: Rational(1, 4), velocity: 1
        )
      end

      unless debug
        expect(context.instance_variable_get(:@s).restart.to_a).to eq(
          [{ grade: 0, octave: 0, duration: 1/4r, velocity: 1 },
           { grade: 1, octave: 0, duration: 1/4r, velocity: 1 },
           { grade: 2, octave: 0, duration: 1/4r, velocity: 1 }]
        )
      end

      unless debug
        expect(context.instance_variable_get(:@p).collect(&:to_a)).to eq(
          [[{ grade: 2, octave: 0, duration: 1/4r, velocity: 1 },
            { grade: 4, octave: 0, duration: 1/4r, velocity: 1 },
            { grade: 6, octave: 0, duration: 1/4r, velocity: 1 }],
           [{ grade: 3, octave: 0, duration: 1/4r, velocity: 1 },
            { grade: 5, octave: 0, duration: 1/4r, velocity: 1 },
            { grade: 7, octave: 0, duration: 1/4r, velocity: 1 }]]
        )
      end

      expect(context.instance_variable_get(:@v)).to eq(1010) unless debug

      expect(context.instance_variable_get(:@c)).to eq(10_000) unless debug

      expect(context.instance_variable_get(:@cc).call).to eq(10_000) unless debug

      unless debug
        expect(played).to eq(
          [{ position: 1 },
           { grade: 0, octave: 0, duration: 1/2r, velocity: 1 },
           { position: 1.5 },
           { grade: 1, octave: 0, duration: 1/2r, velocity: 1 },
           { position: 2 },
           { grade: 2, octave: 0, duration: 1/2r, velocity: 1 },
           { position: 2.5 },
           { grade: 0, octave: 0, duration: 3, velocity: 1 },
           { position: 5.5 },
           { grade: 1, octave: 0, duration: 3, velocity: 1 },
           { position: 8.5 },
           { grade: 2, octave: 0, duration: 3, velocity: 1 }]
        )
      end
    end

    it 'Complex file neuma parsing' do
      debug = false
      #debug = true

      gdv_decoder = Musa::Datasets::GDV::NeumaDecoder.new scale, base_duration: 1
      serie = Musa::Neumalang.parse_file File.join(File.dirname(__FILE__), 'neuma3z_spec.neu')

      if debug
        puts
        puts 'SERIE'
        puts '-----'
        pp serie.duplicate.to_a(true)
        puts
      end

      played = {} if debug
      played = [] unless debug

      sequencer = Musa::Sequencer.new 4, 4 do
        at 1 do
          handler = play serie, decoder: gdv_decoder, mode: :neumalang do |gdv|
            played[position] ||= [] if debug
            played[position] << gdv if debug # .to_pdv(scale)

            played << { position: position } unless debug
            played << gdv unless debug # .to_pdv(scale)
          end

          handler.on :evento do |a, b, c, d, kpar1:, kpar2:, kpar3:|
            played[position] ||= [] if debug
            played[position] << [:evento, a.to_a, b.to_a, c, d, :kpar1, kpar1.to_a, :kpar2, kpar2, :kpar3, kpar3.call(10, 20)] if debug

            played << { position: position } unless debug
            played << [:evento, a.to_a, b.to_a, c, d, :kpar1, kpar1.to_a, :kpar2, kpar2, :kpar3, kpar3.call(10, 20)] unless debug
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
           { grade: 0, octave: 0, duration: 1, velocity: 3 },
           { position: 2 },
           { grade: 1, octave: 0, duration: 1, velocity: 3 },
           { position: 3 },
           { grade: 2, octave: 0, duration: 1, velocity: 3 },
           { position: 4 },
           { grade: 3, octave: 0, duration: 1, velocity: 3 },
           { position: 5 },
           { grade: 4, octave: 0, duration: 1, velocity: 3 },
           { position: 6 },
           { grade: 5, octave: 0, duration: 1, velocity: 3 },
           { position: 7 },
           { grade: 6, octave: 0, duration: 1, velocity: 3 },
           { position: 8 },
           { grade: 6, octave: 0, duration: 1, velocity: 3 },
           { position: 9 },
           { grade: 0, octave: 0, duration: 1, velocity: 3 },
           { position: 10 },
           { grade: 6, octave: 0, duration: 1, velocity: 3 },
           { position: 11 },
           { grade: 7, octave: 0, duration: 1, velocity: 3 },
           { position: 12 },
           { grade: 0, octave: 0, duration: 1, velocity: 3 },
           { position: 13 },
           { grade: 1, octave: 0, duration: 1, velocity: 3 },
           { position: 14 },
           { grade: 2, octave: 0, duration: 1, velocity: 3 },
           { position: 15 },
           { grade: 8, octave: 0, duration: 1, velocity: 3 },
           { position: 16 },
           { grade: 9, octave: 0, duration: 1, velocity: 3 },
           { position: 17 },
           { grade_x: 6, octave_x: 0, duration: 100, velocity_x: 3 },
           { position: 117 },
           { grade: 0, octave: 0, duration: 1, velocity: 3 },
           { position: 117 },
           { grade: 1, octave: 0, duration: 1, velocity: 3 },
           { position: 118 },
           { grade: 2, octave: 0, duration: 1, velocity: 3 },
           { position: 118 },
           { grade: 3, octave: 0, duration: 1, velocity: 3 },
           { position: 119 },
           { grade: 4, octave: 0, duration: 1, velocity: 3 },
           { position: 119 },
           { grade: 5, octave: 0, duration: 1, velocity: 3 },
           { position: 120 },
           { grade: 0, octave: 0, duration: 1, velocity: 3 },
           { position: 121 },
           { grade: 0, octave: 0, duration: 1, velocity: 3 },
           { position: 122 },
           { grade: 0, octave: 0, duration: 1, velocity: 3 },
           { position: 123 },
           { grade: 4, octave: 0, duration: 1, velocity: 3 },
           { position: 124 },
           { grade: 5, octave: 0, duration: 1, velocity: 3 },
           { position: 125 },
           { grade: 6, octave: 0, duration: 1, velocity: 3 },
           { position: 126 },
           { grade: 1, octave: 0, duration: 2, velocity: -1 },
           { position: 128 },
           { grade: 2, octave: 0, duration: 2, velocity: -1 },
           { position: 130 },
           { grade: 3, octave: 0, duration: 2, velocity: -1 },
           { position: 132 },
           { grade: 4, octave: 0, duration: 8, velocity: -1 },
           { position: 140 },
           { grade: 5, octave: 0, duration: 8, velocity: -1 },
           { position: 148 },
           { grade: 6, octave: 0, duration: 8, velocity: -1 },
           { position: 156 },
           [:evento,
            [{ grade: 1, octave: 0, duration: 2, velocity: -1 },
             { grade: 2, octave: 0, duration: 2, velocity: -1 },
             { grade: 3, octave: 0, duration: 2, velocity: -1 },
             { grade: 4, octave: 0, duration: 8, velocity: -1 },
             { grade: 5, octave: 0, duration: 8, velocity: -1 },
             { grade: 6, octave: 0, duration: 8, velocity: -1 }],
            [{ grade: 6, octave: 0, duration: 8, velocity: -1 },
             { grade: 5, octave: 0, duration: 8, velocity: -1 },
             { grade: 4, octave: 0, duration: 8, velocity: -1 },
             { grade: 3, octave: 0, duration: 2, velocity: -1 },
             { grade: 2, octave: 0, duration: 2, velocity: -1 },
             { grade: 1, octave: 0, duration: 2, velocity: -1 }],
            123,
            100,
            :kpar1,
            [{ grade: 4, octave: 0, duration: 1, velocity: 3 },
             { grade: 5, octave: 0, duration: 1, velocity: 3 },
             { grade: 6, octave: 0, duration: 1, velocity: 3 }],
            :kpar2,
            10_000,
            :kpar3,
            200],
           { position: 156 },
           [:evento,
            [{ grade: 1, octave: 0, duration: 2, velocity: -1 },
             { grade: 2, octave: 0, duration: 2, velocity: -1 },
             { grade: 3, octave: 0, duration: 2, velocity: -1 },
             { grade: 4, octave: 0, duration: 8, velocity: -1 },
             { grade: 5, octave: 0, duration: 8, velocity: -1 },
             { grade: 6, octave: 0, duration: 8, velocity: -1 }],
            [{ grade: 0, octave: 0, duration: 1, velocity: 3 },
             { grade: 1, octave: 0, duration: 1, velocity: 3 },
             { grade: 2, octave: 0, duration: 1, velocity: 3 }],
            3,
            4,
            :kpar1,
            [{ grade: 0, octave: 0, duration: 1, velocity: 3 },
             { grade: 1, octave: 0, duration: 1, velocity: 3 },
             { grade: 2, octave: 0, duration: 1, velocity: 3 }],
            :kpar2,
            10_000,
            :kpar3,
            123_456],
           { position: 156 },
           { grade: 0, octave: 0, duration: 1, velocity: 3 },
           { position: 157 },
           { grade: 0, octave: 0, duration: 1, velocity: 3 },
           { position: 158 },
           { grade: 0, octave: 0, duration: 1, velocity: 3 },
           { position: 159 },
           { grade: 2, octave: 0, duration: 1, velocity: 3 },
           { position: 160 },
           { grade: 1, octave: 0, duration: 1, velocity: 3 },
           { position: 161 },
           { grade: 0, octave: 0, duration: 1, velocity: 3 },
           { position: 162 },
           { grade: 4, octave: 0, duration: 1, velocity: 3 },
           { position: 162 },
           { grade: 5, octave: 0, duration: 1, velocity: 3 },
           { position: 163 },
           { grade: 2, octave: 0, duration: 1, velocity: 3 },
           { position: 163 },
           { grade: 3, octave: 0, duration: 1, velocity: 3 },
           { position: 164 },
           { grade: 0, octave: 0, duration: 1, velocity: 3 },
           { position: 164 },
           { grade: 1, octave: 0, duration: 1, velocity: 3 },
           { position: 165 },
           { grade: 6, octave: 0, duration: 8, velocity: -1 },
           { position: 173 },
           { grade: 5, octave: 0, duration: 8, velocity: -1 },
           { position: 181 },
           { grade: 4, octave: 0, duration: 8, velocity: -1 },
           { position: 189 },
           { grade: 3, octave: 0, duration: 2, velocity: -1 },
           { position: 191 },
           { grade: 2, octave: 0, duration: 2, velocity: -1 },
           { position: 193 },
           { grade: 1, octave: 0, duration: 2, velocity: -1 }]
        )
      end
    end
  end
end
