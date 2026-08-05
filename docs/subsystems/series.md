# Series - Sequence Generators

Series are the fundamental building blocks for generating musical sequences. They provide functional operations for transforming pitches, rhythms, dynamics, and any musical parameter.

## When is this the answer

You have a **succession of values of the same kind** and you want to transform
it, combine it with another, or walk it in time. The signal that you want a
serie is that you are about to write an Array and an `each`.

| You have | You want | This |
|---|---|---|
| a list of grades | to play it | `H(grade: ..., duration: ...)` and `play` |
| three parallel lists -- grades, durations, dynamics | one note per element | `H()`, which joins them by position |
| a phrase | it backwards, rotated, twice | `.reverse`, `.shift`, `.repeat` -- and they compose |
| a phrase | it in two voices reading independently | `.buffered`, then one `.buffer` per voice |
| a rule rather than a list | the values it produces | `FOR`, `FIBO`, `SIN`, `RND`, `E` |
| material that arrives while it is already sounding | to keep playing and take it when it comes | `QUEUE` |
| a constant | to put it next to series that vary | `S(value).repeat` -- a constant is a serie too |

**When it is NOT the answer.** A single value moving continuously towards
another is not a serie: that is `move`. A structure chosen by probability is not
a serie: that is Markov. One singular point in time is not a serie: that is
`at`. And a list you build and consume in the same breath, without transforming
or combining it, is better off an Array.

## Prototype and instance

Every constructor gives a **prototype**: a description of a succession, not a
reading of it. `.i` (or `.instance`) turns it into an **instance**, which is
what actually walks. That is why `.i` appears in every example below, and it is
the one thing that has to be understood before anything else here makes sense.

```ruby
melody = S(0, 2, 4)

melody.state      # => :prototype
melody.i.state    # => :instance
```

A prototype cannot be consumed -- `melody.next_value` raises `PrototypingError`
-- and that refusal is the point: it is what stops two voices sharing an
iterator by accident.

**Two instances of the same prototype are independent**, which is what makes a
template a template:

```ruby
melody = S(1, 2, 3)
a = melody.i
b = melody.i

a.next_value   # => 1
b.next_value   # => 1  (not 2: a and b share nothing)
```

The same holds inside a graph. A prototype used in two branches gives **two**
instances, one per branch, and each is walked separately:

```ruby
material = S(1, 2, 3)

H(x: material, y: material.reverse).i.to_a
# => [{ x: 1, y: 3 }, { x: 2, y: 2 }, { x: 3, y: 1 }]
```

Instantiating an instance gives back the same instance, so `.i` is safe to write
wherever you are unsure -- it never re-reads something already being read.

`.to_a`, on the other hand, **restarts**. It is a way of looking at a whole
succession, not a way of draining what is left of one already being walked:

```ruby
s = S(1, 2, 3).i
s.next_value   # => 1
s.to_a         # => [1, 2, 3]  (not [2, 3]: to_a reads from the start)
```

**A whole graph is one or the other.** `S(1,2,3).map { ... }.repeat` is a
prototype because its source is; instantiating it instantiates everything it
stands on. That is also why a serie built around a `PROXY` whose source is not
set yet has no state at all until it is: there is nothing to decide it from.

## Basic Series Operations

```ruby
require 'musa-dsl'
include Musa::Series

# S constructor: Create series from values
melody = S(0, 2, 4, 5, 7).repeat(2)
melody.i.to_a  # => [0, 2, 4, 5, 7, 0, 2, 4, 5, 7]

# Transform with map
transposed = S(60, 64, 67).map { |n| n + 12 }
transposed.i.to_a  # => [72, 76, 79]

# Filter with select
evens = S(1, 2, 3, 4, 5, 6).select { |n| n.even? }
evens.i.to_a  # => [2, 4, 6]
```

## Combining Multiple Parameters

Use `.with` to combine pitches, durations, and velocities:

```ruby
# Combine pitch, duration, and velocity
pitches = S(60, 64, 67, 72)
durations = S(1r, 1/2r, 1/2r, 1r)
velocities = S(96, 80, 90, 100)

notes = pitches.with(dur: durations, vel: velocities) do |p, dur:, vel:|
  { pitch: p, duration: dur, velocity: vel }
end

notes.i.to_a
# => [{pitch: 60, duration: 1r, velocity: 96},
#     {pitch: 64, duration: 1/2r, velocity: 80},
#     {pitch: 67, duration: 1/2r, velocity: 90},
#     {pitch: 72, duration: 1r, velocity: 100}]
```

**Creating PDV with `H()` and `HC()`:**

When series have different lengths, use `H` (stops at shortest) or `HC` (cycles all series):

```ruby
# Create PDV from series of different sizes
pitches = S(60, 62, 64, 65, 67)      # 5 notes
durations = S(1r, 1/2r, 1/4r)        # 3 durations
velocities = S(96, 80, 90, 100)      # 4 velocities

# H: Stop when shortest series exhausts (3 notes - limited by durations)
notes = H(pitch: pitches, duration: durations, velocity: velocities)

notes.i.to_a
# => [{pitch: 60, duration: 1r, velocity: 96},
#     {pitch: 62, duration: 1/2r, velocity: 80},
#     {pitch: 64, duration: 1/4r, velocity: 90}]

# HC: Continue cycling all series (cycles until common multiple)
notes_cycling = HC(pitch: pitches, duration: durations, velocity: velocities)
  .max_size(7)  # Limit output for readability

notes_cycling.i.to_a
# => [{pitch: 60, duration: 1r, velocity: 96},
#     {pitch: 62, duration: 1/2r, velocity: 80},
#     {pitch: 64, duration: 1/4r, velocity: 90},
#     {pitch: 65, duration: 1r, velocity: 100},
#     {pitch: 67, duration: 1/2r, velocity: 96},
#     {pitch: 60, duration: 1/4r, velocity: 80},
#     {pitch: 62, duration: 1r, velocity: 90}]
```

## Merging Melodic Phrases

Use `MERGE` to concatenate multiple series:

```ruby
# Build melody from phrases
phrase1 = S(60, 64, 67)        # C major triad ascending
phrase2 = S(72, 69, 65)        # Descending from octave
phrase3 = S(60, 62, 64)        # Scale fragment

melody = MERGE(phrase1, phrase2, phrase3)
melody.i.to_a  # => [60, 64, 67, 72, 69, 65, 60, 62, 64]

# Repeat merged structure
section = MERGE(S(1, 2, 3), S(4, 5, 6)).repeat(2)
section.i.to_a  # => [1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6]
```

## Numeric Generators

```ruby
# FOR: Numeric ranges
ascending = FOR(from: 0, to: 7, step: 1)
ascending.i.to_a  # => [0, 1, 2, 3, 4, 5, 6, 7]

descending = FOR(from: 10, to: 0, step: 2)
descending.i.to_a  # => [10, 8, 6, 4, 2, 0]

# FIBO: Fibonacci rhythmic proportions
rhythm = FIBO().max_size(8).map { |n| Rational(n, 16) }
rhythm.i.to_a
# => [1/16r, 1/16r, 1/8r, 3/16r, 5/16r, 1/2r, 13/16r, 21/16r]
# With the `r`: without it Ruby reads `1/16` as integer division and gives 0.

# RND: Random melody with constraints
melody = RND(60, 62, 64, 65, 67, 69, 71, 72)
  .repeat                                           # without it there are only 8
  .remove { |note, history| note == history.last }  # No consecutive repeats
  .max_size(16)                                     # after remove, or the cap
melody.i.to_a.size  # => 16                         # counts what remove throws away

# HARMO: Harmonic series (overtones)
harmonics = HARMO(error: 0.5).max_size(10)
harmonics.i.to_a  # => [0, 12, 19, 24, 28, 31, 34, 36, 38, 40]
```

## Structural Transformations

```ruby
# Reverse: Retrograde motion
melody = S(60, 64, 67, 72)
retrograde = melody.reverse
retrograde.i.to_a  # => [72, 67, 64, 60]

# merge operation: Flatten serie of series
chunks = S(1, 2, 3, 4, 5, 6).cut(2)  # Split into pairs (serie of series)

# Each chunk is a serie, use .merge to flatten
reconstructed = chunks.merge
reconstructed.i.to_a  # => [1, 2, 3, 4, 5, 6]

# Chaining operations
result = S(60, 62, 64, 65, 67, 69, 71, 72)
  .select { |n| n.even? }     # Keep even pitches: [60, 62, 64, 72]
  .map { |n| n + 12 }         # Transpose up octave: [72, 74, 76, 84]
  .reverse                     # Retrograde: [84, 76, 74, 72]
  .repeat(2)                   # Repeat twice

result.i.to_a  # => [84, 76, 74, 72, 84, 76, 74, 72]
```

**Serie Constructors:**
- `S(...)` - Array serie
- `E(&block)` - Serie from evaluation block
- `H(k1: s1, k2: s2, ...)` - Hash serie from series (stops at shortest)
- `HC(k1: s1, k2: s2, ...)` - Hash combined (cycles all series)
- `A(s1, s2, ...)` - Array of series (stops at shortest)
- `AC(s1, s2, ...)` - Array combined (cycles all series)
- `FOR(from:, to:, step:)` - Numeric range generator
- `MERGE(s1, s2, ...)` - Concatenate series sequentially
- `RND(...)` - Random permutation, **not** a die: each value is drawn once and removed, so `RND(1..6)` gives six values and then ends, and `infinite?` is false. Sampling *with* replacement is `RND(...).repeat`, which reshuffles on each pass and is infinite
- `RND1(...)` - Random single value (exhausts after one)
- `SIN(steps:, amplitude:, center:)` - Sinusoidal waveform
- `FIBO(first = 1, second = 1)` - Fibonacci sequence; the seeds are its first two values, so `FIBO()` gives 1, 1, 2, 3, 5..., `FIBO(0, 1)` includes the leading zero and `FIBO(2, 1)` gives the Lucas numbers
- `HARMO(error:, extended:)` - Harmonic series (overtones)

**Serie Operations:**
- `.map(&block)` - Transform each value
- `.select(&block)`, `.remove(&block)` - Filter values
- `.with(*series, &block)` - Combine multiple series
- `.hashify(*keys)` - Convert array values to hash
- `.repeat(times)`, `.autorestart` - Repetition control
- `.reverse` - Reverse order
- `.randomize(random:)` - Randomize order
- `.merge`, `.flatten` - Flatten nested series
- `.cut(length)` - Split into chunks
- `.max_size(n)`, `.skip(n)` - Limit/offset control
- `.shift(n)` - Circular rotation (negative: rotate left, positive: rotate right)
- `.after(*series)` - Concatenate series
- `.switch(*series)`, `.multiplex(*series)` - Switch between series
- `.lock` - Lock/freeze values
- `.anticipate(&block)`, `.lazy(&block)` - Advanced evaluation

## API Reference

**Classes:**
- `Musa::Series` - Sequence generators and operations

**Source code:** `lib/musa-dsl/series/`

## Specialized Series Types

Beyond basic operations, Series provides specialized types for advanced transformations and musical applications.

**BufferSerie** - Multiple Independent Readers:

Enables multiple "readers" to independently iterate over the same series source without interfering with each other. Essential for canonic structures (rounds, fugues), polyphonic playback from a single source, and multi-voice compositions.

```ruby
require 'musa-dsl'
include Musa::Series

# Create buffered melody for canon
melody = S(60, 64, 67, 72, 76).buffered

# Create independent readers (voices)
voice1 = melody.buffer.i
voice2 = melody.buffer.i
voice3 = melody.buffer.i

# Each voice progresses independently
voice1.next_value  # => 60
voice1.next_value  # => 64

voice2.next_value  # => 60 (independent of voice1)
voice3.next_value  # => 60 (independent of others)

voice1.next_value  # => 67
voice2.next_value  # => 64

# Use in canon: play voice2 delayed by 2 beats, voice3 delayed by 4 beats
# Each voice reads the same melodic material at its own pace
```

**QuantizerSerie** - Value Quantization:

Quantizes continuous time-value pairs to discrete steps. Useful for converting MIDI controller data to discrete values, snapping pitch bends to semitones, or generating stepped automation curves.

Two quantization modes:
- **Raw mode**: Rounds values to nearest step with configurable boundary inclusion
- **Predictive mode**: Predicts crossings of quantization boundaries for smooth transitions

```ruby
require 'musa-dsl'
include Musa::Series

# Example 1: Quantize continuous pitch bend to semitones
#
# The hashes have to be AbsTimed: quantize works on a serie of timed values,
# and a bare hash of the right shape is not one -- it raises "Don't know how
# to process".
pitch_bend = S({ time: 0r, value: 60.3 },
               { time: 1r, value: 61.8 },
               { time: 2r, value: 63.1 })
             .map { |v| v.extend(Musa::Datasets::AbsTimed) }

quantized = pitch_bend.quantize(step: 1)  # Quantize to integer semitones

quantized.i.to_a
# => [{ time: 0r, value: 60r, duration: 1/2r },
#     { time: 1/2r, value: 61r, duration: 1/2r },
#     { time: 1r, value: 62r, duration: 1r }]
#
# One step per semitone crossed, and each carries the time it holds: the
# result is a staircase, not a list of samples taken at the input times.
#
# Three steps for an input that spans 60.3 to 63.1: the value is truncated
# to the semitone below, so the input never reaches 63 and the last step is
# 62. And the times are where each crossing happens, not where a sample was
# taken -- 1/2 is halfway between the first two points, because that is
# where the ramp passes 61.

# Example 2: Predictive quantization for smooth crossings
continuous = S({ time: 0r, value: 0 }, { time: 4r, value: 10 })
             .map { |v| v.extend(Musa::Datasets::AbsTimed) }

predicted = continuous.quantize(step: 2, predictive: true)

predicted.i.to_a.first(3)
# => [{ time: 0r, value: 0r, duration: 2/5r },
#     { time: 2/5r, value: 2r, duration: 4/5r },
#     { time: 6/5r, value: 4r, duration: 4/5r }]
#
# The crossings are where the ramp actually reaches each step, so the
# durations are uneven: 2/5 of a bar to climb the first unit, 4/5 for each
# of the rest.
```

**TimedSerie Operations** - Time-Based Merging:

Operations for series with explicit `:time` attributes. Enables multi-track MIDI sequencing, polyphonic event streams, and synchronized parameter automation.

```ruby
require 'musa-dsl'
include Musa::Series

# Create independent melodic lines with timing
melody = S({ time: 0r, value: 60 },
           { time: 1r, value: 64 },
           { time: 2r, value: 67 })

bass = S({ time: 0r, value: 36 },
         { time: 2r, value: 38 },
         { time: 4r, value: 41 })

harmony = S({ time: 0r, value: 64 },
            { time: 2r, value: 67 })

# Merge by time using TIMED_UNION (hash mode)
combined = TIMED_UNION(melody: melody, bass: bass, harmony: harmony)

combined.i.to_a
# => [{ time: 0r, value: { melody: 60, bass: 36, harmony: 64 } },
#     { time: 1r, value: { melody: 64, bass: nil, harmony: nil } },
#     { time: 2r, value: { melody: 67, bass: 38, harmony: 67 } },
#     { time: 4r, value: { melody: nil, bass: 41, harmony: nil } }]

# Array mode for unnamed voices
voice1 = S({ time: 0r, value: 60 }, { time: 1r, value: 64 })
voice2 = S({ time: 0r, value: 48 }, { time: 1r, value: 52 })

merged = TIMED_UNION(voice1, voice2)

merged.i.to_a
# => [{ time: 0r, value: [60, 48] },
#     { time: 1r, value: [64, 52] }]

# Flatten timed values
multi = S({ time: 0r, value: { soprano: 60, alto: 64 } })
flat = multi.flatten_timed.i.next_value
# => { soprano: { time: 0r, value: 60 },
#      alto: { time: 0r, value: 64 } }

# Compact removes nil values
sparse = S({ time: 0r, value: [60, nil, 67] })
compact = sparse.compact_timed.i.to_a
# Removes entries where all values are nil
```


