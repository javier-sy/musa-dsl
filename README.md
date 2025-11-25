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

A complete working example with multiple interacting voice lines, demonstrating sequencer DSL, timing control, and shared state.

**📖 [Complete Quick Start Guide](docs/getting-started/quick-start.md)**

## Tutorial

Detailed tutorial showing the Neuma notation system for composing melodies with grade-based notation.

**📖 [Complete Tutorial](docs/getting-started/tutorial.md)**

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
- [**MusaLCEforBitwig**](https://github.com/javier-sy/MusaLCEforBitwig) - Bitwig Studio integration for live coding
- [**MusaLCEforLive**](https://github.com/javier-sy/MusaLCEforLive) - Ableton Live integration for live coding

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

### MIDI - Voice Management & Recording

Polyphonic voice management for MIDI output with automatic note tracking, and MIDI input recording with precise timestamping.

**📖 [Complete Documentation](docs/subsystems/midi.md)**

### Sequencer - Temporal Engine

Event scheduling engine with musical time (bars/beats), precise tick-based timing, and DSL for temporal composition.

**📖 [Complete Documentation](docs/subsystems/sequencer.md)**

### Transport - Timing & Clocks

Comprehensive timing infrastructure connecting clock sources to the sequencer. Supports multiple clock types (TimerClock, InputMidiClock, ExternalTickClock, DummyClock) and manages playback lifecycle with precise timing control.

**📖 [Complete Transport Documentation](docs/subsystems/transport.md)**


### Series - Sequence Generators

Lazy functional sequence generators with map/filter operations, numeric generators, buffering, quantization, and timed merging.

**📖 [Complete Documentation](docs/subsystems/series.md)**

### Neumas & Neumalang - Musical Notation

Compact text-based musical notation system with parser for converting notation to structured musical data.

**📖 [Complete Documentation](docs/subsystems/neumas.md)**

### Datasets - Sonic Data Structures

Type-safe musical event representations (GDV, PDV, PS, P, V) with conversions, validation, Score container, and advanced queries.

**📖 [Complete Documentation](docs/subsystems/datasets.md)**

### Matrix - Sonic Gesture Conversion

Convert matrix representations to point sequences for sequencer playback, treating sonic gestures as geometric objects.

**📖 [Complete Documentation](docs/subsystems/matrix.md)**

### Transcription - MIDI & MusicXML Output

Convert between representations with ornament expansion for MIDI or preservation as notation symbols for MusicXML.

**📖 [Complete Documentation](docs/subsystems/transcription.md)**

### Music - Scales & Chords

Comprehensive scale and chord systems with equal temperament, custom tunings, chord navigation, and extensible definitions.

**📖 [Complete Documentation](docs/subsystems/music.md)**

### Generative - Algorithmic Composition

Algorithmic composition tools: Markov chains, Variatio, Rules (L-systems), GenerativeGrammar, and Darwin (genetic algorithms).

**📖 [Complete Documentation](docs/subsystems/generative.md)**

### MusicXML Builder - Music Notation Export

Comprehensive MusicXML score generation with hierarchical structure, multiple voices, articulations, and dynamics.

**📖 [Complete Documentation](docs/subsystems/musicxml-builder.md)**

### REPL - Live Coding Infrastructure

TCP-based server for live coding with MusaLCE clients (VSCode, Atom, Bitwig, Live), real-time code evaluation and error handling.

**📖 [Complete Documentation](docs/subsystems/repl.md)**

### Core Extensions - Advanced Metaprogramming

Ruby refinements and metaprogramming utilities: Arrayfy, Hashify, ExplodeRanges, DeepCopy, DynamicProxy, AttributeBuilder, Logger.

**📖 [Complete Documentation](docs/subsystems/core-extensions.md)**

## Author

* [Javier Sánchez Yeste](https://github.com/javier-sy)

## License

[Musa-DSL](https://github.com/javier-sy/musa-dsl) Copyright (c) 2016-2025 [Javier Sánchez Yeste](https://yeste.studio), licensed under LGPL 3.0 License
