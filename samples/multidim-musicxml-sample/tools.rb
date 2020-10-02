require_relative '../../lib/musa-dsl'

include Musa::Datasets

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
                  duration: duration }.extend(PS)
end

def render_pitch(pitch, duration, score:, instrument:, position:)
  { instrument: instrument,
    pitch: pitch,
    duration: duration }.extend(PDV).tap { |note| score.at position, add: note }
end

