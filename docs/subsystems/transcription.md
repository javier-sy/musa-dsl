# Transcription - MIDI & MusicXML Output

The Transcription system converts GDV events to MIDI (with ornament expansion) or MusicXML format (preserving ornaments as symbols).

## MIDI with Ornament Expansion

```ruby
require 'musa-dsl'

using Musa::Extension::Neumas

# Neuma notation with ornaments: trill (.tr) and mordent (.mor)
neumas = "(0 1 mf) (+2 1 tr) (+4 1 mor) (+5 1)"

# Create scale and decoder
scale = Musa::Scales::Scales.et12[440.0].major[60]
decoder = Musa::Neumas::Decoders::NeumaDecoder.new(scale, base_duration: 1/4r)

# Create MIDI transcriptor with ornament expansion
transcriptor = Musa::Transcription::Transcriptor.new(
  Musa::Transcriptors::FromGDV::ToMIDI.transcription_set(duration_factor: 1/6r),
  base_duration: 1/4r,
  tick_duration: 1/96r
)

# Parse and expand ornaments to PDV
result = Musa::Neumalang::Neumalang.parse(neumas, decode_with: decoder)
                                   .process_with { |gdv| transcriptor.transcript(gdv) }
                                   .map { |gdv| gdv.to_pdv(scale) }
                                   .to_a(recursive: true)

# View expanded notes (ornaments rendered as note sequences)
result.each do |pdv|
  puts "Pitch: #{pdv[:pitch]}, Duration: #{pdv[:duration]}, Velocity: #{pdv[:velocity]}"
end
# => Pitch: 60, Duration: 1/4, Velocity: 80     # C4 (no ornament)
#    Pitch: 65, Duration: 1/24, Velocity: 80   # Trill: F4 (upper neighbor)
#    Pitch: 64, Duration: 1/24, Velocity: 80   # Trill: E4 (original)
#    Pitch: 65, Duration: 1/24, Velocity: 80   # Trill: F4
#    Pitch: 64, Duration: 1/24, Velocity: 80   # Trill: E4
#    ... (trill alternation continues)
#    Pitch: 71, Duration: 1/24, Velocity: 80   # Mordent: B4 (original)
#    Pitch: 72, Duration: 1/24, Velocity: 80   # Mordent: C5 (neighbor)
#    Pitch: 71, Duration: 1/6, Velocity: 80    # Mordent: B4 (return)
#    Pitch: 79, Duration: 1/4, Velocity: 80    # G5 (no ornament)
```

**Supported ornaments:**
- `.tr` - Trill (rapid alternation with upper note)
- `.mor` - Mordent (quick alternation with adjacent note)
- `.turn` - Turn (four-note figure)
- `.st` - Staccato (shortened duration)

## MusicXML with Ornament Symbols

```ruby
require 'musa-dsl'

using Musa::Extension::Neumas

# Same phrase as MIDI example (ornaments preserved as symbols)
neumas = "(0 1 mf) (+2 1 tr) (+4 1 mor) (+5 1)"

# Create scale and decoder
scale = Musa::Scales::Scales.et12[440.0].major[60]
decoder = Musa::Neumas::Decoders::NeumaDecoder.new(scale, base_duration: 1/4r)

# Create MusicXML transcriptor (preserves ornaments as symbols)
transcriptor = Musa::Transcription::Transcriptor.new(
  Musa::Transcriptors::FromGDV::ToMusicXML.transcription_set,
  base_duration: 1/4r,
  tick_duration: 1/96r
)

# Parse and convert to GDV with preserved ornament markers
serie = Musa::Neumalang::Neumalang.parse(neumas, decode_with: decoder)
                                   .process_with { |gdv| transcriptor.transcript(gdv) }

# Create Score and use sequencer to fill it
score = Musa::Datasets::Score.new
sequencer = Musa::Sequencer::Sequencer.new(4, 24)

sequencer.at 1 do
  play serie, decoder: decoder, mode: :neumalang do |gdv|
    pdv = gdv.to_pdv(scale)
    score.at(position, add: pdv)  # position is automatically tracked by sequencer
  end
end

sequencer.run

# Convert to MusicXML
mxml = score.to_mxml(
  4, 24,  # 4 beats per bar, 24 ticks per beat
  bpm: 120,
  title: 'Ornaments Example',
  creators: { composer: 'MusaDSL' },
  parts: { piano: { name: 'Piano', clefs: { g: 2 } } }
)

# Generated MusicXML (excerpt showing notes with ornaments):
puts mxml.to_xml.string
```

**Generated MusicXML output (excerpt):**
```xml
<note>
  <pitch>
    <step>C</step>
    <octave>4</octave>
  </pitch>
  <duration>24</duration>
  <type>quarter</type>
</note>
<note>
  <pitch>
    <step>E</step>
    <octave>4</octave>
  </pitch>
  <duration>24</duration>
  <type>quarter</type>
  <notations>
    <ornaments>
      <trill-mark />      <!-- Trill preserved as notation symbol -->
    </ornaments>
  </notations>
</note>
<note>
  <pitch>
    <step>B</step>
    <octave>4</octave>
  </pitch>
  <duration>24</duration>
  <type>quarter</type>
  <notations>
    <ornaments>
      <inverted-mordent />   <!-- Mordent preserved as notation symbol -->
    </ornaments>
  </notations>
</note>
```

**Note:** Only 4 notes (vs 11 in MIDI) - ornaments preserved as notation symbols, not expanded

**Documentation:** See `lib/transcription/` and `lib/musicxml/`


