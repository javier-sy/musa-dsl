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