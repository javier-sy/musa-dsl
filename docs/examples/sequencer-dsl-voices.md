# Quick Start

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
