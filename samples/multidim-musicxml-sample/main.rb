require_relative '../../lib/musa-dsl'
require_relative 'tools'

require 'matrix'

include Musa::Sequencer
include Musa::Datasets

using Musa::Extension::Matrix

# [quarter-notes position, pitch, intensity, instrument]
=begin
line = Matrix[ [0 * 4, 60, 50, 2],
               [10 * 4, 60, 50, 5],
               [15 * 4, 65, 70, 2],
               [20 * 4, 65, 80, 5],
               [25 * 4, 60, 70, 0],
               [30 * 4, 60, 50, 2] ]
=end


line = Matrix[
    [0 * 4, 60, 50, 0],
    [4 * 4, 60, 50, 2] # ,
    #[8 * 4, 67, 90, 0],
    #[12 * 4, 67, 90, 1]
    ]

puts "line.to_p(0) = #{line.to_p(0)}"

Packed = Struct.new(:time, :pitch, :intensity, :instrument)

beats_per_bar = 4r
ticks_per_beat = 32r
ticks_per_bar = beats_per_bar * ticks_per_beat

score = Score.new(1 / ticks_per_bar)

sequencer = Sequencer.new(beats_per_bar, ticks_per_beat) do |_|
  _.at 1 do |_|
    line.to_p(0).each do |p|
      _.play p.to_ps_serie do |_, thing|

        puts "thing = #{thing}"

        from = Packed.new(*thing[:from])
        to = Packed.new(*thing[:to])
        duration = thing[:duration]

        instruments = nil
        base_pitch = nil
        intensity = next_intensity = nil
        last_intensity = []

        if from.instrument == to.instrument
          if from.intensity != to.intensity
            puts "a... _.position  = #{_.position.to_f.round(3)} duration = #{duration}"
            score.at _.position,
                     add: { instrument: instrument_number_to_symbol(from.instrument),
                            type: to.intensity > from.intensity ? :crescendo : :diminuendo,
                            from: from.intensity,
                            to: to.intensity,
                            duration: quantize(duration, ticks_per_bar) }.extend(PS)

          elsif from.intensity != last_intensity[from.intensity]
            # cuidado: debería ser un AbsI más que un PS
            puts "b... _.position  = #{_.position.to_f.round(3)} duration = #{duration}"
            score.at _.position,
                     add: { instrument: instrument_number_to_symbol(from.instrument),
                            type: :crescendo,
                            from: from.intensity,
                            to: nil,
                            duration: quantize(duration, ticks_per_bar) }.extend(PS)
          end
        end

        _.move from: from.intensity, to: to.intensity, duration: duration do
        |intensity_, next_intensity_, duration:|

          intensity = intensity_
          next_intensity = next_intensity_
        end

        _.move from: from.instrument, to: to.instrument, duration: duration do
        |instrument, next_instrument|

          instruments = decode_instrument(instrument)
          next_instruments = decode_instrument(next_instrument) if next_instrument
          next_instruments ||= []

          if instruments.size == 1 && next_instruments.size == 2
            puts "#{_.position.to_f.round(3)} cambio de instrumentos: #{instruments} -> #{next_instruments} duration = #{duration}"
            instrument = instrument_number_to_symbol((next_instruments.keys - instruments.keys).first)
            score.at _.position,
                     add: { instrument: instrument,
                           type: :crescendo,
                           from: intensity * (instruments[instrument] || 0),
                           to: next_intensity * (next_instruments[instrument] || 0),
                           duration: quantize(duration, ticks_per_bar) }.extend(PS)

          elsif instruments.size == 2 && next_instruments.size == 1
            puts "#{_.position.to_f.round(3)} cambio de instrumentos: #{instruments} -> #{next_instruments} duration = #{duration}"
            instrument = instrument_number_to_symbol((next_instruments.keys - instruments.keys).first)
            score.at _.position,
                      add: { instrument: instrument,
                             type: :diminuendo,
                             from: intensity * (instruments[instrument] || 0),
                             to: next_intensity * (next_instruments[instrument] || 0),
                             duration: quantize(duration, ticks_per_bar) }.extend(PS)
          else
            # ignore intermediate steps
          end

          # cuidado: los instrumentos en una transición NO comparten la misma intensity
          instruments.each_key do |instrument|
            last_intensity[instrument] = intensity
          end

        end

        _.move from: from.pitch, to: to.pitch, duration: duration, step: 1 do
        |_, pitch, next_pitch, duration:|

          base_pitch = pitch

          instruments.each_key do |instrument|
            puts "pitch... _.position  = #{_.position.to_f.round(3)} duration = #{duration}"
            score.at _.position, add: { instrument: instrument_number_to_symbol(instrument),
                                        pitch: pitch,
                                        duration: quantize(duration, ticks_per_bar) }.extend(PDV)
          end
        end

      end
    end
  end
end

sequencer.run

mxml = score.to_mxml(beats_per_bar, ticks_per_beat,
                     bpm: 90,
                     title: 'work title',
                     creators: { composer: 'Javier Sánchez Yeste' },
                     parts: { v0: { name: 'Violin 0', abbreviation: 'vln0', clefs: { g: 2 } },
                              v1: { name: 'Violin 1', abbreviation: 'vln1', clefs: { g: 2 } },
                              v2: { name: 'Violin 2', abbreviation: 'vln2', clefs: { g: 2 } },
                              v3: { name: 'Violin 3', abbreviation: 'vln3', clefs: { g: 2 } },
                              v4: { name: 'Violin 4', abbreviation: 'vln4', clefs: { g: 2 } },
                              v5: { name: 'Violin 5', abbreviation: 'vln5', clefs: { g: 2 } }
                     } )

File.open(File.join(File.dirname(__FILE__), "multidim_sample.musicxml"), 'w') { |f| f.write(mxml.to_xml.string) }

