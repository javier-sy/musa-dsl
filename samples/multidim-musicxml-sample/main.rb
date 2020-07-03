require_relative '../lib/musa-dsl'

require 'matrix'

include Musa::Sequencer
include Musa::Datasets
include Musa::Score

using Musa::Extension::Matrix

# [bar, pitch, intensity, instrument]
line = Matrix[ [0 * 4, 60, 50, 0],
               [10 * 4, 60, 50, 3],
               [15 * 4, 65, 70, 0],
               [20 * 4, 65, 80, 3],
               [25 * 4, 60, 70, -2],
               [30 * 4, 60, 50, 0] ]

score = Score.new(0.25)

Packed = Struct.new(:time, :pitch, :intensity, :instrument)

sequencer = Sequencer.new(4, 24) do |_|
  _.at 1 do |_|
    line.to_p(0).each do |p|
      _.play p.to_ps_serie do |thing|

        from = Packed.new(*thing[:from])
        to = Packed.new(*thing[:to])
        duration = thing[:duration]

        instruments = nil
        base_pitch = nil

        _.move from: from.instrument, to: to.instrument, duration: duration, step: 1 do |instrument, next_instrument, duration:|
          instruments = decode_instrument(instrument)
        end

        _.move from: from.pitch, to: to.pitch, duration: duration do |pitch, next_pitch, duration:|
          base_pitch = pitch

          _.log "pitch = #{pitch}"
        end

      end
    end
  end
end

sequencer.run

score.each do |thing|
  puts "thing = #{thing}"
end

def decode_instrument(instrument)
  instrument_1 = instrument.round
  instrument_2 = instrument_1 + (instrument <=> instrument_1)

  level_1 = (instrument_2 - instrument).round(Float::DIG).abs
  level_2 = (instrument_1 - instrument).round(Float::DIG).abs

  if instrument_1 == instrument_2
    { instrument_1 => 1 }
  else
    { instrument_1 => level_1, instrument_2 => level_2 }
  end
end