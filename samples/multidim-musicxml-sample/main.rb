require_relative '../../lib/musa-dsl'
require_relative 'tools'

require 'matrix'

include Musa::Sequencer
include Musa::Datasets

using Musa::Extension::Matrix

# [quarter-notes position, pitch, dynamics, instrument]

=begin
line = Matrix[ [0 * 4, 60, 6, 2],
               [10 * 4, 60, 6, 5],
               [15 * 4, 65, 7, 2],
               [20 * 4, 65, 8, 5],
               [25 * 4, 60, 7, 0],
               [30 * 4, 60, 5, 2] ]
=end


line = Matrix[
    [0  * 4, 60, 6, 0],
    [4  * 4, 60, 6, 0],
    [8  * 4, 60, 8, 0],
    [12  * 4, 60, 8, 4],
    [16 * 4, 67, 8, 4],
    [20 * 4, 67, 5, 3] ]

Packed = Struct.new(:time, :pitch, :dynamics, :instrument)

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

        dynamics_changes = from.dynamics != to.dynamics
        instrument_changes = from.instrument != to.instrument
        pitch_changes = from.pitch != to.pitch

        puts
        puts "dynamics_changes = #{dynamics_changes}"
        puts "instrument_changes = #{instrument_changes}"
        puts "pitch_changes = #{pitch_changes}"

        if !instrument_changes
          instrument_symbol = instrument_number_to_symbol(from.instrument)

          render_dynamics from.dynamics, to.dynamics, q_duration,
                          score: score,
                          instrument: instrument_symbol,
                          position: _.position

          if !pitch_changes
            render_pitch from.pitch, q_duration,
                         score: score,
                         instrument: instrument_symbol,
                         position: _.position
          else
            _.move from: from.pitch, to: to.pitch, duration: q_duration, step: 1r do |_, pitch_, duration:|
              render_pitch pitch_, quantize(duration, ticks_per_bar),
                           score: score,
                           instrument: instrument_symbol,
                           position: _.position
            end
          end
        else
          last_note = nil

          _.move from: { instrument: from.instrument, pitch: from.pitch, dynamics: from.dynamics },
                 to: { instrument: to.instrument, pitch: to.pitch, dynamics: to.dynamics },
                 duration: q_duration, step: 1, right_open: true do
          |_, value, next_value, duration:, starts_before:|

            puts "%.3f value = #{value} duration = #{duration} starts_before = #{starts_before}" % _.position.to_f

            from_instrument = value[:instrument]
            to_instrument = next_value[:instrument]

            pitch = value[:pitch]
            dynamics = value[:dynamics]

            q_duration_instrument = quantize(duration[:instrument], ticks_per_bar)
            q_duration_pitch = quantize(duration[:pitch], ticks_per_bar)

            from_instrument_symbol = instrument_number_to_symbol(from_instrument)
            to_instrument_symbol = instrument_number_to_symbol(to_instrument)

            needs_instrument_change = !starts_before[:instrument]
            needs_pitch_change = !starts_before[:pitch]

            q_effective_duration_pitch = if needs_instrument_change && needs_pitch_change
                                           [q_duration_instrument, q_duration_pitch].min
                                         elsif needs_instrument_change
                                           q_duration_instrument
                                         else
                                           q_duration_pitch
                                         end

            puts "%.3f needs_instrument_change = #{needs_instrument_change} needs_pitch_change = #{needs_pitch_change}" % _.position.to_f
            puts "%.3f from_instrument #{from_instrument_symbol} to_instrument #{to_instrument_symbol} duration = #{q_duration_instrument}" % _.position.to_f
            puts "%.3f duration_instrument #{q_duration_instrument}" % _.position.to_f
            puts "%.3f duration_pitch #{q_duration_pitch}" % _.position.to_f
            puts "%.3f effective_duration_pitch #{q_effective_duration_pitch}" % _.position.to_f

            if needs_instrument_change
              if from_instrument && to_instrument
                puts "%.3f new dynamics from #{dynamics} to 0 on instrument #{from_instrument_symbol} duration = #{q_duration_instrument}" % _.position.to_f
                render_dynamics dynamics, 0, q_duration_instrument,
                                score: score, instrument: from_instrument_symbol, position: _.position
              end

              if to_instrument
                puts "%.3f new dynamics from 0 to #{dynamics} on instrument #{to_instrument_symbol} duration = #{q_duration_instrument}" % _.position.to_f
                render_dynamics 0, dynamics, q_duration_instrument,
                                score: score, instrument: to_instrument_symbol, position: _.position
              end
            end

            if needs_instrument_change || needs_pitch_change
              if needs_instrument_change && to_instrument
                if last_note &&
                    last_note[:instrument] == from_instrument_symbol &&
                    last_note[:pitch] == from.pitch

                  puts "%.3f extending duration on #{last_note[:instrument]}" % _.position.to_f
                  last_note[:duration] += q_effective_duration_pitch
                else
                  puts "%.3f new note on from_instrument #{from_instrument_symbol}" % _.position.to_f
                  last_note = render_pitch pitch,
                                           q_effective_duration_pitch,
                                           score: score,
                                           instrument: from_instrument_symbol,
                                           position: _.position
                end
              end

              if to_instrument
                puts "%.3f new note on to_instrument #{to_instrument_symbol}" % _.position.to_f
                last_note = render_pitch pitch,
                                         q_effective_duration_pitch,
                                         score: score,
                                         instrument: to_instrument_symbol,
                                         position: _.position
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
                     parts: { vln0: { name: 'Violin 0', abbreviation: 'vln0', clefs: { g: 2 } },
                              vln1: { name: 'Violin 1', abbreviation: 'vln1', clefs: { g: 2 } },
                              vln2: { name: 'Violin 2', abbreviation: 'vln2', clefs: { g: 2 } },
                              vln3: { name: 'Violin 3', abbreviation: 'vln3', clefs: { g: 2 } },
                              vln4: { name: 'Violin 4', abbreviation: 'vln4', clefs: { g: 2 } },
                              vln5: { name: 'Violin 5', abbreviation: 'vln5', clefs: { g: 2 } }
                     } )

File.open(File.join(File.dirname(__FILE__), "multidim_sample.musicxml"), 'w') { |f| f.write(mxml.to_xml.string) }



