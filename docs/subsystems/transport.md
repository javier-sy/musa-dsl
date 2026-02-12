# Transport - Timing & Clocks

Comprehensive timing infrastructure connecting clock sources to the sequencer. The transport system manages musical playback lifecycle, timing synchronization, and position control.

**Architecture:**
```
Clock --ticks--> Transport --tick()--> Sequencer --events--> Music
```

The system provides precise timing control with support for internal timers, MIDI clock synchronization, and manual control for testing and integration.

## Clock - Timing Sources

**Clock** is the abstract base class for timing sources. All clocks generate regular ticks that drive the sequencer forward. Multiple clock implementations are available for different use cases.

### Clock Activation Models

Clocks use two different activation models:

**Automatic Activation** (DummyClock):
- Begins generating ticks immediately when `transport.start` is called
- No external activation required
- Appropriate for testing, batch processing, simulations

**External Activation** (TimerClock, InputMidiClock, ExternalTickClock):
- Requires external signal/control to begin generating ticks
- `transport.start` blocks waiting for activation
- Appropriate for live coding, DAW sync, external control

### Available Clock Types

**DummyClock** - Simplified clock for testing (automatic activation):
- Fast playback without real-time constraints
- Immediately begins generating ticks
- Useful for test suites or batch generation
- No external dependencies

**TimerClock** - Internal high-precision timer-based clock (external activation):
- Standalone compositions with internal timing
- Requires calling `clock.start()` from another thread
- Configurable BPM (tempo) and ticks per beat
- Can dynamically change tempo during playback
- Appropriate for live coding clients

**InputMidiClock** - Synchronized to external MIDI Clock messages (external activation):
- DAW-synchronized playback
- Waits for MIDI "Start" (0xFA) message to begin ticks
- Automatically follows external MIDI Clock Start/Stop/Continue
- Locked to external timing source

**ExternalTickClock** - Manually triggered ticks (external activation):
- Testing and debugging with precise control
- Integration with external systems (game engines, etc.)
- Call `clock.tick()` manually to generate each tick
- Frame-by-frame control

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

### Clean Shutdown

`transport.stop` triggers the complete lifecycle shutdown sequence, consistently across all clock types:

1. `transport.stop` calls `clock.terminate`
2. `clock.terminate` calls `clock.stop` (fires `on_stop` callbacks)
3. Transport's `on_stop` handler executes `after_stop` callbacks
4. Sequencer is reset
5. `before_begin` callbacks run (preparing for potential restart)
6. Clock's run loop exits
7. `transport.start` returns

```ruby
# Example: Self-terminating composition
transport.sequencer.at 10 do
  puts "Composition finished"
  transport.stop  # This will cause transport.start to return
end

transport.start  # Blocks until transport.stop is called
puts "Cleanup..."  # Executes after stop
output.close
```

**Clock `stop` vs `terminate` contract:**

- **`stop`**: Fires `on_stop` callbacks. Idempotent (second call is a no-op). All clocks implement it.
- **`terminate`**: Calls `stop` first (guarantees callbacks), then exits the run loop. All clocks implement it.

**Note:** For `InputMidiClock`, MIDI Stop messages from the DAW also trigger `clock.stop` (and thus `on_stop` callbacks). To fully exit the run loop, call `clock.terminate` or `transport.stop`.

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

# IMPORTANT: TimerClock requires external activation
# Start transport in background thread (it will block waiting)
thread = Thread.new { transport.start }
sleep 0.1  # Let transport initialize

# Activate clock from external control (e.g., live coding client)
clock.start  # NOW ticks begin generating

# Wait for completion
thread.join

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
