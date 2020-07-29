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

        from = Packed.new(*thing[:from])
        to = Packed.new(*thing[:to])

        duration = thing[:duration]
        right_open = thing[:right_open]

        q_duration = quantize(duration, ticks_per_bar)

        intensity_changes = from.intensity != to.intensity
        instrument_changes = from.instrument != to.instrument
        pitch_changes = from.pitch != to.pitch

        puts "#{_.position.to_f.round(3)} intensity_changes = #{intensity_changes}"
        puts "#{_.position.to_f.round(3)} instrument_changes = #{instrument_changes}"
        puts "#{_.position.to_f.round(3)} pitch_changes = #{pitch_changes}"


        if !instrument_changes
          instrument_symbol = instrument_number_to_symbol(from.instrument)

          render_dynamics from.intensity, to.intensity, q_duration, score: score, instrument: instrument_symbol, position: _.position

          if !pitch_changes
            render_pitch from.pitch, q_duration, score: score, instrument: instrument_symbol, position: _.position
          else
            _.move from: from.pitch, to: to.pitch, duration: q_duration, step: 1r do |_, pitch_, duration:|
              render_pitch pitch_, quantize(duration, ticks_per_bar), score: score, instrument: instrument_symbol, position: _.position
            end
          end
        else
          if !pitch_changes && !intensity_changes
            last_note = nil

            _.move from: from.instrument, to: to.instrument, duration: q_duration, step: 1, right_open: true do
            |_, from_instrument, to_instrument, duration:|

              if to_instrument
                q_duration = quantize(duration, ticks_per_bar)
                from_instrument_symbol = instrument_number_to_symbol(from_instrument)
                to_instrument_symbol = instrument_number_to_symbol(to_instrument)

                render_dynamics from.intensity, 0, q_duration,
                                score: score, instrument: from_instrument_symbol, position: _.position

                render_dynamics 0, from.intensity, q_duration,
                                score: score, instrument: to_instrument_symbol, position: _.position

                if last_note &&
                    last_note[:instrument] == from_instrument_symbol &&
                    last_note[:pitch] == from.pitch

                  last_note[:duration] += q_duration
                else
                  render_pitch from.pitch, q_duration, score: score, instrument: from_instrument_symbol, position: _.position
                end

                last_note = render_pitch from.pitch, q_duration, score: score, instrument: to_instrument_symbol, position: _.position
              end
            end
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



