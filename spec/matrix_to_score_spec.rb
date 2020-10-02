require 'spec_helper'

require 'musa-dsl'
require 'matrix'

using Musa::Extension::Matrix
using Musa::Extension::InspectNice

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

def instrument_number_to_symbol(number)
  return nil if number.nil?
  "vln#{number.to_i.to_s}".to_sym
end

def render_dynamics(dynamics0, dynamicsF, duration, score:, instrument:, position:)
  dynamicsF ||= dynamics0

  score.at position,
           add: { instrument: instrument,
                  type: case dynamicsF <=> dynamics0
                        when 1
                          :crescendo
                        when -1
                          :diminuendo
                        when 0
                          :dynamics
                        end,
                  from: dynamics0,
                  to: dynamicsF,
                  duration: duration }.extend(Musa::Datasets::PS)
end

def render_pitch(pitch, duration, score:, instrument:, position:)
  { instrument: instrument,
    pitch: pitch,
    duration: duration }.extend(Musa::Datasets::PDV).tap { |note| score.at position, add: note }
end

RSpec.describe Musa::Matrix do
  context 'Matrix to score transformation' do

    # [quarter-notes position, pitch, dynamics, instrument]

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

    expected1 =
        {
            # instrument vln0
            # ---------------
            #
            vln0: {
                1r => [
                    { instrument: :vln0, type: :dynamics, from: 6r, to: 6r, duration: 4r },
                    { instrument: :vln0, pitch: 60r, duration: 4r } ],
                5r => [
                    { instrument: :vln0, type: :crescendo, from: 6r, to: 7r, duration: 2r },
                    { instrument: :vln0, pitch: 60r, duration: 2r } ],
                7r => [
                    { instrument: :vln0, type: :crescendo, from: 7r, to: 8r, duration: 2r },
                    { instrument: :vln0, pitch: 60r, duration: 2r } ],
                9r => [
                    { instrument: :vln0, type: :diminuendo, from: 8r, to: 0r, duration: 51/64r },
                    { instrument: :vln0, pitch: 60r, duration: 51/64r } ],
                30+1/2r => [
                    { instrument: :vln0, type: :crescendo, from: 0r, to: 4+1/2r, duration: 3/4r },
                    { instrument: :vln0, pitch: 66r, duration: 3/4r } ],
                31+1/4r => [
                    { instrument: :vln0, type: :diminuendo, from: 4+1/2r, to: 4r, duration: 3/4r },
                    { instrument: :vln0, pitch: 66r, duration: 3/4r } ],
                32r => [
                    { instrument: :vln0, type: :crescendo, from: 4r, to: 5r, duration: 1/2r },
                    { instrument: :vln0, pitch: 66r, duration: 1/2r } ],
                32+1/2r => [
                    { instrument: :vln0, type: :crescendo, from: 5r, to: 6r, duration: 1/2r },
                    { instrument: :vln0, pitch: 66r, duration: 1/2r } ],
                33r => [
                    { instrument: :vln0, type: :diminuendo, from: 6r, to: 0r, duration: 1+85/128r },
                    { instrument: :vln0, pitch: 66r, duration: 1r } ],
                34r => [
                    { instrument: :vln0, pitch: 65r, duration: 85/128r } ]
            },

            # instrument vln1
            # ---------------
            #
            vln1: {
                9r => [
                    { instrument: :vln1, type: :crescendo, from: 0r, to: 8r, duration: 51/64r },
                    { instrument: :vln1, pitch: 60r, duration: 51/64r } ],
                9+51/64r => [
                    { instrument: :vln1, type: :diminuendo, from: 8r, to: 0r, duration: 103/128r },
                    { instrument: :vln1, pitch: 60r, duration: 103/128r } ],
                29+3/4r => [
                    { instrument: :vln1, type: :crescendo, from: 0r, to: 5r, duration: 3/4r },
                    { instrument: :vln1, pitch: 66r, duration: 3/4r } ],
                30+1/2r => [
                    { instrument: :vln1, type: :diminuendo, from: 5r, to: 0r, duration: 3/4r },
                    { instrument: :vln1, pitch: 66r, duration: 3/4r } ],
                33r => [
                    { instrument: :vln1, type: :crescendo, from: 0r, to: 6+213/320r, duration: 1+85/128r },
                    { instrument: :vln1, pitch: 66r, duration: 1r } ],
                34r => [
                    { instrument: :vln1, pitch: 65r, duration: 85/128r } ],
                34+85/128r => [
                    { instrument: :vln1, type: :diminuendo, from: 6+213/320r, to: 3+1/2r, duration: 107/128r },
                    { instrument: :vln1, pitch: 65r, duration: 43/128r } ],
                35r => [
                    { instrument: :vln1, pitch: 64r, duration: 1/2r } ],
                35+1/2r => [
                    { instrument: :vln1, type: :diminuendo, from: 3+1/2r, to: 0r, duration: 107/128r },
                    { instrument: :vln1, pitch: 64r, duration: 1/2r } ],
                36r => [
                    { instrument: :vln1, pitch: 63r, duration: 43/128r } ]
            },

            # instrument vln2
            # ---------------
            #
            vln2: {
                9+51/64r => [
                    { instrument: :vln2, type: :crescendo, from: 0r, to: 8r, duration: 103/128r },
                    { instrument: :vln2, pitch: 60r, duration: 103/128r } ],
                10+77/128r => [
                    { instrument: :vln2, type: :diminuendo, from: 8r, to: 0r, duration: 51/64r },
                    { instrument: :vln2, pitch: 60r, duration: 51/64r } ],
                18+43/128r => [
                    { instrument: :vln2, type: :crescendo, from: 0r, to: 3+1/2r, duration: 85/128r },
                    { instrument: :vln2, pitch: 67r, duration: 85/128r } ],
                19r => [
                    { instrument: :vln2, type: :crescendo, from: 3+1/2r, to: 6+171/256r, duration: 85/128r },
                    { instrument: :vln2, pitch: 67r, duration: 85/128r } ],
                19+85/128r => [
                    { instrument: :vln2, type: :diminuendo, from: 6+171/256r, to: 6r, duration: 1+43/128r },
                    { instrument: :vln2, pitch: 67r, duration: 1+43/128r } ],
                21r => [
                    { instrument: :vln2, type: :diminuendo, from: 6r, to: 0r, duration: 1+43/128r },
                    { instrument: :vln2, pitch: 67r, duration: 1+43/128r } ],
                29r => [
                    { instrument: :vln2, type: :crescendo, from: 0r, to: 5+1/2r, duration: 3/4r },
                    { instrument: :vln2, pitch: 66r, duration: 3/4r } ],
                29+3/4r => [
                    { instrument: :vln2, type: :diminuendo, from: 5+1/2r, to: 0r, duration: 3/4r },
                    { instrument: :vln2, pitch: 66r, duration: 3/4r } ],
                34+85/128r => [
                    { instrument: :vln2, type: :crescendo, from: 0r, to: 3+1/2r, duration: 107/128r },
                    { instrument: :vln2, pitch: 65r, duration: 43/128r } ],
                35r => [
                    { instrument: :vln2, pitch: 64r, duration: 1/2r } ],
                35+1/2r => [
                    { instrument: :vln2, type: :crescendo, from: 3+1/2r, to: 7+107/320r, duration: 107/128r },
                    { instrument: :vln2, pitch: 64r, duration: 1/2r } ],
                36r => [
                    { instrument: :vln2, pitch: 63r, duration: 43/128r } ],
                36+43/128r => [
                    { instrument: :vln2, type: :diminuendo, from: 7+107/320r, to: 0r, duration: 1+85/128r },
                    { instrument: :vln2, pitch: 63r, duration: 85/128r } ],
                37r => [
                    { instrument: :vln2, pitch: 62r, duration: 1r } ]
            },

            # instrument vln3
            # ---------------
            #
            vln3: {
                10+77/128r => [
                    { instrument: :vln3, type: :crescendo, from: 0r, to: 8r, duration: 51/64r },
                    { instrument: :vln3, pitch: 60r, duration: 51/64r } ],
                11+51/128r => [
                    { instrument: :vln3, type: :diminuendo, from: 8r, to: 0r, duration: 103/128r },
                    { instrument: :vln3, pitch: 60r, duration: 103/128r } ],
                17r => [
                    { instrument: :vln3, type: :crescendo, from: 0r, to: 7+85/256r, duration: 1+43/128r },
                    { instrument: :vln3, pitch: 67r, duration: 1+43/128r } ],
                18+43/128r => [
                    { instrument: :vln3, type: :diminuendo, from: 7+85/256r, to: 3+1/2r, duration: 85/128r },
                    { instrument: :vln3, pitch: 67r, duration: 85/128r } ],
                19r => [
                    { instrument: :vln3, type: :diminuendo, from: 3+1/2r, to: 0r, duration: 85/128r },
                    { instrument: :vln3, pitch: 67r, duration: 85/128r } ],
                21r => [
                    { instrument: :vln3, type: :crescendo, from: 0r, to: 6r, duration: 1+43/128r },
                    { instrument: :vln3, pitch: 67r, duration: 1+43/128r } ],
                22+43/128r => [
                    { instrument: :vln3, type: :diminuendo, from: 6r, to: 0r, duration: 1+21/64r },
                    { instrument: :vln3, pitch: 67r, duration: 1+21/64r } ],
                25r => [
                    { instrument: :vln3, type: :crescendo, from: 0r, to: 6r, duration: 2r },
                    { instrument: :vln3, pitch: 67r, duration: 2r } ],
                27r => [
                    { instrument: :vln3, type: :dynamics, from: 6r, to: 6r, duration: 2r },
                    { instrument: :vln3, pitch: 66r, duration: 2r } ],
                29r => [
                    { instrument: :vln3, type: :diminuendo, from: 6r, to: 0r, duration: 3/4r },
                    { instrument: :vln3, pitch: 66r, duration: 3/4r } ],
                36+43/128r => [
                    { instrument: :vln3, type: :crescendo, from: 0r, to: 8r, duration: 1+85/128r },
                    { instrument: :vln3, pitch: 63r, duration: 85/128r } ],
                37r => [
                    { instrument: :vln3, pitch: 62r, duration: 1r } ],
                38r => [
                    { instrument: :vln3, type: :diminuendo, from: 8r, to: 0r, duration: 1+85/128r },
                    { instrument: :vln3, pitch: 61r, duration: 1r } ],
                39r => [
                    { instrument: :vln3, pitch: 60r, duration: 85/128r } ]
            },

            # instrument vln4
            # ---------------
            #
            vln4: {
                11+51/128r => [
                    { instrument: :vln4, type: :crescendo, from: 0r, to: 8r, duration: 103/128r },
                    { instrument: :vln4, pitch: 60r, duration: 103/128r } ],
                12+13/64r => [
                    { instrument: :vln4, type: :dynamics, from: 8r, to: 8r, duration: 51/64r },
                    { instrument: :vln4, pitch: 60r, duration: 51/64r } ],
                13r => [
                    { instrument: :vln4, type: :dynamics, from: 8r, to: 8r, duration: 4r },
                    { instrument: :vln4, pitch: 60r, duration: 1/2r } ],
                13+1/2r => [
                    { instrument: :vln4, pitch: 61r, duration: 1/2r } ],
                14r => [
                    { instrument: :vln4, pitch: 62r, duration: 1/2r } ],
                14+1/2r => [
                    { instrument: :vln4, pitch: 63r, duration: 1/2r } ],
                15r => [
                    { instrument: :vln4, pitch: 64r, duration: 1/2r } ],
                15+1/2r => [
                    { instrument: :vln4, pitch: 65r, duration: 1/2r } ],
                16r => [
                    { instrument: :vln4, pitch: 66r, duration: 1/2r } ],
                16+1/2r => [
                    { instrument: :vln4, pitch: 67r, duration: 1/2r } ],
                17r => [
                    { instrument: :vln4, type: :diminuendo, from: 8r, to: 0r, duration: 1+43/128r },
                    { instrument: :vln4, pitch: 67r, duration: 1+43/128r } ],
                22+43/128r => [
                    { instrument: :vln4, type: :crescendo, from: 0r, to: 6r, duration: 1+21/64r },
                    { instrument: :vln4, pitch: 67r, duration: 1+21/64r } ],
                23+85/128r => [
                    { instrument: :vln4, type: :dynamics, from: 6r, to: 6r, duration: 1+43/128r },
                    { instrument: :vln4, pitch: 67r, duration: 1+43/128r } ],
                25r => [
                    { instrument: :vln4, type: :diminuendo, from: 6r, to: 0r, duration: 2r },
                    { instrument: :vln4, pitch: 67r, duration: 2r } ],
                38r => [
                    { instrument: :vln4, type: :crescendo, from: 0r, to: 8+213/320r, duration: 1+85/128r },
                    { instrument: :vln4, pitch: 61r, duration: 1r } ],
                39r => [
                    { instrument: :vln4, pitch: 60r, duration: 85/128r } ],
                39+85/128r => [
                    { instrument: :vln4, type: :diminuendo, from: 8+213/320r, to: 4+1/2r, duration: 107/128r },
                    { instrument: :vln4, pitch: 60r, duration: 43/128r } ],
                40r => [
                    { instrument: :vln4, pitch: 59r, duration: 1/2r } ],
                40+1/2r => [
                    { instrument: :vln4, type: :diminuendo, from: 4+1/2r, to: 0r, duration: 107/128r },
                    { instrument: :vln4, pitch: 59r, duration: 1/2r } ],
                41r => [
                    { instrument: :vln4, pitch: 58r, duration: 43/128r } ]
            },

            # instrument vln5
            # ---------------
            #
            vln5: {
                39+85/128r => [
                    { instrument: :vln5, type: :crescendo, from: 0r, to: 4+1/2r, duration: 107/128r },
                    { instrument: :vln5, pitch: 60r, duration: 43/128r } ],
                40r => [
                    { instrument: :vln5, pitch: 59r, duration: 1/2r } ],
                40+1/2r => [
                    { instrument: :vln5, type: :crescendo, from: 4+1/2r, to: 9+107/320r, duration: 107/128r },
                    { instrument: :vln5, pitch: 59r, duration: 1/2r } ],
                41r => [
                    { instrument: :vln5, pitch: 58r, duration: 43/128r } ],
                41+43/128r => [
                    { instrument: :vln5, type: :crescendo, from: 9+107/320r, to: 10r, duration: 1+85/128r },
                    { instrument: :vln5, pitch: 58r, duration: 85/128r } ],
                42r => [
                    { instrument: :vln5, pitch: 57r, duration: 1r } ],
                43r => [
                    { instrument: :vln5, type: :dynamics, from: 10r, to: 10r, duration: 4r },
                    { instrument: :vln5, pitch: 57r, duration: 4r } ]
            }
        }

    it 'Several steps sample conversion' do

      beats_per_bar = 4r
      ticks_per_beat = 32r

      score = poly_line.to_score(:time,
                                 mapper: [:time, :pitch, :dynamics, :instrument],
                                 right_open: { dynamics: true },
                                 beats_per_bar: beats_per_bar, ticks_per_beat: ticks_per_beat,
                                 do_log: false) do
      | value, next_value,
          position:,
          duration:,
          quantized_duration:,
          position_jitter:, duration_jitter:,
          started_ago:,
          score:,
          logger: |

        logger.debug
        logger.debug "new element on position #{position}\n\tvalue #{value}\n\tnext #{next_value}\n\tduration #{duration}" \
               "\n\tquantized_duration #{quantized_duration}\n\tstarted_ago #{started_ago}"\
               "\n\tposition_jitter #{position_jitter}\n\tduration_jitter #{duration_jitter}"

        new_instrument_now = !started_ago[:instrument]
        new_dynamics_now = !started_ago[:dynamics]
        new_pitch_now = !started_ago[:pitch]

        logger.debug
        logger.debug "new_dynamics_now #{new_dynamics_now} new_instrument_now #{new_instrument_now} new_pitch_now #{new_pitch_now}"

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

            logger.debug "from_instrument #{from_instrument_symbol} to_instrument #{to_instrument_symbol || 'nil'}"

            logger.debug "segment_q_effective_duration #{segment_q_effective_duration&.inspect || 'nil'}"

            logger.debug "segment_relative_start_position_over_dynamics_timeline #{segment_relative_start_position_over_dynamics_timeline&.to_f&.round(2) || 'nil'}"
            logger.debug "segment_relative_finish_position_over_dynamics_timeline #{segment_relative_finish_position_over_dynamics_timeline&.to_f&.round(2) || 'nil'}"

            logger.debug "value[:dynamics] #{value[:dynamics].to_f.round(2)} delta_dynamics #{delta_dynamics.to_f.round(2)}"
            logger.debug "segment_from_dynamics #{segment_from_dynamics.to_f.round(2)} to_dynamics #{to_dynamics.to_f.round(2)}"

            logger.debug "segment_relative_start_position_over_instrument_timeline #{segment_relative_start_position_over_instrument_timeline&.to_f&.round(2) || 'nil'}"
            logger.debug "segment_relative_finish_position_over_instrument_timeline #{segment_relative_finish_position_over_instrument_timeline&.to_f&.round(2) || 'nil'}"

            logger.debug "#{from_instrument_symbol} segment_from_dynamics #{segment_from_dynamics_from_instrument.to_f.round(2)} to_dynamics #{segment_to_dynamics_from_instrument.to_f.round(2)}"
            logger.debug "#{to_instrument_symbol || 'nil'} segment_from_dynamics #{segment_from_dynamics_to_instrument.to_f.round(2)} to_dynamics #{segment_to_dynamics_to_instrument.to_f.round(2)}"

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

          logger.debug "pitch #{pitch}"

          q_effective_duration_pitch =
              [ q_duration_instrument - (started_ago[:instrument] || 0),
                q_duration_pitch - (started_ago[:pitch] || 0),
                q_duration_dynamics - (started_ago[:dynamics] || 0)].min

          logger.debug "effective_duration_pitch #{q_effective_duration_pitch.inspect}"

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

      do_output = false

      if do_output
        puts
        puts "# score"
        puts "# -----"
        puts "#"
        puts "{"
        first = true
        score.values_of(:instrument).each do |instrument|
          puts "," unless first
          first = false
          puts
          puts "# #{msg = "instrument #{instrument}"}"
          puts "# #{ '-'* msg.size }"
          puts "#"
          STDOUT.write instrument.to_s + ": " + score.subset { |dataset| dataset[:instrument] == instrument }.inspect
        end
        puts
        puts "}"
      end

      expect(score.subset { |dataset| dataset[:instrument] == :vln0 }.to_h).to eq(expected1[:vln0])
      expect(score.subset { |dataset| dataset[:instrument] == :vln1 }.to_h).to eq(expected1[:vln1])
      expect(score.subset { |dataset| dataset[:instrument] == :vln2 }.to_h).to eq(expected1[:vln2])
      expect(score.subset { |dataset| dataset[:instrument] == :vln3 }.to_h).to eq(expected1[:vln3])
      expect(score.subset { |dataset| dataset[:instrument] == :vln4 }.to_h).to eq(expected1[:vln4])
      expect(score.subset { |dataset| dataset[:instrument] == :vln5 }.to_h).to eq(expected1[:vln5])
    end
  end
end
