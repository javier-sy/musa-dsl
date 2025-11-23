# MIDI - Voice Management & Recording

High-level MIDI tools for sequencer-synchronized playback and recording. These utilities integrate MIDI I/O with the sequencer timeline, ensuring correct timing even during fast-forward or quantization.

## MIDIVoices - Polyphonic Voice Management

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

## MIDIRecorder - MIDI Event Recording

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

## API Reference

**Complete API documentation:**
- [Musa::MIDIVoices](https://rubydoc.info/gems/musa-dsl/Musa/MIDIVoices) - Voice management and polyphonic playback
- [Musa::MIDIRecorder](https://rubydoc.info/gems/musa-dsl/Musa/MIDIRecorder) - MIDI input recording and transcription

**Source code:** `lib/midi/`


