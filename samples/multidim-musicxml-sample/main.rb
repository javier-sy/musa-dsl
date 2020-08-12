require_relative '../../lib/musa-dsl'
require_relative 'tools'

require 'matrix'

include Musa::Sequencer
include Musa::Datasets

using Musa::Extension::Matrix

# [quarter-notes position, pitch, segment_from_dynamics, instrument]

poly_line = Matrix[ [0 * 4, 60, 6, 2],
               [10 * 4, 60, 6, 5],
               [15 * 4, 65, 7, 2],
               [20 * 4, 65, 8, 5],
               [25 * 4, 60, 7, 0],
               [30 * 4, 60, 5, 2] ]


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
    [42 * 4, 57, 10, 5] # changes dynamics & pitch & instrument
]

poly_line = Matrix[
    [0 * 4, 66, 6, 0], # changes dynamics
    [10 * 4, 57, 10, 5] # changes dynamics & pitch & instrument

] if false

poly_line = Matrix[
    [0 * 4, 60, 8, 0], # changes dynamics & pitch & instrument
    [2 * 4, 61, 8, 3]
] if false

poly_line = Matrix[
    [0 * 4, 60, 10, 0], # changes dynamics & pitch & instrument
    [2 * 4, 61, 8, 3]
]


Packed = Struct.new(:time, :pitch, :dynamics, :instrument)

beats_per_bar = 4r
ticks_per_beat = 32r
ticks_per_bar = beats_per_bar * ticks_per_beat
resolution = 1 / ticks_per_bar

score = Score.new(resolution)

debug = false

sequencer = Sequencer.new(beats_per_bar, ticks_per_beat, log_decimals: 1.3) do |_|
  _.at 1 do |_|
    poly_line.to_p(0).each do |p|
      _.play p.to_ps_serie do |_, line|

        segment_from = Packed.new(*line[:from])
        segment_to = Packed.new(*line[:to])

        duration = line[:duration]

        q_duration = quantize(duration, ticks_per_bar)

        dynamics_change = segment_from.dynamics != segment_to.dynamics
        instrument_change = segment_from.instrument != segment_to.instrument
        pitch_change = segment_from.pitch != segment_to.pitch

        if debug
          puts
          _.log "dynamics_change = #{dynamics_change}"
          _.log "instrument_change = #{instrument_change}"
          _.log "pitch_change = #{pitch_change}"
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
                 step: 1 do |_, value, next_value,
                                position:,
                                duration:,
                                quantized_duration:,
                                position_jitter:, duration_jitter:,
                                starts_before:|

            puts
            puts
            _.log "\tvalue = #{value}\n\tnext = #{next_value}\n\tposition = #{position}\n\tduration = #{duration}\n\tquantized_duration = #{quantized_duration}\n\tposition_jitter = #{position_jitter}\n\tduration_jitter = #{duration_jitter}\n\tstarts_before = #{starts_before}"

            from_instrument = value[:instrument]
            to_instrument = next_value[:instrument]

            pitch = value[:pitch]

            to_pitch = next_value[:pitch]
            to_dynamics = next_value[:dynamics]

            if to_instrument || to_pitch || to_dynamics # !finished
              new_instrument_now = !!(!starts_before[:instrument] && to_instrument)
              new_pitch_now = !!(!starts_before[:pitch] && to_pitch)
              new_dynamics_now = !!(!starts_before[:dynamics] && to_dynamics)

              q_duration_instrument = quantized_duration[:instrument]
              q_duration_pitch = quantized_duration[:pitch]
              q_duration_dynamics = quantized_duration[:dynamics]

              from_instrument_symbol = instrument_number_to_symbol(from_instrument)
              to_instrument_symbol = instrument_number_to_symbol(to_instrument)

              if new_instrument_now || new_dynamics_now

                start_instrument_position = _.position - (starts_before[:instrument] || 0)
                finish_instrument_position = start_instrument_position + quantized_duration[:instrument]

                start_dynamics_position = _.position - (starts_before[:dynamics] || 0)
                finish_dynamics_position = start_dynamics_position + quantized_duration[:dynamics]

                segment_q_effective_duration =
                    [finish_instrument_position, finish_dynamics_position].min - _.position

                segment_effective_finish_position = _.position + segment_q_effective_duration

                # relative start and finish position are ratios from 0 (beginning) to 1 (finish)
                #
                segment_relative_start_position_over_instrument_timeline =
                    Rational(_.position - start_instrument_position,
                             finish_instrument_position - start_instrument_position)

                segment_relative_finish_position_over_instrument_timeline =
                    Rational(segment_effective_finish_position - start_instrument_position,
                             finish_instrument_position - start_instrument_position)
                #
                segment_relative_start_position_over_dynamics_timeline =
                    Rational(_.position - start_dynamics_position,
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

                if from_instrument && to_instrument
                  render_dynamics segment_from_dynamics_from_instrument.round(half: :up),
                                  segment_to_dynamics_from_instrument.round(half: :up),
                                  segment_q_effective_duration,
                                  score: score,
                                  instrument: from_instrument_symbol,
                                  position: _.position
                end

                if to_instrument
                  render_dynamics segment_from_dynamics_to_instrument.round(half: :down),
                                  segment_to_dynamics_to_instrument.round(half: :down),
                                  segment_q_effective_duration,
                                  score: score,
                                  instrument: to_instrument_symbol,
                                  position: _.position
                end
              end

              puts
              _.log "new_dynamics_now = #{new_dynamics_now} new_instrument_now = #{new_instrument_now} new_pitch_now = #{new_pitch_now}"
              _.log "from_instrument #{from_instrument_symbol} to_instrument #{to_instrument_symbol}"

              _.log "segment_q_effective_duration #{segment_q_effective_duration&.inspect(base: resolution) || 'nil'}"

              _.log "segment_relative_start_position_over_dynamics_timeline = #{segment_relative_start_position_over_dynamics_timeline&.to_f&.round(2) || 'nil'}"
              _.log "segment_relative_finish_position_over_dynamics_timeline = #{segment_relative_finish_position_over_dynamics_timeline&.to_f&.round(2) || 'nil'}"

              _.log "value[:dynamics] = #{value[:dynamics].to_f.round(2)} delta_dynamics = #{delta_dynamics.to_f.round(2)}"
              _.log "segment_from_dynamics = #{segment_from_dynamics.to_f.round(2)} to_dynamics = #{to_dynamics.to_f.round(2)}"

              _.log "segment_relative_start_position_over_instrument_timeline = #{segment_relative_start_position_over_instrument_timeline&.to_f&.round(2) || 'nil'}"
              _.log "segment_relative_finish_position_over_instrument_timeline = #{segment_relative_finish_position_over_instrument_timeline&.to_f&.round(2) || 'nil'}"

              _.log "#{from_instrument_symbol} segment_from_dynamics #{segment_from_dynamics_from_instrument.to_f.round(2)} to_dynamics #{segment_to_dynamics_from_instrument.to_f.round(2)}"
              _.log "#{to_instrument_symbol} segment_from_dynamics #{segment_from_dynamics_to_instrument.to_f.round(2)} to_dynamics #{segment_to_dynamics_to_instrument.to_f.round(2)}"

              _.log "pitch #{pitch}"
              _.log "duration_instrument #{q_duration_instrument.inspect(base: resolution)}"
              _.log "duration_dynamics #{q_duration_dynamics.inspect(base: resolution)}"
              _.log "duration_pitch #{q_duration_pitch.inspect(base: resolution)}"
              _.log "starts_before dynamics #{starts_before[:dynamics]&.inspect(base: resolution) || 'nil'}"
              _.log "starts_before instrument #{starts_before[:instrument]&.inspect(base: resolution) || 'nil'}"
              _.log "starts_before pitch #{starts_before[:pitch]&.inspect(base: resolution) || 'nil'}"

              q_effective_duration_pitch =
                  [ q_duration_instrument - (starts_before[:instrument] || 0),
                    q_duration_pitch - (starts_before[:pitch] || 0),
                    q_duration_dynamics - (starts_before[:dynamics] || 0)].min

              _.log "effective_duration_pitch #{q_effective_duration_pitch.inspect(base: resolution)}"

              render_pitch pitch,
                           q_effective_duration_pitch,
                           score: score,
                           instrument: from_instrument_symbol,
                           position: _.position,
                           data: "new_dynamics_now = #{new_dynamics_now} new_instrument_now = #{new_instrument_now} new_pitch_now = #{new_pitch_now} from_instrument = #{from_instrument_symbol} pitch = #{pitch} to_instrument = #{to_instrument_symbol} (from)"

              if to_instrument
                render_pitch pitch,
                             q_effective_duration_pitch,
                             score: score,
                             instrument: to_instrument_symbol,
                             position: _.position,
                             data: "new_dynamics_now = #{new_dynamics_now} new_instrument_now = #{new_instrument_now} new_pitch_now = #{new_pitch_now} from_instrument = #{from_instrument_symbol} pitch = #{pitch} to_instrument = #{to_instrument_symbol} (to)"
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



