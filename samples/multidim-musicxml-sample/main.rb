require_relative '../../lib/musa-dsl'
require_relative 'tools'

require 'matrix'

include Musa::Sequencer
include Musa::Datasets

using Musa::Extension::Matrix

# [bar, pitch, intensity, instrument]
line = Matrix[ [0 * 4, 60, 50, 2],
               [10 * 4, 60, 50, 5],
               [15 * 4, 65, 70, 2],
               [20 * 4, 65, 80, 5],
               [25 * 4, 60, 70, 0],
               [30 * 4, 60, 50, 2] ]

score = Score.new(0.25)

Packed = Struct.new(:time, :pitch, :intensity, :instrument)

sequencer = Sequencer.new(4, 24) do |_|
  _.at 1 do |_|
    line.to_p(0).each do |p|
      _.play p.to_ps_serie do |_, thing|

        from = Packed.new(*thing[:from])
        to = Packed.new(*thing[:to])
        duration = thing[:duration]

        instruments = nil
        base_pitch = nil
        intensity = nil

        _.move from: from.intensity, to: to.intensity, duration: duration do
        |intensity_, next_intensity, duration:|

          intensity = intensity_
        end

        _.move from: from.instrument, to: to.instrument, duration: duration do
        |instrument, next_instrument|

          instruments = decode_instrument(instrument)
          next_instruments = decode_instrument(next_instrument) if next_instrument
          next_instruments ||= []

          if instruments.size == 1 && next_instruments.size == 2
            score.at _.position,
                     add: { instrument: instrument_number_to_symbol(
                              (next_instruments.keys - instruments.keys).first),
                           type: :crescendo,
                           from: nil,
                           to: nil,
                           duration: duration }.extend(PS)

          elsif instruments.size == 2 && next_instruments.size == 1
            score.at _.position,
                      add: { instrument: instrument_number_to_symbol(
                                (next_instruments.keys - instruments.keys).first),
                             type: :diminuendo,
                             from: nil,
                             to: nil,
                             duration: duration }.extend(PS)
          else
            # ignore intermediate steps
          end
        end

        _.move from: from.pitch, to: to.pitch, duration: duration, step: 1 do
        |_, pitch, next_pitch, duration:|

          base_pitch = pitch

          instruments.each_key do |instrument|
            score.at _.position, add: { instrument: instrument_number_to_symbol(instrument),
                                        pitch: pitch,
                                        duration: duration }.extend(PDV)
          end
        end

      end
    end
  end
end

sequencer.run

pp score

mxml = score.to_mxml(4, 24,
                     bpm: 90,
                     title: 'work title',
                     creators: { composer: 'Javier Sánchez Yeste' },
                     parts: { v1: { name: 'Violin', abbreviation: 'vln1', clefs: { g: 2 } },
                              v2: { name: 'Violin', abbreviation: 'vln2', clefs: { g: 2 } },
                              v3: { name: 'Violin', abbreviation: 'vln3', clefs: { g: 2 } },
                              v4: { name: 'Violin', abbreviation: 'vln4', clefs: { g: 2 } },
                              v5: { name: 'Violin', abbreviation: 'vln5', clefs: { g: 2 } },
                              v6: { name: 'Violin', abbreviation: 'vln6', clefs: { g: 2 } }
                     } )

# puts mxml.to_xml.string

