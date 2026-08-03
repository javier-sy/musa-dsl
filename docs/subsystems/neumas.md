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

## When is this the answer

Neumas are for writing music **as text you can read and edit as music**: a line
of notation instead of a list of hashes. Reach for them when the material is
melodic and you want to see its shape in the source.

```
'(0 1 mf) (+2 1) (+2 1 st)'
```

Each neuma is `(grade duration velocity ornament)`, and the durations are
multiples of a base duration -- `1` is one base duration, not a quarter note.

**The first grade is absolute and the rest are movements.** That is not a
shorthand: it is what lets the same line be re-rooted anywhere, and it is the
same idea as [GDVd](datasets.md) arriving from the notation side. A decoder is
what resolves those movements, and it is what holds the scale and the base
duration they are read against.

| You have | You want | This |
|---|---|---|
| a melodic line you want to see | it written as notation | a neuma string |
| a neuma string | movements, unresolved, to re-root later | parse without a decoder -- you get GDVd |
| a neuma string | notes in a scale, ready to sound | parse `decode_with:` a `NeumaDecoder` |
| ornaments -- trill, mordent, staccato | them actually performed | a `Transcriptor`; without one they are silently ignored |

**When it is NOT the answer.** Material that is computed rather than written --
a series transformation, a generated sequence, anything where the interesting
thing is the rule and not the notes -- gains nothing from being spelled out as
text. Neumas are for what you would otherwise write on paper.

**And the one that bites:** `using Musa::Extension::Neumas` is a refinement, so
it is **file-scoped**. Declaring it in `main.rb` does not make `.to_neumas`
available in `score.rb`.

## API Reference

**Complete API documentation:**
- [Musa::Neumas](https://rubydoc.info/gems/musa-dsl/Musa/Neumas) - Musical notation data structures
- [Musa::Neumalang](https://rubydoc.info/gems/musa-dsl/Musa/Neumalang) - Notation parser and interpreter

**Source code:** `lib/neumas/` and `lib/neumalang/`


