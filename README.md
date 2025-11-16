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

Here's a simple example to get you started:

```ruby
require 'musa-dsl'

using Musa::Extension::Neumas

# Define a melody using neuma notation
melody = "0 +2 +2 -1 0 +4 +5 +7 +5 +4 +2 0".to_neumas

# Create a decoder with a major scale
scale = Musa::Scales::Scales.et12[440.0].major[60]
decoder = Musa::Neumas::Decoders::NeumaDecoder.new(
  scale,
  base_duration: 1/4r
)

# Decode to GDV (Grade-Duration-Velocity) events
notes = melody.map { |neuma| decoder.decode(neuma) }

# Notes are now ready to play
# Each note is a hash with: { grade: Integer, duration: Rational, velocity: Float }

# Setup MIDI output using midi-communications gem
require 'midi-communications'
output = MIDICommunications::Output.gets  # Interactively select output

notes.each do |note|
  pitch = scale.pitch_of(grade: note[:grade], octave: note[:octave])
  velocity = (note[:velocity] * 127).to_i

  output.puts(0x90, pitch, velocity)  # Note on
  sleep(note[:duration])
  output.puts(0x80, pitch, velocity)  # Note off
end
```

## System Architecture

Musa-DSL is organized into modular subsystems that work together:

```
┌─────────────────────────────────────────────────────────┐
│                    Musa-DSL Framework                    │
├─────────────────────────────────────────────────────────┤
│  Notation Layer                                          │
│  ┌──────────────┐  ┌──────────────┐                    │
│  │ Neumas       │  │ Neumalang    │                    │
│  │ (Text Nota.) │  │ (Parser)     │                    │
│  └──────────────┘  └──────────────┘                    │
├─────────────────────────────────────────────────────────┤
│  Generation Layer                                        │
│  ┌──────┐ ┌──────┐ ┌────────┐ ┌──────┐ ┌────────┐   │
│  │Series│ │Markov│ │Variatio│ │Rules │ │Grammar │   │
│  └──────┘ └──────┘ └────────┘ └──────┘ └────────┘   │
│                                         ┌──────┐       │
│                                         │Darwin│       │
│                                         └──────┘       │
├─────────────────────────────────────────────────────────┤
│  Musical Knowledge                                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐             │
│  │ Scales   │  │ Chords   │  │ Datasets │             │
│  └──────────┘  └──────────┘  └──────────┘             │
├─────────────────────────────────────────────────────────┤
│  Temporal Layer                                          │
│  ┌──────────────┐  ┌──────────────┐                    │
│  │ Sequencer    │  │ Transport    │                    │
│  └──────────────┘  └──────────────┘                    │
├─────────────────────────────────────────────────────────┤
│  Output Layer                                            │
│  ┌──────────────┐  ┌──────────────┐                    │
│  │ Transcription│  │ MusicXML     │                    │
│  │ (MIDI)       │  │ Builder      │                    │
│  └──────────────┘  └──────────────┘                    │
└─────────────────────────────────────────────────────────┘
```

## Core Subsystems

### Series - Sequence Generators

Series are the fundamental building blocks for generating musical sequences. They can represent pitches, rhythms, dynamics, or any musical parameter.

```ruby
require 'musa-dsl'

# Create a melodic series using operations
melody = S(0, 2, 4, 5, 7)
  .repeat(2)
  .transpose(12)
  .retrograde

# Infinite generative series
fibonacci = S(1, 1).extend { |prev, prev_prev| prev + prev_prev }

# Combine multiple series
rhythm = S(1/4r, 1/8r, 1/8r, 1/4r).cycle
pitches = S(60, 62, 64, 65, 67)
dynamics = S(0.5, 0.7, 0.9, 0.7, 0.5)

notes = pitches.zip(rhythm, dynamics).map do |p, r, d|
  { pitch: p, duration: r, velocity: d }
end
```

**Documentation:** See `lib/series/`

### Sequencer - Temporal Engine

The Sequencer manages time-based event scheduling with microsecond precision, supporting complex polyrhythmic and polytemporal structures.

```ruby
require 'musa-dsl'
require 'midi-communications'

# Create MIDI output
output = MIDICommunications::Output.gets  # Select MIDI output
scale = Musa::Scales::Scales.et12[440.0].major[60]

# Create clock and transport
clock = Musa::Clock::TimerClock.new(bpm: 120, ticks_per_beat: 24)
transport = Musa::Transport::Transport.new(clock, 4, 24)

# Setup MIDI voices
voices = Musa::MIDIVoices::MIDIVoices.new(
  sequencer: transport.sequencer,
  output: output,
  channels: [0]
)
voice = voices.voices.first

# Get the sequencer from transport
sequencer = transport.sequencer

# Schedule events at specific times
sequencer.at 0 do
  voice.note pitch: scale.pitch_of(grade: 0), duration: 1/4r
end

sequencer.at 1/4r do
  voice.note pitch: scale.pitch_of(grade: 2), duration: 1/4r
end

# Play series with timing
melody = Musa::Series::Constructors.S(0, 2, 4, 5, 7)
sequencer.play melody do |grade|
  voice.note pitch: scale.pitch_of(grade: grade), duration: 1/4r
end

# Repeat every beat
sequencer.every 1r do
  voice.note pitch: 36, duration: 1/8r  # Bass drum
end

transport.start
```

**Documentation:** See `lib/sequencer/`

### Neumas & Neumalang - Musical Notation

Neumas provide a compact text-based notation system inspired by medieval neumes. Neumalang is the parser that converts this notation to structured musical data.

```ruby
require 'musa-dsl'

using Musa::Extension::Neumas

# Simple notation
melody = "0 +2 +2 -1 0".n  # .n is shorthand for .to_neumas

# With durations
rhythm = "+2_ +2_2 +1_/2 +2_".n

# With ornaments
ornate = "+2.tr +3.mor -1.st".n

# With grace notes (appogiatura)
graceful = "(+1_/4)+2_ +2_ +3_".n

# Parallel voices (polyphony)
harmony = "0 +2 +4 +5" | "+7 +5 +7 +9"

# Array composition
song = [
  "0 +2 +4 +5",    # Verse
  "+7 +5 +7",      # Chorus
  "0 +2 +4 +5"     # Verse repeat
].to_neumas
```

**Notation syntax:**
- `0`, `+2`, `-1` - Absolute/relative pitch steps
- `^2`, `v1` - Octave shifts
- `_`, `_2`, `_/2` - Duration (base, double, half)
- `.tr`, `.mor`, `.turn`, `.st` - Ornaments
- `(grace)main` - Grace notes
- `|` - Parallel voices

**Documentation:** See `lib/neumas/` and `lib/neumalang/`

### Transcription - MIDI & MusicXML Output

The Transcription system converts GDV (Grade-Duration-Velocity) events to MIDI or MusicXML format, with support for ornament expansion.

```ruby
require 'musa-dsl'

# Create MIDI transcriptor with ornament expansion
transcriptor = Musa::Transcription::Transcriptor.new(
  Musa::Transcriptors::FromGDV::ToMIDI.transcription_set,
  base_duration: 1/4r
)

# Transcode GDV event with ornament to expanded GDV events
gdv_event = { grade: 2, octave: 0, duration: 1/4r, velocity: 0.7, tr: true }
expanded_events = transcriptor.transcript(gdv_event)

# Trill expanded to multiple rapid notes
# expanded_events is now an array of GDV hashes:
# [{ grade: 3, octave: 0, duration: 1/24r, velocity: 0.7 },
#  { grade: 2, octave: 0, duration: 1/24r, velocity: 0.7 },
#  { grade: 3, octave: 0, duration: 1/24r, velocity: 0.7 }, ...]

# Convert to MIDI and send using midi-communications
require 'midi-communications'
output = MIDICommunications::Output.gets  # Select MIDI output

scale = Musa::Scales::Scales.et12[440.0].major[60]
expanded_events.each do |event|
  pitch = scale.pitch_of(grade: event[:grade], octave: event[:octave])
  velocity = (event[:velocity] * 127).to_i

  output.puts(0x90, pitch, velocity)  # Note on
  sleep(event[:duration])
  output.puts(0x80, pitch, velocity)  # Note off
end

# Create MusicXML transcriptor (preserves ornaments as symbols)
xml_transcriptor = Musa::Transcription::Transcriptor.new(
  Musa::Transcriptors::FromGDV::ToMusicXML.transcription_set
)
```

**Supported ornaments:**
- Appogiatura (grace notes)
- Mordent
- Turn
- Trill
- Staccato

**Documentation:** See `lib/transcription/`

### Generative - Algorithmic Composition

Tools for generative and algorithmic music composition.

```ruby
require 'musa-dsl'

# 1. Markov chains - Probabilistic sequence generation
markov = Musa::Generative::Markov.new do
  from 0, to: { 2 => 0.5, 4 => 0.3, 7 => 0.2 }
  from 2, to: { 0 => 0.3, 4 => 0.5, 5 => 0.2 }
  from 4, to: { 2 => 0.4, 5 => 0.4, 7 => 0.2 }
end

melody = markov.series(starting: 0).take(16)

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
    prune if history.last == chord
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
dorian = Musa::Scales::Scales.et12[440.0].dorian[60]    # C dorian

# Use scales to convert grades to pitches
pitch = major.pitch_of(grade: 2, octave: 0)  # => 64 (E)

# Chromatic operations
transposed = major.chromatic_of(grade: 2, sharp: 1)  # E#

# Chord definitions
c_major = Musa::Chords.get(:major, root: 60)
d_minor7 = Musa::Chords.get(:minor7, root: 62)

# Get chord notes
notes = c_major.notes  # => [60, 64, 67] (C, E, G)
```

**Documentation:** See `lib/music/`

### MusicXML Builder - Music Notation Export

Generate MusicXML files for notation software (Finale, Sibelius, MuseScore, etc.).

```ruby
require 'musa-dsl'

# Create a score
score = Musa::MusicXML::Builder::ScorePartwise.new(
  title: "My Composition",
  composer: "Your Name"
)

# Add a part
part = score.part(id: "P1", name: "Piano")

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
File.write("score.musicxml", score.to_xml)
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
score.add(time: 0, value: { pitch: 60, duration: 1/4r })
score.add(time: 1/4r, value: { pitch: 64, duration: 1/4r })
```

**Documentation:** See `lib/datasets/`

### Matrix - Mathematical Transformations

Matrix operations for musical transformations.

```ruby
require 'musa-dsl'

# Create transformation matrix
matrix = Musa::Matrix[
  [1, 0, 2],
  [0, 1, 3],
  [0, 0, 1]
]

# Apply to musical coordinates
point = [60, 64, 1]  # [pitch1, pitch2, homogeneous]
transformed = matrix * point
```

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
