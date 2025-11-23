# REPL - Live Coding Infrastructure

The REPL (Read-Eval-Print Loop) provides a TCP-based server for live coding, enabling real-time code evaluation and interactive composition. It acts as a bridge between code editors (via MusaLCE clients) and the running Musa DSL environment.

**Architecture:**
```
Editor → MusaLCE Client → TCP (port 1327) → REPL Server → DSL Context
                                                   ↓
                                             Results/Errors
```

**Available MusaLCE Clients:**
- **MusaLCEClientForVSCode**: Visual Studio Code extension
- **MusaLCEClientForAtom**: Atom editor plugin
- **MusaLCEforBitwig**: Bitwig Studio integration
- **MusaLCEforLive**: Ableton Live integration

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

**Basic REPL Server:**

```ruby
require 'musa-dsl'
include Musa::All

# Create sequencer and transport
clock = TimerClock.new(bpm: 120, ticks_per_beat: 24)
transport = Transport.new(clock, 4, 24)

# Start REPL server bound to sequencer context
# The REPL will execute code in the sequencer's DSL context
transport.sequencer.with do
  # DSL methods available in REPL
  def note(pitch:, duration:)
    puts "Playing pitch #{pitch} for #{duration} bars"
  end

  # Create REPL server (port 1327 by default)
  @repl = Musa::REPL::REPL.new(binding)
end

# Start playback (REPL runs in background thread)
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


