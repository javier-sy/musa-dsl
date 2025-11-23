# Transport - Timing & Clocks

Comprehensive timing infrastructure connecting clock sources to the sequencer. The transport system manages musical playback lifecycle, timing synchronization, and position control.

**Architecture:**
```
Clock --ticks--> Transport --tick()--> Sequencer --events--> Music
```

The system provides precise timing control with support for internal timers, MIDI clock synchronization, and manual control for testing and integration.

## Clock - Timing Sources

**Clock** is the abstract base class for timing sources. All clocks generate regular ticks that drive the sequencer forward. Multiple clock implementations are available for different use cases.

**Available clock types:**

**TimerClock** - Internal high-precision timer-based clock:
- Standalone compositions with internal timing
- Configurable BPM (tempo) and ticks per beat
- Can dynamically change tempo during playback

**InputMidiClock** - Synchronized to external MIDI Clock messages:
- DAW-synchronized playback
- Automatically follows external MIDI Clock Start/Stop/Continue
- Locked to external timing source

**ExternalTickClock** - Manually triggered ticks:
- Testing and debugging
- Integration with external systems
- Frame-by-frame control

**DummyClock** - Simplified clock for testing:
- Fast playback without real-time constraints
- Useful for test suites or batch generation

```ruby
require 'musa-dsl'

# TimerClock - Internal timer-based timing
timer_clock = Musa::Clock::TimerClock.new(
  bpm: 120,              # Beats per minute
  ticks_per_beat: 24     # Resolution
)

# InputMidiClock - Synchronized to external MIDI Clock
require 'midi-communications'
midi_input = MIDICommunications::Input.gets  # Select MIDI input

midi_clock = Musa::Clock::InputMidiClock.new(midi_input)

# ExternalTickClock - Manual tick control
external_clock = Musa::Clock::ExternalTickClock.new

# DummyClock - For testing (100 ticks)
dummy_clock = Musa::Clock::DummyClock.new(100)
```

## Transport - Playback Lifecycle Manager

**Transport** connects a clock to a sequencer and manages the playback lifecycle. It provides methods for starting/stopping playback, seeking to different positions, and registering callbacks for lifecycle events.

**Lifecycle phases:**
1. **before_begin** - Run once before first start (initialization)
2. **on_start** - Run each time transport starts
3. **Running** - Clock generates ticks → sequencer processes events
4. **on_change_position** - Run when position jumps/seeks
5. **after_stop** - Run when transport stops

**Key methods:**
- `start` - Start playback (blocks while running)
- `stop` - Stop playback
- `change_position_to(bars: n)` - Seek to position (in bars)

```ruby
require 'musa-dsl'

# Create clock
clock = Musa::Clock::TimerClock.new(bpm: 120, ticks_per_beat: 24)

# Create transport
transport = Musa::Transport::Transport.new(
  clock,
  4,   # beats_per_bar (time signature numerator)
  24   # ticks_per_beat (resolution)
)

# Access sequencer through transport
sequencer = transport.sequencer

# Schedule events
sequencer.at 1 do
  puts "Starting at bar 1!"
end

sequencer.at 4 do
  puts "Reached bar 4"
  transport.stop
end

# Register lifecycle callbacks
transport.before_begin do
  puts "Initializing (runs once)..."
end

transport.on_start do
  puts "Transport started!"
end

transport.after_stop do
  puts "Transport stopped, cleaning up..."
end

# Start playback (blocks until stopped)
transport.start

# Seeking example (in separate context)
# transport.change_position_to(bars: 2)  # Jump to bar 2
```

**Complete example with MIDI Clock synchronization:**

```ruby
require 'musa-dsl'
require 'midi-communications'

# Setup MIDI-synchronized clock
midi_input = MIDICommunications::Input.gets
clock = Musa::Clock::InputMidiClock.new(midi_input)

# Create transport
transport = Musa::Transport::Transport.new(clock, 4, 24)

# Schedule events
transport.sequencer.at 1 do
  puts "Synchronized start at bar 1!"
end

# Start and wait for MIDI Clock Start message
transport.start
```

## API Reference

**Complete API documentation:**
- [Musa::Transport](https://rubydoc.info/gems/musa-dsl/Musa/Transport) - Playback lifecycle management
- [Musa::Clock](https://rubydoc.info/gems/musa-dsl/Musa/Clock) - Timing sources and clock implementations

**Source code:** `lib/transport/`
