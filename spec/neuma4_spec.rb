require 'spec_helper'

require 'pp'

require 'musa-dsl'

RSpec.describe Musa::Neumalang do
  context 'Neuma with neumalang call methods and references parsing' do
    include Musa::Series

    scale = Musa::Scales::Scales.default_system.default_tuning.major[60]

    it 'Simple file neumas parsing' do
      debug = false
      #debug = true

      gdv_decoder = Musa::Neumas::Decoders::NeumaDecoder.new scale, base_duration: 1
      serie = Musa::Neumalang::Neumalang.parse_file File.join(File.dirname(__FILE__), 'neuma4_spec.neu')

      if debug
        puts
        puts 'SERIE'
        puts '-----'
        pp serie.to_a(recursive: true)
        puts
      end

      played = debug ? {} : []

      sequencer = Musa::Sequencer::Sequencer.new 4, 4 do

        on :evento do |*x, **y, &block|
          if debug
            played[position] ||= []
            played[position] << { evento: [x, y, block&.call] }
          else
            played << { position: position }
            played << { evento: [x, y, block&.call] }
          end
        end

        at 1 do
          play serie, decoder: gdv_decoder, mode: :neumalang do |gdv|
            if debug
              played[position] ||= []
              played[position] << gdv # .to_pdv(scale)
            else
              played << { position: position }
              played << gdv # .to_pdv(scale)
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
      else
        expect(played).to eq(
          [
            { position: 1r },
            { grade: 2, octave: 0, duration: 1, velocity: 1 },
            { position: 2r },
            { grade: 1, octave: 0, duration: 1, velocity: 1 },
            { position: 3r },
            { grade: 0, octave: 0, duration: 1, velocity: 1 },
            { position: 4r },
            { grade: 2, octave: 0, duration: 1, velocity: 1 },
            { position: 5r },
            { grade: 1, octave: 0, duration: 1, velocity: 1 },
            { position: 6r },
            { grade: 0, octave: 0, duration: 1, velocity: 1 },
            { position: 7r },
            { grade: 3, octave: 0, duration: 1, velocity: 21 },
            { position: 8r },
            { grade: 4, octave: 0, duration: 1, velocity: 21 },
            { position: 9r },
            { grade: 5, octave: 0, duration: 1, velocity: 21 },
            { position: 10r },
            { grade: 0, octave: 0, duration: 1, velocity: 31 },
            { position: 11r },
            { grade: 1, octave: 0, duration: 1, velocity: 31 },
            { position: 12r },
            { grade: 2, octave: 0, duration: 1, velocity: 31 },
            { position: 13r },
            { evento: [[1000], { cosa: 100 }, 12_345] },
            { position: 13r },
            { grade: 0, octave: 0, duration: 1, velocity: 41 },
            { position: 14r },
            { grade: 1, octave: 0, duration: 1, velocity: 41 },
            { position: 15r },
            { grade: 2, octave: 0, duration: 1, velocity: 41 },
            { position: 16r },
            { grade: 0, octave: 0, duration: 1, velocity: 51 },
            { position: 17r },
            { grade: 1, octave: 0, duration: 1, velocity: 51 },
            { position: 18r },
            { grade: 2, octave: 0, duration: 1, velocity: 51 },
            { position: 19r },
            { evento: [[2000], { cosa: 200 }, 54_321] },
            { position: 19r },
            { grade: 0, octave: 0, duration: 1, velocity: 11 },
            { position: 20r },
            { grade: 1, octave: 0, duration: 1, velocity: 11 },
            { position: 21r },
            { grade: 2, octave: 0, duration: 1, velocity: 11 },
            { position: 22r },
            { grade: 0, octave: 0, duration: 1, velocity: 11 },
            { position: 23r },
            { grade: 1, octave: 0, duration: 1, velocity: 11 },
            { position: 24r },
            { grade: 2, octave: 0, duration: 1, velocity: 11 },
            { position: 25r },
            { evento: [[3000], { cosa: 300 }, 99_999] }
          ]
        )
      end
    end
  end
end

