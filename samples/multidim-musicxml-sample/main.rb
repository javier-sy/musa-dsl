require_relative '../../lib/musa-dsl'
require_relative 'tools'

require 'matrix'

include Musa::Sequencer
include Musa::Datasets

using Musa::Extension::Matrix

# [quarter-notes position, pitch, from_dynamics, instrument]

line = Matrix[ [0 * 4, 60, 6, 2],
               [10 * 4, 60, 6, 5],
               [15 * 4, 65, 7, 2],
               [20 * 4, 65, 8, 5],
               [25 * 4, 60, 7, 0],
               [30 * 4, 60, 5, 2] ]


line = Matrix[
    [0  * 4, 60, 6, 0],
    [4  * 4, 60, 6, 0], # changes nothing
    [8  * 4, 60, 8, 0], # changes dynamics
    [12  * 4, 60, 8, 4], # changes instrument

    [16 * 4, 67, 8, 4], # changes pitch

    [20 * 4, 67, 6, 2], # changes dynamics & instrument
    [24 * 4, 67, 6, 4], # changes instrument

    [28 * 4, 66, 6, 3], # changes pitch & instrument
    [31 * 4, 66, 4, 0], # changes dynamics & instrument

    [32 * 4, 66, 6, 0], # changes dynamics
    [42 * 4, 57, 10, 5] # changes dynamics & pitch & instrument
]

line = Matrix[
    [0 * 4, 60, 10, 0], # changes dynamics & pitch & instrument
    [2 * 4, 61, 8, 3]
] if false

line = Matrix[
    [0 * 4, 66, 6, 0], # changes dynamics
    [10 * 4, 57, 10, 5] # changes dynamics & pitch & instrument

]


Packed = Struct.new(:time, :pitch, :dynamics, :instrument)

beats_per_bar = 4r
ticks_per_beat = 32r
ticks_per_bar = beats_per_bar * ticks_per_beat

score = Score.new(1 / ticks_per_bar)

debug = false

sequencer = Sequencer.new(beats_per_bar, ticks_per_beat) do |_|
  _.at 1 do |_|
    line.to_p(0).each do |p|
      _.play p.to_ps_serie do |_, segment|

        segment_from = Packed.new(*segment[:from])
        segment_to = Packed.new(*segment[:to])

        duration = segment[:duration]
        right_open = segment[:right_open]

        q_duration = quantize(duration, ticks_per_bar)

        dynamics_change = segment_from.dynamics != segment_to.dynamics
        instrument_change = segment_from.instrument != segment_to.instrument
        pitch_change = segment_from.pitch != segment_to.pitch

        if debug
          puts
          puts "%.3f dynamics_change = #{dynamics_change}" % _.position
          puts "%.3f instrument_change = #{instrument_change}" % _.position
          puts "%.3f pitch_change = #{pitch_change}" % _.position
        end

        if !instrument_change
          instrument_symbol = instrument_number_to_symbol(segment_from.instrument)

          render_dynamics segment_from.dynamics, segment_to.dynamics, q_duration,
                          score: score,
                          instrument: instrument_symbol,
                          position: _.position

          if !pitch_change
            render_pitch segment_from.pitch, q_duration,
                         score: score,
                         instrument: instrument_symbol,
                         position: _.position
          else
            _.move from: segment_from.pitch,
                   to: segment_to.pitch,
                   duration: q_duration,
                   step: 1r do |_, pitch_, duration:|

              render_pitch pitch_, quantize(duration, ticks_per_bar),
                           score: score,
                           instrument: instrument_symbol,
                           position: _.position
            end
          end
        else
          _.move from: { instrument: segment_from.instrument,
                         pitch: segment_from.pitch,
                         dynamics: segment_from.dynamics },
                 to: { instrument: segment_to.instrument,
                       pitch: segment_to.pitch,
                       dynamics: segment_to.dynamics },
                 right_open: { instrument: true, dynamics: true },
                 duration: q_duration,
                 step: 1 do |_, value, next_value, duration:, starts_before:|

            puts "%.3f value = #{value} duration = #{duration} starts_before = #{starts_before}" % _.position.to_f if debug

            from_instrument = value[:instrument]
            to_instrument = next_value[:instrument]

            pitch = value[:pitch]
            to_pitch = next_value[:pitch]

            if to_instrument || to_pitch # !finished
              new_instrument_now = !!(!starts_before[:instrument] && to_instrument)
              new_pitch_now = !!(!starts_before[:pitch] && to_pitch)

              from_dynamics = new_instrument_now ? value[:dynamics] : segment_from.dynamics
              to_dynamics = new_instrument_now ? next_value[:dynamics] : segment_to.dynamics

              q_duration_instrument = quantize(duration[:instrument], ticks_per_bar)
              q_duration_pitch = quantize(duration[:pitch], ticks_per_bar)

              from_instrument_symbol = instrument_number_to_symbol(from_instrument)
              to_instrument_symbol = instrument_number_to_symbol(to_instrument)

              q_effective_duration_pitch =
                  [ q_duration_instrument - (starts_before[:instrument] || 0),
                    q_duration_pitch - (starts_before[:pitch] || 0) ].min

              if debug
                puts "%.3f new_instrument_now = #{new_instrument_now} new_pitch_now = #{new_pitch_now}" % _.position.to_f
                puts "%.3f from_instrument #{from_instrument_symbol} to_instrument #{to_instrument_symbol} duration = #{q_duration_instrument}" % _.position.to_f
                puts "%.3f duration_instrument #{q_duration_instrument}" % _.position.to_f
                puts "%.3f duration_pitch #{q_duration_pitch}" % _.position.to_f
                puts "%.3f effective_duration_pitch #{q_effective_duration_pitch}" % _.position.to_f
              end

              if new_instrument_now
                if from_instrument && to_instrument
                  puts "%.3f new dynamics from #{from_dynamics} to 0 on instrument #{from_instrument_symbol} duration = #{q_duration_instrument}" % _.position.to_f if debug
                  render_dynamics from_dynamics, 0, q_duration_instrument,
                                  score: score, instrument: from_instrument_symbol, position: _.position
                end

                if to_instrument
                  puts "%.3f new dynamics from 0 to #{to_dynamics || from_dynamics} on instrument #{to_instrument_symbol} duration = #{q_duration_instrument}" % _.position.to_f if debug
                  render_dynamics 0, to_dynamics || from_dynamics, q_duration_instrument,
                                  score: score, instrument: to_instrument_symbol, position: _.position
                end
              end

              puts
              puts "%.3f new_instrument_now = #{new_instrument_now} new_pitch_now = #{new_pitch_now}" % _.position.to_f
              puts "%.3f from_instrument #{from_instrument_symbol} to_instrument #{to_instrument_symbol}" % _.position.to_f
              puts "%.3f pitch #{pitch}" % _.position.to_f
              puts "%.3f duration_instrument #{q_duration_instrument}" % _.position.to_f
              puts "%.3f duration_pitch #{q_duration_pitch}" % _.position.to_f
              puts "%.3f starts_before dynamics #{starts_before[:dynamics] || 'nil'}" % _.position.to_f
              puts "%.3f starts_before instrument #{starts_before[:instrument] || 'nil'}" % _.position.to_f
              puts "%.3f starts_before pitch #{starts_before[:pitch] || 'nil'}" % _.position.to_f

              puts "%.3f effective_duration_pitch #{q_effective_duration_pitch}" % _.position.to_f

              render_pitch pitch,
                           q_effective_duration_pitch,
                           score: score,
                           instrument: from_instrument_symbol,
                           position: _.position,
                           data: "new_instrument_now = #{new_instrument_now} new_pitch_now = #{new_pitch_now} from_instrument = #{from_instrument_symbol} pitch = #{pitch} to_instrument = #{to_instrument_symbol} (from)"

              if to_instrument
                render_pitch pitch,
                             q_effective_duration_pitch,
                             score: score,
                             instrument: to_instrument_symbol,
                             position: _.position,
                             data: "new_instrument_now = #{new_instrument_now} new_pitch_now = #{new_pitch_now} from_instrument = #{from_instrument_symbol} pitch = #{pitch} to_instrument = #{to_instrument_symbol} (to)"
              end
            end
          end
        end
      end
    end
  end
end

sequencer.run

puts
puts "score"
puts "-----"
score.values_of(:instrument).each do |instrument|
  puts
  puts msg = "instrument #{instrument}"
  puts "-" * msg.size
  pp score.subset { |dataset| dataset[:instrument] == instrument}._score
end

mxml = score.to_mxml(beats_per_bar, ticks_per_beat,
                     bpm: 90,
                     title: 'work title',
                     creators: { composer: 'Javier Sánchez Yeste' },
                     parts: { vln0: { name: 'Violin 0', abbreviation: 'vln0', clefs: { g: 2 } },
                              vln1: { name: 'Violin 1', abbreviation: 'vln1', clefs: { g: 2 } },
                              vln2: { name: 'Violin 2', abbreviation: 'vln2', clefs: { g: 2 } },
                              vln3: { name: 'Violin 3', abbreviation: 'vln3', clefs: { g: 2 } },
                              vln4: { name: 'Violin 4', abbreviation: 'vln4', clefs: { g: 2 } },
                              vln5: { name: 'Violin 5', abbreviation: 'vln5', clefs: { g: 2 } }
                     } )

File.open(File.join(File.dirname(__FILE__), "multidim_sample.musicxml"), 'w') { |f| f.write(mxml.to_xml.string) }



