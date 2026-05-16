# REPL - Live Coding Infrastructure

The REPL (Read-Eval-Print Loop) provides a TCP-based server for live coding, enabling real-time code evaluation and interactive composition. It acts as a bridge between code editors (via MusaLCE clients) and the running Musa DSL environment.

**Architecture:**
```
Editor → MusaLCE Client → TCP (port 1327) → REPL Server → DSL Context
                                                   ↓
                                             Results/Errors
```

The REPL is **only** the TCP eval channel between editor and server. Anything else a live-coding session needs (DAW transport, MIDI routing, OSC surface relay, etc.) lives outside this subsystem.

## Two scenarios

### Case 1 — Standalone live coding (you bring your own REPL)

This is the scenario this document covers. You build your own `main.rb` (sequencer, voices, clock, transport, your own helpers) and start `Musa::REPL::REPL.new(binding)` inside the sequencer's DSL context. Your editor connects to it on `localhost:1327` and you send Ruby fragments live.

Maximum control. Useful when:

- You drive non-DAW targets — SuperCollider, Max/MSP, OSC apps, OS voice synthesis, custom hardware.
- You're prototyping a personal live-coding DSL (helpers, Tidal-Cycles-style API).
- You want to keep the dependency footprint to musa-dsl alone.

A complete worked example with a Tidal-Cycles-style `d(n)` / `hush` / `solo` API: [`musadsl-demo/_demo-13-live-coding`](https://github.com/javier-sy/musadsl-demo).

### Case 2 — Suite workflow (musalce-server handles everything)

When the target is **Ableton Live** or **Bitwig Studio**, the [musalce-server](https://github.com/javier-sy/musalce-server) gem packages this REPL plus a sequencer, a clock, a transport, a DAW handler (OSC over UDP to the per-DAW extension) and a surface for Stream Deck integration via Pulso. Internally case 2 is a **specialization** of case 1 — `musalce-server` opens `Musa::REPL::REPL.new(binding)` after pre-building all the boilerplate, and exposes a `daw.*` API in the DSL context.

Documented separately in the suite's architecture reference: [musalce-server/docs/architecture.md](https://github.com/javier-sy/musalce-server/blob/master/docs/architecture.md).

## Components

**REPL clients** (talk to the REPL server over TCP 1327 — same shape in both scenarios):

- [MusaLCEClientForVSCode](https://github.com/javier-sy/MusaLCEClientForVSCode) — Visual Studio Code extension
- [MusaLCEClientForAtom](https://github.com/javier-sy/MusaLCEClientForAtom) — Atom editor plugin (discontinued, December 2022)

**Suite-only components** (only used in case 2 — see musalce-server architecture doc):

- [musalce-server](https://github.com/javier-sy/musalce-server) — packages REPL + sequencer + DAW handler + surface
- [MusaLCEforBitwig](https://github.com/javier-sy/MusaLCEforBitwig) — Bitwig Studio controller extension (Java)
- [MusaLCEforLive](https://github.com/javier-sy/MusaLCEforLive) — Ableton Live MIDI Remote Script (Python)

## Communication Protocol

The REPL uses a line-based protocol over TCP (default port: 1327).

**Client to Server:**
- `#path` - Start path block (optional, to inject file path context)
- *file path* - Path to the user's file being edited
- `#begin` - Start code block
- *code lines* - Ruby code to execute
- `#end` - Execute accumulated code block

**Server to Client:**
- `//echo` - Start echo block (code about to be executed)
- `//error` - Start error block
- `//backtrace` - Start backtrace section within error block
- `//end` - End current block
- *regular lines* - Output from code execution (puts, etc.)

**Example Session:**
```
Client → Server:
  #path
  /Users/me/composition.rb
  #begin
  puts "Starting composition..."
  at 1 do
    note pitch: 60, duration: 1r
  end
  #end

Server → Client:
  //echo
  puts "Starting composition..."
  at 1 do
    note pitch: 60, duration: 1r
  end
  //end
  Starting composition...
```

## Server Setup (Case 1 — canonical pattern)

```ruby
require 'musa-dsl'
require 'midi-communications'    # or any other MIDI/OSC layer you prefer

include Musa::All

# 1. MIDI output of your choice
output = MIDICommunications::Output.gets

# 2. Clock + transport
clock = TimerClock.new(bpm: 120, ticks_per_beat: 24)
transport = Transport.new(clock, 4, 24)

# 3. Sequencer DSL context — anything you define inside `with` becomes
#    available in the REPL (instance methods, accessors, helpers).
transport.sequencer.with do
  voices = MIDIVoices.new(sequencer: transport.sequencer, output: output, channels: [0, 1])

  # Define whatever DSL surface you want exposed to the REPL.
  def my_note(pitch:, duration:)
    voices.voices[0].note(pitch, duration: duration)
  end

  # 4. Start the REPL server (binds to TCP/1327 in this DSL context)
  @repl = Musa::REPL::REPL.new(binding)
end

# 5. Start playback (REPL runs in background thread)
transport.start
```

If you instead want the **suite workflow** (case 2 — Bitwig or Live with DAW handler + Stream Deck surface), don't write the above by hand: install [musalce-server](https://github.com/javier-sy/musalce-server) and run `musalce-server bitwig|live`. It opens this same REPL with a richer DSL context (`daw.*`, `surface[:event]`, …).

**File Path Injection:**

When a client sends a file path via `#path`, the REPL injects it as `@user_pathname` (Pathname object). This enables relative requires based on the editor's current file location:

```ruby
# In REPL context, clients can use:
require_relative @user_pathname.dirname / 'my_helpers'
```

## Integration with Sequencer

The REPL automatically hooks into sequencer error handling to report async errors during playback:

```ruby
require 'musa-dsl'
include Musa::All

clock = TimerClock.new(bpm: 120, ticks_per_beat: 24)
transport = Transport.new(clock, 4, 24)

transport.sequencer.with do
  # If an error occurs during sequencer execution,
  # REPL clients receive formatted error messages

  at 1 do
    raise "This error will be sent to REPL client"
  end

  @repl = Musa::REPL::REPL.new(binding)
end

transport.start
```

## Use Cases

- **Live coding performances**: Real-time code evaluation during performances
- **Interactive composition**: Develop compositions interactively with immediate feedback
- **DAW synchronization**: Control Musa DSL from within Bitwig or Ableton Live
- **Remote composition control**: Send commands to running compositions over network
- **Educational workshops**: Live demonstrations with instant code execution

## API Reference

**Complete API documentation:**
- [Musa::REPL](https://rubydoc.info/gems/musa-dsl/Musa/REPL) - Live coding server and protocol

**Source code:** `lib/repl/`


