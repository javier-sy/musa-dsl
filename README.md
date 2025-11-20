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

```ruby
require 'musa-dsl'

# 1. Markov chains - Probabilistic sequence generation
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

melody = []
16.times do
  value = markov.next_value
  break unless value
  melody << value
end

# 2. Variatio - Cartesian product of parameter variations
#    Generates ALL combinations of field values
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

# 3. Rules - Production system with growth and pruning
#    Similar to L-systems, generates tree of valid possibilities
rules = Musa::Rules::Rules.new do
  # Growth rules - generate possibilities
  grow 'next chord' do |chord, history|
    case chord
    when :I   then branch(:ii); branch(:IV); branch(:V)
    when :ii  then branch(:V)
    when :IV  then branch(:I); branch(:V)
    when :V   then branch(:I)
    end
  end

  # Pruning rules - eliminate invalid paths
  cut 'avoid repetition' do |chord, history|
    prune if history.size > 0 && history.last == chord
  end

  # End condition
  ended_when do |chord, history|
    history.size == 4  # 4-chord progression
  end
end

tree = rules.apply([:I])
progressions = tree.combinations
# => [[:I, :ii, :V, :I], [:I, :IV, :V, :I], [:I, :IV, :I], ...]

# 4. Generative Grammar - Formal grammars with combinatorial generation
#    Defines grammars using operators | (or), + (sequence), repeat, limit
include Musa::GenerativeGrammar

a = N('a', size: 1)
b = N('b', size: 1)
c = N('c', size: 1)

# Grammar: (a or b) repeated 3 times, then c
grammar = (a | b).repeat(3) + c

# Generate all possibilities
grammar.options(content: :join)
# => ["aaac", "aabc", "abac", "abbc", "baac", "babc", "bbac", "bbbc"]
# 2^3 × 1 = 8 combinations

# With constraints
grammar_limited = (a | b).repeat.limit { |o|
  o.collect { |e| e.attributes[:size] }.sum == 3
}

grammar_limited.options(content: :join)
# => ["aaa", "aab", "aba", "abb", "baa", "bab", "bba", "bbb"]

# 5. Darwin - Genetic algorithms
darwin = Musa::Generative::Darwin.new(
  population_size: 100,
  genome_length: 16
) do |genome|
  # Fitness function
  evaluate_melody_fitness(genome)
end

best_melody = darwin.evolve(generations: 50)
```

**Documentation:** See `lib/generative/`

### Music - Scales & Chords

Comprehensive support for musical scales, tuning systems, and chord structures.

```ruby
require 'musa-dsl'

# Get scales from equal temperament 12-tone system
# et12[reference_frequency].scale_mode[tonic_pitch]
major = Musa::Scales::Scales.et12[440.0].major[60]      # C major
minor = Musa::Scales::Scales.et12[440.0].minor[62]      # D minor

# Use scales to convert grades to pitches
pitch = major.grade(2).pitch  # => 64 (E)

# Access scale notes with octave
note = major.grade(2).octave(1)  # E in octave 1
pitch_with_octave = note.pitch   # => 76

# Chord definitions from scale
c_major = major.tonic.chord
d_minor = major.grade(1).chord

# Get chord note pitches
notes = c_major.notes.map { |n| n.note.pitch }  # => [60, 64, 67] (C, E, G)
```

**Documentation:** See `lib/music/`

### MusicXML Builder - Music Notation Export

Generate MusicXML files for notation software (Finale, Sibelius, MuseScore, etc.).

```ruby
require 'musa-dsl'

# Create a score
score = Musa::MusicXML::Builder::ScorePartwise.new(
  work_title: "My Composition"
)

# Add creator information
score.creators type: "composer", name: "Your Name"

# Add a part
part = score.part "P1", name: "Piano"

# Add measures with notes
measure = part.measure(number: 1)
measure.attributes do
  time 4, 4
  key 0  # C major
  clef :treble
end

measure.note do
  pitch :C, 4
  duration 1
  type :quarter
end

# Export to file
File.write("score.musicxml", score.to_xml.string)
```

**Documentation:** See `lib/musicxml/builder/`

### MIDI - MIDI Recording & Voice Management

Tools for working with MIDI input/output.

```ruby
require 'musa-dsl'

# MIDI voice management for polyphonic playback
require 'midi-communications'

output = MIDICommunications::Output.gets
sequencer = Musa::Sequencer::Sequencer.new(4, 24)

voices = Musa::MIDIVoices::MIDIVoices.new(
  sequencer: sequencer,
  output: output,
  channels: [0],
  polyphony: 8
)

# Use voices for playback
voice = voices.voices.first
voice.note pitch: 60, duration: 1/4r, velocity: 100

# MIDI recording
recorder = Musa::MIDIRecorder::MIDIRecorder.new(
  sequencer: sequencer,
  output: output,
  channel: 0
)

recorder.start
# Recording captures MIDI events with timing
recorder.stop
```

**Documentation:** See `lib/midi/`

### Transport - Timing & Clocks

Precise timing control with multiple clock sources.

```ruby
require 'musa-dsl'

# Internal timer-based clock
clock = Musa::Clock::TimerClock.new(
  bpm: 120,
  ticks_per_beat: 24
)

# Create transport connecting clock to sequencer
transport = Musa::Transport::Transport.new(
  clock,
  4,   # beats_per_bar
  24   # ticks_per_beat
)

# MIDI-based clock (synchronized to external MIDI Clock messages)
require 'midi-communications'
midi_input = MIDICommunications::Input.gets  # Select MIDI input interactively

midi_clock = Musa::Clock::InputMidiClock.new(midi_input)
midi_transport = Musa::Transport::Transport.new(midi_clock, 4, 24)

# External tick-based clock (for manual control)
external_clock = Musa::Clock::ExternalTickClock.new
external_transport = Musa::Transport::Transport.new(external_clock, 4, 24)

# Access sequencer through transport
sequencer = transport.sequencer
```

**Documentation:** See `lib/transport/`

### Datasets - Musical Data Structures

Specialized data structures for musical events.

```ruby
require 'musa-dsl'

# GDV - Grade, Duration, Velocity (absolute)
gdv = { grade: 2, duration: 1/4r, velocity: 0.7 }

# GDVd - Grade, Duration, Velocity (differential)
gdvd = { grade_diff: +2, duration_factor: 2, velocity_factor: 1.2 }

# PDV - Pitch, Duration, Velocity
pdv = { pitch: 64, duration: 1/4r, velocity: 100 }

# Score - Timed event sequences
score = Musa::Datasets::Score.new
score << { start: 0, duration: 1/4r, value: { pitch: 60 } }
score << { start: 1/4r, duration: 1/4r, value: { pitch: 64 } }
```

**Documentation:** See `lib/datasets/`

### Matrix - Musical Gesture Conversion

Musa::Matrix provides refinements to convert matrix representations to P (point sequences) for sequencer playback. Musical gestures can be represented as matrices where rows are time steps and columns are musical parameters.

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
- Merging fragmented musical gestures

**Documentation:** See `lib/matrix/`

## Documentation

Full API documentation is available in YARD format. All 114+ Ruby files in the project are comprehensively documented with:

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
- **Email:** javier.sy@gmail.com

Special thanks to [JetBrains](https://www.jetbrains.com/?from=Musa-DSL) for providing an Open Source project license for RubyMine IDE. Your support is greatly appreciated!

---

*Musa-DSL - Algorithmic sound and musical thinking through code*
