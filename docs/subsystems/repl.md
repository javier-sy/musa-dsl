# REPL - Live Coding Infrastructure

The REPL (Read-Eval-Print Loop) provides a TCP-based server for live coding, enabling real-time code evaluation and interactive composition. It acts as a bridge between code editors (via MusaLCE clients) and the running Musa DSL environment.

**Architecture:**
```
Editor → MusaLCE Client → TCP (port 1327) → REPL Server → DSL Context
                                                   ↓
                                             Results/Errors
```

The REPL is **only** the TCP eval channel between editor and server. Anything else a live-coding session needs — sequencer, voices, clock, transport, output routing — is something you build around it in your own `main.rb`. You start `Musa::REPL::REPL.new(binding)` inside the sequencer's DSL context, and whatever methods and helpers are visible there become reachable from the editor.

Maximum control. Useful when:

- You drive arbitrary targets — SuperCollider, Max/MSP, OSC apps, MIDI hardware, OS voice synthesis, custom electronics over sockets.
- You're prototyping a personal live-coding DSL (helpers, Tidal-Cycles-style API).
- You want to keep the dependency footprint to `musa-dsl` alone.

A complete worked example with a Tidal-Cycles-style `d(n)` / `hush` / `solo` API: [`musadsl-demo/_demo-13-live-coding`](https://github.com/javier-sy/musadsl-demo).

## When is this the answer

The REPL is for **changing the music while it is playing**. It is a TCP server
that evaluates code in the context of a running piece, which is what live coding
needs and what nothing else here provides.

| You want | This |
|---|---|
| to try an idea against a piece that is already running | the REPL |
| to edit from an editor rather than a terminal | a client -- the VSCode extension talks this protocol |
| to keep the piece's own vocabulary available in what you type | evaluate in the sequencer's context |

**When it is NOT the answer.** A piece that is written, run and listened to does
not need it: put the code in a file. The REPL earns its place when the loop
between changing something and hearing it has to be shorter than a restart.

**And it changes an assumption the rest of the framework makes.** With a REPL
open, the schedule can grow from another thread while the sequencer is running --
something can be scheduled between one event and the next. Everything that
assumes a closed world (nothing else touches the schedule) stops holding, which
is why [issue #91](https://github.com/javier-sy/musa-dsl/issues/91) treats live
coding as the case that decides its design.

## REPL clients

Editor extensions that connect to the REPL server over TCP/1327:

- [MusaLCEClientForVSCode](https://github.com/javier-sy/MusaLCEClientForVSCode) — Visual Studio Code extension
- [MusaLCEClientForAtom](https://github.com/javier-sy/MusaLCEClientForAtom) — Atom editor plugin (discontinued, December 2022)

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

## Server Setup

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

# A DummyClock so this page's example terminates; a live REPL session puts a
# TimerClock or an InputMidiClock here.
clock = Musa::Clock::DummyClock.new(200)
transport = Transport.new(clock, 4, 24)

reported = []
transport.sequencer.on_error { |e| reported << e.message }

transport.sequencer.with do
  # An error raised inside a scheduled block does not stop the piece: it is
  # reported and swallowed, and that is what the REPL forwards to its clients.
  at 1 do
    raise "This error will be sent to REPL client"
  end

  at 2 do
    # ... and the next event still runs
  end
end

transport.start

reported  # => ["This error will be sent to REPL client"]
```

## Use Cases

- **Live coding performances**: Real-time code evaluation during performances
- **Interactive composition**: Develop compositions interactively with immediate feedback
- **Remote composition control**: Send commands to running compositions over network
- **Educational workshops**: Live demonstrations with instant code execution

## API Reference

**Complete API documentation:**
- [Musa::REPL](https://rubydoc.info/gems/musa-dsl/Musa/REPL) - Live coding server and protocol

**Source code:** `lib/repl/`


