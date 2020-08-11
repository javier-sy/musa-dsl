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

def quantize(duration, ticks_per_bar)
  ((duration.rationalize * ticks_per_bar).round / ticks_per_bar).to_r
end

def render_dynamics(dynamics0, dynamicsF, duration, score:, instrument:, position:)
  dynamicsF ||= dynamics0

  score.at position,
           add: s = { instrument: instrument,
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

def render_pitch(pitch, duration, score:, instrument:, position:, data: nil)
  { instrument: instrument,
    pitch: pitch,
    duration: duration,
    data: data }.extend(PDV).tap { |note| score.at position, add: note }
end

class Rational
  def inspect(base: nil, digits: nil)
    if base
      factor = base.denominator / denominator
      n = numerator * factor
      d = base.denominator
    else
      n = numerator
      d = denominator
    end

    if base
      denominator_digits = Math.log10(d).to_i + 1
      numerator_digits = 1 # denominator_digits + 2
    else
      digits ||= 1.1

      numerator_digits = digits.to_i
      denominator_digits = ((digits - numerator_digits) * 10).round
    end

    "(%#{numerator_digits}s/%#{denominator_digits}s)" % [n, d]
  end
end

