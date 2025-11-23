# Series - Sequence Generators

Series are the fundamental building blocks for generating musical sequences. They provide functional operations for transforming pitches, rhythms, dynamics, and any musical parameter.

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
# => [{pitch: 60, duration: 1, velocity: 96},
#     {pitch: 64, duration: 1/2, velocity: 80},
#     {pitch: 67, duration: 1/2, velocity: 90},
#     {pitch: 72, duration: 1, velocity: 100}]
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
# => [{pitch: 60, duration: 1, velocity: 96},
#     {pitch: 62, duration: 1/2, velocity: 80},
#     {pitch: 64, duration: 1/4, velocity: 90}]

# HC: Continue cycling all series (cycles until common multiple)
notes_cycling = HC(pitch: pitches, duration: durations, velocity: velocities)
  .max_size(7)  # Limit output for readability

notes_cycling.i.to_a
# => [{pitch: 60, duration: 1, velocity: 96},
#     {pitch: 62, duration: 1/2, velocity: 80},
#     {pitch: 64, duration: 1/4, velocity: 90},
#     {pitch: 65, duration: 1, velocity: 100},
#     {pitch: 67, duration: 1/2, velocity: 96},
#     {pitch: 60, duration: 1/4, velocity: 80},
#     {pitch: 62, duration: 1, velocity: 90}]
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
# => [1/16, 1/16, 1/8, 3/16, 5/16, 1/2, 13/16, 21/16]

# RND: Random melody with constraints
melody = RND(60, 62, 64, 65, 67, 69, 71, 72)
  .max_size(16)
  .remove { |note, history| note == history.last }  # No consecutive repeats

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
- `RND(...)` - Random values (infinite)
- `RND1(...)` - Random single value (exhausts after one)
- `SIN(steps:, amplitude:, center:)` - Sinusoidal waveform
- `FIBO()` - Fibonacci sequence
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
- `.shift(n)` - Shift values by offset
- `.after(*series)` - Concatenate series
- `.switch(*series)`, `.multiplex(*series)` - Switch between series
- `.lock` - Lock/freeze values
- `.anticipate(&block)`, `.lazy(&block)` - Advanced evaluation

## API Reference

**Complete API documentation:**
- [Musa::Series](https://rubydoc.info/gems/musa-dsl/Musa/Series) - Sequence generators and operations

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
pitch_bend = S({ time: 0r, value: 60.3 },
               { time: 1r, value: 61.8 },
               { time: 2r, value: 63.1 })

quantized = pitch_bend.quantize(step: 1)  # Quantize to integer semitones

quantized.i.to_a
# => [{ time: 0r, value: 60, duration: 1r },
#     { time: 1r, value: 62, duration: 1r }]

# Example 2: Predictive quantization for smooth crossings
continuous = S({ time: 0r, value: 0 }, { time: 4r, value: 10 })

predicted = continuous.quantize(step: 2, predictive: true)

predicted.i.to_a
# Generates crossing points at values 0, 2, 4, 6, 8, 10
# with precise timing for each boundary crossing
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


