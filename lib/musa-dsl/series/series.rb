# Series module aggregator and architectural overview.
#
# This file loads all series components providing the complete series system
# for lazy evaluation of musical sequences and transformations.
#
# ## Architecture Overview
#
# The Series system consists of several layers:
#
# ### Core Layer (base-series.rb)
#
# - **Serie**: Module factory (Serie.base, Serie.with)
# - **Prototyping**: Prototype/instance pattern implementation
# - **SerieImplementation**: Core iteration protocol (next_value, restart, etc.)
#
# ### Construction Layer
#
# - **Constructors** (main-serie-constructors.rb): Factory methods
#   - S, E, RND, FOR, FIBO, SIN, HARMO, etc.
#   - H/HC, A/AC (hash/array mode)
#   - PROXY, QUEUE, MERGE
#   - TIMED_UNION, QUANTIZE
#
# ### Transformation Layer
#
# - **Operations** (main-serie-operations.rb): Transformation methods
#   - Mapping: map, with, process_with
#   - Filtering: select, remove, skip, max_size
#   - Control: repeat, autorestart, flatten
#   - Timing: anticipate, lazy
#   - Structural: reverse, randomize, cut
#   - Switching: switch, multiplex
#
# ### Utility Layer
#
# - **Array Extension** (array-to-serie.rb): Array#to_serie
# - **Buffering** (buffer-serie.rb): Multiple independent readers
# - **Splitting** (hash-or-array-serie-splitter.rb): Component extraction
# - **Quantization** (quantizer-serie.rb): Time-value quantization
# - **Timed Operations** (timed-serie.rb): Time-synchronized merging
# - **Composer** (series-composer.rb): Multi-stage pipelines
# - **Proxy** (proxy-serie.rb): Late binding and delegation
# - **Queue** (queue-serie.rb): Dynamic concatenation
#
# ## Key Concepts
#
# ### Prototype/Instance Pattern
#
# Series use prototype/instance pattern for reusability:
#
# ```ruby
# # Prototype (template)
# melody = S(60, 64, 67, 72)
#
# # Instances (independent iterations)
# voice1 = melody.instance  # or melody.i
# voice2 = melody.instance  # separate state
# ```
#
# ### Lazy Evaluation
#
# Values generated on-demand via next_value:
#
# ```ruby
# infinite = FOR(from: 0, step: 1)  # Not evaluated yet
# inst = infinite.i
# inst.next_value  # => 0 (evaluated now)
# inst.next_value  # => 1
# ```
#
# ### Functional Composition
#
# Operations return new series (immutable style):
#
# ```ruby
# transformed = S(1, 2, 3)
#   .map { |x| x * 2 }      # => [2, 4, 6]
#   .select { |x| x > 3 }   # => [4, 6]
#   .repeat(2)              # => [4, 6, 4, 6]
# ```
#
# ### State Management
#
# Three states: :prototype, :instance, :undefined
#
# - Prototypes: Cannot consume (template)
# - Instances: Can consume (active iteration)
# - Undefined: Unresolved dependencies
#
# ## Usage Patterns
#
# ### Basic Construction
#
# ```ruby
# include Musa::Series
#
# notes = S(60, 64, 67, 72)
# inst = notes.i
# inst.to_a  # => [60, 64, 67, 72]
# ```
#
# ### Transformations
#
# ```ruby
# transposed = notes.map { |n| n + 12 }
# selected = notes.select { |n| n > 64 }
# combined = notes.with(durations) { |n, d| {pitch: n, dur: d} }
# ```
#
# ### Complex Pipelines
#
# ```ruby
# result = S(1, 2, 3, 4, 5)
#   .select { |n| n.even? }
#   .map { |n| n * 10 }
#   .repeat(2)
#   .i.to_a  # => [20, 40, 20, 40]
# ```
#
# ### Multi-Voice
#
# ```ruby
# melody = S(60, 64, 67).buffered
# voice1 = melody.buffer.i
# voice2 = melody.buffer.i  # Independent
# ```
#
# ## Musical Applications
#
# - **Melodic sequences**: Pitch series with transformations
# - **Rhythmic patterns**: Duration and timing sequences
# - **Harmonic progressions**: Chord sequences and voicings
# - **Parameter automation**: Dynamic control values
# - **Algorithmic composition**: Generative systems
# - **Multi-voice polyphony**: Independent voice playback
# - **Pattern sequencing**: Loop and variation structures
# - **Live coding**: Interactive sequence manipulation
#
# ## Integration
#
# Series integrate with:
# - **Sequencer**: Play series over time via play() method
# - **Generative**: Use with generative grammars
# - **MIDI**: Generate MIDI events from series
# - **Datasets**: Use AbsTimed, AbsD for timing
#
# ## File Load Order
#
# Files loaded in dependency order:
# 1. base-series (core infrastructure)
# 2. main-serie-constructors (factory methods)
# 3. main-serie-operations (transformations)
# 4. array-to-serie (Array extension)
# 5. Utilities (proxy, queue, buffer, etc.)
# 6. Advanced (quantizer, timed, composer, splitter)
#
# @see Musa::Series::Constructors Serie factory methods
# @see Musa::Series::Operations Serie transformation operations
# @see Musa::Series::Serie::Prototyping Prototype/instance pattern
# @see Musa::Sequencer For playing series over time
#
require_relative 'base-series'

require_relative 'main-serie-constructors'
require_relative 'main-serie-operations'

require_relative 'array-to-serie'

require_relative 'proxy-serie'
require_relative 'queue-serie'

require_relative 'buffer-serie'

require_relative 'series-composer'

require_relative 'hash-or-array-serie-splitter'

require_relative 'quantizer-serie'
require_relative 'timed-serie'

