# Sequencer - Temporal Engine

The Sequencer manages time-based event scheduling with microsecond precision, supporting complex polyrhythmic and polytemporal structures.

```ruby
require 'musa-dsl'
include Musa::All

# Setup: create clock and transport.
#
# DummyClock runs the whole piece as fast as it can, which is what makes this
# page's examples runnable. A piece that is meant to be heard swaps in
# TimerClock (its own tempo) or InputMidiClock (a DAW's) and changes nothing
# else -- see the transport documentation.
clock = Musa::Clock::DummyClock.new(31 * 96)   # 31 bars of 4 beats x 24 ticks
transport = Transport.new(clock, 4, 24)        # 4 beats per bar, 24 ticks per beat

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
  # Default mode is :wait — each element's :duration determines the wait before the next
  at 5 do
    play melody do |note:, duration:, control:|
      puts "Playing note: #{note}, duration: #{duration}"
    end
  end

  # Recurring event (every) with stop control
  # Note: every passes control: as a keyword — declare only the params you need
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

transport.start
```

## When is this the answer

Everything that happens in time goes through here, so the question is not
whether but which verb. By the shape of what you have:

| You have | You want | This |
|---|---|---|
| one singular moment -- a start, a mark, an end | something to happen there | `at` |
| a delay measured from where you are | to come back after it | `wait` |
| a serie whose elements carry their duration | it played, with time walked for you | `play` |
| a serie of values with times attached | to be called at each of them | `play_timed` |
| a value that has to travel from one to another | to be called at every step of the way | `move` |
| a regular pulse | to keep doing something until told otherwise | `every` |

**When `at` is right and when it is the reflex.** A genuine landmark -- the
start of a section, one structural mark, the end -- is exactly what `at` is for.
`at` **inside a loop, with the position computed from the loop variable**, is
the reflex: it means the plan is being kept as arithmetic instead of as data.
A serie carrying `duration:` and given to `play` says the same thing and stays
sliceable, combinable and reusable. See [idioms](../idioms.md) §1.

**`duration` and `note_duration` are not the same key.** For `play`, `:duration`
is the step -- how long until the next element -- and `:note_duration` is how
long the sound lasts. They coincide often enough that the difference only shows
up when it matters: a staccato is a short `note_duration` inside an unchanged
`duration`.

**When it is NOT the answer.** Deciding *what* happens is not this subsystem's
business: that is [series](series.md) and the generative tools. The sequencer
places what you already chose.

## Where time starts, and what a position is

A position is a **bar number**, and `1r` is one bar. Durations are fractions of
a bar, not of a whole note -- in 4/4 that makes `1/4r` a quarter note, which is
why the two readings agree there and only there.

A sequencer with a tick grid starts **one tick before bar 1**:

```ruby
sequencer = Musa::Sequencer::Sequencer.new(4, 24)
sequencer.position   # => 95/96r
```

That is deliberate: 96 ticks to the bar, so the first tick it runs lands exactly
on bar 1. It also has a consequence worth knowing, because it is a common
surprise: an `every` written directly in the `with` block -- outside any `at` --
starts counting from 95/96 and its pulses fall one tick before each bar. Put it
inside `at 1` and it lands on the bar.

```
transport.sequencer.with do
  at 1 do
    every 1r do ... end     # pulses on 1, 2, 3...
  end
end
```

## Times and durations

The Sequencer internally encodes time using `Rational`. It is preferable to use Rational values (`1/2r`, `1r`, `3/4r`) instead of Float (`0.5`, `1.0`, `0.75`) for times and durations, as this avoids potential precision issues in the internal conversion.

```ruby
require 'musa-dsl'
include Musa::All

seq = Musa::Sequencer::BaseSequencer.new(4, 24)
reached = []

seq.at(1 + 1/2r) { reached << seq.position }   # preferable
seq.at(1.5)      { reached << seq.position }   # works, but see below
seq.run

reached  # => [(3/2), (3/2)]
```

Both arrive at the same place here, because 1.5 happens to be exactly
representable. The difference shows where a Float cannot be: a third of a bar is
`1/3r` exactly and `0.3333333333333333` never, and the sequencer's grid is
rational all the way down.

Note the positions: `1 + 1/2r`, not `1/2r`. Bars are numbered from 1, and the
sequencer starts one tick before bar 1, so anything scheduled below that is in
the past before the piece begins:

```ruby
seq = Musa::Sequencer::BaseSequencer.new(4, 24)
never = []
seq.at(1/2r) { never << :fired }
seq.run

never  # => []
```

It does not raise and it does not warn. `at` in the past is the single most
common way for a piece to be silent for no visible reason.

## Block Parameter Flexibility (SmartProcBinder)

All scheduling methods (`every`, `play`, `move`, `play_timed`) pass parameters to user blocks via **SmartProcBinder**. This means blocks can declare **only the parameters they need** — undeclared parameters are silently ignored.

**Important**: keyword parameters (like `control:`) must be declared as **keyword arguments** in the block signature (`|control:|`), not as positional arguments (`|control|`).

### Parameters available per method

| Method | Positional params | Keyword params |
|--------|-------------------|----------------|
| `every` | _(none)_ | `control:` |
| `play` | element (+ hash keys as keywords) | `control:` |
| `move` | value, next_value | `control:`, `duration:`, `quantized_duration:`, `started_ago:`, `position_jitter:`, `duration_jitter:`, `right_open:` |
| `play_timed` | values (+ extra attributes as keywords) | `time:`, `started_ago:`, `control:` |

### Examples

Each block below declares only what it wants, and the sequencer supplies it.
Everything is recorded so the table above can be read off the result rather than
taken on trust:

```ruby
require 'musa-dsl'
include Musa::All

seq = Musa::Sequencer::BaseSequencer.new(4, 24)
log = []

# every — the block may take nothing, or `control:`
seq.every(1r, duration: 2r) { |control:| log << [:every, control.class.name.split('::').last] }

# play — the element's hash keys arrive as keywords
melody = S({ note: 60, duration: 1r }, { note: 64, duration: 1/2r })
seq.play(melody) { |note:, duration:| log << [:play, note, duration] }

# move — two positionals and keyword metadata
seq.move(from: 0, to: 12, duration: 1r, every: 1/2r) do |value, next_value, duration:|
  log << [:move, value, next_value, duration]
end

# play_timed — the values, plus when it happened
timed = S({ time: 0r, value: [60] }, { time: 1r, value: [64] })
seq.play_timed(timed) { |values, time:, started_ago:| log << [:timed, values, time, started_ago] }

seq.run

log
# => [[:every, "EveryControl"],
#     [:play, 60, (1/1)],
#     [:move, (0/1), (12/1), (1/2)],
#     [:timed, [60], (95/96), []],
#     [:move, (12/1), nil, (1/2)],
#     [:every, "EveryControl"],
#     [:play, 64, (1/2)],
#     [:timed, [64], (191/96), []]]
```

Three things the table cannot say and the result does:

- `move` yields `next_value` as `nil` on its last step. There is nothing after
  the arrival, and a block that reads ahead has to expect it.
- `play_timed` yields `time:` as the sequencer's **absolute position**, not the
  `time:` of the serie's element — 95/96 for the element at serie time 0,
  because the sequencer starts one tick before bar 1.
- `started_ago:` is an **array**, not a number: one entry per value that was
  already sounding when this one arrived, empty when nothing was.

## Play Modes

`play` supports three modes that determine how series elements are scheduled. The default mode is `:wait`.

```ruby
require 'musa-dsl'
include Musa::All
using Musa::Extension::Neumas

seq = Musa::Sequencer::BaseSequencer.new(4, 24)
waited = []
timed = []
neumas = []

# :wait (default) — each element must have :duration; the sequencer waits
# that duration before consuming the next element
progression = S({ grade: 0, duration: 1r }, { grade: 3, duration: 1r })
seq.play(progression) { |grade:, duration:| waited << [grade, seq.position] }

# :at — each element must have :at; the sequencer schedules it at that
# absolute position
events = S({ note: 60, at: 1r }, { note: 64, at: 3r })
seq.play(events, mode: :at) { |note:, at:| timed << [note, seq.position] }

# :neumalang — full Neumalang DSL processing with decoder
scale = Musa::Scales.et12[440.0].major[60]
decoder = Musa::Neumas::Decoders::NeumaDecoder.new(scale, base_duration: 1/4r)
seq.play("(0 1) (+2 1)".to_neumas, mode: :neumalang, decoder: decoder) do |gdv|
  neumas << gdv.to_pdv(scale)[:pitch]
end

seq.run

waited  # => [[0, (95/96)], [3, (191/96)]]
timed   # => [[60, (1/1)], [64, (3/1)]]
neumas  # => [60, 64]
```

The contrast between the first two is the whole of the choice. In `:wait` the
first element lands where the sequencer already is — 95/96, one tick before bar
1 — and each following one a duration later. In `:at` the element says where it
goes, so the first lands on bar 1 exactly, and a position already gone by is
played immediately rather than dropped.

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
| Series exhausted (play) | Yes | Yes |
| `move` completed | Yes | Yes |
| Nil interval (`every`, one-shot) | **No** | **No** |

The last row is not a design decision anyone wrote down; it is what the code
does. A one-shot `every(nil)` runs its block once and then simply stops
existing, so nothing downstream of it ever learns that it finished — neither the
cleanup nor the continuation. Do not chain a section off a one-shot.

### Examples

The table above, read off the sequencer rather than taken on trust:

```ruby
require 'musa-dsl'
include Musa::All

def fired_by
  seq = Musa::Sequencer::BaseSequencer.new(4, 24)
  fired = []
  control = yield seq
  control.on_stop { fired << :on_stop }
  control.after   { fired << :after }
  seq.run
  fired
end

fired_by { |s| s.every(1r, duration: 2r) { } }                        # => [:on_stop, :after]
fired_by { |s| s.every(1r, till: 3r) { } }                            # => [:on_stop, :after]
fired_by { |s| s.play(S({ v: 1, duration: 1r })) { |v:| } }           # => [:on_stop, :after]
fired_by { |s| s.move(from: 0, to: 4, duration: 1r, every: 1/2r) { } } # => [:after, :on_stop]
fired_by { |s| s.every(nil) { } }                                     # => []
```

Note the order under `move`: `after` runs before `on_stop`, where everything
else runs them the other way round. If a cleanup and a continuation both touch
the same state, that difference is visible.

And the manual stop, which is the case the two callbacks exist to tell apart:

```ruby
seq = Musa::Sequencer::BaseSequencer.new(4, 24)
fired = []

control = seq.every(1r) { }
control.on_stop { fired << :on_stop }
control.after   { fired << :after }

seq.at(3r) { control.stop }
seq.run

fired  # => [:on_stop]
```

`after` did not fire, which is the whole point: a section chained with `after`
does not launch when somebody stops the pattern by hand.

```ruby
seq = Musa::Sequencer::BaseSequencer.new(4, 24)
sent = []
fired = []

control = seq.move(from: 0, to: 127, duration: 1r, every: 1/2r) { |v| sent << v.round }
control.on_stop { fired << :on_stop }   # any reason
control.after   { fired << :next_section }  # only if the fade completes
seq.run

sent   # => [0, 127]
fired  # => [:next_section, :on_stop]
```

A fade that is allowed to arrive launches the next section; one that is stopped
by hand does not. That is the whole reason to write the continuation as `after`
and not inside `on_stop`.

### Stopping `at`, `wait`, `now` and `play_timed`

All scheduling methods return a control object that supports `.stop`:

```ruby
require 'musa-dsl'
include Musa::All

seq = Musa::Sequencer::BaseSequencer.new(4, 24)
ran = []

handle = seq.at(5) { ran << :bar5 }
seq.at(3) { handle.stop }   # cancels the block scheduled at bar 5
seq.run

ran  # => []
```

A series-based `at` stops where it is told, keeping what it already played:

```ruby
seq = Musa::Sequencer::BaseSequencer.new(4, 24)
played = []

handle = seq.at([1, 2, 3, 4, 5]) { played << seq.position }
seq.at(3.5) { handle.stop }
seq.run

played  # => [(1/1), (2/1), (3/1)]
```

Positions 4 and 5 never happen: `.stop` at 3.5 ends the whole series, not just
the next one.

### Parameter form

`on_stop` and `after` can also be passed as parameters, which is the same thing
the block form does:

```ruby
seq = Musa::Sequencer::BaseSequencer.new(4, 24)
fired = []

seq.every(1r, duration: 2r,
          on_stop: proc { fired << :on_stop },
          after: proc { fired << :after }) { }
seq.run

fired  # => [:on_stop, :after]
```

## API Reference

**Complete API documentation:**
- [Musa::Sequencer](https://rubydoc.info/gems/musa-dsl/Musa/Sequencer) - Main sequencer class and DSL

**Source code:** `lib/sequencer/`


