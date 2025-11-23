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

## API Reference

**Complete API documentation:**
- [Musa::Sequencer](https://rubydoc.info/gems/musa-dsl/Musa/Sequencer) - Main sequencer class and DSL

**Source code:** `lib/sequencer/`


