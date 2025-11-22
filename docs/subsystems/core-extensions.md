# Core Extensions - Advanced Metaprogramming

**Note for Advanced Users:** This section covers low-level Ruby refinements and metaprogramming utilities that form the foundation of MusaDSL's flexible syntax. These tools are primarily intended for users who want to extend the DSL, create custom builders, or integrate Musa DSL deeply into their own frameworks.

Core Extensions provide Ruby refinements and metaprogramming utilities that enable MusaDSL's flexible DSL syntax. These are the building blocks used throughout the framework.

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

# Hashify: convert to hash with specified keys
data = [60, 1r, 80]
data.hashify(:pitch, :duration, :velocity)
# => { pitch: 60, duration: 1r, velocity: 80 }

# Works with hashes (validates keys)
existing = { pitch: 64, duration: 1r }
existing.hashify(:pitch, :duration, :velocity)
# => { pitch: 64, duration: 1r, velocity: nil }
```

**ExplodeRanges** - Range Expansion:

Expand Range objects within arrays, useful for parameter generation.

```ruby
require 'musa-dsl'

using Musa::Extension::ExplodeRanges

# Expand ranges in arrays
[0, 2..4, 7].explode_ranges
# => [0, 2, 3, 4, 7]

# Works with nested structures
[1, 3..5, [10, 12..14]].explode_ranges
# => [1, 3, 4, 5, [10, 12, 13, 14]]

# Useful for pitch collections
chord = [60, 64..67, 72].explode_ranges
# => [60, 64, 65, 66, 67, 72]
```

**DeepCopy** - Deep Object Cloning:

Create deep copies of objects with circular reference handling and singleton module preservation.

```ruby
require 'musa-dsl'

using Musa::Extension::DeepCopy

original = { pitch: 60, envelope: { attack: 0.1, decay: 0.2 } }
copy = original.deep_copy

copy[:envelope][:attack] = 0.5

original[:envelope][:attack]  # => 0.1 (unchanged)
copy[:envelope][:attack]       # => 0.5 (modified)

# Preserves singleton modules (dataset types)
gdv = { grade: 0, duration: 1r }.extend(Musa::Datasets::GDV)
gdv_copy = gdv.deep_copy

gdv_copy.is_a?(Musa::Datasets::GDV)  # => true (module preserved)
```

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

**DynamicProxy** - Lazy Initialization Pattern:

Forward method calls to a lazily-initialized target. Used for deferred object creation.

```ruby
require 'musa-dsl'

# DynamicProxy is used internally for lazy series evaluation
# and deferred resource allocation

# Example: Proxy pattern for expensive resource
class ExpensiveResource
  def initialize
    puts "Initializing expensive resource..."
    @data = (1..1000000).to_a
  end

  def process
    puts "Processing..."
  end
end

# Create proxy (doesn't initialize resource yet)
proxy = Musa::Extension::DynamicProxy::DynamicProxy.new(ExpensiveResource)

# Resource is created only when first method is called
proxy.process  # Outputs: "Initializing expensive resource..." then "Processing..."
proxy.process  # Only outputs: "Processing..." (resource already initialized)
```

**With** - Flexible Block Execution:

Execute blocks with flexible context switching (instance_eval vs call with self). Core utility for DSL builders.

```ruby
require 'musa-dsl'

using Musa::Extension::With

# Used internally by DSL builders to execute configuration blocks
# Can switch between instance_eval (DSL style) and block.call (parameter style)

class Builder
  def initialize(&block)
    @items = []
    # Execute block in builder context using With
    self.with &block
  end

  def item(name)
    @items << name
  end

  def items
    @items
  end
end

# DSL-style block (instance_eval)
builder = Builder.new do
  item "first"
  item "second"
end

builder.items  # => ["first", "second"]
```

**AttributeBuilder** - DSL Builder Macros:

Metaprogramming macros for creating DSL builder patterns. Automatically generates setter and getter methods.

```ruby
require 'musa-dsl'

# AttributeBuilder is used internally by MusicXML Builder and other DSL components

class SynthConfig
  include Musa::Extension::AttributeBuilder

  # Define DSL attributes
  attribute :waveform
  attribute :frequency
  attribute :amplitude

  def initialize(&block)
    self.with &block if block
  end
end

# Use DSL to configure
synth = SynthConfig.new do
  waveform :sine
  frequency 440
  amplitude 0.8
end

synth.waveform   # => :sine
synth.frequency  # => 440
synth.amplitude  # => 0.8
```

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

logger = Musa::Logger.new(
  sequencer: sequencer,
  level: :debug,
  position_format_integer_digits: 3,    # Position: "  4" instead of "4"
  position_format_decimal_digits: 3     # Position: "4.500" instead of "4.5"
)

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

**Documentation:** See `lib/core-ext/` and `lib/logger/`


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
