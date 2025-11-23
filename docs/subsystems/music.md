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
- `:major` - Major scale (Ionian mode)
- `:minor` - Natural minor scale (Aeolian mode)
- `:minor_harmonic` - Harmonic minor scale (raised 7th degree)
- `:chromatic` - Chromatic scale (all 12 semitones)

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

# Example 1: Define a custom pentatonic scale kind for the 12-tone system
class PentatonicMajorScaleKind < ScaleKind
  class << self
    def id
      :pentatonic_major
    end

    def pitches
      [{ functions: [:I, :_1, :tonic], pitch: 0 },
       { functions: [:II, :_2], pitch: 2 },
       { functions: [:III, :_3], pitch: 4 },
       { functions: [:V, :_5], pitch: 7 },
       { functions: [:VI, :_6], pitch: 9 }]
    end

    def grades
      5  # 5 notes per octave
    end
  end
end

# Register the new scale kind with the 12-tone system
Scales.et12.register(PentatonicMajorScaleKind)

# Use the new scale kind
tuning = Scales.default_system.default_tuning
c_pentatonic = tuning[:pentatonic_major][60]  # C pentatonic major
puts c_pentatonic[0].pitch  # => 60 (C)
puts c_pentatonic[1].pitch  # => 62 (D)
puts c_pentatonic[2].pitch  # => 64 (E)

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


