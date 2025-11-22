# Musa-DSL

[![Ruby Version](https://img.shields.io/badge/ruby-3.4.7-red.svg)](https://www.ruby-lang.org/)
[![License](https://img.shields.io/badge/license-LGPL--3.0--or--later-blue.svg)](https://www.gnu.org/licenses/lgpl-3.0.html)

A Ruby framework and DSL for algorithmic sound and musical thinking and composition.

## Description

Musa-DSL is a programming language DSL (Domain-Specific Language) based on Ruby designed for sonic and musical composition. It emphasizes the creation of complex temporal structures independently of the audio rendering engine, providing composers and developers with powerful tools for algorithmic composition, generative music, and musical notation.

**Who is it for?**

- Composers exploring algorithmic composition
- Musicians interested in generative music systems
- Developers building music applications
- Researchers in computational musicology
- Live coders and interactive music performers

## Key Features

- **Advanced Sequencer** - Precise temporal control for complex polyrhythmic and polytemporal structures
- **Transport & Timing** - Multiple clock sources (internal, MIDI, external) with microsecond precision
- **Audio Engine Independent** - Works with any MIDI-capable, OSC-capable or any other output hardware or software system
- **Series-Based Composition** - Flexible sequence generators for pitches, rhythms, dynamics, and any musical parameter
- **Generative Tools** - Markov chains, combinatorial variations (Variatio), rule-based production systems (Rules), formal grammars (GenerativeGrammar), and genetic algorithms (Darwin)
- **Matrix Operations** - Mathematical transformations for musical structures
- **Scale System** - Comprehensive support for scales, tuning systems, and chord structures
- **Neumalang Notation** - Intuitive text-based and customizable musical (or sound) notation
- **Transcription System** - Convert musical gestures to MIDI and MusicXML with ornament transcription expansion

## Installation

Add to your Gemfile:

```ruby
gem 'musa-dsl'
```

Or install directly:

```bash
gem install musa-dsl
```

**Requirements:**
- Ruby ~> 3.4

## Quick Start

Here's a complete example showcasing the sequencer DSL with multiple melodic lines that interact with each other:

```ruby
require 'musa-dsl'
require 'midi-communications'

# Include all Musa DSL components
include Musa::All

# Setup MIDI output
output = MIDICommunications::Output.gets  # Interactively select output

# Create clock and transport with sequencer
# 4 beats per bar, 24 ticks per beat
clock = TimerClock.new(bpm: 120, ticks_per_beat: 24)
transport = Transport.new(clock, 4, 24)

# Create scale for our composition
scale = Scales.et12[440.0].major[60]  # C major starting at middle C

# Setup three MIDI voices on different channels
voices = MIDIVoices.new(
  sequencer: transport.sequencer,
  output: output,
  channels: [0, 1, 2]  # Channels for beat, melody, and harmony
)
beat_voice = voices.voices[0]
melody_voice = voices.voices[1]
harmony_voice = voices.voices[2]

# Shared state: current melody note (so harmony can follow)
current_melody_note = nil

# Program the sequencer using DSL
transport.sequencer.with do
  # Line 1: Beat every 4 bars (for 32 bars total)
  at 1 do
    every 4, duration: 32 do
      beat_voice.note pitch: 36, velocity: 100, duration: 1/8r  # Kick drum
    end
  end

  # Line 2: Ascending melody (bars 1-16) then descending (bars 17-32)
  at 1 do
    # Ascending: move from grade 0 to grade 14 over 16 bars
    move(from: 0, to: 14, duration: 16, every: 1/4r) do |grade|
      pitch = scale[grade.round].pitch
      current_melody_note = grade.round  # Share with harmony line
      melody_voice.note pitch: pitch, velocity: 80, duration: 1/8r
    end
  end

  at 17 do
    # Descending: move from grade 14 to grade 0 over 16 bars
    move(from: 14, to: 0, duration: 16, every: 1/4r) do |grade|
      pitch = scale[grade.round].pitch
      current_melody_note = grade.round  # Share with harmony line
      melody_voice.note pitch: pitch, velocity: 80, duration: 1/8r
    end
  end

  # Line 3: Harmony playing 3rd or 5th every 2 bars (for 32 bars total)
  at 1 do
    use_third = true  # Alternate between 3rd and 5th

    every 2, duration: 32 do
      if current_melody_note
        # Calculate harmony: 3rd is +2 grades, 5th is +4 grades
        harmony_grade = current_melody_note + (use_third ? 2 : 4)
        harmony_pitch = scale[harmony_grade].pitch

        # Play long note (whole note duration)
        harmony_voice.note pitch: harmony_pitch, velocity: 70, duration: 1

        # Alternate for next time
        use_third = !use_third
      end
    end
  end
end

# Start playback
transport.start
```

This example demonstrates:
- **Multiple independent voice lines** scheduled in the sequencer
- **`move` function** to smoothly animate pitch values over time
- **`every` for repeating events** at regular intervals
- **Shared state between voices** (harmony follows melody)
- **Precise timing control** with bars and beats

## Not So Quick Start

Here's a more detailed example showing the Neuma notation system:

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
# Durations: 1/4 = quarter, 1/2 = half, 1 = whole
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

## System Architecture

MusaDSL is a comprehensive ecosystem consisting of a core framework (musa-dsl) and associated projects for communication, development, and integration.

### MusaDSL Ecosystem

**Core Framework:**
- [**musa-dsl**](https://github.com/javier-sy/musa-dsl) - Main DSL framework for algorithmic composition and musical thinking

**MIDI Communication Stack:**
- [**midi-events**](https://github.com/javier-sy/midi-events) - Low-level MIDI event definitions and protocols
- [**midi-parser**](https://github.com/javier-sy/midi-parser) - MIDI file parsing and analysis
- [**midi-communications**](https://github.com/javier-sy/midi-communications) - Cross-platform MIDI I/O abstraction layer
- [**midi-communications-macos**](https://github.com/javier-sy/midi-communications-macos) - macOS-specific MIDI native implementation

**Live Coding Environment (MusaLCE):**
- [**musalce-server**](https://github.com/javier-sy/musalce-server) - Live coding evaluation server with hot-reload capabilities
- [**MusaLCEClientForVSCode**](https://github.com/javier-sy/MusaLCEClientForVSCode) - Visual Studio Code extension for live coding
- [**MusaLCEClientForAtom**](https://github.com/javier-sy/MusaLCEClientForAtom) - Atom editor plugin for live coding
- [**MusaLCEforBitwig**](https://github.com/javier-sy/MusaLCEforBitwig) - Bitwig Studio integration for live performance
- [**MusaLCEforLive**](https://github.com/javier-sy/MusaLCEforLive) - Ableton Live integration for interactive composition

### musa-dsl Internal Architecture

The musa-dsl framework is organized in modular layers:

#### 1. Foundation Layer
- **core-ext** - Ruby core extensions (refinements for enhanced syntax)
- **logger** - Structured logging system with severity levels

#### 2. Temporal & Scheduling Layer
- **sequencer** - Event scheduling engine with microsecond precision
  - Tick-based (quantized) and tickless (continuous) timing modes
  - Series playback with automatic duration management
  - Support for polyrhythms and polytemporal structures
- **transport** - High-level playback control with clock synchronization
  - BPM management and tempo changes
  - Start/stop/pause/continue controls
  - Multiple clock source support (internal, MIDI, external)

#### 3. Notation & Parsing Layer
- **neumas** - Text-based musical notation system
- **neumalang** - Parser and interpreter for neuma notation with DSL support

#### 4. Generation & Transformation Layer
- **series** - Lazy sequence generators with functional operations
  - Map, filter, transpose, repeat, and combination operations
  - Infinite and finite series support
- **generative** - Algorithmic composition tools
  - **Markov chains**: Probabilistic sequence generation
  - **Variatio**: Cartesian product parameter variations
  - **Rules**: L-system-like production systems with growth/pruning
  - **GenerativeGrammar**: Formal grammar-based generation
  - **Darwin**: Genetic algorithms for evolutionary composition
- **matrix** - Matrix operations for musical gestures
  - Matrix-to-P (point sequence) conversion
  - Gesture condensation and transformation

#### 5. Output & Communication Layer
- **transcription** - Musical event transformation system
  - Ornament expansion (trills, mordents, turns)
  - GDV to MIDI/MusicXML conversion
  - Dynamic articulation rendering
- **musicxml** - MusicXML score generation
  - Multi-part score creation
  - Notation directives (dynamics, tempo, articulations)
  - Standard MusicXML 3.0 output
- **midi** - MIDI voice management
  - Polyphonic voice allocation
  - Channel management
  - Note-on/note-off scheduling

#### 6. Musical Knowledge Layer
- **music** - Scales, tuning systems, intervals, and chord structures
  - Equal temperament and just intonation support
  - Modal scales (major, minor, chromatic, etc.)
  - Chord definitions and harmonic analysis
- **datasets** - Musical data structures (GDV, PDV, Score)
  - GDV (Grade-Duration-Velocity): Scale-relative representation
  - PDV (Pitch-Duration-Velocity): Absolute pitch representation
  - Score: Timeline-based multi-track composition structure

#### 7. Development & Interaction Layer
- **repl** - Interactive Read-Eval-Print Loop for live composition

## Core Subsystems

### Series - Sequence Generators

Series are the fundamental building blocks for generating musical sequences. They provide functional operations for transforming pitches, rhythms, dynamics, and any musical parameter.

#### Basic Series Operations

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

#### Combining Multiple Parameters

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

#### Merging Melodic Phrases

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

#### Numeric Generators

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

#### Structural Transformations

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

**Documentation:** See `lib/musa-dsl/series/`

### Sequencer - Temporal Engine

The Sequencer manages time-based event scheduling with microsecond precision, supporting complex polyrhythmic and polytemporal structures.

```ruby
require 'musa-dsl'
include Musa::All

# Setup: Create clock and transport (for real-time execution)
clock = TimerClock.new(bpm: 120, ticks_per_beat: 24)
transport = Transport.new(clock, 4, 24)  # 4 beats per bar, 24 ticks per beat

# Define series outside DSL block (Series constructors not available in DSL context)
melody = S({ note: 60, duration: 1/2r }, { note: 62, duration: 1/2r },
            { note: 64, duration: 1/2r }, { note: 65, duration: 1/2r },
            { note: 67, duration: 1/2r }, { note: 65, duration: 1/2r },
            { note: 64, duration: 1/2r }, { note: 62, duration: 1/2r })

# Program sequencer using DSL
transport.sequencer.with do
  # Custom event handlers (on/launch)
  on :section_change do |name|
    puts "Section: #{name}"
  end

  # Immediate event (now)
  now do
    launch :section_change, "Start"
  end

  # Absolute positioning (at): event at bar 1
  at 1 do
    puts "Bar 1: position #{position}"
  end

  # Relative positioning (wait): event 2 bars later
  wait 2 do
    puts "Bar 3: position #{position}"
  end

  # Play series (play): reproduces series with automatic timing
  at 5 do
    play melody do |note:, duration:, control:|
      puts "Playing note: #{note}, duration: #{duration}"
    end
  end

  # Recurring event (every) with stop control
  beat_loop = nil
  at 10 do
    # Store control object to stop it later
    beat_loop = every 2, duration: 10 do
      puts "Beat at position #{position}"
    end
  end

  # Stop the beat loop at bar 18
  at 18 do
    beat_loop.stop if beat_loop
    puts "Beat loop stopped"
  end

  # Animated value (move) from 0 to 10 over 4 bars
  at 20 do
    move from: 0, to: 10, duration: 4, every: 1/2r do |value|
      puts "Value: #{value.round(2)}"
    end
  end

  # Multi-parameter animation (move with hash)
  at 25 do
    move from: { pitch: 60, vel: 60 },
         to: { pitch: 72, vel: 100 },
         duration: 2,
         every: 1/4r do |values|
      puts "Pitch: #{values[:pitch].round}, Velocity: #{values[:vel].round}"
    end
  end

  # Final event
  at 30 do
    launch :section_change, "End"
    puts "Finished at position #{position}"
  end
end

# Start real-time playback
transport.start
```

**Documentation:** See `lib/sequencer/`

### Neumas & Neumalang - Musical Notation

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

### Transcription - MIDI & MusicXML Output

The Transcription system converts GDV events to MIDI (with ornament expansion) or MusicXML format (preserving ornaments as symbols).

#### MIDI with Ornament Expansion

```ruby
require 'musa-dsl'

using Musa::Extension::Neumas

# Neuma notation with ornaments: trill (.tr) and mordent (.mor)
neumas = "(0 1 mf) (+2 1 tr) (+4 1 mor) (+5 1)"

# Create scale and decoder
scale = Musa::Scales::Scales.et12[440.0].major[60]
decoder = Musa::Neumas::Decoders::NeumaDecoder.new(scale, base_duration: 1/4r)

# Create MIDI transcriptor with ornament expansion
transcriptor = Musa::Transcription::Transcriptor.new(
  Musa::Transcriptors::FromGDV::ToMIDI.transcription_set(duration_factor: 1/6r),
  base_duration: 1/4r,
  tick_duration: 1/96r
)

# Parse and expand ornaments to PDV
result = Musa::Neumalang::Neumalang.parse(neumas, decode_with: decoder)
                                   .process_with { |gdv| transcriptor.transcript(gdv) }
                                   .map { |gdv| gdv.to_pdv(scale) }
                                   .to_a(recursive: true)

# View expanded notes (ornaments rendered as note sequences)
result.each do |pdv|
  puts "Pitch: #{pdv[:pitch]}, Duration: #{pdv[:duration]}, Velocity: #{pdv[:velocity]}"
end
# => Pitch: 60, Duration: 1/4, Velocity: 80     # C4 (no ornament)
#    Pitch: 65, Duration: 1/24, Velocity: 80   # Trill: F4 (upper neighbor)
#    Pitch: 64, Duration: 1/24, Velocity: 80   # Trill: E4 (original)
#    Pitch: 65, Duration: 1/24, Velocity: 80   # Trill: F4
#    Pitch: 64, Duration: 1/24, Velocity: 80   # Trill: E4
#    ... (trill alternation continues)
#    Pitch: 71, Duration: 1/24, Velocity: 80   # Mordent: B4 (original)
#    Pitch: 72, Duration: 1/24, Velocity: 80   # Mordent: C5 (neighbor)
#    Pitch: 71, Duration: 1/6, Velocity: 80    # Mordent: B4 (return)
#    Pitch: 79, Duration: 1/4, Velocity: 80    # G5 (no ornament)
```

**Supported ornaments:**
- `.tr` - Trill (rapid alternation with upper note)
- `.mor` - Mordent (quick alternation with adjacent note)
- `.turn` - Turn (four-note figure)
- `.st` - Staccato (shortened duration)

#### MusicXML with Ornament Symbols

```ruby
require 'musa-dsl'

using Musa::Extension::Neumas

# Same phrase as MIDI example (ornaments preserved as symbols)
neumas = "(0 1 mf) (+2 1 tr) (+4 1 mor) (+5 1)"

# Create scale and decoder
scale = Musa::Scales::Scales.et12[440.0].major[60]
decoder = Musa::Neumas::Decoders::NeumaDecoder.new(scale, base_duration: 1/4r)

# Create MusicXML transcriptor (preserves ornaments as symbols)
transcriptor = Musa::Transcription::Transcriptor.new(
  Musa::Transcriptors::FromGDV::ToMusicXML.transcription_set,
  base_duration: 1/4r,
  tick_duration: 1/96r
)

# Parse and convert to GDV with preserved ornament markers
serie = Musa::Neumalang::Neumalang.parse(neumas, decode_with: decoder)
                                   .process_with { |gdv| transcriptor.transcript(gdv) }

# Create Score and use sequencer to fill it
score = Musa::Datasets::Score.new
sequencer = Musa::Sequencer::Sequencer.new(4, 24)

sequencer.at 1 do
  play serie, decoder: decoder, mode: :neumalang do |gdv|
    pdv = gdv.to_pdv(scale)
    score.at(position, add: pdv)  # position is automatically tracked by sequencer
  end
end

sequencer.run

# Convert to MusicXML
mxml = score.to_mxml(
  4, 24,  # 4 beats per bar, 24 ticks per beat
  bpm: 120,
  title: 'Ornaments Example',
  creators: { composer: 'MusaDSL' },
  parts: { piano: { name: 'Piano', clefs: { g: 2 } } }
)

# Generated MusicXML (excerpt showing notes with ornaments):
puts mxml.to_xml.string
```

**Generated MusicXML output (excerpt):**
```xml
<note>
  <pitch>
    <step>C</step>
    <octave>4</octave>
  </pitch>
  <duration>24</duration>
  <type>quarter</type>
</note>
<note>
  <pitch>
    <step>E</step>
    <octave>4</octave>
  </pitch>
  <duration>24</duration>
  <type>quarter</type>
  <notations>
    <ornaments>
      <trill-mark />      <!-- Trill preserved as notation symbol -->
    </ornaments>
  </notations>
</note>
<note>
  <pitch>
    <step>B</step>
    <octave>4</octave>
  </pitch>
  <duration>24</duration>
  <type>quarter</type>
  <notations>
    <ornaments>
      <inverted-mordent />   <!-- Mordent preserved as notation symbol -->
    </ornaments>
  </notations>
</note>
```

**Note:** Only 4 notes (vs 11 in MIDI) - ornaments preserved as notation symbols, not expanded

**Documentation:** See `lib/transcription/` and `lib/musicxml/`

### Generative - Algorithmic Composition

Tools for generative and algorithmic music composition.

#### Markov Chains

Probabilistic sequence generation using transition matrices. Markov chains generate sequences where each value depends only on the current state and transition probabilities.

Parameters:
- `start:` - Initial state value
- `finish:` - End state symbol (transitions to this value terminate the sequence)
- `transitions:` - Hash mapping each state to possible next states with probabilities
  - Format: `state => { next_state => probability, ... }`
  - Probabilities for each state should sum to 1.0

```ruby
require 'musa-dsl'

markov = Musa::Markov::Markov.new(
  start: 0,
  finish: :end,
  transitions: {
    0 => { 2 => 0.5, 4 => 0.3, 7 => 0.2 },
    2 => { 0 => 0.3, 4 => 0.5, 5 => 0.2 },
    4 => { 2 => 0.4, 5 => 0.4, 7 => 0.2 },
    5 => { 0 => 0.5, :end => 0.5 },
    7 => { 0 => 0.6, :end => 0.4 }
  }
).i

# Generate melody pitches (Markov is a Serie, so we can use .to_a)
melody_pitches = markov.to_a
```

#### Variatio

Generates all combinations of parameter variations using Cartesian product. Useful for creating comprehensive parameter sweeps, exploring all possibilities of a musical motif, or generating exhaustive harmonic permutations.

**Constructor parameters:**
- `instance_name` (Symbol) - Name for the object parameter in blocks (e.g., `:chord`, `:note`, `:synth`)
- `&block` - DSL block defining fields, constructor, and optional attributes/finalize

**DSL methods:**
- `field(name, options)` - Define a parameter field with possible values (Array or Range)
- `fieldset(name, options, &block)` - Define nested field group with its own fields
- `constructor(&block)` - Define how to construct each variation object (required)
- `with_attributes(&block)` - Modify objects with field/fieldset values (optional)
- `finalize(&block)` - Post-process completed objects (optional)

**Execution methods:**
- `run` - Generate all variations with default field values
- `on(**values)` - Generate variations with runtime field value overrides

```ruby
require 'musa-dsl'

variatio = Musa::Variatio::Variatio.new :chord do
  field :root, [60, 64, 67]     # C, E, G
  field :type, [:major, :minor]

  constructor do |root:, type:|
    { root: root, type: type }
  end
end

all_chords = variatio.run
# => [
#   { root: 60, type: :major }, { root: 60, type: :minor },
#   { root: 64, type: :major }, { root: 64, type: :minor },
#   { root: 67, type: :major }, { root: 67, type: :minor }
# ]
# 3 roots × 2 types = 6 variations

# Override field values at runtime
limited_chords = variatio.on(root: [60, 64])
# => 2 roots × 2 types = 4 variations
```

#### Rules

Production system with growth and pruning rules (similar to L-systems). Generates tree structures by applying sequential growth rules to create branches and validation rules to prune invalid paths. Useful for harmonic progressions with voice leading rules, melodic variations with contour constraints, or rhythmic patterns following metric rules.

**Constructor parameters:**
- `&block` - DSL block defining grow rules, cut rules, and end condition

**DSL methods:**
- `grow(name, &block)` - Define growth rule that generates new branches
  - Block receives: `|object, history, **params|`
  - Use `branch(new_object)` to create new possibilities
- `cut(reason, &block)` - Define pruning rule to eliminate invalid paths
  - Block receives: `|object, history, **params|`
  - Use `prune` to reject current branch
- `ended_when(&block)` - Define end condition to mark complete branches
  - Block receives: `|object, history, **params|`
  - Return `true` to mark branch as complete

**Execution methods:**
- `apply(seed_or_seeds, **params)` - Apply rules to initial object(s), returns tree Node
  - Accepts single object or array of objects
  - Optional parameters passed to all rule blocks

**Tree Node methods:**
- `combinations` - Returns array of all valid complete paths through tree
- `fish` - Returns array of all valid endpoint objects

```ruby
require 'musa-dsl'

# Build chord voicings by adding notes sequentially
rules = Musa::Rules::Rules.new do
  # Step 1: Choose root note
  grow 'add root' do |seed|
    [60, 64, 67].each { |root| branch [root] }  # C, E, G
  end

  # Step 2: Add third (major or minor)
  grow 'add third' do |chord|
    branch chord + [chord[0] + 4]  # Major third
    branch chord + [chord[0] + 3]  # Minor third
  end

  # Step 3: Add fifth
  grow 'add fifth' do |chord|
    branch chord + [chord[0] + 7]
  end

  # Pruning rule: avoid wide intervals
  cut 'no wide spacing' do |chord|
    if chord.size >= 2
      prune if (chord[-1] - chord[-2]) > 12  # Max octave between adjacent notes
    end
  end

  # End after three notes
  ended_when do |chord|
    chord.size == 3
  end
end

tree = rules.apply(0)  # seed value (triggers generation)
combinations = tree.combinations

# Extract final voicings from each path
voicings = combinations.map { |path| path.last }
# => [[60, 64, 67], [60, 63, 67], [64, 68, 71], [64, 67, 71], [67, 71, 74], [67, 70, 74]]
# 3 roots × 2 thirds × 1 fifth = 6 voicings

# With parameters
tree_with_params = rules.apply(0, max_interval: 7)
```

#### Generative Grammar

Formal grammars with combinatorial generation using operators. Useful for generating melodic patterns with rhythmic constraints, harmonic progressions, or variations of musical motifs.

**Constructors:**
- `N(content, **attributes)` - Create terminal node with fixed content and attributes
- `N(**attributes, &block)` - Create block node with dynamic content generation
- `PN()` - Create proxy node for recursive grammar definitions

**Combination operators:**
- `|` (or) - Alternative/choice between nodes (e.g., `a | b`)
- `+` (next) - Concatenation/sequence of nodes (e.g., `a + b`)
- `repeat(exactly:)` or `repeat(min:, max:)` - Repeat node multiple times
- `limit(&block)` - Filter options by condition

**Result methods:**
- `options(content: :join)` - Generate all combinations as joined strings
- `options(content: :itself)` - Generate all combinations as arrays (default)
- `options(raw: true)` - Generate raw OptionElement objects with attributes
- `options(&condition)` - Generate filtered combinations

```ruby
require 'musa-dsl'

include Musa::GenerativeGrammar

a = N('a', size: 1)
b = N('b', size: 1)
c = N('c', size: 1)
d = b | c  # d can be either b or c

# Grammar: (a or d) repeated 3 times, then c
grammar = (a | d).repeat(3) + c

# Generate all possibilities
grammar.options(content: :join)
# => ["aaac", "aabc", "aacc", "abac", "abbc", "abcc", "acac", "acbc", "accc",
#     "baac", "babc", "bacc", "bbac", "bbbc", "bbcc", "bcac", "bcbc", "bccc",
#     "caac", "cabc", "cacc", "cbac", "cbbc", "cbcc", "ccac", "ccbc", "cccc"]
# 3^3 × 1 = 27 combinations

# With constraints - filter by attribute
grammar_with_limit = (a | d).repeat(min: 1, max: 4).limit { |o|
  o.collect { |e| e.attributes[:size] }.sum <= 3
}

result_limited = grammar_with_limit.options(content: :join)
# Includes: ["a", "b", "c", "aa", "ab", "ac", "ba", "bb", "bc", "ca", "cb", "cc", "aaa", "aab", "aac", ...]
# Only combinations where total size <= 3
```

#### Darwin

Evolutionary selection algorithm based on fitness evaluation. Darwin doesn't generate populations - it selects and ranks existing candidates using user-defined measures (features and dimensions) and weights. Each object is evaluated, normalized across the population, scored, and sorted by fitness.

**How it works:**
1. Define measures (features & dimensions) to evaluate each candidate
2. Define weights for each measure
3. Darwin evaluates all candidates, normalizes dimensions, applies weights
4. Returns population sorted by fitness (best first)

**Constructor:**
- `&block` - DSL block defining measures and weights

**DSL methods:**
- `measures(&block)` - Define evaluation block for each object
  - Block receives each object to evaluate
  - Inside block use: `feature(name)`, `dimension(name, value)`, `die`
- `weight(**weights)` - Assign weights to features/dimensions
  - Positive weights favor the measure
  - Negative weights penalize the measure

**Measures methods (inside measures block):**
- `feature(name)` - Mark object as having a boolean feature
- `dimension(name, value)` - Record numeric measurement (will be normalized 0-1)
- `die` - Mark object as non-viable (will be excluded from results)

**Execution methods:**
- `select(population)` - Evaluate and rank population, returns sorted array (best first)

```ruby
require 'musa-dsl'

# Generate candidate melodies using Variatio
variatio = Musa::Variatio::Variatio.new :melody do
  field :interval, 1..7        # Intervals in semitones
  field :contour, [:up, :down, :repeat]
  field :duration, [1/4r, 1/2r, 1r]

  constructor do |interval:, contour:, duration:|
    { interval: interval, contour: contour, duration: duration }
  end
end

candidates = variatio.run  # Generate all combinations

# Create Darwin selector with musical criteria
darwin = Musa::Darwin::Darwin.new do
  measures do |melody|
    # Eliminate melodies with unwanted characteristics
    die if melody[:interval] > 5  # No large leaps

    # Binary features (present/absent)
    feature :stepwise if melody[:interval] <= 2        # Stepwise motion
    feature :has_quarter_notes if melody[:duration] == 1/4r

    # Numeric dimensions (will be normalized across population)
    # Use negative values to prefer lower numbers
    dimension :interval_size, -melody[:interval].to_f
    dimension :duration_value, melody[:duration].to_f
  end

  # Weight each measure's contribution to fitness
  weight interval_size: 2.0,      # Strongly prefer smaller intervals
         stepwise: 1.5,            # Prefer stepwise motion
         has_quarter_notes: 1.0,   # Slightly prefer quarter notes
         duration_value: -0.5      # Slightly penalize longer durations
end

# Select and rank melodies by fitness
ranked = darwin.select(candidates)

best_melody = ranked.first       # Highest fitness
top_10 = ranked.first(10)        # Top 10 melodies
worst = ranked.last              # Lowest fitness (but still viable)
```

### Music - Scales & Chords

Comprehensive framework for working with musical scales, tuning systems, and chord structures. The system resolves two main domains:

#### Scales System

The **Scales** module provides hierarchical access to musical scales with multiple tuning systems and scale types:

**Architecture:**
- **ScaleSystem** (`Musa::Scales::ScaleSystem`): Defines tuning systems (e.g., 12-tone equal temperament)
- **ScaleSystemTuning** (`Musa::Scales::ScaleSystemTuning`): A scale system with specific reference frequency (e.g., A=440Hz)
- **ScaleKind** (`Musa::Scales::ScaleKind`): Scale types (major, minor, chromatic, etc.)
- **Scale** (`Musa::Scales::Scale`): A scale kind rooted on a specific pitch (e.g., C major)
- **NoteInScale** (`Musa::Scales::NoteInScale`): A specific note within a scale

**Registry:**
- **Scales::Scales** (`Musa::Scales::Scales`): Central registry for accessing scale systems by ID or method name

**Available scale systems:**
- `:et12` (EquallyTempered12ToneScaleSystem): 12-tone equal temperament (default)

**Available scale kinds in et12:**
- `:major` - Major scale (Ionian mode)
- `:minor` - Natural minor scale (Aeolian mode)
- `:minor_harmonic` - Harmonic minor scale (raised 7th degree)
- `:chromatic` - Chromatic scale (all 12 semitones)

#### Chords System

The **Chords** module provides chord structures with scale context:

**Architecture:**
- **Chord** (`Musa::Chords::Chord`): Instantiated chord with root note and scale context
- **ChordDefinition** (`Musa::Chords::ChordDefinition`): Abstract chord structure definition (quality, size, intervals)

**Features:**
- Access chord tones by name (root, third, fifth, seventh, etc.)
- Voicing modifications (move, duplicate, octave)
- Navigate between related chords (change quality, add extensions)
- Extract pitches and notes

**Usage examples:**

```ruby
require 'musa-dsl'

include Musa::Scales
include Musa::Chords

# Access default system and tuning
tuning = Scales.default_system.default_tuning  # A=440Hz

# Create scales using available scale kinds
c_major = tuning.major[60]           # C major (tonic pitch 60)
d_minor = tuning.minor[62]           # D minor (natural)
e_harmonic = tuning.minor_harmonic[64]  # E harmonic minor
chromatic = tuning.chromatic[60]     # C chromatic

# Alternative access methods
c_major = Scales.et12[440.0].major[60]  # Explicit system and frequency

# Access notes by grade (0-based) or function
tonic = c_major[0]      # => C (grade 0)
mediant = c_major[2]    # => E (grade 2)
dominant = c_major[4]   # => G (grade 4)

# Access by function name
tonic = c_major.tonic         # => C
supertonic = c_major.supertonic  # => D
mediant = c_major.mediant     # => E
subdominant = c_major.subdominant  # => F
dominant = c_major.dominant   # => G

# Access by Roman numeral or symbol
c_major[:I]    # => Tonic (C)
c_major[:V]    # => Dominant (G)

# Get pitch values from notes
pitch = c_major.tonic.pitch   # => 60

# Navigate with octaves
note = c_major[2].octave(1)  # E in octave 1
pitch_with_octave = note.pitch     # => 76

# Chromatic operations - sharp and flat
c_sharp = c_major.tonic.sharp   # => C# (chromatic, +1 semitone)
c_flat = c_major.tonic.flat     # => Cb (chromatic, -1 semitone)

# Navigate by semitones
fifth_up = c_major.tonic.sharp(7)  # => G (+7 semitones = perfect fifth)
third_up = c_major.tonic.sharp(4)  # => E (+4 semitones = major third)

# Frequency calculation
frequency = c_major.tonic.frequency  # => 261.63 Hz (middle C at A=440)

# Create chords from scale degrees
i_chord = c_major.tonic.chord        # C major triad [C, E, G]
ii_chord = c_major.supertonic.chord  # D minor triad [D, F, A]
v_chord = c_major.dominant.chord     # G major triad [G, B, D]

# Create extended chords
i_seventh = c_major.tonic.chord :seventh  # C major 7th [C, E, G, B]
v_ninth = c_major.dominant.chord :ninth   # G 9th chord

# Access chord tones by name
root = i_chord.root      # => C (NoteInScale)
third = i_chord.third    # => E (NoteInScale)
fifth = i_chord.fifth    # => G (NoteInScale)

# Get chord pitches
pitches = i_chord.pitches  # => [60, 64, 67] (C, E, G)
notes = i_chord.notes      # Array of ChordGradeNote structs

# Chord features
i_chord.quality  # => :major
i_chord.size     # => :triad

# Navigate between chord qualities
minor_chord = i_chord.with_quality(:minor)      # C minor [C, Eb, G]
diminished = i_chord.with_quality(:diminished)  # C diminished [C, Eb, Gb]

# Change chord extensions
seventh_chord = i_chord.with_size(:seventh)  # C major 7th
ninth_chord = i_chord.with_size(:ninth)      # C major 9th

# Voicing modifications - move specific tones to different octaves
voiced = i_chord.move(root: -1, fifth: 1)  # Root down, fifth up

# Duplicate tones in other octaves
doubled = i_chord.duplicate(root: -2, third: [-1, 1])  # Root 2 down, third 1 down and 1 up

# Transpose entire chord
lower = i_chord.octave(-1)  # Move chord down one octave
```

#### Defining Custom Scale Systems, Scale Kinds, and Chord Definitions

The framework is extensible, allowing users to define custom tuning systems, scale types, and chord structures:

**Custom Scale Systems:**

Users can create custom tuning systems by subclassing `Musa::Scales::ScaleSystem` and implementing:
- `.id` - Unique symbol identifier
- `.notes_in_octave` - Number of notes per octave
- `.part_of_tone_size` - Size of smallest pitch unit
- `.intervals` - Hash mapping interval names to semitone offsets
- `.frequency_of_pitch(pitch, root_pitch, a_frequency)` - Pitch to frequency conversion

After defining, register with `Musa::Scales::Scales.register(CustomScaleSystem, default: false)`

**Custom Scale Kinds:**

Users can define new scale types by subclassing `Musa::Scales::ScaleKind` and implementing:
- `.id` - Unique symbol identifier (e.g., `:dorian`, `:pentatonic`)
- `.pitches` - Array defining scale structure with functions and pitch offsets
- `.chromatic?` - Whether this is the chromatic scale (optional, default: false)
- `.grades` - Number of grades per octave (optional, default: pitches.length)

After defining, register with `YourScaleSystem.register(CustomScaleKind)`

**Custom Chord Definitions:**

Users can register new chord types using `Musa::Chords::ChordDefinition.register`:
- `name` - Symbol identifier (e.g., `:sus4`, `:add9`)
- `offsets:` - Hash defining semitone intervals from root (e.g., `{ root: 0, fourth: 5, fifth: 7 }`)
- `**features` - Chord characteristics like `quality:` and `size:`

**Examples of custom definitions:**

```ruby
require 'musa-dsl'

include Musa::Scales
include Musa::Chords

# Example 1: Define a custom pentatonic scale kind for the 12-tone system
class PentatonicMajorScaleKind < ScaleKind
  class << self
    def id
      :pentatonic_major
    end

    def pitches
      [{ functions: [:I, :_1, :tonic], pitch: 0 },
       { functions: [:II, :_2], pitch: 2 },
       { functions: [:III, :_3], pitch: 4 },
       { functions: [:V, :_5], pitch: 7 },
       { functions: [:VI, :_6], pitch: 9 }]
    end

    def grades
      5  # 5 notes per octave
    end
  end
end

# Register the new scale kind with the 12-tone system
Scales.et12.register(PentatonicMajorScaleKind)

# Use the new scale kind
tuning = Scales.default_system.default_tuning
c_pentatonic = tuning[:pentatonic_major][60]  # C pentatonic major
puts c_pentatonic[0].pitch  # => 60 (C)
puts c_pentatonic[1].pitch  # => 62 (D)
puts c_pentatonic[2].pitch  # => 64 (E)

# Example 2: Register a custom chord definition (sus4)
Musa::Chords::ChordDefinition.register :sus4,
  quality: :suspended,
  size: :triad,
  offsets: { root: 0, fourth: 5, fifth: 7 }

# Use the custom chord definition
c_major = tuning.major[60]
# To use custom chords, access via NoteInScale#chord with the definition name
# or create manually using the definition

# Example 3: Register a custom chord definition (add9)
Musa::Chords::ChordDefinition.register :add9,
  quality: :major,
  size: :extended,
  offsets: { root: 0, third: 4, fifth: 7, ninth: 14 }
```

**Documentation:** See `lib/music/`

### MusicXML Builder - Music Notation Export

Comprehensive builder for generating MusicXML 3.0 files compatible with music notation software (Finale, Sibelius, MuseScore, Dorico, etc.). MusicXML is the standard open format for exchanging digital sheet music between applications.

#### Root Class: ScorePartwise

The entry point for creating MusicXML documents is `Musa::MusicXML::Builder::ScorePartwise`, which represents the `<score-partwise>` root element. It organizes music by parts (instruments/voices) and measures.

**Structure:**
- **Metadata**: work info, movement info, creators, rights, encoding date
- **Part List**: part definitions with names and abbreviations
- **Parts**: musical content organized by measures

#### Key Features

**Multiple staves:**
Use `staff:` parameter to specify which staff (1, 2, etc.) for grand staff notation (piano, harp, organ, etc.).
```ruby
pitch 'C', octave: 3, staff: 2  # Note in staff 2 (bass clef)
```

**Multiple voices:**
Use `voice:` parameter for polyphonic notation within a single staff (independent melodic lines).
```ruby
pitch 'C', octave: 4, voice: 1  # Voice 1
pitch 'E', octave: 3, voice: 2  # Voice 2 (simultaneous)
```

**Backup/Forward:**
Navigate timeline within measures to layer voices. `backup(duration)` returns to an earlier point, `forward(duration)` skips ahead.
```ruby
pitch 'C', octave: 4, duration: 4
backup 4  # Return to beginning
pitch 'E', octave: 3, duration: 4  # Play simultaneously
```

**Divisions:**
Set rhythmic precision as divisions per quarter note in measure attributes. Higher values allow smaller note values.
```ruby
attributes do
  divisions 4  # 4 divisions per quarter (allows 16th notes)
end
```

**Alterations:**
Use `alter:` parameter for accidentals: `-1` for flat, `1` for sharp, `2` for double sharp, etc.
```ruby
pitch 'F', octave: 4, alter: 1  # F# (sharp)
pitch 'B', octave: 4, alter: -1  # Bb (flat)
```

**Articulations:**
Add slurs, dots, and other articulations via parameters.
```ruby
pitch 'C', octave: 4, slur: 'start'  # Begin slur
pitch 'D', octave: 4, slur: 'stop'   # End slur
pitch 'E', octave: 4, dots: 1        # Dotted note
```

**Dynamics:**
Add dynamic markings using `direction` blocks with `dynamics` method. Supported: `pp`, `p`, `mp`, `mf`, `f`, `ff`, `fff`, etc.
```ruby
direction do
  dynamics 'f'  # Forte
end
```

**Wedges:**
Add crescendo/diminuendo markings with `wedge` in direction blocks.
```ruby
direction do
  wedge 'crescendo'  # Start crescendo
end
# ... notes ...
direction wedge: 'stop'  # End crescendo
```

**Metronome:**
Add tempo markings with `metronome` in measures.
```ruby
metronome beat_unit: 'quarter', per_minute: 120
```

**Rests:**
Use `rest` method instead of `pitch` for rest notation.
```ruby
rest duration: 2, type: 'quarter'
```

#### Two Usage Modes

**Constructor Style (Method Calls):**

Use constructor parameters and `add_*` methods for programmatic building:

```ruby
require 'musa-dsl'

# Create score with metadata
score = Musa::MusicXML::Builder::ScorePartwise.new(
  work_title: "Piano Piece",
  creators: { composer: "Your Name" },
  encoding_date: DateTime.new(2024, 1, 1)
)

# Add parts using add_* methods
part = score.add_part(:p1, name: "Piano", abbreviation: "Pno.")

# Add measures and attributes
measure = part.add_measure(divisions: 4)

# Add attributes (key, time, clef, etc.)
measure.attributes.last.add_key(1, fifths: 0)        # C major
measure.attributes.last.add_time(1, beats: 4, beat_type: 4)
measure.attributes.last.add_clef(1, sign: 'G', line: 2)

# Add notes
measure.add_pitch(step: 'C', octave: 4, duration: 4, type: 'quarter')
measure.add_pitch(step: 'E', octave: 4, duration: 4, type: 'quarter')
measure.add_pitch(step: 'G', octave: 4, duration: 4, type: 'quarter')
measure.add_pitch(step: 'C', octave: 5, duration: 4, type: 'quarter')

# Export to file
File.write("score.musicxml", score.to_xml.string)
```

**DSL Style (Blocks):**

Use blocks with method names as setters/builders for more readable, declarative code:

```ruby
require 'musa-dsl'

score = Musa::MusicXML::Builder::ScorePartwise.new do
  work_title "Piano Piece"
  creators composer: "Your Name"
  encoding_date DateTime.new(2024, 1, 1)

  part :p1, name: "Piano", abbreviation: "Pno." do
    measure do
      attributes do
        divisions 4
        key 1, fifths: 0        # C major
        time 1, beats: 4, beat_type: 4
        clef 1, sign: 'G', line: 2
      end

      pitch 'C', octave: 4, duration: 4, type: 'quarter'
      pitch 'E', octave: 4, duration: 4, type: 'quarter'
      pitch 'G', octave: 4, duration: 4, type: 'quarter'
      pitch 'C', octave: 5, duration: 4, type: 'quarter'
    end
  end
end

File.write("score.musicxml", score.to_xml.string)
```

**Sophisticated Example - Piano Score with Multiple Features:**

```ruby
require 'musa-dsl'

score = Musa::MusicXML::Builder::ScorePartwise.new do
  work_title "Étude in D Major"
  work_number 1
  creators composer: "Example Composer"
  encoding_date DateTime.now

  part :p1, name: "Piano" do
    # Measure 1 - Setup and opening with two staves
    measure do
      attributes do
        divisions 2  # 2 divisions per quarter note

        # Treble clef (staff 1)
        key 1, fifths: 2        # D major (2 sharps)
        clef 1, sign: 'G', line: 2
        time 1, beats: 4, beat_type: 4

        # Bass clef (staff 2)
        key 2, fifths: 2
        clef 2, sign: 'F', line: 4
        time 2, beats: 4, beat_type: 4
      end

      # Tempo marking
      metronome beat_unit: 'quarter', per_minute: 120

      # Right hand melody (staff 1)
      pitch 'D', octave: 4, duration: 4, type: 'half', slur: 'start'
      pitch 'E', octave: 4, duration: 4, type: 'half', slur: 'stop'

      # Return to beginning for left hand (staff 2)
      backup 8

      # Left hand accompaniment (staff 2)
      pitch 'D', octave: 3, duration: 8, type: 'whole', staff: 2
    end

    # Measure 2 - Two voices in treble clef
    measure do
      # Voice 1
      pitch 'F#', octave: 4, duration: 2, type: 'quarter', alter: 1, voice: 1
      pitch 'G', octave: 4, duration: 2, type: 'quarter', voice: 1
      pitch 'A', octave: 4, duration: 2, type: 'quarter', voice: 1
      pitch 'B', octave: 4, duration: 2, type: 'quarter', voice: 1

      # Return to beginning for voice 2
      backup 8

      # Voice 2 (inner voice)
      pitch 'A', octave: 3, duration: 3, type: 'quarter', dots: 1, voice: 2
      pitch 'B', octave: 3, duration: 1, type: 'eighth', voice: 2
      pitch 'C#', octave: 4, duration: 3, type: 'quarter', dots: 1, alter: 1, voice: 2
      pitch 'D', octave: 4, duration: 1, type: 'eighth', voice: 2

      # Return for left hand
      backup 8

      # Left hand (staff 2)
      pitch 'A', octave: 2, duration: 8, type: 'whole', staff: 2
    end

    # Measure 3 - Dynamics and articulations
    measure do
      # Dynamic marking
      direction do
        dynamics 'pp'
        wedge 'crescendo'
      end

      # Notes with crescendo
      pitch 'C#', octave: 5, duration: 1, type: 'eighth', alter: 1
      pitch 'D', octave: 5, duration: 1, type: 'eighth'
      pitch 'E', octave: 5, duration: 1, type: 'eighth'
      pitch 'F#', octave: 5, duration: 1, type: 'eighth', alter: 1

      pitch 'G', octave: 5, duration: 1, type: 'eighth'
      pitch 'A', octave: 5, duration: 1, type: 'eighth'
      pitch 'B', octave: 5, duration: 1, type: 'eighth'
      pitch 'C#', octave: 6, duration: 1, type: 'eighth', alter: 1

      # End of crescendo, forte
      direction wedge: 'stop', dynamics: 'f'
    end
  end
end

# Export to file
File.write("etude.musicxml", score.to_xml.string)

# Or write directly to IO
File.open("etude.musicxml", 'w') { |f| score.to_xml(f) }
```

**Documentation:** See `lib/musicxml/builder/`

### MIDI - Voice Management & Recording

High-level MIDI tools for sequencer-synchronized playback and recording. These utilities integrate MIDI I/O with the sequencer timeline, ensuring correct timing even during fast-forward or quantization.

#### MIDIVoices - Polyphonic Voice Management

**MIDIVoices** manages MIDI channels as voices synchronized with the sequencer clock. Each voice maintains state (active notes, controllers, sustain pedal) and schedules all events on the musical timeline.

**Key features:**
- Voice abstraction for MIDI channels with automatic note scheduling
- Duration tracking and note-off scheduling
- Sustain pedal management
- Fast-forward support for silent timeline catch-up
- Polyphonic playback with chord support

```ruby
require 'musa-dsl'
require 'midi-communications'

# Setup sequencer and MIDI output
output = MIDICommunications::Output.gets  # Select MIDI output interactively
sequencer = Musa::Sequencer::Sequencer.new(4, 24)

# Create voice manager
voices = Musa::MIDIVoices::MIDIVoices.new(
  sequencer: sequencer,
  output: output,
  channels: [0, 1, 2]  # Use MIDI channels 0, 1, and 2
)

# Get a voice and play notes
voice = voices.voices.first

# Play single notes with automatic note-off
voice.note pitch: 60, velocity: 100, duration: 1/4r  # Quarter note

# Play chords
voice.note pitch: [60, 64, 67], velocity: 90, duration: 1r  # C major chord, whole note

# Control notes manually
note_ctrl = voice.note pitch: 64, velocity: 80, duration: nil  # Indefinite duration
note_ctrl.on_stop { puts "Note ended!" }
# ... later:
note_ctrl.note_off  # Manually stop the note

# Use fast-forward for silent catch-up (useful for seeking)
voices.fast_forward = true
# ... replay past events silently ...
voices.fast_forward = false  # Resume audible output
```

#### MIDIRecorder - MIDI Event Recording

**MIDIRecorder** captures raw MIDI bytes alongside sequencer position timestamps and converts them into structured note events. Useful for recording phrases from external MIDI controllers synchronized with the sequencer timeline.

**Key features:**
- Records MIDI events with sequencer position timestamps
- Transcribes raw MIDI into structured note hashes
- Pairs note-on/note-off events automatically
- Calculates durations and detects silences
- Output format compatible with Musa transcription pipelines

```ruby
require 'musa-dsl'
require 'midi-communications'

# Setup sequencer and MIDI input
input = MIDICommunications::Input.gets  # Select MIDI input interactively
sequencer = Musa::Sequencer::Sequencer.new(4, 24)

# Create recorder
recorder = Musa::MIDIRecorder::MIDIRecorder.new(sequencer)

# Capture MIDI from controller during playback
input.on_message { |bytes| recorder.record(bytes) }

# Start sequencer and play/record...
# (MIDI events from controller are captured with timing)

# After recording, get structured notes
notes = recorder.transcription

# The transcription returns an array of note hashes:
# [
#   { position: 1r, channel: 0, pitch: 60, velocity: 100, duration: 1/4r, velocity_off: 64 },
#   { position: 5/4r, channel: 0, pitch: :silence, duration: 1/8r },
#   { position: 11/8r, channel: 0, pitch: 62, velocity: 90, duration: 1/4r, velocity_off: 64 }
# ]

notes.each do |note|
  if note[:pitch] == :silence
    puts "Silence at #{note[:position]} for #{note[:duration]} bars"
  else
    puts "Note #{note[:pitch]} at #{note[:position]} for #{note[:duration]} bars (vel: #{note[:velocity]})"
  end
end

# Access raw recorded messages if needed
raw_messages = recorder.raw  # Array of timestamped MIDI events

# Clear for next recording
recorder.clear
```

**Transcription output format:**

Each note hash contains:
- `:position` - Sequencer position (Rational) when note started
- `:channel` - MIDI channel (0-15)
- `:pitch` - MIDI note number (0-127) or `:silence` for gaps
- `:velocity` - Note-on velocity (0-127)
- `:duration` - Note duration in bars (Rational)
- `:velocity_off` - Note-off velocity (0-127)

**Documentation:** See `lib/midi/`

### Transport - Timing & Clocks

Comprehensive timing infrastructure connecting clock sources to the sequencer. The transport system manages musical playback lifecycle, timing synchronization, and position control.

**Architecture:**
```
Clock --ticks--> Transport --tick()--> Sequencer --events--> Music
```

The system provides precise timing control with support for internal timers, MIDI clock synchronization, and manual control for testing and integration.

#### Clock - Timing Sources

**Clock** is the abstract base class for timing sources. All clocks generate regular ticks that drive the sequencer forward. Multiple clock implementations are available for different use cases.

**Available clock types:**

**TimerClock** - Internal high-precision timer-based clock:
- Standalone compositions with internal timing
- Configurable BPM (tempo) and ticks per beat
- Can dynamically change tempo during playback

**InputMidiClock** - Synchronized to external MIDI Clock messages:
- DAW-synchronized playback
- Automatically follows external MIDI Clock Start/Stop/Continue
- Locked to external timing source

**ExternalTickClock** - Manually triggered ticks:
- Testing and debugging
- Integration with external systems
- Frame-by-frame control

**DummyClock** - Simplified clock for testing:
- Fast playback without real-time constraints
- Useful for test suites or batch generation

```ruby
require 'musa-dsl'

# TimerClock - Internal timer-based timing
timer_clock = Musa::Clock::TimerClock.new(
  bpm: 120,              # Beats per minute
  ticks_per_beat: 24     # Resolution
)

# InputMidiClock - Synchronized to external MIDI Clock
require 'midi-communications'
midi_input = MIDICommunications::Input.gets  # Select MIDI input

midi_clock = Musa::Clock::InputMidiClock.new(midi_input)

# ExternalTickClock - Manual tick control
external_clock = Musa::Clock::ExternalTickClock.new

# DummyClock - For testing (100 ticks)
dummy_clock = Musa::Clock::DummyClock.new(100)
```

#### Transport - Playback Lifecycle Manager

**Transport** connects a clock to a sequencer and manages the playback lifecycle. It provides methods for starting/stopping playback, seeking to different positions, and registering callbacks for lifecycle events.

**Lifecycle phases:**
1. **before_begin** - Run once before first start (initialization)
2. **on_start** - Run each time transport starts
3. **Running** - Clock generates ticks → sequencer processes events
4. **on_change_position** - Run when position jumps/seeks
5. **after_stop** - Run when transport stops

**Key methods:**
- `start` - Start playback (blocks while running)
- `stop` - Stop playback
- `change_position_to(bars: n)` - Seek to position (in bars)

```ruby
require 'musa-dsl'

# Create clock
clock = Musa::Clock::TimerClock.new(bpm: 120, ticks_per_beat: 24)

# Create transport
transport = Musa::Transport::Transport.new(
  clock,
  4,   # beats_per_bar (time signature numerator)
  24   # ticks_per_beat (resolution)
)

# Access sequencer through transport
sequencer = transport.sequencer

# Schedule events
sequencer.at 1 do
  puts "Starting at bar 1!"
end

sequencer.at 4 do
  puts "Reached bar 4"
  transport.stop
end

# Register lifecycle callbacks
transport.before_begin do
  puts "Initializing (runs once)..."
end

transport.on_start do
  puts "Transport started!"
end

transport.after_stop do
  puts "Transport stopped, cleaning up..."
end

# Start playback (blocks until stopped)
transport.start

# Seeking example (in separate context)
# transport.change_position_to(bars: 2)  # Jump to bar 2
```

**Complete example with MIDI Clock synchronization:**

```ruby
require 'musa-dsl'
require 'midi-communications'

# Setup MIDI-synchronized clock
midi_input = MIDICommunications::Input.gets
clock = Musa::Clock::InputMidiClock.new(midi_input)

# Create transport
transport = Musa::Transport::Transport.new(clock, 4, 24)

# Schedule events
transport.sequencer.at 1 do
  puts "Synchronized start at bar 1!"
end

# Start and wait for MIDI Clock Start message
transport.start
```

**Documentation:** See `lib/transport/`

### Datasets - Sonic Data Structures

Comprehensive framework for representing and transforming sonic events and processes. Datasets are flexible, extensible hash structures that support multiple representations (MIDI, score notation, delta encoding) with rich conversion capabilities.

**Key characteristics:**

- **Flexible and extensible**: All datasets are hashes that can include any custom parameters beyond their natural keys
- **Event vs Process abstractions**: Distinguish between instantaneous events and time-spanning processes
- **Bidirectional conversions**: Transform between MIDI (PDV), score notation (GDV), delta encoding (GDVd), and other formats
- **Integration**: Used throughout MusaDSL components (sequencer, series, neumas, transcription, matrix)

#### Dataset Hierarchy

**Event Type Modules (E)** - Define absolute vs delta encoding:

```
E (base event)
├── Abs (absolute values)
│   ├── AbsI (array-indexed)       → used by V
│   ├── AbsTimed (with :time)      → used by P conversions
│   └── AbsD (with :duration)      → used by PDV, GDV
└── Delta (incremental values)
    ├── DeltaI (array-indexed delta)
    └── DeltaD (delta with duration) → used by GDVd
```

**Data Structure Modules** - Basic containers:

- **V**: Value arrays - ordered values in array form
- **PackedV**: Packed values - key-value hash pairs
- **P**: Point series - sequential points in time with durations [point, duration, point, duration, ...]

**Dataset Modules** - Domain-specific representations:

**Musical datasets** (scale-based and MIDI):
- **PDV**: Pitch/Duration/Velocity - MIDI-style absolute pitches (0-127)
- **GDV**: Grade/Duration/Velocity - Score-style scale degrees with dynamics
- **GDVd**: Grade/Duration/Velocity delta - Incremental encoding for compression

**Sonic datasets** (continuous parameters and events):
- **PS**: Parameter Segments - Continuous changes between multidimensional points (from/to/duration for glissandi, sweeps, modulations)
- **Score**: Time-indexed container for organizing sonic events

#### Event Categories

**Instantaneous Sound Events** - Occur at a point in time:
- Events without duration (triggers, markers)
- AbsTimed events (time-stamped values)

**Sound Processes** - Span duration over time:
- Notes with duration (AbsD, PDV, GDV)
- Glissandi and parameter sweeps (PS)
- Dynamics changes and other evolving parameters

#### Extensibility

All datasets support custom parameters beyond their natural keys:

```ruby
require 'musa-dsl'
include Musa::Datasets

# GDV with standard parameters
gdv = { grade: 0, duration: 1r, velocity: 0 }.extend(GDV)

# Extended with custom parameters for your composition
gdv_extended = {
  grade: 0,
  duration: 1r,
  velocity: 0,
  # Custom parameters
  articulation: :staccato,
  timbre: :bright,
  reverb_send: 0.3,
  custom_control: 42
}.extend(GDV)

# Custom parameters preserved through conversions
scale = Musa::Scales::Scales.et12[440.0].major[60]
pdv = gdv_extended.to_pdv(scale)
# => { pitch: 60, duration: 1r, velocity: 64,
#      articulation: :staccato, timbre: :bright, ... }
```

#### Dataset Validation

Check dataset validity and type:

```ruby
include Musa::Datasets

# Create dataset
gdv = { grade: 0, duration: 1r, velocity: 0 }.extend(GDV)

# Validation methods
gdv.valid?      # => true - check if valid
gdv.validate!   # Raises if invalid, returns if valid

# Type checking
gdv.is_a?(GDV)   # => true
gdv.is_a?(Abs)   # => true (GDV includes Abs)
gdv.is_a?(AbsD)  # => true (GDV includes AbsD for duration)
```

#### Dataset Conversions

Datasets provide rich conversion capabilities for transforming between different representations, each optimized for specific compositional tasks:

- **GDV ↔ PDV** (Score ↔ MIDI): Bidirectional conversion between symbolic information (scale degrees) and absolute pitches for (i.e.) MIDI output
- **GDV ↔ GDVd** (Absolute ↔ Delta): Generation and analysis of melodic patterns using incremental encoding
- **V ↔ PackedV** (Array ↔ Hash): Compact representation that expands to verbose structures with semantic labels
- **P → PS** (Points → Segments): Creation of glissandi and continuous interpolations between sequentially timed points
- **P → AbsTimed** (Relative → Absolute time): Conversion from relative temporal expressions to absolute time coordinates for (i.e.) scheduling and motif replication at different temporal positions
- **GDV → Neuma**: Export to Neumalang notation strings for human-readable scores

**Score ↔ MIDI (GDV ↔ PDV)**:

```ruby
include Musa::Datasets

scale = Musa::Scales::Scales.et12[440.0].major[60]

# Score to MIDI
gdv = { grade: 0, octave: 0, duration: 1r, velocity: 0 }.extend(GDV)
pdv = gdv.to_pdv(scale)
# => { pitch: 60, duration: 1r, velocity: 64 }

# MIDI to Score
pdv = { pitch: 64, duration: 1r, velocity: 80 }.extend(PDV)
gdv = pdv.to_gdv(scale)
# => { grade: 2, octave: 0, duration: 1r, velocity: 1 }
```

**Absolute ↔ Delta Encoding (GDV ↔ GDVd)**:

```ruby
include Musa::Datasets

scale = Musa::Scales::Scales.et12[440.0].major[60]

# First note (absolute)
gdv1 = { grade: 0, duration: 1r, velocity: 0 }.extend(GDV)
gdvd1 = gdv1.to_gdvd(scale)
# => { abs_grade: 0, abs_duration: 1r, abs_velocity: 0 }

# Second note (delta from previous)
gdv2 = { grade: 2, duration: 1r, velocity: 1 }.extend(GDV)
gdvd2 = gdv2.to_gdvd(scale, previous: gdv1)
# => { delta_grade: 2, delta_velocity: 1 }
# duration unchanged, omitted for compression
```

**Array ↔ Hash (V ↔ PackedV)**:

```ruby
include Musa::Datasets

# Array to hash
v = [60, 1r, 64].extend(V)
pv = v.to_packed_V([:pitch, :duration, :velocity])
# => { pitch: 60, duration: 1r, velocity: 64 }

# Hash to array
pv = { pitch: 60, duration: 1r, velocity: 64 }.extend(PackedV)
v = pv.to_V([:pitch, :duration, :velocity])
# => [60, 1r, 64]

# With default values (compression)
v = [60, 1r, 64].extend(V)
pv = v.to_packed_V({ pitch: 60, duration: 1r, velocity: 64 })
# => {}  (all values match defaults, fully compressed)
```

**Series ↔ Segments (P → PS)**:

```ruby
include Musa::Datasets

# Point series to parameter segments
p = [60, 4, 64, 8, 67].extend(P)
p.base_duration = 1/4r

ps_serie = p.to_ps_serie
ps1 = ps_serie.next_value
# => { from: 60, to: 64, duration: 1r, right_open: true }

ps2 = ps_serie.next_value
# => { from: 64, to: 67, duration: 2r, right_open: false }
```

**Series → Timed Events (P → AbsTimed)**:

```ruby
include Musa::Datasets

p = [60, 4, 64, 8, 67].extend(P)

timed_serie = p.to_timed_serie(base_duration: 1/4r, time_start: 0)
timed_serie.next_value  # => { time: 0r, value: 60 }
timed_serie.next_value  # => { time: 1r, value: 64 }
timed_serie.next_value  # => { time: 3r, value: 67 }
```

**Score Notation → String (GDV → Neuma)**:

```ruby
include Musa::Datasets

gdv = { grade: 0, octave: 1, duration: 1r, velocity: 2 }.extend(GDV)
gdv.base_duration = 1/4r

neuma = gdv.to_neuma
# => "(0 o1 4 f)"
# Format: (grade octave duration_in_quarters dynamics)
```

#### Integration with Other Components

**Sequencer** - Accepts extended datasets:

```ruby
require 'musa-dsl'
include Musa::All

sequencer = Sequencer.new(4, 24)

# Use GDV datasets directly
sequencer.at 1 do
  event = { grade: 0, duration: 1r, velocity: 0, articulation: :legato }.extend(GDV)
  # Process event...
end
```

**Series** - Work with any dataset type:

```ruby
include Musa::All

# Series of GDV events
gdv_serie = S(
  { grade: 0, duration: 1r }.extend(GDV),
  { grade: 2, duration: 1r }.extend(GDV),
  { grade: 4, duration: 1r }.extend(GDV)
)

# Transform while preserving dataset type
scale = Scales.et12[440.0].major[60]
pdv_serie = gdv_serie.map { |gdv| gdv.to_pdv(scale) }
```

**Matrix** - Generates P series:

```ruby
require 'musa-dsl'
using Musa::Extension::Matrix

# Matrix to P format
gesture = Matrix[[0, 60], [1, 62], [2, 64]]
p_sequences = gesture.to_p(time_dimension: 0)
# => [[[60], 1, [62], 1, [64]]]
# P format: alternating values and durations
```

**Neumas** - Parse to GDV:

```ruby
include Musa::All

# Neuma strings parse to GDV datasets
neuma = "(0 4 mf) (2 4 f) (4 4 ff)"
gdv_serie = Neumas(neuma, scale: Scales.default_system.default_tuning.major[60])

gdv_serie.each do |gdv|
  puts gdv.inspect  # Each is a GDV hash
  # => { grade: 0, duration: 1r, velocity: 0 }
  # => { grade: 2, duration: 1r, velocity: 1 }
  # => { grade: 4, duration: 1r, velocity: 2 }
end
```

**Transcription** - Converts between representations:

```ruby
include Musa::All

scale = Scales.et12[440.0].major[60]

# GDV to PDV for MIDI output
gdv_events = [
  { grade: 0, duration: 1r, velocity: 0 }.extend(GDV),
  { grade: 2, duration: 1r, velocity: 1 }.extend(GDV)
]

midi_events = gdv_events.map { |gdv| gdv.to_pdv(scale) }
# Send to MIDI output...
```

**Score Container** - Organize events in time:

```ruby
include Musa::Datasets

score = Score.new

# Add events at specific times
score.at(1r, add: { grade: 0, duration: 1r }.extend(GDV))
score.at(2r, add: { grade: 2, duration: 1r }.extend(GDV))
score.at(3r, add: { grade: 4, duration: 1r }.extend(GDV))

# Query events
events_at_2 = score.at(2r)
events_in_range = score.between(1r, 3r)
```

**Documentation:** See `lib/datasets/`

### Matrix - Sonic Gesture Conversion

Musa::Matrix provides refinements to convert matrix representations to P (point sequences) for sequencer playback. Sonic gestures can be represented as matrices where rows are time steps and columns are sonic parameters.

This opens a world of compositional possibilities by treating sonic gestures as **geometric objects in multidimensional spaces**. Each dimension of the matrix can represent a different sonic parameter (pitch, velocity, timbre, pan, filter cutoff, etc.), allowing you to:

- **Apply mathematical transformations**: Use standard matrix operations (rotation, scaling, translation, shearing) to transform sonic gestures geometrically. A rotation matrix can morph a melodic contour into a completely different shape while maintaining its gestural coherence.

- **Compose in geometric space**: Design sonic trajectories as paths through multidimensional parameter spaces. A straight line in pitch-velocity space becomes a linear glissando with proportional dynamic changes.

- **Interpolate and morph**: Create smooth transitions between sonic states by interpolating matrix points, generating continuous parameter sweeps that move through complex multidimensional spaces.

- **Decompose and recompose**: Extract individual parameter dimensions for independent processing, then recombine them into new sonic configurations.

The conversion to P format preserves the temporal relationships (durations calculated from time differences) while making the data suitable for sequencer playback, enabling you to realize complex geometric transformations as actual sonic events.

```ruby
require 'musa-dsl'

using Musa::Extension::Matrix

# Matrix representing a melodic gesture: [time, pitch]
# Time progresses: 0 -> 1 -> 2
# Pitch changes: 60 -> 62 -> 64
melody_matrix = Matrix[[0, 60], [1, 62], [2, 64]]

# Convert to P format for sequencer playback
# time_dimension: 0 means first column is time
# Time dimension removed, used only for duration calculation
p_sequence = melody_matrix.to_p(time_dimension: 0)

# Result: [[[60], 1, [62], 1, [64]]]
# Format: [[pitch1], duration1, [pitch2], duration2, [pitch3]]
# Each value [60], [62], [64] is extended with V module

# Multi-parameter example: [time, pitch, velocity]
gesture = Matrix[[0, 60, 100], [0.5, 62, 110], [1, 64, 120]]
p_with_velocity = gesture.to_p(time_dimension: 0)
# Result: [[[60, 100], 0.5, [62, 110], 0.5, [64, 120]]]

# Condensing connected gestures
phrase1 = Matrix[[0, 60], [1, 62]]
phrase2 = Matrix[[1, 62], [2, 64], [3, 65]]

# Matrices that share endpoints are automatically merged
merged = [phrase1, phrase2].to_p(time_dimension: 0)
# Result: [[[60], 1, [62], 1, [64], 1, [65]]]
# Both phrases merged into continuous sequence
```

**Use cases:**
- Converting recorded MIDI data to playable sequences
- Transforming algorithmic compositions from matrix form to time-based sequences
- Merging fragmented sonic gestures

**Documentation:** See `lib/matrix/`

## Documentation

Full API documentation is available in YARD format. All files in the project are comprehensively documented with:

- Architecture overviews
- Usage examples
- Parameter descriptions
- Return values
- Integration examples

To generate and view the documentation locally:

```bash
yard doc
yard server
```

Then open http://localhost:8808 in your browser.

## Examples & Works

Listen to compositions created with Musa-DSL: [yeste.studio](https://yeste.studio)

## Contributing

Contributions are welcome! Please feel free to:

1. Fork the repository
2. Create a feature branch
3. Make your changes with tests
4. Submit a pull request

**Repository:** https://github.com/javier-sy/musa-dsl

## License

Musa-DSL is released under the [LGPL-3.0-or-later](https://www.gnu.org/licenses/lgpl-3.0.html) license.

## Acknowledgments

- **Author:** Javier Sánchez Yeste ([yeste.studio](https://yeste.studio))
- **Email:** javier (at) yeste.studio

Special thanks to [JetBrains](https://www.jetbrains.com/?from=Musa-DSL) for providing an Open Source project license for RubyMine IDE during several years. 

---

*Musa-DSL - Algorithmic sound and musical thinking through code*
