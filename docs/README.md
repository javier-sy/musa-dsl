# Musa DSL Documentation

Complete documentation for the Musa DSL framework for algorithmic sound and musical composition.

## 📚 Documentation Structure

### Getting Started
- **[Installation](../README.md#getting-started)** - Set up Musa DSL
- **[Examples](../README.md#examples)** - Two runnable examples:
  - [Sequencer DSL with interacting voices](https://github.com/javier-sy/musa-dsl/blob/master/docs/examples/sequencer-dsl-voices.md)
  - [Neuma notation](https://github.com/javier-sy/musa-dsl/blob/master/docs/examples/neuma-notation.md)

### Core Subsystems

Detailed documentation for each Musa DSL subsystem:

| Subsystem | Description | Documentation |
|-----------|-------------|---------------|
| **MIDI** | Voice management & recording | [midi.md](https://github.com/javier-sy/musa-dsl/blob/master/docs/subsystems/midi.md) |
| **Sequencer** | Temporal engine | [sequencer.md](https://github.com/javier-sy/musa-dsl/blob/master/docs/subsystems/sequencer.md) |
| **Transport** | Timing & clocks | [subsystems/transport.md](https://github.com/javier-sy/musa-dsl/blob/master/docs/subsystems/transport.md) |
| **Series** | Sequence generators | [series.md](https://github.com/javier-sy/musa-dsl/blob/master/docs/subsystems/series.md) |
| **Neumas** | Musical notation | [neumas.md](https://github.com/javier-sy/musa-dsl/blob/master/docs/subsystems/neumas.md) |
| **Datasets** | Sonic data structures | [datasets.md](https://github.com/javier-sy/musa-dsl/blob/master/docs/subsystems/datasets.md) |
| **Matrix** | Sonic gesture conversion | [matrix.md](https://github.com/javier-sy/musa-dsl/blob/master/docs/subsystems/matrix.md) |
| **Transcription** | MIDI & MusicXML output | [transcription.md](https://github.com/javier-sy/musa-dsl/blob/master/docs/subsystems/transcription.md) |
| **Music** | Scales & chords | [music.md](https://github.com/javier-sy/musa-dsl/blob/master/docs/subsystems/music.md) |
| **Generative** | Algorithmic composition | [generative.md](https://github.com/javier-sy/musa-dsl/blob/master/docs/subsystems/generative.md) |
| **MusicXML Builder** | Music notation export | [musicxml-builder.md](https://github.com/javier-sy/musa-dsl/blob/master/docs/subsystems/musicxml-builder.md) |

### Advanced Topics

For users extending the DSL or integrating deeply:

| Topic | Description | Documentation |
|-------|-------------|---------------|
| **REPL** | Live coding infrastructure | [repl.md](https://github.com/javier-sy/musa-dsl/blob/master/docs/subsystems/repl.md) |
| **Core Extensions** | Metaprogramming utilities | [core-extensions.md](https://github.com/javier-sy/musa-dsl/blob/master/docs/subsystems/core-extensions.md) |

## 🎯 Learning Paths

### New to Musa DSL?
1. Start with one of the [Examples](../README.md#examples)
2. Read [MusaDSL Architecture](../README.md#musadsl-architecture)
3. Explore subsystems in this order:
   - [MIDI](https://github.com/javier-sy/musa-dsl/blob/master/docs/subsystems/midi.md) - Output basics
   - [Sequencer](https://github.com/javier-sy/musa-dsl/blob/master/docs/subsystems/sequencer.md) - Temporal control
   - [Series](https://github.com/javier-sy/musa-dsl/blob/master/docs/subsystems/series.md) - Sequence generation
   - [Datasets](https://github.com/javier-sy/musa-dsl/blob/master/docs/subsystems/datasets.md) - Data structures

### Want to Compose?
1. Learn [Neumas](https://github.com/javier-sy/musa-dsl/blob/master/docs/subsystems/neumas.md) notation
2. Explore [Music](https://github.com/javier-sy/musa-dsl/blob/master/docs/subsystems/music.md) (scales & chords)
3. Try [Generative](https://github.com/javier-sy/musa-dsl/blob/master/docs/subsystems/generative.md) algorithms
4. Use [MusicXML Builder](https://github.com/javier-sy/musa-dsl/blob/master/docs/subsystems/musicxml-builder.md) for scores
5. Explore [Demo Projects](https://github.com/javier-sy/musadsl-demo) - 22+ working examples

### Live Coding?
1. Set up [REPL](https://github.com/javier-sy/musa-dsl/blob/master/docs/subsystems/repl.md)
2. Configure MusaLCE client (VSCode/Atom/Bitwig/Live)
3. Learn [Sequencer](https://github.com/javier-sy/musa-dsl/blob/master/docs/subsystems/sequencer.md) DSL
4. Explore [Transport](https://github.com/javier-sy/musa-dsl/blob/master/docs/subsystems/transport.md) for timing

### Extending the DSL?
1. Understand [Core Extensions](https://github.com/javier-sy/musa-dsl/blob/master/docs/subsystems/core-extensions.md)
2. Study [Datasets](https://github.com/javier-sy/musa-dsl/blob/master/docs/subsystems/datasets.md) extensibility
3. Review existing subsystem implementations
4. Check YARD documentation for API details

## 📖 Additional Resources

- **Main README**: [../README.md](https://github.com/javier-sy/musa-dsl/blob/master/docs/README.md)
- **API Reference**: [api-reference.md](https://github.com/javier-sy/musa-dsl/blob/master/docs/api-reference.md) - Complete class/method documentation (RubyDoc.info)
- **Examples**: See examples/ directory in repository
- **Source Code**: lib/musa-dsl/

## 🔗 External Links

- **GitHub Repository**: https://github.com/javier-sy/musa-dsl
- **RubyGems**: https://rubygems.org/gems/musa-dsl
- **Community**: See [Contributing](../README.md#contributing)

---

**Navigation**: [← Back to Main README](https://github.com/javier-sy/musa-dsl/blob/master/docs/README.md) | [↑ Top](#musa-dsl-documentation)
