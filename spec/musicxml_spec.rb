require 'spec_helper'

require 'musa-dsl'

include Musa::MusicXML::Builder

RSpec.describe Musa::MusicXML::Builder do
  context 'MusicXML generation' do
    it 'ScorePartwise header structure is equal between constructor, add_ methods and builder' do
      score1 = ScorePartwise.new

      score1.add_creator "composer", "Javier"
      score1.add_creator "lyrics", "Javier S. lyrics"
      score1.add_rights "lyrics", "Javier S."
      score1.work_title = "Work Title"
      score1.work_number = 100
      score1.movement_title = "Movement Title"
      score1.movement_number = "1"
      score1.encoding_date = DateTime.new(2020, 1, 29)

      score2 = ScorePartwise.new work_title: "Work Title", work_number: 100,
                                 movement_title: "Movement Title", movement_number: "1",
                                 creators: { composer: "Javier", lyrics: "Javier S. lyrics" },
                                 rights: { lyrics: "Javier S." },
                                 encoding_date: DateTime.new(2020, 1, 29)

      expect(score1.to_xml.string).to eq score2.to_xml.string
    end

    it 'ScorePartwise simple header structure is correct' do
      score = ScorePartwise.new work_title: "Work Title", work_number: 100,
                                 movement_title: "Movement Title", movement_number: "1",
                                 creators: { composer: "Javier", lyrics: "Javier S. lyrics" },
                                 rights: { lyrics: "Javier S." },
                                 encoding_date: DateTime.new(2020, 1, 29)

      expect(score.to_xml.string.strip).to eq File.read(File.join(File.dirname(__FILE__), "musicxml_1_spec.musicxml")).strip
    end

    it 'ScorePartwise simple header structure created with builder' do
      score = ScorePartwise.new do
        work_title "Work Title"
        work_number 100

        movement_title "Movement Title"
        movement_number 1
        encoding_date DateTime.new(2020, 1, 29)
        creators composer: "Javier", lyrics: "Javier S. lyrics"
        rights lyrics: "Javier S."
      end

      expect(score.to_xml.string.strip).to eq File.read(File.join(File.dirname(__FILE__), "musicxml_1_spec.musicxml")).strip
    end

    it 'Score with some simple notes created with adder methods' do
      score = ScorePartwise.new creators: { composer: "Javier Sánchez" },
                                encoding_date: DateTime.new(2020, 1, 29)

      part = score.add_part :p1, name: "Piano", abbreviation: "p."

      measure = part.add_measure divisions: 2

      measure.attributes.last.add_key 1, fifths: 2
      measure.attributes.last.add_clef 1, sign: 'G', line: 2
      measure.attributes.last.add_time 1, beats: 4, beat_type: 4

      measure.attributes.last.add_key 2, fifths: 2
      measure.attributes.last.add_clef 2, sign: 'F', line: 4
      measure.attributes.last.add_time 2, beats: 4, beat_type: 4

      measure.add_metronome beat_unit: 'quarter', per_minute: 90

      measure.add_pitch step: 'D', octave: 4, duration: 4, type: 'half', slur: 'start'
      measure.add_pitch step: 'E', octave: 4, duration: 4, type: 'half', slur: 'stop'

      measure.add_backup 8

      measure.add_pitch step: 'C', octave: 3, duration: 8, type: 'whole', staff: 2, slur: 'start'

      measure = part.add_measure

      measure.add_pitch step: 'C', octave: 4, duration: 2, type: 'quarter'
      measure.add_pitch step: 'D', octave: 4, duration: 2, type: 'quarter'
      measure.add_pitch step: 'E', octave: 4, duration: 2, type: 'quarter'
      measure.add_pitch step: 'F', octave: 4, duration: 2, type: 'quarter'

      measure.add_backup 8

      measure.add_pitch step: 'A', octave: 4, duration: 3, type: 'quarter', dots: 1, alter: 1, voice: 2
      measure.add_pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2
      measure.add_pitch step: 'B', octave: 4, duration: 3, type: 'quarter', dots: 1, alter: 1, voice: 2
      measure.add_pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2

      measure.add_backup 8

      measure.add_pitch step: 'D', octave: 3, duration: 8, type: 'whole', staff: 2, slur: 'start'

      measure = part.add_measure

      measure.add_pitch step: 'E', octave: 4, duration: 1, type: 'eighth', voice: 1
      measure.add_pitch step: 'E', octave: 4, duration: 1, type: 'eighth', voice: 1
      measure.add_pitch step: 'E', octave: 4, duration: 1, type: 'eighth', voice: 1
      measure.add_pitch step: 'E', octave: 4, duration: 1, type: 'eighth', voice: 1

      measure.add_rest duration: 2, type: 'quarter', voice: 1

      measure.add_pitch step: 'F', octave: 4, duration: 1, type: 'eighth', voice: 1
      measure.add_pitch step: 'F', octave: 4, duration: 1, type: 'eighth', voice: 1

      measure.add_backup 8

      measure.add_pitch step: 'F', octave: 4, duration: 1, type: 'eighth', voice: 2
      measure.add_pitch step: 'F', octave: 4, duration: 1, type: 'eighth', voice: 2

      measure.add_rest duration: 2, type: 'quarter', voice: 2

      measure.add_pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2
      measure.add_pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2
      measure.add_pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2
      measure.add_pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2

      measure.add_backup 8

      measure.add_pitch step: 'C', octave: 2, duration: 8, type: 'whole', staff: 2, slur: 'stop'

      measure = part.add_measure

      direction = measure.add_direction
      direction.add_dynamics 'pp'
      direction.add_wedge 'crescendo'

      measure.add_pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2
      measure.add_pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2
      measure.add_pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2
      measure.add_pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2

      measure.add_pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2
      measure.add_pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2
      measure.add_pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2
      measure.add_pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2

      direction = measure.add_direction
      direction.add_wedge 'stop'
      direction.add_dynamics 'ff'

      # File.open('test.musicxml', 'w') { |f| f.write(score.to_xml.string) }

      expect(score.to_xml.string.strip).to eq File.read(File.join(File.dirname(__FILE__), "musicxml_2_spec.musicxml")).strip
    end

    it 'Score with some simple notes created with builder methods' do
      score = ScorePartwise.new creators: { composer: "Javier Sánchez" },
                                encoding_date: DateTime.new(2020, 1, 29) do

        part :p1, name: "Piano", abbreviation: "p." do
          measure do
            attributes do
              divisions 2

              key 1, fifths: 2
              clef 1, sign: 'G', line: 2
              time 1, beats: 4, beat_type: 4

              key 2, fifths: 2
              clef 2, sign: 'F', line: 4
              time 2, beats: 4, beat_type: 4
            end

            metronome beat_unit: 'quarter', per_minute: 90

            pitch 'D', octave: 4, duration: 4, type: 'half', slur: 'start'
            pitch 'E', octave: 4, duration: 4, type: 'half', slur: 'stop'

            backup 8

            pitch 'C', octave: 3, duration: 8, type: 'whole', staff: 2, slur: 'start'
          end

          measure do
            pitch 'C', octave: 4, duration: 2, type: 'quarter'
            pitch 'D', octave: 4, duration: 2, type: 'quarter'
            pitch 'E', octave: 4, duration: 2, type: 'quarter'
            pitch 'F', octave: 4, duration: 2, type: 'quarter'

            backup 8

            pitch 'A', octave: 4, duration: 3, type: 'quarter', dots: 1, alter: 1, voice: 2
            pitch 'C', octave: 5, duration: 1, type: 'eighth', voice: 2
            pitch 'B', octave: 4, duration: 3, type: 'quarter', dots: 1, alter: 1, voice: 2
            pitch 'C', octave: 5, duration: 1, type: 'eighth', voice: 2

            backup 8

            pitch 'D', octave: 3, duration: 8, type: 'whole', staff: 2, slur: 'start'
          end

          measure do
            pitch 'E', octave: 4, duration: 1, type: 'eighth', voice: 1
            pitch 'E', octave: 4, duration: 1, type: 'eighth', voice: 1
            pitch 'E', octave: 4, duration: 1, type: 'eighth', voice: 1
            pitch 'E', octave: 4, duration: 1, type: 'eighth', voice: 1

            rest duration: 2, type: 'quarter', voice: 1

            pitch 'F', octave: 4, duration: 1, type: 'eighth', voice: 1
            pitch 'F', octave: 4, duration: 1, type: 'eighth', voice: 1

            backup 8

            pitch 'F', octave: 4, duration: 1, type: 'eighth', voice: 2
            pitch 'F', octave: 4, duration: 1, type: 'eighth', voice: 2

            rest duration: 2, type: 'quarter', voice: 2

            pitch 'C', octave: 5, duration: 1, type: 'eighth', voice: 2
            pitch 'C', octave: 5, duration: 1, type: 'eighth', voice: 2
            pitch 'C', octave: 5, duration: 1, type: 'eighth', voice: 2
            pitch 'C', octave: 5, duration: 1, type: 'eighth', voice: 2

            backup 8

            pitch 'C', octave: 2, duration: 8, type: 'whole', staff: 2, slur: 'stop'
          end

          measure do
            direction do
              dynamics 'pp'
              wedge 'crescendo'
            end

            pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2
            pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2
            pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2
            pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2

            pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2
            pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2
            pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2
            pitch step: 'C', octave: 5, duration: 1, type: 'eighth', voice: 2

            direction wedge: 'stop', dynamics: 'ff'
          end
        end
      end

      # File.open('test.musicxml', 'w') { |f| f.write(score.to_xml.string) }

      expect(score.to_xml.string.strip).to eq File.read(File.join(File.dirname(__FILE__), "musicxml_2_spec.musicxml")).strip
    end

    it 'Score with part groups' do
      score = ScorePartwise.new creators: { composer: "Javier Sánchez" },
                                encoding_date: DateTime.new(2020, 1, 29)

      score.add_group 1, type: 'start', name: "Grupo A"

      part1 = score.add_part :p1, name: "Piano", abbreviation: "p."

      measure1 = part1.add_measure divisions: 2

      measure1.attributes.last.add_key 1, fifths: 2
      measure1.attributes.last.add_clef 1, sign: 'G', line: 2
      measure1.attributes.last.add_time 1, beats: 4, beat_type: 4

      measure1.attributes.last.add_key 2, fifths: 2
      measure1.attributes.last.add_clef 2, sign: 'F', line: 4
      measure1.attributes.last.add_time 2, beats: 4, beat_type: 4

      measure1.add_metronome beat_unit: 'quarter', per_minute: 90

      part2 = score.add_part :p2, name: "Violin", abbreviation: "vln"

      measure2 = part2.add_measure divisions: 2

      measure2.attributes.last.add_key fifths: 2
      measure2.attributes.last.add_clef sign: 'G', line: 2
      measure2.attributes.last.add_time beats: 4, beat_type: 4

      score.add_group 1, type: 'stop'


      score.add_group 2, type: 'start', name: "Grupo B"

      part3 = score.add_part :p3, name: "Viola", abbreviation: "vla"

      measure3 = part3.add_measure divisions: 2

      measure3.attributes.last.add_key fifths: 2
      measure3.attributes.last.add_clef sign: 'G', line: 2
      measure3.attributes.last.add_time beats: 4, beat_type: 4

      part4 = score.add_part :p4, name: "Cello", abbreviation: "vlc"

      measure4 = part4.add_measure divisions: 2

      measure4.attributes.last.add_key fifths: 2
      measure4.attributes.last.add_clef sign: 'G', line: 2
      measure4.attributes.last.add_time beats: 4, beat_type: 4

      score.add_group 2, type: 'stop'

      measure1.add_pitch step: 'D', octave: 4, duration: 4, type: 'half', slur: 'start'
      measure1.add_pitch step: 'E', octave: 4, duration: 4, type: 'half', slur: 'stop'

      measure1.add_backup 8

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

      measure2.add_backup 8

      measure2.add_pitch step: 'C', octave: 5, duration: 8, type: 'whole'

      measure3.add_rest type: 'whole', duration: 8
      measure4.add_rest type: 'whole', duration: 8

      # File.open('test.musicxml', 'w') { |f| f.write(score.to_xml.string) }

      expect(score.to_xml.string.strip).to eq File.read(File.join(File.dirname(__FILE__), "musicxml_3_spec.musicxml")).strip
    end

    it 'Score with some simple notes and tuplets' do
      score = ScorePartwise.new creators: { composer: "Javier Sánchez" },
                                work_title: "Prueba de tuplets",
                                encoding_date: DateTime.new(2020, 1, 29) do

        part :p1, name: "Piano", abbreviation: "p." do
          measure do
            attributes do
              divisions 16

              key 1, fifths: 2
              clef 1, sign: 'G', line: 2
              time 1, beats: 4, beat_type: 4

              key 2, fifths: 2
              clef 2, sign: 'F', line: 4
              time 2, beats: 4, beat_type: 4
            end

            metronome beat_unit: 'quarter', per_minute: 90

            pitch 'D', octave: 4, duration: 16, type: 'quarter'
            pitch 'E', octave: 4, duration: 16, type: 'quarter'
            pitch 'F', octave: 4, duration: 16, type: 'quarter'
            pitch 'G', octave: 4, duration: 16, type: 'quarter'
          end

          measure do
            pitch 'C', octave: 4, duration: 11, type: 'quarter' do
              tuplet type: 'start', bracket: true, show_number: 'both', show_type: 'both', actual_number: 3, normal_number: 2
              time_modification actual_notes: 3, normal_notes: 2
            end
            pitch 'D', octave: 4, duration: 10, type: 'quarter' do
              time_modification actual_notes: 3, normal_notes: 2
            end
            pitch 'E', octave: 4, duration: 11, type: 'quarter' do
              tuplet type: 'stop'
              time_modification actual_notes: 3, normal_notes: 2
            end

            pitch 'C', octave: 4, duration: 16, type: 'quarter'
            pitch 'C', octave: 4, duration: 16, type: 'quarter'
          end

          measure do
            pitch 'C', octave: 4, duration: 11, type: 'quarter' do
              tuplet type: 'start', bracket: true, show_number: 'both', show_type: 'both', actual_number: 3, actual_type: 'quarter', normal_number: 4, normal_type: 'quarter'
              time_modification actual_notes: 3, normal_notes: 4
            end

            pitch 'D', octave: 4, duration: 10, type: 'quarter' do
              time_modification actual_notes: 3, normal_notes: 4
            end

            pitch 'E', octave: 4, duration: 11, type: 'quarter' do
              tuplet type: 'stop'
              time_modification actual_notes: 3, normal_notes: 4
            end
          end

          measure do
            pitch 'C', octave: 4, duration: 10, type: 'quarter' do
              tuplet type: 'start', bracket: true, show_number: 'both', show_type: 'both', actual_number: 5, actual_type: 'quarter', normal_number: 3, normal_type: 'quarter'
              time_modification actual_notes: 5, normal_notes: 3
            end

            pitch 'D', octave: 4, duration: 9, type: 'quarter' do
              time_modification actual_notes: 5, normal_notes: 3
            end

            pitch 'D', octave: 4, duration: 10, type: 'quarter' do
              time_modification actual_notes: 5, normal_notes: 3
            end

            pitch 'D', octave: 4, duration: 9, type: 'quarter' do
              time_modification actual_notes: 5, normal_notes: 3
            end

            pitch 'E', octave: 4, duration: 10, type: 'quarter' do
              tuplet type: 'stop'
              time_modification actual_notes: 5, normal_notes: 3
            end

            pitch 'C', octave: 4, duration: 16, type: 'quarter'

          end

          measure do
            pitch 'C', octave: 4, duration: 10, type: 'quarter' do
              tuplet type: 'start', bracket: true, show_number: 'both', show_type: 'both', actual_number: 3, actual_type: 'eighth', normal_number: 2, normal_type: 'eighth'
              time_modification actual_notes: 3, normal_notes: 2
            end

            pitch 'D', octave: 4, duration: 6, type: 'eighth' do
              time_modification actual_notes: 3, normal_notes: 2
              tuplet type: 'stop'
            end
          end

          measure do
            pitch 'C', octave: 4, duration: 11, type: 'quarter' do
              tuplet type: 'start', bracket: true, show_number: 'both', show_type: 'both', actual_number: 3, normal_number: 2
              time_modification actual_notes: 3, normal_notes: 2
            end
            pitch 'E', octave: 4, duration: 11, type: 'quarter' do
              tuplet type: 'stop'
              time_modification actual_notes: 3, normal_notes: 2
            end
            pitch 'C', octave: 4, duration: 16, type: 'quarter'
            pitch 'C', octave: 4, duration: 16, type: 'quarter'
          end

          measure do
            pitch 'C', octave: 4, duration: 11, type: 'quarter' do
              tuplet type: 'start', bracket: true, show_number: 'both', show_type: 'both', actual_number: 3, normal_number: 2
              time_modification actual_notes: 3, normal_notes: 2
              tuplet type: 'stop'
            end
          end

          measure do
            pitch 'C', octave: 4, duration: 13, type: 'quarter' do
              tuplet type: 'start', number: 1, bracket: true, show_number: 'both', show_type: 'both', actual_number: 5, normal_number: 4, actual_type: 'quarter', normal_type: 'quarter'
              time_modification actual_notes: 5, normal_notes: 4, normal_type: 'quarter'
            end

            pitch 'C', octave: 4, duration: 16, type: 'quarter' do
              tuplet type: 'start', number: 2, bracket: true, show_number: 'both', show_type: 'both', actual_number: 4, normal_number: 5, actual_type: 'eighth', normal_type: 'eighth'
              time_modification actual_notes: 20, normal_notes: 20, normal_type: 'quarter'
            end

            pitch 'C', octave: 4, duration: 16, type: 'quarter' do
              time_modification actual_notes: 20, normal_notes: 20, normal_type: 'quarter'
              tuplet type: 'stop', number: 2
            end

            pitch 'C', octave: 4, duration: 19, type: 'quarter', dots: 1 do
              time_modification actual_notes: 5, normal_notes: 4
              tuplet type: 'stop', number: 1
            end
          end

          measure do
            pitch 'D', octave: 4, duration: 16, type: 'quarter'

            pitch 'E', octave: 4, duration: 16, type: 'quarter'

            pitch 'F', octave: 4, duration: 13, type: 'quarter' do
              tuplet type: 'start', number: 1, bracket: true, show_number: 'both', show_type: 'both', actual_number: 5, normal_number: 4, actual_type: 'eighth', normal_type: 'eighth'
              time_modification actual_notes: 5, normal_notes: 4, normal_type: 'quarter'
            end

            pitch 'E', octave: 4, duration: 19, type: 'quarter', dots: 1 do
              time_modification actual_notes: 5, normal_notes: 4, normal_type: 'quarter'
              tuplet type: 'stop', number: 1
            end
          end

        end
      end

      puts score.to_xml.string


      File.open(File.join(File.dirname(__FILE__), "musicxml_4_spec.musicxml"), 'w') { |f| f.write(score.to_xml.string) }

      # expect(score.to_xml.string.strip).to eq File.read(File.join(File.dirname(__FILE__), "musicxml_4_spec.musicxml")).strip
    end


  end
end
