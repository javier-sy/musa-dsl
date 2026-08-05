# Transport - Timing & Clocks

Comprehensive timing infrastructure connecting clock sources to the sequencer. The transport system manages musical playback lifecycle, timing synchronization, and position control.

**Architecture:**
```
Clock --ticks--> Transport --tick()--> Sequencer --events--> Music
```

The system provides precise timing control with support for internal timers, MIDI clock synchronization, and manual control for testing and integration.

## When is this the answer

The transport is what turns a schedule into something that happens. You need one
whenever the music has to run in time -- and you do **not** need one to compute,
render or export, where `sequencer.run` walks the whole schedule as fast as it
can.

The decision is which clock, and it comes down to **who owns the tempo**:

| The tempo comes from | This |
|---|---|
| musa-dsl itself | `TimerClock` -- master; needs an explicit `clock.start` |
| a DAW, over MIDI | `InputMidiClock` -- slave; follows start, stop and position |
| your own code, tick by tick | `ExternalTickClock` -- you call `tick` |
| nowhere: run as fast as possible | `DummyClock`, for tests and offline rendering |

**Master or slave is not a preference, it is a fact about the setup.** If a DAW
is recording, it owns the tempo and musa-dsl follows; if musa-dsl is driving the
DAW, the reverse. Choosing the wrong one shows up as drift that no amount of
correction fixes.

**All of them are grids.** A clock emits a pulse every so often, which is a MIDI
inheritance -- 24 ppqn -- and it is why irregular structures have to be written
against a regular pulse. A clock that waits the exact time between one event and
the next, with no grid at all, is
[issue #91](https://github.com/javier-sy/musa-dsl/issues/91).

**Three of the callbacks are the lifecycle, and they are not interchangeable**
(a fourth, `on_change_position`, reports seeks and is not part of it).
`before_begin`
runs before the first tick, with the sequencer already built -- it is where to
schedule what has to exist before time starts. `on_start` runs when the clock
actually starts. `after_stop` runs when it stops, however it stopped.

**`stop` cannot be called from a signal handler.** Stopping resets the sequencer,
that reset takes a mutex, and Ruby refuses to take one inside a trap: a plain
`trap('INT') { transport.stop }` raises `ThreadError: can't be called from trap
context` and the transport goes on running, so the Ctrl+C that was meant to end
the piece does nothing at all. Moving the call out of trap context --
`trap('INT') { Thread.new { transport.stop } }` -- is enough, and `start` then
returns as it should.

## Clock - Timing Sources

**Clock** is the abstract base class for timing sources. All clocks generate regular ticks that drive the sequencer forward. Multiple clock implementations are available for different use cases.

### Clock Activation Models

Clocks use two different activation models:

**Automatic Activation** (DummyClock):
- Begins generating ticks immediately when `transport.start` is called
- No external activation required
- Appropriate for testing, batch processing, simulations

**External Activation** (TimerClock, InputMidiClock):
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
1. **before_begin** - Runs before each start, including the one prepared by a stop (initialization)
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

### Clock `stop` vs `terminate` contract

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

## The lifecycle, run

```ruby
require 'musa-dsl'
include Musa::All

events = []

transport = Transport.new(Musa::Clock::DummyClock.new(200), 4, 24)
transport.before_begin { events << :before_begin }
transport.on_start     { events << :on_start }
transport.after_stop   { events << :after_stop }

transport.sequencer.at(1) { events << :bar_1 }
transport.sequencer.at(2) { events << :bar_2 }

transport.start

events
# => [:before_begin, :on_start, :bar_1, :bar_2, :after_stop, :before_begin]
```

The numbered sequence above, run. Read the last entry: `before_begin` appears a
second time. Stopping prepares the transport for the next start, so a
`before_begin` that allocates -- opens a MIDI port, builds voices -- has to
expect to run more than once, and `after_stop` is where the matching release
belongs.

Note also how the callbacks were registered: one method call each, after
construction. `Transport.new(clock) { |t| t.before_begin { ... } }` is accepted
by Ruby, ignored by the constructor, and registers nothing. The constructor's own
form is keywords: `Transport.new(clock, 4, 24, before_begin: -> { ... })`.

And `on_change_position` fires only on a seek. A piece that runs from start to
finish never triggers it:

```ruby
positions = []

transport = Transport.new(Musa::Clock::DummyClock.new(200), 4, 24)
transport.on_change_position { |p| positions << p }
transport.sequencer.at(1) { }
transport.start

positions  # => []
```

## API Reference

**Classes:**
- `Musa::Transport` - Playback lifecycle management
- `Musa::Clock` - Timing sources and clock implementations

**Source code:** `lib/musa-dsl/transport/`
