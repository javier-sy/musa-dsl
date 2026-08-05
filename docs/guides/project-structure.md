# Project structure

A piece is not one file. This is how a musa-dsl project is laid out and why:
**conventions, not API**. Nothing here is enforced by the framework, and
everything here follows from something that is.

The fragments below are fenced as `text` and not as `ruby` on purpose. They need
a MIDI device, a thread or a signal to mean anything, and a fence that says ruby
is a promise that the block runs -- `tools/doc-examples.rb` holds every such
block to it.

## Two files: infrastructure and composition

Split the project into **`main.rb`**, which owns everything that is not music --
MIDI output, clock, transport, voices, shutdown -- and **`score.rb`**, which owns
the music and nothing else.

```text
main.rb    output, clock, transport, voices, accessors, shutdown, start
score.rb   material, events, form
```

The reason is not tidiness. `transport.start` blocks until the transport stops
(see [transport](../subsystems/transport.md)), so `main.rb` is a program with a
beginning and an end, while `score.rb` is a body of declarations evaluated inside
a running sequencer. They have different lifetimes, and mixing them means the
only way to change a note is to restart the MIDI connection.

That is also what makes live coding possible: `score.rb` can be re-evaluated
against a transport that never stopped.

## Reaching the infrastructure from the score

The score needs the scale, the voices, the transport -- and it should not receive
them as parameters, or every method grows a tail of arguments that have nothing
to do with music.

Put the infrastructure in instance variables of the sequencer context, expose it
through one-line readers, and mix the score in:

```text
# main.rb
transport.sequencer.with do
  @transport = transport
  @voices = voices
  @scale = scale

  def transport = @transport
  def scale = @scale
  def v(n) = @voices.voices[n]
  def debug(&block) = @transport.logger.debug('score', &block)

  load 'score.rb'
  extend TheScore
  score
end
```

```text
# score.rb
using Musa::Extension::Neumas   # refinements are file-scoped: this must be here too

module TheScore
  def score
    bass = v(0)
    at 1 do
      launch :section_a
    end
    # ...
  end
end
```

Three things are load-bearing:

- **`with` belongs to `Sequencer`, not to `BaseSequencer`.** A bare
  `BaseSequencer` has no DSL context to define anything in.
- **`load`, not `require_relative`.** `require` refuses to read the same file
  twice, which is exactly what re-evaluating a score is.
- **`extend`, not `include`.** The module joins *this* sequencer context, the one
  that already holds the accessors, rather than a class somewhere.

And `using Musa::Extension::Neumas` has to appear in `score.rb` itself: Ruby
refinements are file-scoped, so declaring it in `main.rb` does nothing for the
score.

## Naming the voices

`MIDIVoices` does not define `[]` -- the voice is `voices.voices[0]`. Write that
twice and the noise is already louder than the music, so the `v(n)` accessor
above exists to be used once per voice, at the top of the score:

```text
bass  = v(0)
lead  = v(1)
drums = v(9)
```

From there on the score says `bass`, and the channel number appears exactly once.

## Helpers as methods, not procs

Auxiliary functions go in `module TheScore` as `def`, outside `def score`:

```text
module TheScore
  def bass_durations(instability, random)
    base = instability > 0.5 ? [1/2r, 1/4r] : [1r, 1/2r]
    base.collect { |d| d * random.rand(0.8..1.2).rationalize(1/100r) }
  end

  def score
    durations = bass_durations(0.3, @random)
  end
end
```

A lambda would work and would capture its surroundings silently: read it a month
later and you cannot tell what it depends on. A `def` has to declare what it
needs, which is the same discipline the rest of the framework asks for -- state
travels as arguments, not as scope. Note the random generator among them: a
generative helper that reaches for `rand` is one you cannot reproduce.

## Stopping

Register the cleanup on `after_stop`:

```text
transport.after_stop do
  voices.panic     # CC 123, all notes off, on every channel
  output&.close
end
```

`panic` is what stops a piece from leaving notes sounding after the transport is
gone. Do **not** reset the sequencer here: the transport runs the `after_stop`
callbacks and resets it immediately afterwards, so a manual reset is at best
redundant.

Ctrl+C needs one more turn of the screw. `transport.stop` cannot be called from
inside a signal handler -- it raises `ThreadError` and the transport keeps running
-- so the call has to leave trap context:

```text
trap('INT') { Thread.new { transport.stop } }
```

The reason is in [transport](../subsystems/transport.md).

## Sections that recalculate themselves

`every` repeats a block; it does not recompute the material the block plays. When
each pass has to be *generated* from the state the previous ones left behind, the
shape is an event that relaunches itself when its material runs out:

```text
on :bass_bar do
  grades = 4.times.collect { @markov.next_value }
  control = play H(grade: S(*grades), duration: S(*@durations)) do |note|
    bass.note pitch: @scale[note[:grade]].pitch, duration: note[:duration]
  end
  control.after { launch :bass_bar }
end

at(1) { launch :bass_bar }
```

`@markov` is an **instance**, held across bars: each pass continues the chain
where the previous one left it, which is the whole point -- a fresh instance each
bar would restart the tendency instead of developing it. Series have no `.first`;
`next_value` is how a fixed number of values is taken, and `.max_size(n)` is how a
serie is made finite.

`control.after` fires on natural completion only, so the next bar starts when
this one is genuinely finished rather than when a clock says it should be. A
`.stop` ends the chain instead of advancing it, which is what you want from a
stop.

## Form as a state machine

For a piece with several phases, keep the position in the form in one place and
route every change through a single event:

```text
@state = { phase: :exposition, episode: 0 }

on :transition do |next_phase|
  @state[:phase] = next_phase
  @state[:episode] = 0
  launch next_phase
end

on :exposition do
  @state[:episode] += 1
  next launch(:transition, :development) if @state[:episode] > 3

  control = play(exposition_material(@state[:episode])) { |note| ... }
  control.after { wait(1/8r) { launch :exposition } }
end

at(1) { launch :exposition }
```

Each phase generates its material, plays it, and asks for a transition when it is
done -- **without naming what comes next**. Inserting a section, reordering two,
or repeating one is then an edit in `:transition` alone.

The alternative is a column of `at 17`, `at 33`, `at 49`: absolute positions
computed by hand, every one of which is wrong the moment a duration upstream
changes.

Two syntactic traps live in this shape. `at 1 { ... }` is a **syntax error** in
Ruby -- a brace block binds to the last argument, not to the method -- so write
`at(1) { ... }` or `at 1 do ... end`, and the same for `wait`. And `return`
inside an event block returns from the enclosing method, not from the block: use
`next`.

## The same piece in real time and offline

`TimerClock` plays a piece at its tempo. `DummyClock` advances as fast as the
machine allows, while a condition holds, so a piece renders or tests in the time
it takes to compute it. Choosing between them should not be visible in the score:

```text
clock = if realtime
          TimerClock.new(bpm: 120)
        else
          DummyClock.new { !sequencer.empty? }
        end
```

`TimerClock` needs an explicit `clock.start` from another thread -- it waits to be
activated -- and `DummyClock` does not. A thin proxy that forwards `start`, `stop`
and `bpm=` only when the wrapped clock answers to them keeps that difference out
of the composition, and out of every future clock as well.

## Control arriving from outside

OSC messages, MIDI CC and network events arrive when they arrive, which is never
on a musical grid. Do not make notes from them. Let them **write state**, and let
the sequencer **read that state** on its own grid:

```text
# push -- arrives asynchronously
on :density_changed do |params|
  @pattern = DENSITY[params[:density]]
end

# poll -- happens on the grid
every 1/8r do
  next unless @pattern[(position * 8).to_i % 8] == 1
  lead.note pitch: @scale[@random.rand(0..6)].pitch, duration: 1/16r
end
```

Playing a note straight from the input handler makes its timing a property of the
network. Polling the input *from* the sequencer is worse: a blocking read inside a
scheduled block stops time itself.

## Logging

`Transport.new(..., do_log: true)` turns on the log; the `debug` accessor from the
top of this page takes a block, and the block is only evaluated if the level is
active:

```text
debug { "bass_bar at #{position}, instability #{@instability}" }
```

Interpolating that string on every bar of a piece that is not being debugged is a
cost paid for nothing, which is what the block form avoids. The sequencer itself
is loud at `debug`, so a score that wants its own messages usually wants its own
logger with a different level rather than a quieter sequencer.
