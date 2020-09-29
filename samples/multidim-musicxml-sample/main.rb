require_relative '../../lib/musa-dsl'
require_relative 'tools'

require 'matrix'

include Musa::Sequencer
include Musa::Datasets

using Musa::Extension::Matrix

# [quarter-notes position, pitch, dynamics, instrument]

# TODO ligar notas (para hacer legato)?
# TODO ligar notas cuando no cambia de altura en el mismo instrumento?

poly_line = Matrix[
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
    [42 * 4, 57, 10, 5], # changes dynamics & pitch & instrument
    [46 * 4, 57, 10, 5] # change nothing
]

beats_per_bar = 4r
ticks_per_beat = 32r

score = Score.new

sequencer = Sequencer.new(beats_per_bar, ticks_per_beat, log_decimals: 1.3) do |_|
  _.at 1 do |_|
    poly_line.to_p(0).each do |p|

      p.to_score(score: score,
                 position: _.position,
                 right_open: { dynamics: true }, # TODO traducir los símbolos!!!
                 beats_per_bar: beats_per_bar, ticks_per_beat: ticks_per_beat) do
        | value, next_value,
          position:,
          duration:,
          quantized_duration:,
          position_jitter:, duration_jitter:,
          started_ago:,
          s:|

        puts
        s.log "\n\tvalue #{value}\n\tnext #{next_value}\n\tscore_position #{position}\n\tduration #{duration}" \
              "\n\tquantized_duration #{quantized_duration}\n\tstarted_ago #{started_ago}"\
              "\n\tposition_jitter #{position_jitter}\n\tduration_jitter #{duration_jitter}"

        new_instrument_now = !started_ago[:instrument]
        new_dynamics_now = !started_ago[:dynamics]
        new_pitch_now = !started_ago[:pitch]

        puts
        s.log "new_dynamics_now #{new_dynamics_now} new_instrument_now #{new_instrument_now} new_pitch_now #{new_pitch_now}"

        if new_instrument_now || new_dynamics_now || new_pitch_now

          q_duration_instrument = quantized_duration[:instrument]
          q_duration_dynamics = quantized_duration[:dynamics]
          q_duration_pitch = quantized_duration[:pitch]

          from_instrument = value[:instrument]
          to_instrument = next_value[:instrument]

          from_instrument_symbol = instrument_number_to_symbol(from_instrument)
          to_instrument_symbol = instrument_number_to_symbol(to_instrument)

          to_dynamics = next_value[:dynamics]

          pitch = value[:pitch]

          if new_instrument_now || new_dynamics_now

            start_instrument_position = position - (started_ago[:instrument] || 0)
            finish_instrument_position = start_instrument_position + quantized_duration[:instrument]

            start_dynamics_position = position - (started_ago[:dynamics] || 0)
            finish_dynamics_position = start_dynamics_position + quantized_duration[:dynamics]

            segment_q_effective_duration =
                [finish_instrument_position, finish_dynamics_position].min - position

            segment_effective_finish_position = position + segment_q_effective_duration

            # relative start and finish position are ratios from 0 (beginning) to 1 (finish)
            #
            segment_relative_start_position_over_instrument_timeline =
                Rational(position - start_instrument_position,
                         finish_instrument_position - start_instrument_position)

            segment_relative_finish_position_over_instrument_timeline =
                Rational(segment_effective_finish_position - start_instrument_position,
                         finish_instrument_position - start_instrument_position)
            #
            segment_relative_start_position_over_dynamics_timeline =
                Rational(position - start_dynamics_position,
                         finish_dynamics_position - start_dynamics_position)

            segment_relative_finish_position_over_dynamics_timeline =
                Rational(segment_effective_finish_position - start_dynamics_position,
                         finish_dynamics_position - start_dynamics_position)

            delta_dynamics = (next_value[:dynamics] || value[:dynamics]) - value[:dynamics]

            segment_from_dynamics =
                value[:dynamics] +
                    delta_dynamics * segment_relative_start_position_over_dynamics_timeline

            segment_to_dynamics =
                value[:dynamics] +
                    delta_dynamics * segment_relative_finish_position_over_dynamics_timeline

            segment_from_dynamics_from_instrument =
                segment_from_dynamics *
                    (1r - segment_relative_start_position_over_instrument_timeline)

            segment_to_dynamics_from_instrument =
                segment_to_dynamics *
                    (1r - segment_relative_finish_position_over_instrument_timeline)

            segment_from_dynamics_to_instrument =
                segment_from_dynamics *
                    segment_relative_start_position_over_instrument_timeline

            segment_to_dynamics_to_instrument =
                segment_to_dynamics *
                    segment_relative_finish_position_over_instrument_timeline

            s.log "from_instrument #{from_instrument_symbol} to_instrument #{to_instrument_symbol || 'nil'}"

            s.log "segment_q_effective_duration #{segment_q_effective_duration&.inspect(base: 0.0001) || 'nil'}"

            s.log "segment_relative_start_position_over_dynamics_timeline #{segment_relative_start_position_over_dynamics_timeline&.to_f&.round(2) || 'nil'}"
            s.log "segment_relative_finish_position_over_dynamics_timeline #{segment_relative_finish_position_over_dynamics_timeline&.to_f&.round(2) || 'nil'}"

            s.log "value[:dynamics] #{value[:dynamics].to_f.round(2)} delta_dynamics #{delta_dynamics.to_f.round(2)}"
            s.log "segment_from_dynamics #{segment_from_dynamics.to_f.round(2)} to_dynamics #{to_dynamics.to_f.round(2)}"

            s.log "segment_relative_start_position_over_instrument_timeline #{segment_relative_start_position_over_instrument_timeline&.to_f&.round(2) || 'nil'}"
            s.log "segment_relative_finish_position_over_instrument_timeline #{segment_relative_finish_position_over_instrument_timeline&.to_f&.round(2) || 'nil'}"

            s.log "#{from_instrument_symbol} segment_from_dynamics #{segment_from_dynamics_from_instrument.to_f.round(2)} to_dynamics #{segment_to_dynamics_from_instrument.to_f.round(2)}"
            s.log "#{to_instrument_symbol || 'nil'} segment_from_dynamics #{segment_from_dynamics_to_instrument.to_f.round(2)} to_dynamics #{segment_to_dynamics_to_instrument.to_f.round(2)}"

            if from_instrument && to_instrument
              render_dynamics segment_from_dynamics_from_instrument,
                              segment_to_dynamics_from_instrument,
                              segment_q_effective_duration,
                              score: score,
                              instrument: from_instrument_symbol,
                              position: position

              render_dynamics segment_from_dynamics_to_instrument,
                              segment_to_dynamics_to_instrument,
                              segment_q_effective_duration,
                              score: score,
                              instrument: to_instrument_symbol,
                              position: position
            end

            if from_instrument && !to_instrument
              render_dynamics segment_from_dynamics,
                              segment_to_dynamics,
                              segment_q_effective_duration,
                              score: score,
                              instrument: from_instrument_symbol,
                              position: position
            end
          end

          s.log "pitch #{pitch}"

          q_effective_duration_pitch =
              [ q_duration_instrument - (started_ago[:instrument] || 0),
                q_duration_pitch - (started_ago[:pitch] || 0),
                q_duration_dynamics - (started_ago[:dynamics] || 0)].min

          s.log "effective_duration_pitch #{q_effective_duration_pitch.inspect(base: 0.0001)}"

          render_pitch pitch,
                       q_effective_duration_pitch,
                       score: score,
                       instrument: from_instrument_symbol,
                       position: position

          if to_instrument
            render_pitch pitch,
                         q_effective_duration_pitch,
                         score: score,
                         instrument: to_instrument_symbol,
                         position: position
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
                     },
                     do_log: true)

File.open(File.join(File.dirname(__FILE__), "multidim_sample.musicxml"), 'w') { |f| f.write(mxml.to_xml.string) }



