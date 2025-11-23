# Musa DSL Documentation

Complete documentation for the Musa DSL framework for algorithmic sound and musical composition.

## 📚 Documentation Structure

### Getting Started
- **[Installation](../README.md#installation)** - Set up Musa DSL
- **[Quick Start](../README.md#quick-start)** - 5-minute introduction
- **[Not So Quick Start](../README.md#not-so-quick-start)** - Comprehensive tutorial

### Core Subsystems

Detailed documentation for each Musa DSL subsystem:

| Subsystem | Description | Documentation |
|-----------|-------------|---------------|
| **MIDI** | Voice management & recording | [midi.md](subsystems/midi.md) |
| **Sequencer** | Temporal engine | [sequencer.md](subsystems/sequencer.md) |
| **Transport** | Timing & clocks | [subsystems/transport.md](subsystems/transport.md) |
| **Series** | Sequence generators | [series.md](subsystems/series.md) |
| **Neumas** | Musical notation | [neumas.md](subsystems/neumas.md) |
| **Datasets** | Sonic data structures | [datasets.md](subsystems/datasets.md) |
| **Matrix** | Sonic gesture conversion | [matrix.md](subsystems/matrix.md) |
| **Transcription** | MIDI & MusicXML output | [transcription.md](subsystems/transcription.md) |
| **Music** | Scales & chords | [music.md](subsystems/music.md) |
| **Generative** | Algorithmic composition | [generative.md](subsystems/generative.md) |
| **MusicXML Builder** | Music notation export | [musicxml-builder.md](subsystems/musicxml-builder.md) |

### Advanced Topics

For users extending the DSL or integrating deeply:

| Topic | Description | Documentation |
|-------|-------------|---------------|
| **REPL** | Live coding infrastructure | [repl.md](subsystems/repl.md) |
| **Core Extensions** | Metaprogramming utilities | [core-extensions.md](subsystems/core-extensions.md) |

## 🎯 Learning Paths

### New to Musa DSL?
1. Start with [Quick Start](../README.md#quick-start)
2. Read [System Architecture](../README.md#system-architecture)
3. Explore subsystems in this order:
   - [MIDI](subsystems/midi.md) - Output basics
   - [Sequencer](subsystems/sequencer.md) - Temporal control
   - [Series](subsystems/series.md) - Sequence generation
   - [Datasets](subsystems/datasets.md) - Data structures

### Want to Compose?
1. Learn [Neumas](subsystems/neumas.md) notation
2. Explore [Music](subsystems/music.md) (scales & chords)
3. Try [Generative](subsystems/generative.md) algorithms
4. Use [MusicXML Builder](subsystems/musicxml-builder.md) for scores

### Live Coding?
1. Set up [REPL](subsystems/repl.md)
2. Configure MusaLCE client (VSCode/Atom/Bitwig/Live)
3. Learn [Sequencer](subsystems/sequencer.md) DSL
4. Explore [Transport](subsystems/transport.md) for timing

### Extending the DSL?
1. Understand [Core Extensions](subsystems/core-extensions.md)
2. Study [Datasets](subsystems/datasets.md) extensibility
3. Review existing subsystem implementations
4. Check YARD documentation for API details

## 📖 Additional Resources

- **Main README**: [../README.md](../README.md)
- **API Reference**: [api-reference.md](api-reference.md) - Complete class/method documentation (RubyDoc.info)
- **Examples**: See examples/ directory in repository
- **Source Code**: lib/musa-dsl/

## 🔗 External Links

- **GitHub Repository**: https://github.com/javier-sy/musa-dsl
- **RubyGems**: https://rubygems.org/gems/musa-dsl
- **Community**: See [Contributing](../README.md#contributing)

---

**Navigation**: [← Back to Main README](../README.md) | [↑ Top](#musa-dsl-documentation)
