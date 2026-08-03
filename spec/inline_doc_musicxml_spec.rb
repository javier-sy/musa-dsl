require 'spec_helper'
require 'musa-dsl'

RSpec.describe 'MusicXML Builder Inline Documentation Examples' do
  context 'ScorePartwise (score-partwise.rb)' do
    it '@example Complete score with two parts' do
      score = Musa::MusicXML::Builder::ScorePartwise.new do
        work_title "Duet"
        creators composer: "J. Composer"
        encoding_date DateTime.new(2024, 1, 1)

        part :p1, name: "Flute" do
          measure do
            attributes do
              divisions 4
              key fifths: 1  # G major
              time beats: 3, beat_type: 4
              clef sign: 'G', line: 2
            end
            pitch 'G', octave: 4, duration: 4, type: 'quarter'
            pitch 'A', octave: 4, duration: 4, type: 'quarter'
            pitch 'B', octave: 4, duration: 4, type: 'quarter'
          end
        end

        part :p2, name: "Piano" do
          measure do
            attributes do
              divisions 4
              key fifths: 1
              time beats: 3, beat_type: 4
              clef sign: 'G', line: 2
            end
            pitch 'D', octave: 4, duration: 12, type: 'half', dots: 1
          end
        end
      end

      xml_string = score.to_xml.string
      expect(xml_string).to include('<work-title>Duet</work-title>')
      expect(xml_string).to include('<creator type="composer">J. Composer</creator>')
      expect(xml_string).to include('<score-part id="p1">')
      expect(xml_string).to include('<part-name>Flute</part-name>')
      expect(xml_string).to include('<score-part id="p2">')
      expect(xml_string).to include('<part-name>Piano</part-name>')
    end

    it '@example With metadata in constructor' do
      score = Musa::MusicXML::Builder::ScorePartwise.new(
        work_title: "Sonata in C",
        work_number: 1,
        movement_title: "Allegro",
        creators: { composer: "Mozart", arranger: "Smith" },
        rights: { lyrics: "Public Domain" }
      )

      xml_string = score.to_xml.string
      expect(xml_string).to include('<work-title>Sonata in C</work-title>')
      expect(xml_string).to include('<work-number>1</work-number>')
      expect(xml_string).to include('<movement-title>Allegro</movement-title>')
      expect(xml_string).to include('<creator type="composer">Mozart</creator>')
      expect(xml_string).to include('<creator type="arranger">Smith</creator>')
      expect(xml_string).to include('<rights type="lyrics">Public Domain</rights>')
    end
  end

  context 'Part (part.rb)' do
    it '@example Creating a part with measures' do
      part = Musa::MusicXML::Builder::Internal::Part.new(:p1, name: "Violin I", abbreviation: "Vln. I") do
        measure do
          attributes do
            divisions 4
            key fifths: 1  # G major
            time beats: 4, beat_type: 4
            clef sign: 'G', line: 2
          end
          pitch 'D', octave: 5, duration: 4, type: 'quarter'
        end

        measure do
          pitch 'E', octave: 5, duration: 4, type: 'quarter'
          pitch 'F', octave: 5, duration: 4, type: 'quarter', alter: 1
        end
      end

      xml_string = part.to_xml.string
      expect(xml_string).to include('<part id="p1">')
      expect(xml_string).to include('<measure number="1">')
      expect(xml_string).to include('<measure number="2">')
      expect(xml_string).to include('<step>D</step>')
      expect(xml_string).to include('<step>E</step>')
      expect(xml_string).to include('<step>F</step>')
      expect(xml_string).to include('<alter>1</alter>')
    end
  end

  context 'Measure (measure.rb)' do
    it '@example Simple measure with quarter notes' do
      measure = Musa::MusicXML::Builder::Internal::Measure.new(1, divisions: 2) do
        attributes do
          key fifths: 0  # C major
          time beats: 4, beat_type: 4
          clef sign: 'G', line: 2
        end

        pitch 'C', octave: 4, duration: 2, type: 'quarter'
        pitch 'D', octave: 4, duration: 2, type: 'quarter'
        pitch 'E', octave: 4, duration: 2, type: 'quarter'
        pitch 'F', octave: 4, duration: 2, type: 'quarter'
      end

      xml_string = measure.to_xml.string
      expect(xml_string).to include('<measure number="1">')
      expect(xml_string).to include('<divisions>2</divisions>')
      expect(xml_string).to include('<fifths>0</fifths>')
      expect(xml_string).to include('<beats>4</beats>')
      expect(xml_string).to include('<beat-type>4</beat-type>')
      expect(xml_string).to include('<step>C</step>')
      expect(xml_string).to include('<step>D</step>')
      expect(xml_string).to include('<step>E</step>')
      expect(xml_string).to include('<step>F</step>')
    end

    it '@example Measure with dynamics and tempo' do
      measure = Musa::MusicXML::Builder::Internal::Measure.new(1, divisions: 4) do
        metronome beat_unit: 'quarter', per_minute: 120

        direction do
          dynamics 'p'
          wedge 'crescendo'
        end

        pitch 'C', octave: 4, duration: 4, type: 'quarter'
        pitch 'D', octave: 4, duration: 4, type: 'quarter'

        direction do
          wedge 'stop'
          dynamics 'f'
        end
      end

      xml_string = measure.to_xml.string
      expect(xml_string).to include('<beat-unit>quarter</beat-unit>')
      expect(xml_string).to include('<per-minute>120</per-minute>')
      expect(xml_string).to include('<p />')
      expect(xml_string).to include('<wedge type="crescendo"')
      expect(xml_string).to include('<f />')
      expect(xml_string).to include('<wedge type="stop"')
    end
  end

  context 'Attributes (attributes.rb)' do
    it '@example Simple single-staff attributes' do
      attrs = Musa::MusicXML::Builder::Internal::Attributes.new(
        divisions: 4,
        key_fifths: 1,        # G major
        time_beats: 4, time_beat_type: 4,
        clef_sign: 'G', clef_line: 2
      )

      xml_string = attrs.to_xml.string
      expect(xml_string).to include('<divisions>4</divisions>')
      expect(xml_string).to include('<fifths>1</fifths>')
      expect(xml_string).to include('<beats>4</beats>')
      expect(xml_string).to include('<beat-type>4</beat-type>')
      expect(xml_string).to include('<sign>G</sign>')
      expect(xml_string).to include('<line>2</line>')
    end

    it '@example Piano with different keys per staff' do
      attrs = Musa::MusicXML::Builder::Internal::Attributes.new do
        divisions 4
        key 1, fifths: 0      # Treble: C major
        key 2, fifths: -1     # Bass: F major
        time beats: 3, beat_type: 4
        clef 1, sign: 'G', line: 2
        clef 2, sign: 'F', line: 4
      end

      xml_string = attrs.to_xml.string
      expect(xml_string).to include('<divisions>4</divisions>')
      expect(xml_string).to include('<staves>2</staves>')
      expect(xml_string).to include('<key number="1">')
      expect(xml_string).to include('<key number="2">')
      expect(xml_string).to include('<fifths>0</fifths>')
      expect(xml_string).to include('<fifths>-1</fifths>')
    end
  end

  context 'Key (attributes.rb)' do

  end

  context 'Time (attributes.rb)' do
    it '@example Common time (4/4)' do
      time = Musa::MusicXML::Builder::Internal::Time.new(beats: 4, beat_type: 4)

      xml_string = time.to_xml.string
      expect(xml_string).to include('<time>')
      expect(xml_string).to include('<beats>4</beats>')
      expect(xml_string).to include('<beat-type>4</beat-type>')
    end

    it '@example Compound signature (3+2+3/8)' do
      time = Musa::MusicXML::Builder::Internal::Time.new
      time.add_beats(beats: 3, beat_type: 8)
      time.add_beats(beats: 2, beat_type: 8)
      time.add_beats(beats: 3, beat_type: 8)

      xml_string = time.to_xml.string
      expect(xml_string).to include('<time>')
      expect(xml_string.scan(/<beats>/).length).to eq(3)
      expect(xml_string.scan(/<beat-type>/).length).to eq(3)
    end
  end

  context 'Clef (attributes.rb)' do

  end

  context 'PitchedNote (pitched-note.rb)' do

    it '@example F# with sharp symbol' do
      note = Musa::MusicXML::Builder::Internal::PitchedNote.new('F', alter: 1, octave: 5, duration: 2, type: 'eighth',
                                                                  accidental: 'sharp')

      xml_string = note.to_xml.string
      expect(xml_string).to include('<step>F</step>')
      expect(xml_string).to include('<alter>1</alter>')
      expect(xml_string).to include('<octave>5</octave>')
      expect(xml_string).to include('<type>eighth</type>')
      expect(xml_string).to include('<accidental>sharp</accidental>')
    end

    it '@example Bb dotted half note with staccato' do
      note = Musa::MusicXML::Builder::Internal::PitchedNote.new('B', alter: -1, octave: 4, duration: 6, type: 'half',
                                                                  dots: 1, accidental: 'flat', staccato: true)

      xml_string = note.to_xml.string
      expect(xml_string).to include('<step>B</step>')
      expect(xml_string).to include('<alter>-1</alter>')
      expect(xml_string).to include('<octave>4</octave>')
      expect(xml_string).to include('<type>half</type>')
      expect(xml_string).to include('<dot />')
      expect(xml_string).to include('<accidental>flat</accidental>')
      expect(xml_string).to include('<staccato />')
    end
  end

  context 'Rest (rest.rb)' do

  end

  context 'UnpitchedNote (unpitched-note.rb)' do

    it '@example Snare drum hit with accent' do
      note = Musa::MusicXML::Builder::Internal::UnpitchedNote.new(duration: 2, type: 'quarter', accent: true)

      xml_string = note.to_xml.string
      expect(xml_string).to include('<unpitched />')
      expect(xml_string).to include('<accent />')
    end
  end

  context 'Backup (backup-forward.rb)' do
    it '@example Piano with simultaneous treble and bass' do
      measure = Musa::MusicXML::Builder::Internal::Measure.new(1, divisions: 2) do
        pitch 'D', octave: 4, duration: 4, type: 'half'
        pitch 'E', octave: 4, duration: 4, type: 'half'

        backup 8  # Rewind full measure (8 divisions)

        pitch 'C', octave: 3, duration: 8, type: 'whole', staff: 2
      end

      xml_string = measure.to_xml.string
      expect(xml_string).to include('<backup><duration>8</duration></backup>')
      expect(xml_string).to include('<staff>2</staff>')
    end

    it '@example Two voices on the same staff' do
      measure = Musa::MusicXML::Builder::Internal::Measure.new(1, divisions: 2) do
        pitch 'C', octave: 5, duration: 2, type: 'quarter', voice: 1
        pitch 'D', octave: 5, duration: 2, type: 'quarter', voice: 1
        pitch 'E', octave: 5, duration: 2, type: 'quarter', voice: 1
        pitch 'F', octave: 5, duration: 2, type: 'quarter', voice: 1

        backup 8  # Back to measure start

        pitch 'E', octave: 4, duration: 4, type: 'half', voice: 2
        pitch 'F', octave: 4, duration: 4, type: 'half', voice: 2
      end

      xml_string = measure.to_xml.string
      expect(xml_string).to include('<voice>1</voice>')
      expect(xml_string).to include('<voice>2</voice>')
      expect(xml_string).to include('<backup><duration>8</duration></backup>')
    end
  end

  context 'Forward (backup-forward.rb)' do
    it '@example Skip a quarter note in voice 2' do
      forward = Musa::MusicXML::Builder::Internal::Forward.new(2, voice: 2)

      xml_string = forward.to_xml.string
      expect(xml_string).to include('<forward>')
      expect(xml_string).to include('<duration>2</duration>')
      expect(xml_string).to include('<voice>2</voice>')
    end
  end

  context 'Direction (direction.rb)' do
    it '@example Tempo marking' do
      direction = Musa::MusicXML::Builder::Internal::Direction.new(placement: 'above') do
        metronome beat_unit: 'quarter', per_minute: '120'
        words 'Allegro'
      end

      xml_string = direction.to_xml.string
      expect(xml_string).to include('<direction placement="above">')
      expect(xml_string).to include('<metronome>')
      expect(xml_string).to include('<beat-unit>quarter</beat-unit>')
      expect(xml_string).to include('<per-minute>120</per-minute>')
      expect(xml_string).to include('<words>Allegro</words>')
    end

    it '@example Crescendo hairpin' do
      direction = Musa::MusicXML::Builder::Internal::Direction.new(placement: 'below') do
        wedge 'crescendo'
      end

      xml_string = direction.to_xml.string
      expect(xml_string).to include('<direction placement="below">')
      expect(xml_string).to include('<wedge type="crescendo"')
    end
  end

  context 'Metronome (direction.rb)' do
    it '@example Quarter note = 120 BPM' do
      metronome = Musa::MusicXML::Builder::Internal::Metronome.new(beat_unit: 'quarter', per_minute: '120')

      xml_string = metronome.to_xml.string
      expect(xml_string).to include('<metronome>')
      expect(xml_string).to include('<beat-unit>quarter</beat-unit>')
      expect(xml_string).to include('<per-minute>120</per-minute>')
    end
  end

  context 'Dynamics (direction.rb)' do
    it '@example Single dynamic' do
      dynamics = Musa::MusicXML::Builder::Internal::Dynamics.new('f')

      xml_string = dynamics.to_xml.string
      expect(xml_string).to include('<dynamics>')
      expect(xml_string).to include('<f />')
    end
  end

  context 'PartGroup (part-group.rb)' do
    it '@example String quartet grouping' do
      group_start = Musa::MusicXML::Builder::Internal::PartGroup.new(1,
        type: 'start',
        name: "String Quartet",
        symbol: 'bracket'
      )

      xml_string = group_start.header_to_xml.string
      expect(xml_string).to include('<part-group number="1" type="start">')
      expect(xml_string).to include('<group-name>String Quartet</group-name>')
      expect(xml_string).to include('<group-symbol>bracket</group-symbol>')
    end

    it '@example Piano grand staff' do
      group = Musa::MusicXML::Builder::Internal::PartGroup.new(1,
        type: 'start',
        symbol: 'brace',
        group_barline: true
      )

      xml_string = group.header_to_xml.string
      expect(xml_string).to include('<part-group number="1" type="start">')
      expect(xml_string).to include('<group-symbol>brace</group-symbol>')
      expect(xml_string).to include('<group-barline>yes</group-barline>')
    end
  end

  context 'TimeModification (note-complexities.rb)' do

  end

  context 'Tuplet (note-complexities.rb)' do

  end

  context 'Harmonic (note-complexities.rb)' do

  end

  context 'Creator (typed-text.rb)' do
    it '@example Creator' do
      creator = Musa::MusicXML::Builder::Internal::Creator.new(:composer, "Ludwig van Beethoven")

      xml_string = creator.to_xml.string
      expect(xml_string).to include('<creator type="composer">Ludwig van Beethoven</creator>')
    end
  end

  context 'Rights (typed-text.rb)' do
    it '@example Rights' do
      rights = Musa::MusicXML::Builder::Internal::Rights.new(:lyrics, "Copyright 2024 Publisher Name")

      xml_string = rights.to_xml.string
      expect(xml_string).to include('<rights type="lyrics">Copyright 2024 Publisher Name</rights>')
    end
  end
end
