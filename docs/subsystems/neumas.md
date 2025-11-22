# Neumas & Neumalang - Musical Notation

Neumas provide a compact text-based notation system for musical composition. Neumalang is the parser that converts this notation to structured musical data.

```ruby
require 'musa-dsl'
require 'midi-communications'

# To play the song, decode neumas to GDV and convert to PDV
include Musa::All

using Musa::Extension::Neumas

# Neuma notation requires parentheses around each neuma element
# Parsed using Musa::Neumalang::Neumalang.parse()

# Complete example with durations and dynamics (parallel voices using |)
song = "(0 1 mf) (+2 1 mp) (+4 2 p) (+5 1/2 mf) (+7 1 f)" |      # Voice 1: melody with varied dynamics
       "(+7 2 p) (+5 1 mp) (+7 1 mf) (+9 1/2 f) (+12 2 ff)"      # Voice 2: harmony with crescendo

# Wrap parallel structure in serie
song_serie = S(song)

# Create decoder with a scale
scale = Scales.et12[440.0].major[60]
decoder = Decoders::NeumaDecoder.new(scale, base_duration: 1r)

# Setup sequencer with clock and transport
output = MIDICommunications::Output.gets

clock = TimerClock.new(bpm: 120, ticks_per_beat: 24)
transport = Transport.new(clock, 4, 24)

voices = MIDIVoices.new(sequencer: transport.sequencer, output: output, channels: [0, 1])

# Play both voices simultaneously - sequencer handles parallel structure automatically
transport.sequencer.with do
  at 1 do
    play song_serie, decoder: decoder, mode: :neumalang do |gdv|
      # Convert GDV to PDV for MIDI output
      pdv = gdv.to_pdv(scale)

      # Use voice based on channel assignment (sequencer maintains voice separation)
      voice_index = gdv[:channel] || 0
      voices.voices[voice_index].note pitch: pdv[:pitch],
                                      velocity: pdv[:velocity],
                                      duration: pdv[:duration]
    end
  end
end

transport.start
```

**Notation syntax:**
- `(0)`, `(+2)`, `(-1)` - Absolute/relative pitch steps (in parentheses)
- `o0`, `o1`, `o-1` - Octave specification
- `1`, `2`, `1/2`, `1/4` - Duration (whole, double, half, quarter)
- `ppp`, `pp`, `p`, `mp`, `mf`, `f`, `ff`, `fff` - Dynamics (velocity)
- `+f`, `+ff`, `-p`, `-pp` - Relative dynamics (louder/softer)
- `|` operator - Parallel voices (polyphonic structure)

**Documentation:** See `lib/neumas/` and `lib/neumalang/`


