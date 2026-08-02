# Neuma notation

A more detailed example showing the Neuma notation system:

```ruby
require 'musa-dsl'
require 'midi-communications'

# Include all Musa DSL components
include Musa::All

using Musa::Extension::Neumas

# Create a decoder with a major scale
scale = Scales.et12[440.0].major[60]
decoder = Decoders::NeumaDecoder.new(
  scale,
  base_duration: 1r  # Base duration for explicit duration values
)

# Define a melody using neuma notation with duration and velocity
# Format: (grade duration velocity)
# Durations are multiples of base_duration, which here is 1r -- a bar. So the
# numbers below are fractions of a bar: 1/4 of a bar, 1/2 of a bar, a whole
# bar. In 4/4 those are a quarter, a half and a whole note; in another meter
# they are not, because a bar and a whole note are only the same in 4/4.
# Velocities: pp, p, mp, mf, f, ff
melody = "(0 1/4 p) (+2 1/4 mp) (+2 1/4 mf) (-1 1/2 f) " \
         "(0 1/4 mf) (+4 1/4 mp) (+5 1/2 f) (+7 1/4 ff) " \
         "(+5 1/4 f) (+4 1/4 mf) (+2 1/4 mp) (0 1 p)"

# Decode to GDV (Grade-Duration-Velocity) events
gdv_notes = Neumalang.parse(melody, decode_with: decoder)

# Convert GDV to PDV (Pitch-Duration-Velocity) for playback
pdv_notes = gdv_notes.map { |note| note.to_pdv(scale) }

# Setup MIDI output and sequencer
output = MIDICommunications::Output.gets  # Interactively select output

# Create clock and transport with sequencer
clock = TimerClock.new(bpm: 120, ticks_per_beat: 24)
transport = Transport.new(clock, 4, 24)

# Setup MIDI voices for output
voices = MIDIVoices.new(
  sequencer: transport.sequencer,
  output: output,
  channels: [0]
)
voice = voices.voices.first

# Play notes using sequencer (automatically manages timing)
sequencer = transport.sequencer
sequencer.play(pdv_notes) do |note|
  voice.note pitch: note[:pitch], velocity: note[:velocity], duration: note[:duration]
end

# Start playback
transport.start
```
