require_relative '../../lib/musa-dsl'
require_relative 'tools'

require 'matrix'

include Musa::Sequencer
include Musa::Datasets
include Musa::Series

using Musa::Extension::Matrix
using Musa::Extension::InspectNice

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

s = BaseSequencer.new beats_per_bar, ticks_per_beat, do_log: true, do_error_log: true
logger = s.logger
score = Score.new

mapper = [:pitch, :dynamics, :instrument]

s.at 1 do
  poly_line.to_p(time_dimension: 0).each do |line|

    puts "line = #{line}\n\n"

    values = {}
    next_values = {}
    quantized_durations = {}

    u = TIMED_UNION(
        **line.map { |v| v.to_packed_V(mapper) }
              .to_timed_serie
              .flatten_timed
              .split
              .to_h
              .collect { |key, serie|
                [ key,
                  serie.quantize(stops: true)
                      .anticipate { |c, n|
                        n ? c.clone.tap { |_| _[:next_value] = (c[:value] == n[:value]) ? nil : n[:value] } :
                            c } ] }.to_h )

    s.play_timed(u) do |value, next_value:, duration:, started_ago:|
      quantized_duration =
          duration.keys.collect do |component|
            [component, s.quantize_position(s.position + duration[component]) - s.position]
          end.to_h

      logger.debug
      logger.debug "new element at position #{s.position.inspect}\n\t\tvalue #{value}\n\t\tnext #{next_value}\n\t\tduration #{duration}" \
               "\n\t\tquantized_duration #{quantized_duration}\n\t\tstarted_ago #{started_ago}\n"

      new_instrument_now = !started_ago[:instrument]
      new_dynamics_now = !started_ago[:dynamics]
      new_pitch_now = !started_ago[:pitch]

      # logger.debug
      # logger.debug "new_dynamics_now #{new_dynamics_now} new_instrument_now #{new_instrument_now} new_pitch_now #{new_pitch_now}"

      value.each_pair do |component, value|
        values[component] = value
      end

      next_value.each_pair do |component, value|
        next_values[component] = value
      end

      quantized_duration.each_pair do |component, duration|
        quantized_durations[component] = duration
      end

      if new_instrument_now || new_dynamics_now || new_pitch_now

        q_duration_instrument = quantized_durations[:instrument]
        q_duration_dynamics = quantized_durations[:dynamics]
        q_duration_pitch = quantized_durations[:pitch]

        from_instrument = values[:instrument]
        to_instrument = next_values[:instrument]

        from_instrument_symbol = instrument_number_to_symbol(from_instrument)
        to_instrument_symbol = instrument_number_to_symbol(to_instrument)

        to_dynamics = next_values[:dynamics]

        pitch = values[:pitch]

        if new_instrument_now || new_dynamics_now

          start_instrument_position = s.position - (started_ago[:instrument] || 0)
          finish_instrument_position = start_instrument_position + quantized_durations[:instrument]

          start_dynamics_position = s.position - (started_ago[:dynamics] || 0)
          finish_dynamics_position = start_dynamics_position + quantized_durations[:dynamics]

          segment_q_effective_duration =
              [finish_instrument_position, finish_dynamics_position].min - s.position

          segment_effective_finish_position = s.position + segment_q_effective_duration

          # relative start and finish position are ratios from 0 (beginning) to 1 (finish)
          #

          # for instrument
          #
          if finish_instrument_position == start_instrument_position
            segment_relative_start_position_over_instrument_timeline = 0r
            segment_relative_finish_position_over_instrument_timeline = 1r
          else
            segment_relative_start_position_over_instrument_timeline =
                Rational(s.position - start_instrument_position,
                         finish_instrument_position - start_instrument_position)

            segment_relative_finish_position_over_instrument_timeline =
                Rational(segment_effective_finish_position - start_instrument_position,
                         finish_instrument_position - start_instrument_position)

          end

          # for dynamics
          #
          if finish_dynamics_position == start_dynamics_position
            segment_relative_start_position_over_dynamics_timeline = 0r
            segment_relative_finish_position_over_dynamics_timeline = 1r
          else
            segment_relative_start_position_over_dynamics_timeline =
                Rational(s.position - start_dynamics_position,
                         finish_dynamics_position - start_dynamics_position)

            segment_relative_finish_position_over_dynamics_timeline =
                Rational(segment_effective_finish_position - start_dynamics_position,
                         finish_dynamics_position - start_dynamics_position)
          end

          delta_dynamics = (next_values[:dynamics] || values[:dynamics]) - values[:dynamics]

          segment_from_dynamics =
              values[:dynamics] +
                  delta_dynamics * segment_relative_start_position_over_dynamics_timeline

          segment_to_dynamics =
              values[:dynamics] +
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

          # logger.debug "from_instrument #{from_instrument_symbol} to_instrument #{to_instrument_symbol || 'nil'}"
          #
          # logger.debug "segment_q_effective_duration #{segment_q_effective_duration&.inspect || 'nil'}"
          #
          # logger.debug "segment_relative_start_position_over_dynamics_timeline #{segment_relative_start_position_over_dynamics_timeline&.to_f&.round(2) || 'nil'}"
          # logger.debug "segment_relative_finish_position_over_dynamics_timeline #{segment_relative_finish_position_over_dynamics_timeline&.to_f&.round(2) || 'nil'}"
          #
          # logger.debug "value[:dynamics] #{values[:dynamics].to_f.round(2)} delta_dynamics #{delta_dynamics.to_f.round(2)}"
          # logger.debug "segment_from_dynamics #{segment_from_dynamics.to_f.round(2)} to_dynamics #{to_dynamics.to_f.round(2)}"
          #
          # logger.debug "segment_relative_start_position_over_instrument_timeline #{segment_relative_start_position_over_instrument_timeline&.to_f&.round(2) || 'nil'}"
          # logger.debug "segment_relative_finish_position_over_instrument_timeline #{segment_relative_finish_position_over_instrument_timeline&.to_f&.round(2) || 'nil'}"
          #
          # logger.debug "#{from_instrument_symbol} segment_from_dynamics #{segment_from_dynamics_from_instrument.to_f.round(2)} to_dynamics #{segment_to_dynamics_from_instrument.to_f.round(2)}"
          # logger.debug "#{to_instrument_symbol || 'nil'} segment_from_dynamics #{segment_from_dynamics_to_instrument.to_f.round(2)} to_dynamics #{segment_to_dynamics_to_instrument.to_f.round(2)}"
          #
          if from_instrument && to_instrument
            logger.debug "rendering dynamics for instrument change: new_dynamics_now #{new_dynamics_now} new_instrument_now #{new_instrument_now}"

            render_dynamics segment_from_dynamics_from_instrument,
                            segment_to_dynamics_from_instrument,
                            segment_q_effective_duration,
                            score: score,
                            instrument: from_instrument_symbol,
                            position: s.position

            render_dynamics segment_from_dynamics_to_instrument,
                            segment_to_dynamics_to_instrument,
                            segment_q_effective_duration,
                            score: score,
                            instrument: to_instrument_symbol,
                            position: s.position
          end

          if from_instrument && !to_instrument
            logger.debug "rendering dynamics without instrument change: new_dynamics_now #{new_dynamics_now} new_instrument_now #{new_instrument_now}"

            render_dynamics segment_from_dynamics,
                            segment_to_dynamics,
                            segment_q_effective_duration,
                            score: score,
                            instrument: from_instrument_symbol,
                            position: s.position
          end
        end

        logger.debug "pitch #{pitch}"
        logger.debug "q_duration_pitch #{q_duration_pitch.inspect} q_duration_dynamics #{q_duration_dynamics.inspect} q_duration_instrument #{q_duration_instrument.inspect}"
        logger.debug "started_ago #{started_ago.inspect}"

        q_effective_duration_pitch =
            [ q_duration_instrument - (started_ago[:instrument] || 0),
              q_duration_pitch - (started_ago[:pitch] || 0),
              q_duration_dynamics - (started_ago[:dynamics] || 0)].min

        logger.debug "effective_duration_pitch #{q_effective_duration_pitch.inspect}"

        render_pitch pitch,
                     q_effective_duration_pitch,
                     score: score,
                     instrument: from_instrument_symbol,
                     position: s.position

        if to_instrument
          render_pitch pitch,
                       q_effective_duration_pitch,
                       score: score,
                       instrument: to_instrument_symbol,
                       position: s.position
        end

      end
    end
  end
end

s.run

puts "\nscore created\n"
puts
puts score.inspect

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
                     do_log: false)

f = File.join(File.dirname(__FILE__), "multidim_sample2.musicxml")
File.open(f, 'w') { |f| f.write(mxml.to_xml.string) }
puts "Created sample MusicXML file #{f}"
