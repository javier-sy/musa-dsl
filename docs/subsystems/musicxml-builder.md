# MusicXML Builder - Music Notation Export

Comprehensive builder for generating MusicXML 3.0 files compatible with music notation software (Finale, Sibelius, MuseScore, Dorico, etc.). MusicXML is the standard open format for exchanging digital sheet music between applications.

## Root Class: ScorePartwise

The entry point for creating MusicXML documents is `Musa::MusicXML::Builder::ScorePartwise`, which represents the `<score-partwise>` root element. It organizes music by parts (instruments/voices) and measures.

**Structure:**
- **Metadata**: work info, movement info, creators, rights, encoding date
- **Part List**: part definitions with names and abbreviations
- **Parts**: musical content organized by measures

## Key Features

**Multiple staves:**
Use `staff:` parameter to specify which staff (1, 2, etc.) for grand staff notation (piano, harp, organ, etc.).
```ruby
pitch 'C', octave: 3, staff: 2  # Note in staff 2 (bass clef)
```

**Multiple voices:**
Use `voice:` parameter for polyphonic notation within a single staff (independent melodic lines).
```ruby
pitch 'C', octave: 4, voice: 1  # Voice 1
pitch 'E', octave: 3, voice: 2  # Voice 2 (simultaneous)
```

**Backup/Forward:**
Navigate timeline within measures to layer voices. `backup(duration)` returns to an earlier point, `forward(duration)` skips ahead.
```ruby
pitch 'C', octave: 4, duration: 4
backup 4  # Return to beginning
pitch 'E', octave: 3, duration: 4  # Play simultaneously
```

**Divisions:**
Set rhythmic precision as divisions per quarter note in measure attributes. Higher values allow smaller note values.
```ruby
attributes do
  divisions 4  # 4 divisions per quarter (allows 16th notes)
end
```

**Alterations:**
Use `alter:` parameter for accidentals: `-1` for flat, `1` for sharp, `2` for double sharp, etc.
```ruby
pitch 'F', octave: 4, alter: 1  # F# (sharp)
pitch 'B', octave: 4, alter: -1  # Bb (flat)
```

**Articulations:**
Add slurs, dots, and other articulations via parameters.
```ruby
pitch 'C', octave: 4, slur: 'start'  # Begin slur
pitch 'D', octave: 4, slur: 'stop'   # End slur
pitch 'E', octave: 4, dots: 1        # Dotted note
```

**Dynamics:**
Add dynamic markings using `direction` blocks with `dynamics` method. Supported: `pp`, `p`, `mp`, `mf`, `f`, `ff`, `fff`, etc.
```ruby
direction do
  dynamics 'f'  # Forte
end
```

**Wedges:**
Add crescendo/diminuendo markings with `wedge` in direction blocks.
```ruby
direction do
  wedge 'crescendo'  # Start crescendo
end
# ... notes ...
direction wedge: 'stop'  # End crescendo
```

**Metronome:**
Add tempo markings with `metronome` in measures.
```ruby
metronome beat_unit: 'quarter', per_minute: 120
```

**Rests:**
Use `rest` method instead of `pitch` for rest notation.
```ruby
rest duration: 2, type: 'quarter'
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

# Add parts using add_* methods
part = score.add_part(:p1, name: "Piano", abbreviation: "Pno.")

# Add measures and attributes
measure = part.add_measure(divisions: 4)

# Add attributes (key, time, clef, etc.)
measure.attributes.last.add_key(1, fifths: 0)        # C major
measure.attributes.last.add_time(1, beats: 4, beat_type: 4)
measure.attributes.last.add_clef(1, sign: 'G', line: 2)

# Add notes
measure.add_pitch(step: 'C', octave: 4, duration: 4, type: 'quarter')
measure.add_pitch(step: 'E', octave: 4, duration: 4, type: 'quarter')
measure.add_pitch(step: 'G', octave: 4, duration: 4, type: 'quarter')
measure.add_pitch(step: 'C', octave: 5, duration: 4, type: 'quarter')

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


