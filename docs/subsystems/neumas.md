# Neumas & Neumalang - Musical Notation

Neumas provide a compact text-based notation system for musical composition. Neumalang is the parser that converts this notation to structured musical data.

```ruby
require 'musa-dsl'
include Musa::All

using Musa::Extension::Neumas

# Neuma notation requires parentheses around each neuma element.
# Two voices, written in parallel with |
song = "(0 1 mf) (+2 1 mp) (+4 2 p)" |      # Voice 1: melody
       "(+7 2 p) (+5 1 mp) (+7 1 mf)"       # Voice 2: harmony

scale = Scales.et12[440.0].major[60]
decoder = Musa::Neumas::Decoders::NeumaDecoder.new(scale, base_duration: 1r)

# A BaseSequencer runs as fast as it can, which is what makes this example
# runnable. A piece meant to be heard uses a Transport over a real clock; the
# scheduling code is the same.
seq = Musa::Sequencer::BaseSequencer.new(4, 24)
played = []

seq.at(1) do
  seq.play(S(song), decoder: decoder, mode: :neumalang) do |gdv|
    pdv = gdv.to_pdv(scale)
    played << [seq.position, pdv[:pitch], pdv[:duration]]
  end
end

seq.run

played
# => [[(1/1), 60, (1/1)], [(1/1), 72, (2/1)],
#     [(2/1), 64, (1/1)], [(3/1), 81, (1/1)],
#     [(3/1), 71, (2/1)], [(4/1), 93, (1/1)]]
```

Read the pitches down each voice and the point of the `|` appears. Voice 1 is
60, 64, 71 and voice 2 is 72, 81, 93: **each voice keeps its own state**, so the
`+2` of the melody counts from the melody's last note and not from whatever the
harmony just did. One decoder, two independent readings of it.

**And that state outlives the reading.** A decoder handed to a second `play`
brings the first one's last values with it, so a section opening with `(+1)`
counts from wherever the previous section stopped -- which is right for a piece
written as one continuous line, and wrong for sections meant to stand on their
own:

```ruby
scale = Scales.et12[440.0].major[60]

section = lambda do |decoder, neumas|
  seq = Musa::Sequencer::BaseSequencer.new(4, 24)
  grades = []
  seq.at(1) do
    seq.play(neumas.to_neumas, decoder: decoder, mode: :neumalang) { |gdv| grades << gdv[:grade] }
  end
  seq.run
  grades
end

decoder = Musa::Neumas::Decoders::NeumaDecoder.new(scale, base_duration: 1/4r)

section.call(decoder, '(0 1) (+2 1) (+2 1)')   # => [0, 2, 4]
section.call(decoder, '(+1 1)')                # => [5]  (not 1: it counts from 4)

decoder.base = { grade: 0, octave: 0, duration: 1/4r, velocity: 1 }
section.call(decoder, '(+1 1)')                # => [1]
```

Nothing raises and nothing warns: the second section simply sounds transposed.
Setting `decoder.base` at the head of each independent section is what makes its
opening mean what it says.

The pitches also show what a relative step is. `(+7)` from grade 0 in C major is
grade 7 -- the octave, 72 -- and not seven semitones. Steps are **scale
degrees**; the semitones follow from the scale.

And what is NOT there: the events carry `:grade`, `:octave`, `:duration` and
`:velocity`, and nothing that says which voice they came from. Separating the
voices for output is the caller's job -- give each `play` its own block, or
schedule the two strings separately against different MIDI channels.


**Notation syntax:**
- `(0)`, `(+2)`, `(-1)` - Absolute/relative pitch steps (in parentheses)
- `o0`, `o1`, `o-1` - Octave specification
- `1`, `2`, `1/2`, `1/4` - Duration, as a MULTIPLE of the decoder's
  `base_duration` -- not a note figure. `1` is one base_duration, `2` is two,
  `1/2` is half of one
- `ppp`, `pp`, `p`, `mp`, `mf`, `f`, `ff`, `fff` - Dynamics (velocity)
- `+f`, `+ff`, `-p`, `-pp` - Relative dynamics (louder/softer)
- `|` operator - Parallel voices (polyphonic structure)

The duration line is the one that catches people. A neuma's `1` means one
`base_duration`, and `base_duration` is itself a fraction of a BAR:

```ruby
# A lambda and not a `def`: a method body does not see the `scale` bound above it.
durations_with = lambda do |base|
  decoder = Musa::Neumas::Decoders::NeumaDecoder.new(scale, base_duration: base)
  seq = Musa::Sequencer::BaseSequencer.new(4, 24)
  durations = []
  seq.at(1) do
    seq.play("(0 1) (0 2) (0 1/2)".to_neumas, decoder: decoder, mode: :neumalang) do |gdv|
      durations << gdv[:duration]
    end
  end
  seq.run
  durations
end

durations_with[1r]    # => [(1/1), (2/1), (1/2)]
durations_with[1/4r]  # => [(1/4), (1/2), (1/8)]
```

With `base_duration: 1/4r` in a 4/4 bar, a `1` sounds like a quarter note -- which
is why "1 = quarter" reads true and is nonetheless the wrong rule. In 3/4 the
same `1` is a third of a bar.

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

**Classes:**
- `Musa::Neumas` - Musical notation data structures
- `Musa::Neumalang` - Notation parser and interpreter

**Source code:** `lib/musa-dsl/neumas/` and `lib/musa-dsl/neumalang/`

## Sending it somewhere

The examples above run on a `BaseSequencer`, which has no notion of sound. To
hear the same code, put a real clock under a `Transport` and a `MIDIVoices` on
the far side. Nothing about the scheduling changes:

```ruby
require 'midi-communications'

output = MIDICommunications::Output.gets   # asks which port to use
clock = TimerClock.new(bpm: 120, ticks_per_beat: 24)
transport = Transport.new(clock, 4, 24)

voices = MIDIVoices.new(sequencer: transport.sequencer, output: output, channels: [0, 1])

transport.sequencer.with do
  at 1 do
    play S(song), decoder: decoder, mode: :neumalang do |gdv|
      pdv = gdv.to_pdv(scale)
      voices.voices[0].note pitch: pdv[:pitch],
                            velocity: pdv[:velocity],
                            duration: pdv[:duration]
    end
  end
end

transport.start
```
