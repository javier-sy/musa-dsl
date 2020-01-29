require 'spec_helper'

require 'musa-dsl'

include Musa::MusicXML

RSpec.describe Musa::MusicXML do
  context 'MusicXML generation' do
    it 'ScorePartwise header structure is equal between constructor and add_ methods' do
      score1 = ScorePartwise.new

      score1.add_creator "composer", name: "Javier"
      score1.add_creator "lyrics", name: "Javier S. lyrics"
      score1.add_rights "lyrics", name: "Javier S."
      score1.work_title = "Work Title"
      score1.work_number = 100
      score1.movement_title = "Movement Title"
      score1.movement_number = "1"

      score2 = ScorePartwise.new work_title: "Work Title", work_number: 100,
                                 movement_title: "Movement Title", movement_number: "1",
                                 creators: { composer: "Javier", lyrics: "Javier S. lyrics" },
                                 rights: { lyrics: "Javier S." }

      expect(score1.to_xml.string).to eq score2.to_xml.string
    end

    it 'ScorePartwise simple header structure is correct' do
      score = ScorePartwise.new work_title: "Work Title", work_number: 100,
                                 movement_title: "Movement Title", movement_number: "1",
                                 creators: { composer: "Javier", lyrics: "Javier S. lyrics" },
                                 rights: { lyrics: "Javier S." }

      expect(score.to_xml.string.strip).to eq File.read(File.join(File.dirname(__FILE__), "musicxml_1_spec.musicxml")).strip
    end

    it 'Score with some simple notes' do
      score = ScorePartwise.new creators: { composer: "Javier Sánchez" }

      part = score.add_part :p1, name: "Piano", abbreviation: "p."

      measure = part.add_measure divisions: 2

      measure.last_attributes.add_key fifths: 2
      measure.last_attributes.add_clef sign: 'G', line: 2
      measure.last_attributes.add_time beats: 4, beat_type: 4

      measure.last_attributes.add_key fifths: 2
      measure.last_attributes.add_clef sign: 'F', line: 4
      measure.last_attributes.add_time beats: 4, beat_type: 4

      measure.add_metronome beat_unit: 'quarter', per_minute: 90

      measure.add_pitch step: 'D', octave: 4, duration: 4, type: 'half', slur: 'start'
      measure.add_pitch step: 'E', octave: 4, duration: 4, type: 'half', slur: 'stop'

      measure.add_backup duration: 8

      measure.add_pitch step: 'C', octave: 3, duration: 8, type: 'whole', staff: 2, slur: 'start'

      measure = part.add_measure

      measure.add_pitch step: 'C', octave: 4, duration: 2, type: 'quarter'
      measure.add_pitch step: 'D', octave: 4, duration: 2, type: 'quarter'
      measure.add_pitch step: 'E', octave: 4, duration: 2, type: 'quarter'
      measure.add_pitch step: 'F', octave: 4, duration: 2, type: 'quarter'

      measure.add_backup duration: 8

      measure.add_pitch step: 'A', octave: 4, duration: 3, type: 'quarter', dots: 1, alter: 1, voice: 2
      measure.add_pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2
      measure.add_pitch step: 'B', octave: 4, duration: 3, type: 'quarter', dots: 1, alter: 1, voice: 2
      measure.add_pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2

      measure.add_backup duration: 8

      measure.add_pitch step: 'D', octave: 3, duration: 8, type: 'whole', staff: 2, slur: 'start'

      measure = part.add_measure

      measure.add_pitch step: 'E', octave: 4, duration: 1, type: 'eighth', voice: 1
      measure.add_pitch step: 'E', octave: 4, duration: 1, type: 'eighth', voice: 1
      measure.add_pitch step: 'E', octave: 4, duration: 1, type: 'eighth', voice: 1
      measure.add_pitch step: 'E', octave: 4, duration: 1, type: 'eighth', voice: 1

      measure.add_rest duration: 2, type: 'quarter', voice: 1

      measure.add_pitch step: 'F', octave: 4, duration: 1, type: 'eighth', voice: 1
      measure.add_pitch step: 'F', octave: 4, duration: 1, type: 'eighth', voice: 1

      measure.add_backup duration: 8

      measure.add_pitch step: 'F', octave: 4, duration: 1, type: 'eighth', voice: 2
      measure.add_pitch step: 'F', octave: 4, duration: 1, type: 'eighth', voice: 2

      measure.add_rest duration: 2, type: 'quarter', voice: 2

      measure.add_pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2
      measure.add_pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2
      measure.add_pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2
      measure.add_pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2

      measure.add_backup duration: 8

      measure.add_pitch step: 'C', octave: 2, duration: 8, type: 'whole', staff: 2, slur: 'stop'

      measure = part.add_measure

      measure.add_direction [ { kind: :dynamics, value: 'pp' },
                              { kind: :wedge, type: 'crescendo'} ]

      measure.add_pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2
      measure.add_pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2
      measure.add_pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2
      measure.add_pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2

      measure.add_pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2
      measure.add_pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2
      measure.add_pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2
      measure.add_pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2

      measure.add_direction [ { kind: :wedge, type: 'stop'},
                              { kind: :dynamics, value: 'ff' } ]

      # File.open('test.musicxml', 'w') { |f| f.write(score.to_xml.string) }

      expect(score.to_xml.string.strip).to eq File.read(File.join(File.dirname(__FILE__), "musicxml_2_spec.musicxml")).strip
    end

    it 'Score with part groups' do
      score = ScorePartwise.new creators: { composer: "Javier Sánchez" }

      score.add_group 1, type: 'start', name: "Grupo A"

      part1 = score.add_part :p1, name: "Piano", abbreviation: "p."

      measure1 = part1.add_measure divisions: 2

      measure1.last_attributes.add_key fifths: 2
      measure1.last_attributes.add_clef sign: 'G', line: 2
      measure1.last_attributes.add_time beats: 4, beat_type: 4

      measure1.last_attributes.add_key fifths: 2
      measure1.last_attributes.add_clef sign: 'F', line: 4
      measure1.last_attributes.add_time beats: 4, beat_type: 4

      measure1.add_metronome beat_unit: 'quarter', per_minute: 90

      part2 = score.add_part :p2, name: "Violin", abbreviation: "vln"

      measure2 = part2.add_measure divisions: 2

      measure2.last_attributes.add_key fifths: 2
      measure2.last_attributes.add_clef sign: 'G', line: 2
      measure2.last_attributes.add_time beats: 4, beat_type: 4

      score.add_group 1, type: 'stop'


      score.add_group 2, type: 'start', name: "Grupo B"

      part3 = score.add_part :p3, name: "Viola", abbreviation: "vla"

      measure3 = part3.add_measure divisions: 2

      measure3.last_attributes.add_key fifths: 2
      measure3.last_attributes.add_clef sign: 'G', line: 2
      measure3.last_attributes.add_time beats: 4, beat_type: 4

      part4 = score.add_part :p4, name: "Cello", abbreviation: "vlc"

      measure4 = part4.add_measure divisions: 2

      measure4.last_attributes.add_key fifths: 2
      measure4.last_attributes.add_clef sign: 'G', line: 2
      measure4.last_attributes.add_time beats: 4, beat_type: 4

      score.add_group 2, type: 'stop'

      measure1.add_pitch step: 'D', octave: 4, duration: 4, type: 'half', slur: 'start'
      measure1.add_pitch step: 'E', octave: 4, duration: 4, type: 'half', slur: 'stop'

      measure1.add_backup duration: 8

      measure1.add_pitch step: 'C', octave: 3, duration: 8, type: 'whole', staff: 2

      measure2.add_pitch step: 'C', octave: 4, duration: 2, type: 'quarter'
      measure2.add_pitch step: 'D', octave: 4, duration: 2, type: 'quarter'
      measure2.add_pitch step: 'E', octave: 4, duration: 2, type: 'quarter'
      measure2.add_pitch step: 'F', octave: 4, duration: 2, type: 'quarter'

      measure3.add_pitch step: 'D', octave: 4, duration: 4, type: 'half', slur: 'start'
      measure3.add_pitch step: 'E', octave: 4, duration: 4, type: 'half', slur: 'stop'

      measure4.add_pitch step: 'D', octave: 4, duration: 4, type: 'half', slur: 'start'
      measure4.add_pitch step: 'E', octave: 4, duration: 4, type: 'half', slur: 'stop'

      measure1 = part1.add_measure
      measure2 = part2.add_measure
      measure3 = part3.add_measure
      measure4 = part4.add_measure

      measure1.add_pitch step: 'C', octave: 4, duration: 2, type: 'quarter'
      measure1.add_pitch step: 'D', octave: 4, duration: 2, type: 'quarter'
      measure1.add_pitch step: 'E', octave: 4, duration: 2, type: 'quarter'
      measure1.add_pitch step: 'F', octave: 4, duration: 2, type: 'quarter'

      measure2.add_pitch step: 'D', octave: 4, duration: 4, type: 'half', slur: 'start'
      measure2.add_pitch step: 'E', octave: 4, duration: 4, type: 'half', slur: 'stop'

      measure2.add_backup duration: 8

      measure2.add_pitch step: 'C', octave: 5, duration: 8, type: 'whole'

      measure3.add_rest type: 'whole', duration: 8
      measure4.add_rest type: 'whole', duration: 8

      # File.open('test.musicxml', 'w') { |f| f.write(score.to_xml.string) }

      expect(score.to_xml.string.strip).to eq File.read(File.join(File.dirname(__FILE__), "musicxml_3_spec.musicxml")).strip
    end

  end
end
