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
  "v#{number.to_i.to_s}".to_sym
end

def quantize(duration, ticks_per_bar)
  ((duration.rationalize * ticks_per_bar).round / ticks_per_bar).to_r
end

def render_dynamics(intensity0, intensityF, duration, score:, instrument:, position:)
  intensityF ||= intensity0

  score.at position,
           add: { instrument: instrument,
                  type: case intensityF <=> intensity0
                        when 1
                          :crescendo
                        when -1
                          :diminuendo
                        when 0
                          :dynamics
                        end,
                  from: intensity0,
                  to: intensityF,
                  duration: duration }.extend(PS)
end

def render_pitch(pitch, duration, score:, instrument:, position:)
  { instrument: instrument,
    pitch: pitch,
    duration: duration }.extend(PDV).tap { |note| score.at position, add: note }
end
