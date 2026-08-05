# MIDI - Voice Management & Recording

High-level MIDI tools for sequencer-synchronized playback and recording. These utilities integrate MIDI I/O with the sequencer timeline, ensuring correct timing even during fast-forward or quantization.

## When is this the answer

This is the boundary: everything above it is music, everything below it is a
protocol from 1983. You come here to send notes to an instrument and to record
what came back, and the less of your piece knows about it, the better.

| You have | You want | This |
|---|---|---|
| notes to send | them played, with note-offs handled | `MIDIVoices` -- one voice per channel |
| a chord | its notes as one event | `voice.note [60, 64, 67], duration: 1r` |
| something to record | the incoming events, on the timeline | `MIDIRecorder` |
| a note that must not end by itself | to release it by hand | `note` without `duration:`, then `note_off` |

**A pitch on a channel is a boolean, not a counter.** Two overlapping notes of
the same pitch on one voice are one sounding pitch: musa-dsl sends a NoteOn for
each re-articulation and a single NoteOff when the last of them lets go. Note
ons and note offs are not meant to balance, and counting them is not how you
find a stuck note -- what matters is the last thing said about each pitch.

**Channels are numbered from 0.** The sixteen are `0` to `15`, which is what the
protocol puts on the wire. Instruments and DAWs almost all display them from 1,
so the channel you read on a screen is one more than the one you write here: the
percussion channel of General MIDI, universally called 10, is `9`.

**A voice is reached through `.voices`.** `MIDIVoices` does not define `[]`, so
`voices[0]` raises `NoMethodError` -- the voice is `voices.voices[0]`. Writing
that twice is enough to want a one-line accessor for it in the score.

**When it is NOT the answer.** Anything that is not communication with a device.
Pitch belongs to [music](music.md), duration to [datasets](datasets.md), and
placement in time to the [sequencer](sequencer.md). A composition that reasons in
MIDI pitches has moved this boundary up into itself.

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

## What the recorder does, without any hardware

The recorder needs no hardware to be understood: `record` takes the raw bytes
and stamps them with wherever the sequencer is, so the whole surface can be
exercised by moving the position by hand.

```ruby
require 'musa-dsl'
include Musa::All

sequencer = Musa::Sequencer::BaseSequencer.new(4, 24)
recorder = Musa::MIDIRecorder::MIDIRecorder.new(sequencer)

recorder.transcription  # => []

sequencer.position = 1r
recorder.record([0x90, 60, 100])          # note on

recorder.transcription
# => [{ position: (1/1), channel: 0, pitch: 60, velocity: 100 }]

sequencer.position = 5/4r
recorder.record([0x80, 60, 64])           # note off

recorder.transcription
# => [{ position: (1/1), channel: 0, pitch: 60, velocity: 100,
#       duration: (1/4), velocity_off: 64 }]

recorder.raw.size       # => 2
recorder.clear
recorder.transcription  # => []
```

Note what the note-off does: it does not append an event, it **completes** the
one that was open, adding `:duration` and `:velocity_off`. A note that is still
sounding has neither, which is how you tell a finished phrase from a truncated
one. `raw` keeps both messages regardless -- it is the tape, `transcription` is
the reading.

**Transcription output format:**

Each note hash contains:
- `:position` - Sequencer position (Rational) when note started
- `:channel` - MIDI channel (0-15)
- `:pitch` - MIDI note number (0-127) or `:silence` for gaps
- `:velocity` - Note-on velocity (0-127)
- `:duration` - Note duration in bars (Rational)
- `:velocity_off` - Note-off velocity (0-127)

## API Reference

**Classes:**
- `Musa::MIDIVoices` - Voice management and polyphonic playback
- `Musa::MIDIRecorder` - MIDI input recording and transcription

**Source code:** `lib/musa-dsl/midi/`


