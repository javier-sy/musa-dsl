# API Reference

Complete class and method documentation generated from inline YARD comments.

## Online Documentation

**Official API documentation is hosted on RubyDoc.info:**

🔗 **[https://rubydoc.info/gems/musa-dsl](https://rubydoc.info/gems/musa-dsl)**

This documentation is automatically generated and updated with each gem release.

## Key Modules

### Foundation
- [Musa::Extension](https://rubydoc.info/gems/musa-dsl/Musa/Extension) - Ruby refinements and metaprogramming
- [Musa::Logger](https://rubydoc.info/gems/musa-dsl/Musa/Logger) - Structured logging

### Temporal & Scheduling
- [Musa::Sequencer](https://rubydoc.info/gems/musa-dsl/Musa/Sequencer) - Event scheduling engine
- [Musa::Transport](https://rubydoc.info/gems/musa-dsl/Musa/Transport) - Playback lifecycle
- [Musa::Clock](https://rubydoc.info/gems/musa-dsl/Musa/Clock) - Timing sources

### Notation & Parsing
- [Musa::Neumas](https://rubydoc.info/gems/musa-dsl/Musa/Neumas) - Musical notation
- [Musa::Neumalang](https://rubydoc.info/gems/musa-dsl/Musa/Neumalang) - Notation parser

### Generation & Transformation
- [Musa::Series](https://rubydoc.info/gems/musa-dsl/Musa/Series) - Sequence generators
- [Musa::Generative](https://rubydoc.info/gems/musa-dsl/Musa/Generative) - Algorithmic composition
- [Musa::Matrix](https://rubydoc.info/gems/musa-dsl/Musa/Matrix) - Gesture conversion

### Output & Communication
- [Musa::Transcription](https://rubydoc.info/gems/musa-dsl/Musa/Transcription) - Event transformation
- [Musa::MusicXML::Builder](https://rubydoc.info/gems/musa-dsl/Musa/MusicXML/Builder) - Score generation
- [Musa::MIDIVoices](https://rubydoc.info/gems/musa-dsl/Musa/MIDIVoices) - Voice management
- [Musa::MIDIRecorder](https://rubydoc.info/gems/musa-dsl/Musa/MIDIRecorder) - MIDI recording

### Musical Knowledge
- [Musa::Scales](https://rubydoc.info/gems/musa-dsl/Musa/Scales) - Scale systems
- [Musa::Chords](https://rubydoc.info/gems/musa-dsl/Musa/Chords) - Chord structures
- [Musa::Datasets](https://rubydoc.info/gems/musa-dsl/Musa/Datasets) - Data structures

### Development
- [Musa::REPL](https://rubydoc.info/gems/musa-dsl/Musa/REPL) - Live coding server

## Generating Documentation Locally

If you want to generate the API documentation locally:

### Install YARD

```bash
gem install yard
```

### Generate Documentation

```bash
cd /path/to/musa-dsl
yard doc
```

This creates documentation in the `doc/` directory (not versioned in git).

### Browse Documentation

```bash
yard server
```

Then open http://localhost:8808 in your browser.

## Documentation Coverage

Check which code is documented:

```bash
yard stats --list-undoc
```

## See Also

- **Conceptual Documentation**: [subsystems/](subsystems/) - Guides and tutorials for each subsystem
- **Getting Started**: [getting-started/](getting-started/) - Quick start and tutorials
- **Main Documentation**: [README.md](README.md) - Documentation hub
