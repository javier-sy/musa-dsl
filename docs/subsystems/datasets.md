# Datasets - Sonic Data Structures

Comprehensive framework for representing and transforming sonic events and processes. Datasets are flexible, extensible hash structures that support multiple representations (MIDI, score notation, delta encoding) with rich conversion capabilities.

**Key characteristics:**

- **Flexible and extensible**: All datasets are hashes that can include any custom parameters beyond their natural keys
- **Event vs Process abstractions**: Distinguish between instantaneous events and time-spanning processes
- **Bidirectional conversions**: Transform between MIDI (PDV), score notation (GDV), delta encoding (GDVd), and other formats
- **Integration**: Used throughout MusaDSL components (sequencer, series, neumas, transcription, matrix)

## When is this the answer

A dataset is a Hash (or an Array) with a module extended into it. The module is
not decoration: it is what says how to read the keys, and it is what carries the
conversions. So you reach for one when **a hash of yours has to be understood by
something else** -- the sequencer, a voice, the MusicXML writer, a transcriptor.

By the shape of what you have:

| You have | You want | This |
|---|---|---|
| a MIDI pitch, a duration, a velocity | to send it to an instrument | **PDV** |
| a scale degree, a duration, a dynamic | to write it as music, not as MIDI | **GDV** |
| a motif that has to work from any starting note | to keep the shape and drop the origin | **GDVd** |
| a value that changes over time | to walk it with `play_timed` | **AbsTimed** |
| a shape given as points and the times between them | a gesture to be played or read as segments | **P** |
| a ramp from one value to another | its endpoints and how long it takes | **PS** |
| several parallel values at one instant | to treat them as one event | **V**, or **PackedV** keyed |

**The distinction that organises the rest** is event against process. An event
happens at an instant and has a duration -- a note. A process spans time and is
read as it goes -- a glissando, an envelope, a gesture. `at` and `play` are for
the first; `move` and `play_timed` for the second, and P, PS and AbsTimed are
its datasets.

**When it is NOT the answer.** A hash you build and consume yourself needs no
dataset: extending it buys nothing and costs the reader a question. The module
earns its place at the boundary, where somebody else has to know what the keys
mean.

**And two things that bite.**

Copying a dataset with `dup(deep: true)` **drops the module** -- it is a
singleton class, and `dup` drops singleton classes exactly as plain Ruby does.
Use `clone(deep: true)`. What comes back from `dup` is a plain hash with the
right keys, and it works until something calls `to_pdv` on it.

A duration is a fraction of a **bar**, not of a whole note. `1r` is a bar. In
4/4 that makes `1/4r` a quarter note, which is why the two readings agree there
and only there: in 3/4 a quarter note is `1/3r`.

## Dataset Hierarchy

**Event Type Modules (E)** - Define absolute vs delta encoding:

```
E (base event)
├── Abs (absolute values)
│   ├── AbsI (array-indexed)       → used by V
│   ├── AbsTimed (with :time)      → used by P conversions
│   └── AbsD (with :duration)      → used by PDV, GDV
└── Delta (incremental values)
    ├── DeltaI (array-indexed delta)
    └── DeltaD (delta with duration) → used by GDVd
```

**Data Structure Modules** - Basic containers:

- **V**: Value arrays - ordered values in array form
- **PackedV**: Packed values - key-value hash pairs
- **P**: Point series - sequential points in time with durations [point, duration, point, duration, ...]

**Dataset Modules** - Domain-specific representations:

**Musical datasets** (scale-based and MIDI):
- **PDV**: Pitch/Duration/Velocity - MIDI-style absolute pitches (0-127)
- **GDV**: Grade/Duration/Velocity - Score-style scale degrees with dynamics
- **GDVd**: Grade/Duration/Velocity delta - Incremental encoding for compression

**Sonic datasets** (continuous parameters and events):
- **PS**: Parameter Segments - Continuous changes between multidimensional points (from/to/duration for glissandi, sweeps, modulations)
- **Score**: Time-indexed container for organizing sonic events

## Event Categories

**Instantaneous Sound Events** - Occur at a point in time:
- Events without duration (triggers, markers)
- AbsTimed events (time-stamped values)

**Sound Processes** - Span duration over time:
- Notes with duration (AbsD, PDV, GDV)
- Glissandi and parameter sweeps (PS)
- Dynamics changes and other evolving parameters

## Duration Types in AbsD

AbsD defines three duration concepts that enable complex rhythmic structures:

| Field | Purpose | Default |
|-------|---------|---------|
| `:duration` | Total event process time | Required |
| `:note_duration` | Actual sound length (staccato/legato) | = duration |
| `:forward_duration` | Time until next event starts | = duration |

**Examples:**

```ruby
include Musa::Datasets

# Normal note - all durations equal
{ pitch: 60, duration: 1.0 }.extend(AbsD)

# Staccato - sounds shorter than it "lasts"
{ pitch: 60, duration: 1.0, note_duration: 0.5 }.extend(AbsD)

# Chord (simultaneous notes) - next event starts immediately
{ pitch: 60, duration: 1.0, forward_duration: 0 }.extend(AbsD)

# Overlap (legato) - next note starts before this one ends
{ pitch: 60, duration: 1.0, forward_duration: 0.8 }.extend(AbsD)
```

**Understanding DeltaD:**

DeltaD is the delta-encoding counterpart to AbsD. While AbsD stores absolute durations, DeltaD stores changes relative to a previous event. If duration hasn't changed from the previous event, it can be omitted for compression (as shown in GDV → GDVd conversions).

## Natural Keys

Each dataset type defines "natural keys" - semantically meaningful fields for that type:

| Module | Natural Keys |
|--------|--------------|
| **E** | `[]` (none) |
| **AbsD** | `[:duration, :note_duration, :forward_duration]` |
| **PDV** | AbsD keys + `[:pitch, :velocity]` |
| **GDV** | AbsD keys + `[:grade, :sharps, :octave, :velocity, :silence]` |

Custom keys (any not in NaturalKeys) are preserved through conversions, enabling you to attach composition-specific metadata that travels with your musical data.

## Extensibility

All datasets support custom parameters beyond their natural keys:

```ruby
require 'musa-dsl'
include Musa::Datasets

# GDV with standard parameters
gdv = { grade: 0, duration: 1r, velocity: 0 }.extend(GDV)

# Extended with custom parameters for your composition
gdv_extended = {
  grade: 0,
  duration: 1r,
  velocity: 0,
  # Custom parameters
  articulation: :staccato,
  timbre: :bright,
  reverb_send: 0.3,
  custom_control: 42
}.extend(GDV)

# Custom parameters preserved through conversions
scale = Musa::Scales::Scales.et12[440.0].major[60]
pdv = gdv_extended.to_pdv(scale)
# => { pitch: 60, duration: 1r, velocity: 64,
#      articulation: :staccato, timbre: :bright, ... }
```

## Dataset Validation

Check dataset validity and type:

```ruby
include Musa::Datasets

# Create dataset
gdv = { grade: 0, duration: 1r, velocity: 0 }.extend(GDV)

# Validation methods
gdv.valid?      # => true - check if valid
gdv.validate!   # Raises if invalid, returns if valid

# Type checking
gdv.is_a?(GDV)   # => true
gdv.is_a?(Abs)   # => true (GDV includes Abs)
gdv.is_a?(AbsD)  # => true (GDV includes AbsD for duration)
```

## Using AbsD for Containers

AbsD is not just for notes - use it for any time-spanning structure that needs a duration. This is useful for chord progression steps, sections, or any compositional element that occupies time but isn't itself a single note.

```ruby
include Musa::Datasets

scale = Musa::Scales::Scales.et12[440.0].major[60]

# A chord progression step (not a note, but has duration)
step = {
  duration: 2,                    # How long this step lasts
  symbol: :I,                     # Chord symbol for reference
  bass: { grade: 0, octave: -1, duration: 2, velocity: 0 }.extend(GDV),
  chord: scale[:I].chord,         # Chord object
  chord_duration: 7/4r,
  chord_velocity: -1
}.extend(AbsD)

# Now the sequencer can use step.duration for timing
# while the step contains all the musical information needed to render it
```

**When to use AbsD directly:**

- Containers that hold multiple notes (chords, arpeggios)
- Section markers with timing information
- Harmonic rhythm steps in a progression
- Any structure where you need `:duration` but PDV/GDV semantics don't apply

## Dataset Conversions

Datasets provide rich conversion capabilities for transforming between different representations, each optimized for specific compositional tasks:

- **GDV ↔ PDV** (Score ↔ MIDI): Bidirectional conversion between symbolic information (scale degrees) and absolute pitches for (i.e.) MIDI output
- **GDV ↔ GDVd** (Absolute ↔ Delta): Generation and analysis of melodic patterns using incremental encoding
- **V ↔ PackedV** (Array ↔ Hash): Compact representation that expands to verbose structures with semantic labels
- **P → PS** (Points → Segments): Creation of glissandi and continuous interpolations between sequentially timed points
- **P → AbsTimed** (Relative → Absolute time): Conversion from relative temporal expressions to absolute time coordinates for (i.e.) scheduling and motif replication at different temporal positions
- **GDV → Neuma**: Export to Neumalang notation strings for human-readable scores

**Score ↔ MIDI (GDV ↔ PDV)**:

```ruby
include Musa::Datasets

scale = Musa::Scales::Scales.et12[440.0].major[60]

# Score to MIDI
gdv = { grade: 0, octave: 0, duration: 1r, velocity: 0 }.extend(GDV)
pdv = gdv.to_pdv(scale)
# => { pitch: 60, duration: 1r, velocity: 64 }

# MIDI to Score
pdv = { pitch: 64, duration: 1r, velocity: 80 }.extend(PDV)
gdv = pdv.to_gdv(scale)
# => { grade: 2, octave: 0, duration: 1r, velocity: 1 }
```

**Absolute ↔ Delta Encoding (GDV ↔ GDVd)**:

A GDVd states each event as *movement from whatever came before*: an interval
instead of a grade, a factor instead of a duration. **This is not compression.**
A passage written this way says nothing about where it starts, so it can start
anywhere -- the same GDVd sequence applied to a different GDV is the same music
transposed, in another register, at another dynamic, at another speed, and
applied to a different scale it is the same shape read through other intervals.
A motif is its profile, and the profile is the dataset.

```ruby
include Musa::Datasets

scale = Musa::Scales::Scales.et12[440.0].major[60]

# Both events need :octave for an interval to be computable, and both need
# base_duration set: without it the conversion divides by nil.
gdv1 = { grade: 0, octave: 0, duration: 1r, velocity: 0 }.extend(GDV)
gdv2 = { grade: 2, octave: 0, duration: 1r, velocity: 1 }.extend(GDV)
[gdv1, gdv2].each { |g| g.base_duration = 1/4r }

# The first has nothing to move from, so it states itself
gdv1.to_gdvd(scale)
# => { abs_grade: 0, abs_duration: 1r, abs_velocity: 0 }

# The second, as movement from the first
gdv2.to_gdvd(scale, previous: gdv1)
# => { delta_grade: 2, delta_sharps: 0, delta_velocity: 1 }
# The duration did not change, so nothing is said about it -- and saying
# nothing about it is what lets this fragment keep whatever duration the
# passage it is dropped into has.
```

`previous:` is the base the movement departs from, in both directions: the same
argument that turns a GDV into a GDVd turns it back, and that is where
re-rooting happens.

```ruby
gdvd = gdv2.to_gdvd(scale, previous: gdv1)
gdvd.base_duration = 1/4r

gdvd.to_gdv(scale, previous: gdv1)
# => { grade: 2, octave: 0, duration: 1r, velocity: 1 }
```

Give it another `previous:` and the same movement lands somewhere else. That is
the whole point.

The notation is written this way too: `(+1 -o1 *2)` in a neuma is a GDVd.

**Array ↔ Hash (V ↔ PackedV)**:

```ruby
include Musa::Datasets

# Array to hash
v = [60, 1r, 64].extend(V)
pv = v.to_packed_V([:pitch, :duration, :velocity])
# => { pitch: 60, duration: 1r, velocity: 64 }

# Hash to array
pv = { pitch: 60, duration: 1r, velocity: 64 }.extend(PackedV)
v = pv.to_V([:pitch, :duration, :velocity])
# => [60, 1r, 64]

# With default values (compression)
v = [60, 1r, 64].extend(V)
pv = v.to_packed_V({ pitch: 60, duration: 1r, velocity: 64 })
# => {}  (all values match defaults, fully compressed)
```

**Series ↔ Segments (P → PS)**:

```ruby
include Musa::Datasets

# Point series to parameter segments. `to_ps_serie` gives a PROTOTYPE, so it
# has to be instantiated with `.i` before anything can be read from it.
p = [60, 4, 64, 8, 67].extend(P)

p.to_ps_serie.i.to_a
# => [{ from: 60, duration: 1r, to: 64, right_open: true },
#     { from: 64, duration: 2r, to: 67, right_open: false }]
#
# Two points become one segment: [60, 4, 64] says "from 60, over 4 base
# durations, to 64". The last one is not right_open because there is nothing
# after it to leave room for.
```

**Series → Timed Events (P → AbsTimed)**:

```ruby
include Musa::Datasets

p = [60, 4, 64, 8, 67].extend(P)

p.to_timed_serie(base_duration: 1/4r, time_start: 0).i.to_a
# => [{ time: 0, value: 60 }, { time: 1r, value: 64 }, { time: 3r, value: 67 }]
#
# The times are the durations accumulated: 4 base durations of 1/4 is one bar,
# 8 more is two more.
```

**Score Notation → String (GDV → Neuma)**:

```ruby
include Musa::Datasets

gdv = { grade: 0, octave: 1, duration: 1r, velocity: 2 }.extend(GDV)
gdv.base_duration = 1/4r

neuma = gdv.to_neuma
# => "(0 o1 4 f)"
# Format: (grade octave duration_in_quarters dynamics)
```

## Integration with Other Components

**Sequencer** - Accepts extended datasets:

```ruby
require 'musa-dsl'
include Musa::All

sequencer = Sequencer.new(4, 24)

# Use GDV datasets directly
sequencer.at 1 do
  event = { grade: 0, duration: 1r, velocity: 0, articulation: :legato }.extend(GDV)
  # Process event...
end
```

**Series** - Work with any dataset type:

```ruby
include Musa::All

# Series of GDV events
gdv_serie = S(
  { grade: 0, duration: 1r }.extend(GDV),
  { grade: 2, duration: 1r }.extend(GDV),
  { grade: 4, duration: 1r }.extend(GDV)
)

# Transform while preserving dataset type
scale = Scales.et12[440.0].major[60]
pdv_serie = gdv_serie.map { |gdv| gdv.to_pdv(scale) }
```

**Matrix** - Generates P series:

```ruby
require 'musa-dsl'
using Musa::Extension::Matrix

# Matrix to P format
gesture = Matrix[[0, 60], [1, 62], [2, 64]]
p_sequences = gesture.to_p(time_dimension: 0)
# => [[[60], 1, [62], 1, [64]]]
# P format: alternating values and durations
```

**Neumas** - Parse to GDV:

Parsing needs a decoder, because the notation is differential and the decoder
is what holds the scale and the base duration the movements are read against.

```ruby
include Musa::All

scale = Scales.et12[440.0].major[60]
decoder = Musa::Neumas::Decoders::NeumaDecoder.new(scale, base_duration: 1/4r)

# Note the notation: the first grade is absolute, the rest are movements
Musa::Neumalang::Neumalang.parse("(0 4 mf) (+2 4 f) (+2 4 ff)",
                                 decode_with: decoder).i.to_a
# => [{ grade: 0, octave: 0, duration: 1r, velocity: 1 },
#     { grade: 2, octave: 0, duration: 1r, velocity: 2 },
#     { grade: 4, octave: 0, duration: 1r, velocity: 3 }]
```

Without `decode_with:` the parse stops at the notation and gives GDVd -- the
movements themselves, unresolved. That is the useful form when the material is
to be re-rooted somewhere else; see the GDVd section above.

**Transcription** - Converts between representations:

```ruby
include Musa::All

scale = Scales.et12[440.0].major[60]

# GDV to PDV for MIDI output
gdv_events = [
  { grade: 0, duration: 1r, velocity: 0 }.extend(GDV),
  { grade: 2, duration: 1r, velocity: 1 }.extend(GDV)
]

midi_events = gdv_events.map { |gdv| gdv.to_pdv(scale) }
# Send to MIDI output...
```

**Score Container** - Organize events in time:

```ruby
include Musa::Datasets

score = Score.new

# Add events at specific times
score.at(1r, add: { grade: 0, duration: 1r }.extend(GDV))
score.at(2r, add: { grade: 2, duration: 1r }.extend(GDV))
score.at(3r, add: { grade: 4, duration: 1r }.extend(GDV))

# Query events
events_at_2 = score.at(2r)
events_in_range = score.between(1r, 3r)
```

## API Reference

**Complete API documentation:**
- [Musa::Datasets](https://rubydoc.info/gems/musa-dsl/Musa/Datasets) - Musical data structures (GDV, PDV, Score)

**Source code:** `lib/datasets/`

## Score - Advanced Queries & Filtering

Score provides powerful query and filtering capabilities beyond basic event storage. These methods enable temporal analysis, event filtering, and subset extraction.

**Interval Queries** - `between(start, finish)`:

Retrieves all events that overlap a given time interval. Returns events with their effective start/finish times within the query range.

```ruby
include Musa::Datasets

score = Score.new

# Add events with durations
score.at(1r, add: { pitch: 60, duration: 2r }.extend(PDV))  # 1-3
score.at(2r, add: { pitch: 64, duration: 1r }.extend(PDV))  # 2-3
score.at(3r, add: { pitch: 67, duration: 2r }.extend(PDV))  # 3-5

# Query events overlapping interval [2, 4)
events = score.between(2r, 4r)

events.each do |event|
  puts "Pitch #{event[:dataset][:pitch]}"
  puts "  Original: #{event[:start]} - #{event[:finish]}"
  puts "  In interval: #{event[:start_in_interval]} - #{event[:finish_in_interval]}"
end

# => Pitch 60 (started at 1, overlaps 2-4)
#    Original: 1r - 3r
#    In interval: 2r - 3r
#
# => Pitch 64 (completely within 2-4)
#    Original: 2r - 3r
#    In interval: 2r - 3r
#
# => Pitch 67 (started at 3, overlaps 2-4)
#    Original: 3r - 5r
#    In interval: 3r - 4r
```

**Timeline Changes** - `changes_between(start, finish)`:

Returns a timeline of note-on/note-off style events. Useful for real-time rendering, event-based processing, or analyzing harmonic density over time.

```ruby
include Musa::Datasets

score = Score.new

score.at(1r, add: { pitch: 60, duration: 2r }.extend(PDV))
score.at(2r, add: { pitch: 64, duration: 1r }.extend(PDV))
score.at(3r, add: { pitch: 67, duration: 1r }.extend(PDV))

# Get all start/finish events in bar
changes = score.changes_between(0r, 4r)

changes.each do |change|
  case change[:change]
  when :start
    puts "#{change[:time]}: Note ON  - pitch #{change[:dataset][:pitch]}"
  when :finish
    puts "#{change[:time]}: Note OFF - pitch #{change[:dataset][:pitch]}"
  end
end

# => 1r: Note ON  - pitch 60
#    2r: Note ON  - pitch 64
#    3r: Note OFF - pitch 60
#    3r: Note OFF - pitch 64
#    3r: Note ON  - pitch 67
#    4r: Note OFF - pitch 67
```

**Attribute Collection** - `values_of(attribute)`:

Extracts all unique values for a specific attribute across all events. Useful for analysis, validation, or generating material from existing compositions.

```ruby
include Musa::Datasets

score = Score.new

score.at(1r, add: { pitch: 60, duration: 1r }.extend(PDV))
score.at(2r, add: { pitch: 64, duration: 1r }.extend(PDV))
score.at(3r, add: { pitch: 67, duration: 1r }.extend(PDV))
score.at(4r, add: { pitch: 64, duration: 1r }.extend(PDV))  # Repeated

# Get all unique pitches used
pitches = score.values_of(:pitch)
# => #<Set: {60, 64, 67}>

# Analyze durations
durations = score.values_of(:duration)
# => #<Set: {1r}>

# Check velocities
velocities = score.values_of(:velocity)
# => #<Set: {64}>  (default velocity from PDV)
```

**Filtering** - `subset { |event| condition }`:

Creates a new Score containing only events matching a condition. Preserves timing and all event attributes.

```ruby
include Musa::Datasets

score = Score.new

score.at(1r, add: { pitch: 60, velocity: 80, duration: 1r }.extend(PDV))
score.at(2r, add: { pitch: 72, velocity: 100, duration: 1r }.extend(PDV))
score.at(3r, add: { pitch: 64, velocity: 60, duration: 1r }.extend(PDV))
score.at(4r, add: { pitch: 79, velocity: 90, duration: 1r }.extend(PDV))

# Filter by pitch range
high_notes = score.subset { |event| event[:pitch] >= 70 }

high_notes.at(2r).first[:pitch]  # => 72
high_notes.at(4r).first[:pitch]  # => 79

# Filter by velocity
loud_notes = score.subset { |event| event[:velocity] >= 85 }

# Filter by custom attribute
scale = Musa::Scales::Scales.et12[440.0].major[60]

score_gdv = Score.new
score_gdv.at(1r, add: { grade: 0, duration: 1r }.extend(GDV))
score_gdv.at(2r, add: { grade: 2, duration: 1r }.extend(GDV))
score_gdv.at(3r, add: { grade: 4, duration: 1r }.extend(GDV))

# Extract tonic notes only
tonic_notes = score_gdv.subset { |event| event[:grade] == 0 }
```

**Use Cases:**

- **Score Analysis**: Extract patterns, identify harmonic structures, analyze voice leading
- **Partial Rendering**: Render only specific time ranges or event types
- **Material Generation**: Extract pitches, rhythms, or other parameters for reuse
- **Real-time Processing**: Convert to timeline format for event-based playback
- **Filtering**: Create variations by extracting subsets (high notes, loud notes, specific scales)


