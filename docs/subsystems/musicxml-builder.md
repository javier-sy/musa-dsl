# MusicXML Builder - Music Notation Export

Comprehensive builder for generating MusicXML 3.0 files compatible with music notation software (Finale, Sibelius, MuseScore, Dorico, etc.). MusicXML is the standard open format for exchanging digital sheet music between applications.

## When is this the answer

You want a **score somebody can read** -- opened in Finale, Sibelius, MuseScore
or Dorico. That is the whole of it, and it is a different goal from sounding:
notation has to say what a performer needs, which is not what a synthesiser
needs.

| You have | You want | This |
|---|---|---|
| a piece already written as datasets | a score, without rebuilding it | `Score#to_mxml` |
| notation to construct directly | full control of the elements | the builder DSL |
| ornaments | them kept as symbols, not expanded into notes | a MusicXML transcriptor |

**Notation is a rendering, not the music.** The same GDV goes to MIDI with its
ornaments expanded and to MusicXML with them preserved; see
[transcription](transcription.md). If you find yourself writing the same phrase
twice, once to sound and once to print, something has been decided at the wrong
layer.

**And the unit trap.** MusicXML counts durations in divisions **per quarter
note**, while a duration in this framework is a fraction of a **bar**. In 4/4
the two agree; in 3/4 they do not, and a quarter note is `1/3r` of a bar. The
generator takes `beats_per_bar` and `beat_type` for exactly this reason.

## Root Class: ScorePartwise

The entry point for creating MusicXML documents is `Musa::MusicXML::Builder::ScorePartwise`, which represents the `<score-partwise>` root element. It organizes music by parts (instruments/voices) and measures.

**Structure:**
- **Metadata**: work info, movement info, creators, rights, encoding date
- **Part List**: part definitions with names and abbreviations
- **Parts**: musical content organized by measures

## Key Features

The fragments below are written against a measure built like this, so that each
one can be read -- and run -- on its own:

```ruby
require 'musa-dsl'

Measure = Musa::MusicXML::Builder::Internal::Measure
measure = Measure.new(1, divisions: 4)
```

**Multiple staves:**
Use `staff:` parameter to specify which staff (1, 2, etc.) for grand staff notation (piano, harp, organ, etc.).
```ruby
measure.pitch 'C', octave: 3, staff: 2  # Note in staff 2 (bass clef)
```

**Multiple voices:**
Use `voice:` parameter for polyphonic notation within a single staff (independent melodic lines).
```ruby
measure.pitch 'C', octave: 4, voice: 1  # Voice 1
measure.pitch 'E', octave: 3, voice: 2  # Voice 2 (simultaneous)
```

**Backup/Forward:**
Navigate timeline within measures to layer voices. `backup(duration)` returns to an earlier point, `forward(duration)` skips ahead.
```ruby
measure.pitch 'C', octave: 4, duration: 4
measure.backup 4  # Return to beginning
measure.pitch 'E', octave: 3, duration: 4  # Play simultaneously
```

**Divisions:**
Set rhythmic precision as divisions per quarter note in measure attributes. Higher values allow smaller note values.
```ruby
measure.attributes do
  divisions 4  # 4 divisions per quarter (allows 16th notes)
end
```

**Alterations:**
Use `alter:` parameter for accidentals: `-1` for flat, `1` for sharp, `2` for double sharp, etc.
```ruby
measure.pitch 'F', octave: 4, alter: 1  # F# (sharp)
measure.pitch 'B', octave: 4, alter: -1  # Bb (flat)
```

**Articulations:**
Add slurs, dots, and other articulations via parameters.
```ruby
measure.pitch 'C', octave: 4, slur: 'start'  # Begin slur
measure.pitch 'D', octave: 4, slur: 'stop'   # End slur
measure.pitch 'E', octave: 4, dots: 1        # Dotted note
```

**Dynamics:**
Add dynamic markings using `direction` blocks with `dynamics` method. Supported: `pp`, `p`, `mp`, `mf`, `f`, `ff`, `fff`, etc.
```ruby
measure.direction do
  dynamics 'f'  # Forte
end
```

**Wedges:**
Add crescendo/diminuendo markings with `wedge` in direction blocks.
```ruby
measure.direction do
  wedge 'crescendo'  # Start crescendo
end
# ... notes ...
measure.direction { wedge 'stop' }  # End crescendo
```

**Metronome:**
Add tempo markings with `metronome` in measures.
```ruby
measure.metronome beat_unit: 'quarter', per_minute: 120
```

**Rests:**
Use `rest` method instead of `pitch` for rest notation.
```ruby
measure.rest duration: 2, type: 'quarter'
```

Every fragment above was added to the same `measure`, so this is the markup they
produced between them:

```ruby
measure.to_xml.string.lines.map(&:strip)
       .grep(/staff|<voice>|alter|dot |slur|<f \/>|wedge|per-minute|<rest/).uniq
# => ["<staff>2</staff>", "<voice>1</voice>", "<voice>2</voice>",
#     "<alter>1</alter>", "<alter>-1</alter>",
#     "<slur type=\"start\"/>", "<slur type=\"stop\"/>", "<dot />",
#     "<f />", "<wedge type=\"crescendo\"/>", "<wedge type=\"stop\"/>",
#     "<per-minute>120</per-minute>", "<rest />"]
```

Note what `direction` does with what it is given: each mark becomes its own
`<direction>` element rather than several inside one, which is why a crescendo
and its stop are two directions and not a range.

```ruby
measure.to_xml.string.scan(/<(note|backup|direction)[ >]/).flatten
# => ["note", "note", "note", "note", "backup", "note", "note", "note", "note",
#     "note", "note", "direction", "direction", "direction", "direction", "note"]
```

## Two Usage Modes

**Constructor Style (Method Calls):**

Use constructor parameters and `add_*` methods for programmatic building:

```ruby
require 'musa-dsl'

# Create score with metadata
score = Musa::MusicXML::Builder::ScorePartwise.new(
  work_title: "Piano Piece",
  creators: { composer: "Your Name" },
  encoding_date: DateTime.new(2024, 1, 1)
)

# Add parts using add_* methods. Note the variable names: `part` and `measure`
# are also DSL verbs, and in Ruby a local variable shadows a method of the same
# name -- bind them here and the block form further down stops parsing.
piano = score.add_part(:p1, name: "Piano", abbreviation: "Pno.")

# Add measures and attributes
bar1 = piano.add_measure(divisions: 4)

# Add attributes (key, time, clef, etc.)
bar1.attributes.last.add_key(1, fifths: 0)        # C major
bar1.attributes.last.add_time(1, beats: 4, beat_type: 4)
bar1.attributes.last.add_clef(1, sign: 'G', line: 2)

# Add notes
bar1.add_pitch(step: 'C', octave: 4, duration: 4, type: 'quarter')
bar1.add_pitch(step: 'E', octave: 4, duration: 4, type: 'quarter')
bar1.add_pitch(step: 'G', octave: 4, duration: 4, type: 'quarter')
bar1.add_pitch(step: 'C', octave: 5, duration: 4, type: 'quarter')

score.to_xml.string.scan(/<step>(\w)<\/step>/).flatten  # => ["C", "E", "G", "C"]

# Export to file
File.write("score.musicxml", score.to_xml.string)
```

**DSL Style (Blocks):**

Use blocks with method names as setters/builders for more readable, declarative code:

```ruby
require 'musa-dsl'

score = Musa::MusicXML::Builder::ScorePartwise.new do
  work_title "Piano Piece"
  creators composer: "Your Name"
  encoding_date DateTime.new(2024, 1, 1)

  part :p1, name: "Piano", abbreviation: "Pno." do
    measure do
      attributes do
        divisions 4
        key 1, fifths: 0        # C major
        time 1, beats: 4, beat_type: 4
        clef 1, sign: 'G', line: 2
      end

      pitch 'C', octave: 4, duration: 4, type: 'quarter'
      pitch 'E', octave: 4, duration: 4, type: 'quarter'
      pitch 'G', octave: 4, duration: 4, type: 'quarter'
      pitch 'C', octave: 5, duration: 4, type: 'quarter'
    end
  end
end

File.write("score.musicxml", score.to_xml.string)
```

**Sophisticated Example - Piano Score with Multiple Features:**

```ruby
require 'musa-dsl'

score = Musa::MusicXML::Builder::ScorePartwise.new do
  work_title "Étude in D Major"
  work_number 1
  creators composer: "Example Composer"
  encoding_date DateTime.now

  part :p1, name: "Piano" do
    # Measure 1 - Setup and opening with two staves
    measure do
      attributes do
        divisions 2  # 2 divisions per quarter note

        # Treble clef (staff 1)
        key 1, fifths: 2        # D major (2 sharps)
        clef 1, sign: 'G', line: 2
        time 1, beats: 4, beat_type: 4

        # Bass clef (staff 2)
        key 2, fifths: 2
        clef 2, sign: 'F', line: 4
        time 2, beats: 4, beat_type: 4
      end

      # Tempo marking
      metronome beat_unit: 'quarter', per_minute: 120

      # Right hand melody (staff 1)
      pitch 'D', octave: 4, duration: 4, type: 'half', slur: 'start'
      pitch 'E', octave: 4, duration: 4, type: 'half', slur: 'stop'

      # Return to beginning for left hand (staff 2)
      backup 8

      # Left hand accompaniment (staff 2)
      pitch 'D', octave: 3, duration: 8, type: 'whole', staff: 2
    end

    # Measure 2 - Two voices in treble clef
    measure do
      # Voice 1
      pitch 'F#', octave: 4, duration: 2, type: 'quarter', alter: 1, voice: 1
      pitch 'G', octave: 4, duration: 2, type: 'quarter', voice: 1
      pitch 'A', octave: 4, duration: 2, type: 'quarter', voice: 1
      pitch 'B', octave: 4, duration: 2, type: 'quarter', voice: 1

      # Return to beginning for voice 2
      backup 8

      # Voice 2 (inner voice)
      pitch 'A', octave: 3, duration: 3, type: 'quarter', dots: 1, voice: 2
      pitch 'B', octave: 3, duration: 1, type: 'eighth', voice: 2
      pitch 'C#', octave: 4, duration: 3, type: 'quarter', dots: 1, alter: 1, voice: 2
      pitch 'D', octave: 4, duration: 1, type: 'eighth', voice: 2

      # Return for left hand
      backup 8

      # Left hand (staff 2)
      pitch 'A', octave: 2, duration: 8, type: 'whole', staff: 2
    end

    # Measure 3 - Dynamics and articulations
    measure do
      # Dynamic marking
      direction do
        dynamics 'pp'
        wedge 'crescendo'
      end

      # Notes with crescendo
      pitch 'C#', octave: 5, duration: 1, type: 'eighth', alter: 1
      pitch 'D', octave: 5, duration: 1, type: 'eighth'
      pitch 'E', octave: 5, duration: 1, type: 'eighth'
      pitch 'F#', octave: 5, duration: 1, type: 'eighth', alter: 1

      pitch 'G', octave: 5, duration: 1, type: 'eighth'
      pitch 'A', octave: 5, duration: 1, type: 'eighth'
      pitch 'B', octave: 5, duration: 1, type: 'eighth'
      pitch 'C#', octave: 6, duration: 1, type: 'eighth', alter: 1

      # End of crescendo, forte
      direction wedge: 'stop', dynamics: 'f'
    end
  end
end

# Export to file
File.write("etude.musicxml", score.to_xml.string)

# Or write directly to IO
File.open("etude.musicxml", 'w') { |f| score.to_xml(f) }
```

## API Reference

**Complete API documentation:**
- [Musa::MusicXML::Builder](https://rubydoc.info/gems/musa-dsl/Musa/MusicXML/Builder) - MusicXML score generation

**Source code:** `lib/musicxml/builder/`


