# Music - Scales & Chords

Comprehensive framework for working with musical scales, tuning systems, and chord structures. The system resolves two main domains:

## Scales System

The **Scales** module provides hierarchical access to musical scales with multiple tuning systems and scale types:

**Architecture:**
- **ScaleSystem** (`Musa::Scales::ScaleSystem`): Defines tuning systems (e.g., 12-tone equal temperament)
- **ScaleSystemTuning** (`Musa::Scales::ScaleSystemTuning`): A scale system with specific reference frequency (e.g., A=440Hz)
- **ScaleKind** (`Musa::Scales::ScaleKind`): Scale types (major, minor, chromatic, etc.)
- **Scale** (`Musa::Scales::Scale`): A scale kind rooted on a specific pitch (e.g., C major)
- **NoteInScale** (`Musa::Scales::NoteInScale`): A specific note within a scale

**Registry:**
- **Scales::Scales** (`Musa::Scales::Scales`): Central registry for accessing scale systems by ID or method name

**Available scale systems:**
- `:et12` (EquallyTempered12ToneScaleSystem): 12-tone equal temperament (default)

**Available scale kinds in et12:**

*Core scales:*
- `:major` - Major scale (Ionian mode) - 7 notes
- `:minor` - Natural minor scale (Aeolian mode) - 7 notes
- `:minor_harmonic` - Harmonic minor scale (raised 7th) - 7 notes
- `:major_harmonic` - Harmonic major scale (lowered 6th) - 7 notes
- `:chromatic` - Chromatic scale (all 12 semitones) - 12 notes

*Greek/church modes:*
- `:dorian` - Dorian mode (minor with major 6th) - 7 notes
- `:phrygian` - Phrygian mode (minor with minor 2nd) - 7 notes
- `:lydian` - Lydian mode (major with augmented 4th) - 7 notes
- `:mixolydian` - Mixolydian mode (major with minor 7th) - 7 notes
- `:locrian` - Locrian mode (diminished 5th and minor 2nd) - 7 notes

*Pentatonic scales:*
- `:pentatonic_major` - Major pentatonic (no 4th or 7th) - 5 notes
- `:pentatonic_minor` - Minor pentatonic (no 2nd or 6th) - 5 notes

*Blues scales:*
- `:blues` - Blues scale (minor pentatonic + b5 blue note) - 6 notes
- `:blues_major` - Major blues scale (major pentatonic + b3 blue note) - 6 notes

*Symmetric scales:*
- `:whole_tone` - Whole tone scale (all whole steps) - 6 notes
- `:diminished_hw` - Diminished half-whole (octatonic) - 8 notes
- `:diminished_wh` - Diminished whole-half (dominant diminished) - 8 notes

*Melodic minor modes:*
- `:minor_melodic` - Melodic minor (jazz minor) - 7 notes
- `:dorian_b2` - Dorian b2 / Phrygian #6 - 7 notes
- `:lydian_augmented` - Lydian augmented (#4, #5) - 7 notes
- `:lydian_dominant` - Lydian dominant / Bartók scale (#4, b7) - 7 notes
- `:mixolydian_b6` - Mixolydian b6 / Hindu scale - 7 notes
- `:locrian_sharp2` - Locrian #2 / Half-diminished scale - 7 notes
- `:altered` - Altered / Super Locrian (all tensions altered) - 7 notes

*Ethnic/exotic scales:*
- `:double_harmonic` - Double harmonic / Byzantine (two augmented 2nds) - 7 notes
- `:hungarian_minor` - Hungarian minor / Gypsy minor (#4, raised 7th) - 7 notes
- `:phrygian_dominant` - Phrygian dominant / Spanish Phrygian (b2, major 3rd) - 7 notes
- `:neapolitan_minor` - Neapolitan minor (harmonic minor with b2) - 7 notes
- `:neapolitan_major` - Neapolitan major (melodic minor with b2) - 7 notes

*Bebop scales:*
- `:bebop_dominant` - Bebop dominant (Mixolydian + major 7th passing) - 8 notes
- `:bebop_major` - Bebop major (major + #5 passing) - 8 notes
- `:bebop_minor` - Bebop minor (Dorian + major 7th passing) - 8 notes

## Chords System

The **Chords** module provides chord structures with scale context:

**Architecture:**
- **Chord** (`Musa::Chords::Chord`): Instantiated chord with root note and scale context
- **ChordDefinition** (`Musa::Chords::ChordDefinition`): Abstract chord structure definition (quality, size, intervals)

**Features:**
- Access chord tones by name (root, third, fifth, seventh, etc.)
- Voicing modifications (move, duplicate, octave)
- Navigate between related chords (change quality, add extensions)
- Extract pitches and notes

**Usage examples:**

```ruby
require 'musa-dsl'

include Musa::Scales
include Musa::Chords

# Access default system and tuning
tuning = Scales.default_system.default_tuning  # A=440Hz

# Create scales using available scale kinds
c_major = tuning.major[60]           # C major (tonic pitch 60)
d_minor = tuning.minor[62]           # D minor (natural)
e_harmonic = tuning.minor_harmonic[64]  # E harmonic minor
chromatic = tuning.chromatic[60]     # C chromatic

# Alternative access methods
c_major = Scales.et12[440.0].major[60]  # Explicit system and frequency

# Access notes by grade (0-based) or function
tonic = c_major[0]      # => C (grade 0)
mediant = c_major[2]    # => E (grade 2)
dominant = c_major[4]   # => G (grade 4)

# Access by function name
tonic = c_major.tonic         # => C
supertonic = c_major.supertonic  # => D
mediant = c_major.mediant     # => E
subdominant = c_major.subdominant  # => F
dominant = c_major.dominant   # => G

# Access by Roman numeral or symbol
c_major[:I]    # => Tonic (C)
c_major[:V]    # => Dominant (G)

# Get pitch values from notes
pitch = c_major.tonic.pitch   # => 60

# Navigate with octaves
note = c_major[2].octave(1)  # E in octave 1
pitch_with_octave = note.pitch     # => 76

# Chromatic operations - sharp and flat
c_sharp = c_major.tonic.sharp   # => C# (chromatic, +1 semitone)
c_flat = c_major.tonic.flat     # => Cb (chromatic, -1 semitone)

# Navigate by semitones
fifth_up = c_major.tonic.sharp(7)  # => G (+7 semitones = perfect fifth)
third_up = c_major.tonic.sharp(4)  # => E (+4 semitones = major third)

# Frequency calculation
frequency = c_major.tonic.frequency  # => 261.63 Hz (middle C at A=440)

# Greek modes (church modes)
d_dorian = tuning.dorian[62]         # D Dorian (minor with major 6th)
e_phrygian = tuning.phrygian[64]     # E Phrygian (minor with minor 2nd)
f_lydian = tuning.lydian[65]         # F Lydian (major with augmented 4th)
g_mixolydian = tuning.mixolydian[67] # G Mixolydian (major with minor 7th)
b_locrian = tuning.locrian[71]       # B Locrian (diminished 5th)

# Access notes in Greek modes by function
d_dorian.tonic.pitch      # => 62 (D)
d_dorian[:vi].pitch       # => 71 (B - the major 6th characteristic of Dorian)

e_phrygian[:ii].pitch     # => 65 (F - the minor 2nd characteristic of Phrygian)

f_lydian[:IV].pitch       # => 71 (B - the augmented 4th characteristic of Lydian)

g_mixolydian[:VII].pitch  # => 77 (F - the minor 7th characteristic of Mixolydian)

b_locrian[:v].pitch       # => 77 (F - the diminished 5th characteristic of Locrian)

# Pentatonic and blues scales
c_pent_maj = tuning.pentatonic_major[60]  # C major pentatonic
a_pent_min = tuning.pentatonic_minor[69]  # A minor pentatonic
a_blues = tuning.blues[69]                 # A blues scale
a_blues[:blue].pitch  # => 75 (Eb - the blue note)

# Symmetric scales
c_whole = tuning.whole_tone[60]      # C whole tone
c_dim_hw = tuning.diminished_hw[60]  # C diminished (half-whole)
c_dim_wh = tuning.diminished_wh[60]  # C diminished (whole-half)

# Melodic minor modes
c_mel_min = tuning.minor_melodic[60]     # C melodic minor
g_altered = tuning.altered[67]            # G altered (for G7alt chords)
f_lyd_dom = tuning.lydian_dominant[65]   # F lydian dominant (F7#11)

# Ethnic scales
e_phry_dom = tuning.phrygian_dominant[64]  # E Phrygian dominant (flamenco)
a_hung_min = tuning.hungarian_minor[69]    # A Hungarian minor

# Bebop scales (8 notes for smooth eighth-note lines)
g_bebop = tuning.bebop_dominant[67]  # G bebop dominant
g_bebop[7].pitch  # => 78 (F# - the chromatic passing tone)

# Create chords from scale degrees
i_chord = c_major.tonic.chord        # C major triad [C, E, G]
ii_chord = c_major.supertonic.chord  # D minor triad [D, F, A]
v_chord = c_major.dominant.chord     # G major triad [G, B, D]

# Create extended chords
i_seventh = c_major.tonic.chord :seventh  # C major 7th [C, E, G, B]
v_ninth = c_major.dominant.chord :ninth   # G 9th chord

# Access chord tones by name
root = i_chord.root      # => C (NoteInScale)
third = i_chord.third    # => E (NoteInScale)
fifth = i_chord.fifth    # => G (NoteInScale)

# Get chord pitches
pitches = i_chord.pitches  # => [60, 64, 67] (C, E, G)
notes = i_chord.notes      # Array of ChordGradeNote structs

# Chord features
i_chord.quality  # => :major
i_chord.size     # => :triad

# Navigate between chord qualities
minor_chord = i_chord.with_quality(:minor)      # C minor [C, Eb, G]
diminished = i_chord.with_quality(:diminished)  # C diminished [C, Eb, Gb]

# Change chord extensions
seventh_chord = i_chord.with_size(:seventh)  # C major 7th
ninth_chord = i_chord.with_size(:ninth)      # C major 9th

# Voicing modifications - move specific tones to different octaves
voiced = i_chord.move(root: -1, fifth: 1)  # Root down, fifth up

# Duplicate tones in other octaves
doubled = i_chord.duplicate(root: -2, third: [-1, 1])  # Root 2 down, third 1 down and 1 up

# Transpose entire chord
lower = i_chord.octave(-1)  # Move chord down one octave
```

### Chord-Scale Navigation

MusaDSL provides methods to explore the relationship between chords and scales,
enabling harmonic analysis and discovery of functional contexts.

#### Checking if a Scale Contains a Chord

```ruby
c_major = Scales.et12[440.0].major[60]
g7 = c_major.dominant.chord :seventh

c_major.contains_chord?(g7)     # => true
c_major.degree_of_chord(g7)     # => 4 (V degree, 0-based)

# Non-diatonic chords return false/nil
cm = c_major.tonic.chord.with_quality(:minor)  # C minor (Eb not in C major)
c_major.contains_chord?(cm)     # => false
c_major.degree_of_chord(cm)     # => nil
```

#### Creating a Chord in a Different Scale Context

```ruby
# Get the same chord but with a different scale as context
g_mixolydian = Scales.et12[440.0].mixolydian[67]
g7_in_mixolydian = g_mixolydian.chord_on(g7)
g7_in_mixolydian.scale                        # => G Mixolydian scale
g_mixolydian.degree_of_chord(g7_in_mixolydian)  # => 0 (I degree)
```

#### Finding Scales That Contain a Chord

```ruby
g_triad = c_major.dominant.chord  # G-B-D

# Search in diatonic scales
g_triad.in_scales(family: :diatonic)
# => [Chord in C major (V), Chord in G major (I), Chord in D major (IV), ...]

# Search using metadata filters
g_triad.in_scales(family: :greek_modes, brightness: -1..1)

# Search in all scale types
g_triad.in_scales

# Each result has its scale context
g_triad.in_scales(family: :diatonic).each do |chord|
  scale = chord.scale
  degree = scale.degree_of_chord(chord)
  puts "#{scale.kind.class.id} rooted on #{scale.root_pitch}: degree #{degree}"
end
# Output:
# major rooted on 60: degree 4
# major rooted on 67: degree 0
# major rooted on 62: degree 3
```

#### Low-Level Navigation Methods

```ruby
tuning = Scales.et12[440.0]

# Search at ScaleKind level
tuning.major.scales_containing(g_triad)

# Search at ScaleSystemTuning level with metadata filters
tuning.chords_of(g7, family: :diatonic, roots: 60..71)
```

### Scale Kind Metadata

Scale kinds in MusaDSL have a three-layer metadata system that provides
both automatic structural information and extensible custom properties.

#### Metadata Layers

1. **Intrinsic metadata**: Automatically derived from scale structure
   - `id`: Scale kind identifier
   - `grades`: Number of scale degrees
   - `pitches`: Array of pitch offsets from root
   - `intervals`: Intervals between consecutive degrees
   - `has_leading_tone`: Whether scale has pitch 11 (semitone below octave)
   - `has_tritone`: Whether scale contains tritone interval (pitch 6)
   - `symmetric`: Type of symmetry if any (`:equal`, `:palindrome`, `:repeating`)

2. **Base metadata**: Defined by musa-dsl library
   - `family`: Scale family (`:diatonic`, `:greek_modes`, `:pentatonic`, etc.)
   - `brightness`: Relative brightness (-3 to +3, major = 0)
   - `character`: Array of descriptive tags
   - `parent`: Parent scale and degree for modes (e.g., `{ scale: :major, degree: 2 }`)

3. **Custom metadata**: Added by users at runtime

#### Accessing Metadata

```ruby
tuning = Scales.et12[440.0]
major_class = tuning.major.class

# Get combined metadata (intrinsic < base < custom)
major_class.metadata
# => { id: :major, grades: 7, pitches: [0,2,4,5,7,9,11], family: :diatonic, ... }

# Get specific layer
major_class.intrinsic_metadata  # Structure-derived only
major_class.base_metadata       # Library-defined only
major_class.custom_metadata     # User-added only

# Query helpers
major_class.has_metadata?(:family)              # => true
major_class.has_metadata?(:family, :diatonic)   # => true
major_class.has_metadata?(:character, :bright)  # => true (array inclusion)
major_class.metadata_value(:brightness)         # => 0
```

#### Extending Metadata

Users can add custom metadata to any scale kind:

```ruby
# Extend a specific scale kind class
tuning.dorian.class.extend_metadata(
  my_mood: :nostalgic,
  suitable_for: [:jazz, :fusion],
  personal_rating: 5
)

# Or use the convenience method with scale ID
Scales.extend_metadata(:dorian, my_mood: :nostalgic)

# Multiple calls merge metadata
Scales.extend_metadata(:phrygian, mood: :dark)
Scales.extend_metadata(:phrygian, origin: :spanish)  # Merges with previous

# Reset custom metadata if needed
tuning.dorian.class.reset_custom_metadata
```

#### Custom Metadata Overrides

Custom metadata takes precedence over base metadata:

```ruby
# Override library-defined family
Scales.extend_metadata(:dorian, family: :my_custom_category)
tuning.dorian.class.metadata[:family]  # => :my_custom_category
```

#### Brightness Scale Reference

| Value | Meaning | Examples |
|-------|---------|----------|
| +3 | Very bright | Lydian augmented |
| +2 | Bright | Lydian |
| +1 | Slightly bright | Mixolydian, Lydian dominant |
| 0 | Neutral (reference) | Major (Ionian) |
| -1 | Slightly dark | Dorian |
| -2 | Dark | Minor harmonic, Phrygian |
| -3 | Very dark | Locrian, Natural minor |

#### Scale Families

- `:diatonic` - Major, minor natural, minor harmonic
- `:greek_modes` - Dorian, Phrygian, Lydian, Mixolydian, Locrian
- `:melodic_minor_modes` - Melodic minor and its modes
- `:pentatonic` - Pentatonic major/minor
- `:blues` - Blues scales
- `:bebop` - Bebop scales
- `:symmetric` - Whole tone, diminished
- `:ethnic` - Hungarian, Spanish, Neapolitan, etc.
- `:chromatic` - Chromatic scale

### Searching Scale Kinds

The `scale_kinds` method on ScaleSystemTuning allows searching and filtering
scale kinds by their metadata properties.

#### Basic Usage

```ruby
tuning = Scales.et12[440.0]

# Get all scale kinds
tuning.scale_kinds
# => [major_kind, minor_kind, dorian_kind, ...]

# Filter by family
tuning.scale_kinds(family: :diatonic)
# => [major_kind, minor_kind, minor_harmonic_kind, harmonic_major_kind]

# Filter by brightness range
tuning.scale_kinds(brightness: -1..1)

# Filter by character
tuning.scale_kinds(character: :jazz)
```

#### Custom Filtering with Blocks

Use a block for complex filtering based on any metadata:

```ruby
# Scales with leading tone
tuning.scale_kinds { |klass| klass.intrinsic_metadata[:has_leading_tone] }

# Combine criteria and block
tuning.scale_kinds(family: :greek_modes) { |klass| klass.metadata[:brightness]&.negative? }
# => [dorian_kind, phrygian_kind, locrian_kind]
```

#### Integration with Chord Search

The `chords_of` method uses the same metadata filtering:

```ruby
g7 = tuning.major[60].dominant.chord(:seventh)

# Find G7 in diatonic scales
tuning.chords_of(g7, family: :diatonic)

# Find G7 in scales with specific brightness
tuning.chords_of(g7, brightness: -1..1)
```

## Defining Custom Scale Systems, Scale Kinds, and Chord Definitions

The framework is extensible, allowing users to define custom tuning systems, scale types, and chord structures:

**Custom Scale Systems:**

Users can create custom tuning systems by subclassing `Musa::Scales::ScaleSystem` and implementing:
- `.id` - Unique symbol identifier
- `.notes_in_octave` - Number of notes per octave
- `.part_of_tone_size` - Size of smallest pitch unit
- `.intervals` - Hash mapping interval names to semitone offsets
- `.frequency_of_pitch(pitch, root_pitch, a_frequency)` - Pitch to frequency conversion

After defining, register with `Musa::Scales::Scales.register(CustomScaleSystem, default: false)`

**Custom Scale Kinds:**

Users can define new scale types by subclassing `Musa::Scales::ScaleKind` and implementing:
- `.id` - Unique symbol identifier (e.g., `:dorian`, `:pentatonic`)
- `.pitches` - Array defining scale structure with functions and pitch offsets
- `.chromatic?` - Whether this is the chromatic scale (optional, default: false)
- `.grades` - Number of grades per octave (optional, default: pitches.length)

After defining, register with `YourScaleSystem.register(CustomScaleKind)`

**Custom Chord Definitions:**

Users can register new chord types using `Musa::Chords::ChordDefinition.register`:
- `name` - Symbol identifier (e.g., `:sus4`, `:add9`)
- `offsets:` - Hash defining semitone intervals from root (e.g., `{ root: 0, fourth: 5, fifth: 7 }`)
- `**features` - Chord characteristics like `quality:` and `size:`

**Examples of custom definitions:**

```ruby
require 'musa-dsl'

include Musa::Scales
include Musa::Chords

# Example 1: Define a custom Hirajoshi scale (Japanese pentatonic)
class HirajoshiScaleKind < ScaleKind
  class << self
    def id
      :hirajoshi
    end

    def pitches
      [{ functions: [:I, :_1, :tonic], pitch: 0 },
       { functions: [:II, :_2], pitch: 2 },
       { functions: [:III, :_3], pitch: 3 },
       { functions: [:V, :_4], pitch: 7 },
       { functions: [:VI, :_5], pitch: 8 }]
    end

    def grades
      5  # 5 notes per octave
    end
  end
end

# Register the new scale kind with the 12-tone system
Scales.et12.register(HirajoshiScaleKind)

# Use the new scale kind
tuning = Scales.default_system.default_tuning
c_hirajoshi = tuning[:hirajoshi][60]  # C Hirajoshi
puts c_hirajoshi[0].pitch  # => 60 (C)
puts c_hirajoshi[1].pitch  # => 62 (D)
puts c_hirajoshi[2].pitch  # => 63 (Eb)

# Example 2: Register a custom chord definition (sus4)
Musa::Chords::ChordDefinition.register :sus4,
  quality: :suspended,
  size: :triad,
  offsets: { root: 0, fourth: 5, fifth: 7 }

# Use the custom chord definition
c_major = tuning.major[60]
# To use custom chords, access via NoteInScale#chord with the definition name
# or create manually using the definition

# Example 3: Register a custom chord definition (add9)
Musa::Chords::ChordDefinition.register :add9,
  quality: :major,
  size: :extended,
  offsets: { root: 0, third: 4, fifth: 7, ninth: 14 }
```

## API Reference

**Complete API documentation:**
- [Musa::Scales](https://rubydoc.info/gems/musa-dsl/Musa/Scales) - Scale systems and tuning
- [Musa::Chords](https://rubydoc.info/gems/musa-dsl/Musa/Chords) - Chord structures and navigation

**Source code:** `lib/music/`


