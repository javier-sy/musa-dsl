# Generative - Algorithmic Composition

Tools for generative and algorithmic music composition.

## Markov Chains

Probabilistic sequence generation using transition matrices. Markov chains generate sequences where each value depends only on the current state and transition probabilities.

Parameters:
- `start:` - Initial state value
- `finish:` - End state symbol (transitions to this value terminate the sequence)
- `transitions:` - Hash mapping each state to possible next states with probabilities
  - Format: `state => { next_state => probability, ... }`
  - Probabilities for each state should sum to 1.0

```ruby
require 'musa-dsl'

markov = Musa::Markov::Markov.new(
  start: 0,
  finish: :end,
  transitions: {
    0 => { 2 => 0.5, 4 => 0.3, 7 => 0.2 },
    2 => { 0 => 0.3, 4 => 0.5, 5 => 0.2 },
    4 => { 2 => 0.4, 5 => 0.4, 7 => 0.2 },
    5 => { 0 => 0.5, :end => 0.5 },
    7 => { 0 => 0.6, :end => 0.4 }
  }
).i

# Generate melody pitches (Markov is a Serie, so we can use .to_a)
melody_pitches = markov.to_a
```

## Variatio

Generates all combinations of parameter variations using Cartesian product. Useful for creating comprehensive parameter sweeps, exploring all possibilities of a musical motif, or generating exhaustive harmonic permutations.

**Constructor parameters:**
- `instance_name` (Symbol) - Name for the object parameter in blocks (e.g., `:chord`, `:note`, `:synth`)
- `&block` - DSL block defining fields, constructor, and optional attributes/finalize

**DSL methods:**
- `field(name, options)` - Define a parameter field with possible values (Array or Range)
- `fieldset(name, options, &block)` - Define nested field group with its own fields
- `constructor(&block)` - Define how to construct each variation object (required)
- `with_attributes(&block)` - Modify objects with field/fieldset values (optional)
- `finalize(&block)` - Post-process completed objects (optional)

**Execution methods:**
- `run` - Generate all variations with default field values
- `on(**values)` - Generate variations with runtime field value overrides

```ruby
require 'musa-dsl'

variatio = Musa::Variatio::Variatio.new :chord do
  field :root, [60, 64, 67]     # C, E, G
  field :type, [:major, :minor]

  constructor do |root:, type:|
    { root: root, type: type }
  end
end

all_chords = variatio.run
# => [
#   { root: 60, type: :major }, { root: 60, type: :minor },
#   { root: 64, type: :major }, { root: 64, type: :minor },
#   { root: 67, type: :major }, { root: 67, type: :minor }
# ]
# 3 roots × 2 types = 6 variations

# Override field values at runtime
limited_chords = variatio.on(root: [60, 64])
# => 2 roots × 2 types = 4 variations
```

## Rules

Production system with growth and pruning rules (similar to L-systems). Generates tree structures by applying sequential growth rules to create branches and validation rules to prune invalid paths. Useful for harmonic progressions with voice leading rules, melodic variations with contour constraints, or rhythmic patterns following metric rules.

**Constructor parameters:**
- `&block` - DSL block defining grow rules, cut rules, and end condition

**DSL methods:**
- `grow(name, &block)` - Define growth rule that generates new branches
  - Block receives: `|object, history, **params|`
  - Use `branch(new_object)` to create new possibilities
- `cut(reason, &block)` - Define pruning rule to eliminate invalid paths
  - Block receives: `|object, history, **params|`
  - Use `prune` to reject current branch
- `ended_when(&block)` - Define end condition to mark complete branches
  - Block receives: `|object, history, **params|`
  - Return `true` to mark branch as complete

**Execution methods:**
- `apply(seed_or_seeds, **params)` - Apply rules to initial object(s), returns tree Node
  - Accepts single object or array of objects
  - Optional parameters passed to all rule blocks

**Tree Node methods:**
- `combinations` - Returns array of all valid complete paths through tree
- `fish` - Returns array of all valid endpoint objects

```ruby
require 'musa-dsl'

# Build chord voicings by adding notes sequentially
rules = Musa::Rules::Rules.new do
  # Step 1: Choose root note
  grow 'add root' do |seed|
    [60, 64, 67].each { |root| branch [root] }  # C, E, G
  end

  # Step 2: Add third (major or minor)
  grow 'add third' do |chord|
    branch chord + [chord[0] + 4]  # Major third
    branch chord + [chord[0] + 3]  # Minor third
  end

  # Step 3: Add fifth
  grow 'add fifth' do |chord|
    branch chord + [chord[0] + 7]
  end

  # Pruning rule: avoid wide intervals
  cut 'no wide spacing' do |chord|
    if chord.size >= 2
      prune if (chord[-1] - chord[-2]) > 12  # Max octave between adjacent notes
    end
  end

  # End after three notes
  ended_when do |chord|
    chord.size == 3
  end
end

tree = rules.apply(0)  # seed value (triggers generation)
combinations = tree.combinations

# Extract final voicings from each path
voicings = combinations.map { |path| path.last }
# => [[60, 64, 67], [60, 63, 67], [64, 68, 71], [64, 67, 71], [67, 71, 74], [67, 70, 74]]
# 3 roots × 2 thirds × 1 fifth = 6 voicings

# With parameters
tree_with_params = rules.apply(0, max_interval: 7)
```

## Generative Grammar

Formal grammars with combinatorial generation using operators. Useful for generating melodic patterns with rhythmic constraints, harmonic progressions, or variations of musical motifs.

**Constructors:**
- `N(content, **attributes)` - Create terminal node with fixed content and attributes
- `N(**attributes, &block)` - Create block node with dynamic content generation
- `PN()` - Create proxy node for recursive grammar definitions

**Combination operators:**
- `|` (or) - Alternative/choice between nodes (e.g., `a | b`)
- `+` (next) - Concatenation/sequence of nodes (e.g., `a + b`)
- `repeat(exactly:)` or `repeat(min:, max:)` - Repeat node multiple times
- `limit(&block)` - Filter options by condition

**Result methods:**
- `options(content: :join)` - Generate all combinations as joined strings
- `options(content: :itself)` - Generate all combinations as arrays (default)
- `options(raw: true)` - Generate raw OptionElement objects with attributes
- `options(&condition)` - Generate filtered combinations

```ruby
require 'musa-dsl'

include Musa::GenerativeGrammar

a = N('a', size: 1)
b = N('b', size: 1)
c = N('c', size: 1)
d = b | c  # d can be either b or c

# Grammar: (a or d) repeated 3 times, then c
grammar = (a | d).repeat(3) + c

# Generate all possibilities
grammar.options(content: :join)
# => ["aaac", "aabc", "aacc", "abac", "abbc", "abcc", "acac", "acbc", "accc",
#     "baac", "babc", "bacc", "bbac", "bbbc", "bbcc", "bcac", "bcbc", "bccc",
#     "caac", "cabc", "cacc", "cbac", "cbbc", "cbcc", "ccac", "ccbc", "cccc"]
# 3^3 × 1 = 27 combinations

# With constraints - filter by attribute
grammar_with_limit = (a | d).repeat(min: 1, max: 4).limit { |o|
  o.collect { |e| e.attributes[:size] }.sum <= 3
}

result_limited = grammar_with_limit.options(content: :join)
# Includes: ["a", "b", "c", "aa", "ab", "ac", "ba", "bb", "bc", "ca", "cb", "cc", "aaa", "aab", "aac", ...]
# Only combinations where total size <= 3
```

## Darwin

Evolutionary selection algorithm based on fitness evaluation. Darwin doesn't generate populations - it selects and ranks existing candidates using user-defined measures (features and dimensions) and weights. Each object is evaluated, normalized across the population, scored, and sorted by fitness.

**How it works:**
1. Define measures (features & dimensions) to evaluate each candidate
2. Define weights for each measure
3. Darwin evaluates all candidates, normalizes dimensions, applies weights
4. Returns population sorted by fitness (best first)

**Constructor:**
- `&block` - DSL block defining measures and weights

**DSL methods:**
- `measures(&block)` - Define evaluation block for each object
  - Block receives each object to evaluate
  - Inside block use: `feature(name)`, `dimension(name, value)`, `die`
- `weight(**weights)` - Assign weights to features/dimensions
  - Positive weights favor the measure
  - Negative weights penalize the measure

**Measures methods (inside measures block):**
- `feature(name)` - Mark object as having a boolean feature
- `dimension(name, value)` - Record numeric measurement (will be normalized 0-1)
- `die` - Mark object as non-viable (will be excluded from results)

**Execution methods:**
- `select(population)` - Evaluate and rank population, returns sorted array (best first)

```ruby
require 'musa-dsl'

# Generate candidate melodies using Variatio
variatio = Musa::Variatio::Variatio.new :melody do
  field :interval, 1..7        # Intervals in semitones
  field :contour, [:up, :down, :repeat]
  field :duration, [1/4r, 1/2r, 1r]

  constructor do |interval:, contour:, duration:|
    { interval: interval, contour: contour, duration: duration }
  end
end

candidates = variatio.run  # Generate all combinations

# Create Darwin selector with musical criteria
darwin = Musa::Darwin::Darwin.new do
  measures do |melody|
    # Eliminate melodies with unwanted characteristics
    die if melody[:interval] > 5  # No large leaps

    # Binary features (present/absent)
    feature :stepwise if melody[:interval] <= 2        # Stepwise motion
    feature :has_quarter_notes if melody[:duration] == 1/4r

    # Numeric dimensions (will be normalized across population)
    # Use negative values to prefer lower numbers
    dimension :interval_size, -melody[:interval].to_f
    dimension :duration_value, melody[:duration].to_f
  end

  # Weight each measure's contribution to fitness
  weight interval_size: 2.0,      # Strongly prefer smaller intervals
         stepwise: 1.5,            # Prefer stepwise motion
         has_quarter_notes: 1.0,   # Slightly prefer quarter notes
         duration_value: -0.5      # Slightly penalize longer durations
end

# Select and rank melodies by fitness
ranked = darwin.select(candidates)

best_melody = ranked.first       # Highest fitness
top_10 = ranked.first(10)        # Top 10 melodies
worst = ranked.last              # Lowest fitness (but still viable)
```


