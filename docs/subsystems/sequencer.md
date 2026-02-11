# Sequencer - Temporal Engine

The Sequencer manages time-based event scheduling with microsecond precision, supporting complex polyrhythmic and polytemporal structures.

```ruby
require 'musa-dsl'
include Musa::All

# Setup: Create clock and transport (for real-time execution)
clock = TimerClock.new(bpm: 120, ticks_per_beat: 24)
transport = Transport.new(clock, 4, 24)  # 4 beats per bar, 24 ticks per beat

# Define series outside DSL block (Series constructors not available in DSL context)
melody = S({ note: 60, duration: 1/2r }, { note: 62, duration: 1/2r },
            { note: 64, duration: 1/2r }, { note: 65, duration: 1/2r },
            { note: 67, duration: 1/2r }, { note: 65, duration: 1/2r },
            { note: 64, duration: 1/2r }, { note: 62, duration: 1/2r })

# Program sequencer using DSL
transport.sequencer.with do
  # Custom event handlers (on/launch)
  on :section_change do |name|
    puts "Section: #{name}"
  end

  # Immediate event (now)
  now do
    launch :section_change, "Start"
  end

  # Absolute positioning (at): event at bar 1
  at 1 do
    puts "Bar 1: position #{position}"
  end

  # Relative positioning (wait): event 2 bars later
  wait 2 do
    puts "Bar 3: position #{position}"
  end

  # Play series (play): reproduces series with automatic timing
  at 5 do
    play melody do |note:, duration:, control:|
      puts "Playing note: #{note}, duration: #{duration}"
    end
  end

  # Recurring event (every) with stop control
  beat_loop = nil
  at 10 do
    # Store control object to stop it later
    beat_loop = every 2, duration: 10 do
      puts "Beat at position #{position}"
    end
  end

  # Stop the beat loop at bar 18
  at 18 do
    beat_loop.stop if beat_loop
    puts "Beat loop stopped"
  end

  # Animated value (move) from 0 to 10 over 4 bars
  at 20 do
    move from: 0, to: 10, duration: 4, every: 1/2r do |value|
      puts "Value: #{value.round(2)}"
    end
  end

  # Multi-parameter animation (move with hash)
  at 25 do
    move from: { pitch: 60, vel: 60 },
         to: { pitch: 72, vel: 100 },
         duration: 2,
         every: 1/4r do |values|
      puts "Pitch: #{values[:pitch].round}, Velocity: #{values[:vel].round}"
    end
  end

  # Final event
  at 30 do
    launch :section_change, "End"
    puts "Finished at position #{position}"
  end
end

# Start real-time playback
transport.start
```

## Times and durations

The Sequencer internally encodes time using `Rational`. It is preferable to use Rational values (`1/2r`, `1r`, `3/4r`) instead of Float (`0.5`, `1.0`, `0.75`) for times and durations, as this avoids potential precision issues in the internal conversion.

```ruby
# Preferable
at 1/2r do ... end
wait 3/4r do ... end
every 1/4r do ... end

# Works but may cause imprecision
at 0.5 do ... end
```

## Control Objects and `.stop`

All scheduling methods (`at`, `wait`, `now`, `play`, `play_timed`, `every`, `move`) return a control object that supports `.stop` to cancel execution. Calling `.stop` on the control prevents the associated block from running at its scheduled position, or stops further iterations for series/recurring operations.

### `on_stop` vs `after` callbacks

The control objects returned by `every`, `play`, `play_timed`, and `move` support two types of callbacks with different semantics:

- **`on_stop`**: Cleanup callback — fires **always** when the control terminates, whether naturally or via manual `.stop`. Use for resource cleanup, state updates, logging.
- **`after`**: Continuation callback — fires **only on natural termination** (duration reached, series exhausted, till exceeded, condition failed). **NOT** called when `.stop` is used. Use for chaining sections, scheduling follow-up events.

| Termination cause | `on_stop` fires? | `after` fires? |
|---|---|---|
| Manual `.stop` | Yes | **No** |
| Duration reached | Yes | Yes |
| Till position exceeded | Yes | Yes |
| Condition failed | Yes | Yes |
| Series exhausted (play) | Yes | Yes |
| Nil interval (every, one-shot) | Yes | Yes |

### Examples

```ruby
# Safe section chaining — .stop won't cause relaunch
ctrl = every 1r do
  # ... play pattern ...
end

ctrl.on_stop { puts "Pattern stopped (any reason)" }
ctrl.after { launch :next_section }  # Only on natural end

# Later: manual stop does NOT trigger :next_section
ctrl.stop
```

```ruby
# Play with on_stop for cleanup
ctrl = play melody do |note:, duration:|
  voice.note(note, duration: duration)
end

ctrl.on_stop { voice.all_notes_off }  # Always cleanup
ctrl.after { launch :next_phrase }     # Only if melody finishes naturally
```

```ruby
# Move with after for continuation
ctrl = move from: 0, to: 127, duration: 4r, every: 1/4r do |v|
  midi_cc(7, v.round)
end

ctrl.on_stop { puts "Fade ended" }     # Any reason
ctrl.after { launch :next_section }     # Only if fade completes
```

### Stopping `at`, `wait`, `now` and `play_timed`

All scheduling methods return a control object that supports `.stop`:

```ruby
# Stop a scheduled at/wait/now before it executes
h = at 5 do
  puts "This won't execute if stopped before bar 5"
end

at 3 do
  h.stop  # Cancels the block scheduled at bar 5
end
```

```ruby
# Stop a series-based at/wait
h = at [1, 2, 3, 4, 5] do
  puts "Repeating at positions from series"
end

at 3.5 do
  h.stop  # No more executions from the series after this point
end
```

```ruby
# Stop play_timed — same on_stop/after semantics as play/every/move
ctrl = play_timed(timed_serie) do |values, time:, started_ago:, control:|
  # process values
end

ctrl.on_stop { puts "Stopped (any reason)" }
ctrl.after { launch :next_section }  # Only on natural end

at 10 do
  ctrl.stop  # on_stop fires, after does NOT
end
```

### Parameter form

`on_stop` and `after` can also be passed as parameters:

```ruby
every 1r, on_stop: proc { cleanup }, after: proc { continue } do
  # ...
end

play melody, on_stop: proc { cleanup } do |note:|
  # ...
end
```

## API Reference

**Complete API documentation:**
- [Musa::Sequencer](https://rubydoc.info/gems/musa-dsl/Musa/Sequencer) - Main sequencer class and DSL

**Source code:** `lib/sequencer/`


