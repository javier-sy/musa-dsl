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

## Getting Started

### Recommended Editor: RubyMine

[RubyMine](https://www.jetbrains.com/ruby/) provides the best experience for MusaDSL development: intelligent autocomplete of methods and parameters, hover documentation, and type inference help you discover the API as you write.

**Free licenses available:**
- [Non-commercial use](https://www.jetbrains.com/non-commercial/) — for learning, hobbies, open-source, content creation
- [Students](https://www.jetbrains.com/academy/student-pack/) and [Teachers/Researchers](https://www.jetbrains.com/academy/teacher-pack/) — with institutional email

[VSCode](https://code.visualstudio.com/) with the Ruby LSP extension also works well, though Ruby autocomplete and hover documentation are less complete.

### Framework Installation

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

## Examples

Two complete, runnable examples included here. Pedagogical learning is covered separately in the [musadsl-demo](https://github.com/javier-sy/musadsl-demo) repository.

- **[Sequencer DSL with interacting voices](docs/examples/sequencer-dsl-voices.md)** — multiple voice lines coordinated through shared state, demonstrating the sequencer DSL and timing primitives.
- **[Neuma notation](docs/examples/neuma-notation.md)** — composing melodies with grade-based Neuma notation and the parser.

## Demo Projects

A collection of 22+ working demo projects covering the full spectrum of Musa DSL capabilities:

- **Basic concepts**: Setup, series, neumas, canon
- **Generative tools**: Markov chains, Variatio, Darwin, Grammar, Rules, Matrix
- **DAW integration**: MIDI sync, live coding, clock modes
- **External protocols**: OSC with SuperCollider and Max/MSP
- **Advanced patterns**: Event architecture, parameter automation, multi-phase compositions

Each demo is a complete, runnable project with documentation explaining the concepts demonstrated.

**📦 [musadsl-demo Repository](https://github.com/javier-sy/musadsl-demo)**

## MusaDSL Ecosystem

MusaDSL is a comprehensive ecosystem consisting of a core framework (musa-dsl) and associated projects for communication, development, and integration.

**Core Framework:**
- [**musa-dsl**](https://github.com/javier-sy/musa-dsl) - Main DSL framework for algorithmic composition and musical thinking

**MIDI Communication Stack** (used internally by musa-dsl for MIDI I/O):
- [**midi-events**](https://github.com/javier-sy/midi-events) - Low-level MIDI event definitions and protocols
- [**midi-parser**](https://github.com/javier-sy/midi-parser) - MIDI file parsing and analysis
- [**midi-communications**](https://github.com/javier-sy/midi-communications) - Cross-platform MIDI I/O abstraction layer
- [**midi-communications-macos**](https://github.com/javier-sy/midi-communications-macos) - macOS-specific MIDI native implementation

## MusaDSL Architecture

The musa-dsl framework is organized in modular layers. Each component has its own detailed documentation.

### 1. Foundation Layer
- [**core-ext**](docs/subsystems/core-extensions.md) - Ruby refinements and metaprogramming utilities: Arrayfy, Hashify, ExplodeRanges, DeepCopy, DynamicProxy, AttributeBuilder.
- **logger** - Structured logging system with severity levels.

### 2. Temporal & Scheduling Layer
- [**sequencer**](docs/subsystems/sequencer.md) - Event scheduling engine with musical time (bars/beats), microsecond-precise tick-based timing, and a DSL for temporal composition. Tick-based (quantized) and tickless (continuous) modes; series playback with automatic duration management; polyrhythms and polytemporal structures.
- [**transport**](docs/subsystems/transport.md) - Comprehensive timing infrastructure connecting clock sources to the sequencer. Supports multiple clock types (TimerClock, InputMidiClock, ExternalTickClock, DummyClock), BPM management, tempo changes, and the start/stop/pause/continue playback lifecycle.

### 3. Notation & Parsing Layer
- [**neumas + neumalang**](docs/subsystems/neumas.md) - Compact text-based musical notation system with parser and interpreter for converting notation to structured musical data, with DSL support.

### 4. Generation & Transformation Layer
- [**series**](docs/subsystems/series.md) - Lazy functional sequence generators with map/filter operations, numeric generators, buffering, quantization, and timed merging. Transpose, repeat, and combination operations; infinite and finite series support.
- [**generative**](docs/subsystems/generative.md) - Algorithmic composition tools: Markov chains (probabilistic sequence generation), Variatio (Cartesian product parameter variations), Rules (L-system-like production systems with growth/pruning), GenerativeGrammar (formal grammar-based generation), and Darwin (genetic algorithms for evolutionary composition).
- [**matrix**](docs/subsystems/matrix.md) - Matrix operations for musical gestures: matrix-to-P (point sequence) conversion for sequencer playback, gesture condensation and transformation. Treats sonic gestures as geometric objects.

### 5. Output & Communication Layer
- [**transcription**](docs/subsystems/transcription.md) - Musical event transformation system with ornament expansion (trills, mordents, turns), GDV to MIDI/MusicXML conversion, and dynamic articulation rendering. Expansion for MIDI or preservation as notation symbols for MusicXML.
- [**musicxml**](docs/subsystems/musicxml-builder.md) - MusicXML score generation. Hierarchical structure, multiple voices, multi-part scores, articulations, dynamics, tempo, and notation directives. Standard MusicXML 3.0 output.
- [**midi**](docs/subsystems/midi.md) - MIDI voice management with polyphonic voice allocation, channel management, note-on/note-off scheduling, automatic note tracking, and MIDI input recording with precise timestamping.

### 6. Musical Knowledge Layer
- [**music**](docs/subsystems/music.md) - Scales, tuning systems, intervals, and chord structures. Equal temperament and just intonation support; modal scales (major, minor, chromatic, etc.); chord definitions, harmonic analysis, and chord navigation.
- [**datasets**](docs/subsystems/datasets.md) - Type-safe musical event representations: GDV (Grade-Duration-Velocity, scale-relative), PDV (Pitch-Duration-Velocity, absolute), PS, P, V. Conversions, validation, Score container (timeline-based multi-track composition), and advanced queries.

### 7. Development & Interaction Layer
- [**repl**](docs/subsystems/repl.md) - Interactive Read-Eval-Print Loop for live composition. TCP-based server for real-time code evaluation and error handling. Consumed by external REPL clients (editor extensions, custom evaluators).

## Author

* [Javier Sánchez Yeste](https://github.com/javier-sy)

## License

[Musa-DSL](https://github.com/javier-sy/musa-dsl) Copyright (c) 2016-2026 [Javier Sánchez Yeste](https://yeste.studio), licensed under LGPL 3.0 License
