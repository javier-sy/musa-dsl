require 'docs_helper'

using Musa::Extension::Neumas
using Musa::Extension::Matrix

RSpec.describe 'MusicXML Builder Documentation Examples' do

  context 'MusicXML Builder - Music Notation Export' do
    it 'creates score using constructor style (method calls)' do
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

      # Verify XML is generated
      xml_string = score.to_xml.string
      expect(xml_string).to include('<?xml version="1.0"')
      expect(xml_string).to include('<score-partwise')
      expect(xml_string).to include('<work-title>Piano Piece</work-title>')
      expect(xml_string).to include('<creator type="composer">Your Name</creator>')
      expect(xml_string).to include('</score-partwise>')
    end

    it 'creates score using DSL style (blocks)' do
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

      # Verify XML is generated
      xml_string = score.to_xml.string
      expect(xml_string).to include('<?xml version="1.0"')
      expect(xml_string).to include('<score-partwise')
      expect(xml_string).to include('<work-title>Piano Piece</work-title>')
      expect(xml_string).to include('<creator type="composer">Your Name</creator>')
      expect(xml_string).to include('</score-partwise>')
    end

    it 'creates sophisticated piano score with multiple features' do
      score = Musa::MusicXML::Builder::ScorePartwise.new do
        work_title "Étude in D Major"
        work_number 1
        creators composer: "Example Composer"
        encoding_date DateTime.new(2024, 1, 1)

        part :p1, name: "Piano" do
          # Measure 1 - Setup and opening with two staves
          measure do
            attributes do
              divisions 2

              # Treble clef (staff 1)
              key 1, fifths: 2        # D major
              clef 1, sign: 'G', line: 2
              time 1, beats: 4, beat_type: 4

              # Bass clef (staff 2)
              key 2, fifths: 2
              clef 2, sign: 'F', line: 4
              time 2, beats: 4, beat_type: 4
            end

            # Tempo marking
            metronome beat_unit: 'quarter', per_minute: 120

            # Right hand
            pitch 'D', octave: 4, duration: 4, type: 'half', slur: 'start'
            pitch 'E', octave: 4, duration: 4, type: 'half', slur: 'stop'

            # Return for left hand
            backup 8

            # Left hand
            pitch 'D', octave: 3, duration: 8, type: 'whole', staff: 2
          end

          # Measure 2 - Two voices
          measure do
            # Voice 1
            pitch 'F#', octave: 4, duration: 2, type: 'quarter', alter: 1, voice: 1
            pitch 'G', octave: 4, duration: 2, type: 'quarter', voice: 1

            # Return for voice 2
            backup 4

            # Voice 2
            pitch 'A', octave: 3, duration: 2, type: 'quarter', voice: 2
            pitch 'B', octave: 3, duration: 2, type: 'quarter', voice: 2
          end
        end
      end

      xml_string = score.to_xml.string

      # Verify structure
      expect(xml_string).to include('<work-title>Étude in D Major</work-title>')
      expect(xml_string).to include('<work-number>1</work-number>')
      expect(xml_string).to include('<beat-unit>quarter</beat-unit>')
      expect(xml_string).to include('<per-minute>120</per-minute>')

      # Verify multiple staves
      expect(xml_string).to include('<staff>2</staff>')
      expect(xml_string).to include('<staves>2</staves>')

      # Verify slurs
      expect(xml_string).to include('<slur type="start"/>')
      expect(xml_string).to include('<slur type="stop"/>')

      # Verify backup
      expect(xml_string).to include('<backup>')

      # Verify voices
      expect(xml_string).to include('<voice>1</voice>')
      expect(xml_string).to include('<voice>2</voice>')

      # Verify alterations
      expect(xml_string).to include('<alter>1</alter>')
    end
  end


end
