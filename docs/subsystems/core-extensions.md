# Core Extensions - Advanced Metaprogramming

**Note for Advanced Users:** This section covers low-level Ruby refinements and metaprogramming utilities that form the foundation of MusaDSL's flexible syntax. These tools are primarily intended for users who want to extend the DSL, create custom builders, or integrate Musa DSL deeply into their own frameworks.

Core Extensions provide Ruby refinements and metaprogramming utilities that enable MusaDSL's flexible DSL syntax. These are the building blocks used throughout the framework.

## When is this the answer

These are not tools for writing music. They are what the DSL is made of, and you
reach for them when you are **extending** it -- a builder of your own, a verb
that takes parameters as loosely as the framework's do, a structure that has to
survive being copied.

By the shape of the problem:

| You have | You want | This |
|---|---|---|
| a parameter that may be one thing or many | to stop writing `x.is_a?(Array) ? x : [x]` | `arrayfy` |
| a parameter that may be one value or one per voice | `velocity: 80` and `velocity: [80, 90]` to mean the same thing | `hashify` -- a single value broadcasts to every key |
| `60..67` written where a list was expected | the range opened out | `explode_ranges` |
| a nested structure about to be handed to somebody who mutates | a copy that shares nothing | `dup(deep: true)`, or `clone(deep: true)` if it is a dataset |
| a block whose body should read as a DSL | `item 'first'` to resolve against your object | `With` |
| a reference to something that does not exist yet | to hand it out now and decide later | `DynamicProxy` |
| a class with many `add_x` / `xs` pairs to write | not to write them | `AttributeBuilder` |
| a block that receives who-knows-what | to declare only the parameters you use | `SmartProcBinder` |

**When it is NOT the answer.** If you are placing notes in time, choosing
material, or shaping a phrase, nothing here is what you want -- see
[series](series.md), [sequencer](sequencer.md) and [neumas](neumas.md). These
extensions have no musical meaning: they are about Ruby, and they are here
because the musical layer is built on them.

**The two that bite.** `dup` drops the singleton class and `clone` keeps it, so
copying a GDV with `dup(deep: true)` gives back a plain hash that works until
something calls `to_pdv` on it. And `explode_ranges` only opens the top level: a
range inside a nested array stays a range.

## Ruby Refinements & Metaprogramming

**Arrayfy & Hashify** - Parameter Normalization:

Convert any object to array or hash with specified keys. Essential for flexible DSL method signatures.

```ruby
require 'musa-dsl'

using Musa::Extension::Arrayfy
using Musa::Extension::Hashify

# Arrayfy: ensure parameter is array
value = 42
value.arrayfy  # => [42]

array = [1, 2, 3]
array.arrayfy  # => [1, 2, 3] (already array, unchanged)

# Hashify: convert to hash with the given keys, which go in `keys:`
data = [60, 1r, 80]
data.hashify(keys: [:pitch, :duration, :velocity])
# => { pitch: 60, duration: 1r, velocity: 80 }

# A hash keeps what it has and gains what it lacks
existing = { pitch: 64, duration: 1r }
existing.hashify(keys: [:pitch, :duration, :velocity])
# => { pitch: 64, duration: 1r, velocity: nil }

# And a single value is BROADCAST to every key, which is the whole point:
# it is what lets `velocity: 80` and `velocity: [80, 90, 100]` be written
# the same way at the call site
80.hashify(keys: [:soprano, :alto, :bass])
# => { soprano: 80, alto: 80, bass: 80 }

# `default:` fills the gaps instead of leaving them nil
{ pitch: 64 }.hashify(keys: [:pitch, :velocity], default: 80)
# => { pitch: 64, velocity: 80 }
```

**ExplodeRanges** - Range Expansion:

Expand Range objects within arrays, useful for parameter generation.

```ruby
require 'musa-dsl'

using Musa::Extension::ExplodeRanges

# Expand ranges in arrays
[0, 2..4, 7].explode_ranges
# => [0, 2, 3, 4, 7]

# Only at the top level: a range inside a nested array is left alone.
[1, 3..5, [10, 12..14]].explode_ranges
# => [1, 3, 4, 5, [10, 12..14]]

# Useful for pitch collections
chord = [60, 64..67, 72].explode_ranges
# => [60, 64, 65, 66, 67, 72]
```

**DeepCopy** - Deep Object Cloning:

Create deep copies of objects with circular reference handling and singleton module preservation.

The refinement adds a `deep:` option to `dup` and `clone`; there is no
`deep_copy` method on the object.

```ruby
require 'musa-dsl'

using Musa::Extension::DeepCopy

original = { pitch: 60, envelope: { attack: 0.1, decay: 0.2 } }
copy = original.dup(deep: true)

copy[:envelope][:attack] = 0.5

original[:envelope][:attack]  # => 0.1
copy[:envelope][:attack]      # => 0.5
```

**`dup` or `clone` decides whether the dataset survives**, and it decides it the
same way plain Ruby does: `dup` drops the singleton class, `clone` keeps it. A
GDV, a PDV, an AbsI — every dataset in this framework is a Hash or an Array with
a module extended into its singleton class, so this is not a detail:

```ruby
gdv = { grade: 0, duration: 1r }.extend(Musa::Datasets::GDV)

gdv.clone(deep: true).is_a?(Musa::Datasets::GDV)  # => true
gdv.dup(deep: true).is_a?(Musa::Datasets::GDV)    # => false
```

Copy a dataset with `dup` and what comes back is a plain hash with the right
keys, which will go on working until something asks it `to_pdv` and finds no
such method.

**Freezing follows `Object#clone`'s three rules, at every node.** `freeze: true`
freezes the whole copy, `false` freezes nothing, and the default — `nil` —
gives each node the state its own original had, so a frozen tree comes back
frozen and a mixed one comes back mixed:

```ruby
frozen = { a: { b: 1 }.freeze }.freeze
frozen.clone(deep: true).frozen?       # => true
frozen.clone(deep: true)[:a].frozen?   # => true

frozen.clone(deep: true, freeze: false).frozen?  # => false
```

It also handles circular graphs: a structure that refers to itself is copied
once and the copy refers to itself in the same shape.

**SmartProcBinder** - Intelligent Parameter Binding:

Automatically match Proc parameters with available values, enabling flexible block signatures in DSL methods.

```ruby
require 'musa-dsl'

# SmartProcBinder is used internally by Series operations
# to match block parameters flexibly

using Musa::Extension::SmartProcBinder

# Example: .with operation uses SmartProcBinder
pitches = S(60, 64, 67)
durations = S(1r, 1/2r, 1/4r)

# Block can request any combination of parameters
notes = pitches.with(dur: durations) do |p, dur:|
  { pitch: p, duration: dur }
end

# SmartProcBinder matches 'p' to pitch value, 'dur:' to duration value
# regardless of parameter order or naming
```

**DynamicProxy** - A Reference Before There Is Anything To Refer To:

An object that forwards everything to a `receiver` you set later. It does not
create anything by itself: what it buys is being able to hand out a reference
now and decide what it points at afterwards.

```ruby
require 'musa-dsl'

proxy = Musa::Extension::DynamicProxy::DynamicProxy.new

proxy.receiver = [1, 2, 3]
proxy.size   # => 3

proxy.receiver = 'Hello'
proxy.size   # => 5
```

Called before its receiver is set, it says so rather than failing obscurely:

```ruby
begin
  Musa::Extension::DynamicProxy::DynamicProxy.new.size
rescue NoMethodError => e
  e.message
end
# => "Method 'size' is unknown because self is a DynamicProxy with undefined receiver"
```

**With** - Flexible Block Execution:

Run a block either in the caller's context or in the object's, which is what
lets a DSL read as a DSL. `include Musa::Extension::With` and the object gains
`with`.

```ruby
require 'musa-dsl'

class Builder
  include Musa::Extension::With

  attr_reader :items

  def initialize(&block)
    @items = []
    with(&block) if block
  end

  def item(name)
    @items << name
    self
  end
end

Builder.new { item 'first'; item 'second' }.items
# => ["first", "second"]
```

Inside the block, `item` resolves against the Builder: the block was
`instance_eval`ed. Write a parameter named `_` and it flips — the block runs in
the caller's context and the object arrives as that parameter, which is what you
want when the block needs the surrounding scope more than the object's verbs.

**AttributeBuilder** - DSL Builder Macros:

Generates the adder/getter pairs that the Score classes are built from. It is
`extend`ed, not included, and the macros are named after the shape of what they
build -- there is no generic `attribute`:

| Macro | Generates |
|---|---|
| `attr_simple_builder :name` | `name(value)` sets, `name` reads |
| `attr_tuple_adder_to_hash :item, Klass` | `add_item(id, value)`, `items` |
| `attr_tuple_adder_to_array :item, Klass` | `add_item(...)`, `items` |
| `attr_complex_adder_to_array :item, Klass` | the same, with a block-built value |
| `attr_complex_adder_to_custom :item` | the same, with your own constructor |

```ruby
require 'musa-dsl'

Track = Struct.new(:id, :name)

class Arrangement
  extend Musa::Extension::AttributeBuilder

  def initialize
    @tracks = {}
  end

  attr_tuple_adder_to_hash :track, Track
end

arrangement = Arrangement.new
arrangement.add_track :piano, 'Piano I'
arrangement.tracks[:piano].name  # => "Piano I"
```

The plural is derived from the singular (`track` → `tracks`) unless `plural:`
says otherwise, and the adder builds `Klass.new(id, value)`, so the class has to
take both.

## Logger - Sequencer-Aware Logging

Specialized logger that displays sequencer position alongside log messages. Essential for debugging temporal issues in compositions.

**Features:**
- Automatic sequencer position formatting
- Configurable position precision (integer and decimal digits)
- Integration with InspectNice for readable Rational display
- Standard Ruby Logger levels (DEBUG, INFO, WARN, ERROR, FATAL)

```ruby
require 'musa-dsl'

# Create sequencer-aware logger
sequencer = Musa::Sequencer::Sequencer.new(4, 24)

# The position format is ONE number: integer digits before the point, decimal
# digits after it. 3.3 prints bar 4.5 as "  4.500".
logger = Musa::Logger::Logger.new(sequencer: sequencer, position_format: 3.3)
logger.level = Logger::DEBUG

# Use logger in sequencer context
sequencer.at 1 do
  logger.info "Starting melody at bar 1"
end

sequencer.at 4.5r do
  logger.debug "Halfway through bar 5"
end

sequencer.at 10 do
  logger.warn "Approaching ending"
end

# Run sequencer to see logged output
sequencer.run

# Output:
#   001.000: [INFO] Starting melody at bar 1
#   004.500: [DEBUG] Halfway through bar 5
#   010.000: [WARN] Approaching ending
```

**Use Cases:**
- **Temporal Debugging**: Track down timing issues by seeing exact musical position
- **MIDI Event Monitoring**: Log MIDI note-on/note-off with positions
- **Composition Development**: Monitor sequencer flow during development
- **Performance Analysis**: Identify bottlenecks by logging with timestamps

## API Reference

**Complete API documentation:**
- [Musa::Extension](https://rubydoc.info/gems/musa-dsl/Musa/Extension) - Ruby refinements and metaprogramming utilities
- [Musa::Logger](https://rubydoc.info/gems/musa-dsl/Musa/Logger) - Structured logging system

**Source code:** `lib/core-ext/` and `lib/logger/`


## Documentation

Full API documentation is available in YARD format. All files in the project are comprehensively documented with:

- Architecture overviews
- Usage examples
- Parameter descriptions
- Return values
- Integration examples

To generate and view the documentation locally:

```bash
yard doc
yard server
```

Then open http://localhost:8808 in your browser.

## Examples & Works

Listen to compositions created with Musa-DSL: [yeste.studio](https://yeste.studio)

## Contributing

Contributions are welcome! Please feel free to:

1. Fork the repository
2. Create a feature branch
3. Make your changes with tests
4. Submit a pull request

**Repository:** https://github.com/javier-sy/musa-dsl

## License

Musa-DSL is released under the [LGPL-3.0-or-later](https://www.gnu.org/licenses/lgpl-3.0.html) license.

## Acknowledgments

- **Author:** Javier Sánchez Yeste ([yeste.studio](https://yeste.studio))
- **Email:** javier (at) yeste.studio

Special thanks to [JetBrains](https://www.jetbrains.com/?from=Musa-DSL) for providing an Open Source project license for RubyMine IDE during several years. 

---

*Musa-DSL - Algorithmic sound and musical thinking through code*
