require 'spec_helper'
require 'musa-dsl'

include Musa::Datasets::Score::ToMXML
include Musa::Datasets

RSpec.describe Musa::Datasets::Score::ToMXML do
  context 'Score with complexities to MXML generation' do

    it 'converts a pdv + ps with dynamics dataset score to MusicXML' do
      score = Score.new

      score.at 1, add: { pitch: 60, duration: 1/4r }.extend(PDV)
      score.at 1.25, add: { pitch: 60, duration: 1/4r }.extend(PDV)
      score.at 1.50, add: { pitch: 61, duration: 1/4r }.extend(PDV)
      score.at 1.75, add: { pitch: 60, duration: 1/4r }.extend(PDV)
      score.at 2, add: { pitch: 62, duration: 1r }.extend(PDV)
      score.at 1, add: { type: :crescendo, from: 4, to: 9, duration: 2 }.extend(PS)
      score.at 3, add: { pitch: 63, duration: 1r }.extend(PDV)
      score.at 3, add: { type: :diminuendo, from: nil, to: 4, duration: 2 }.extend(PS)
      score.at 4, add: { pitch: 64, duration: 1r }.extend(PDV)

      mxml = score.to_mxml(4, 24,
                           bpm: 90,
                           title: 'work title',
                           creators: { composer: 'Javier Sánchez Yeste' },
                           encoding_date: DateTime.new(2020, 7, 31),
                           parts: { piano: { name: 'Piano', abbreviation: 'pno', clefs: { g: 2, f: 4 } } },
                           do_log: false)

      # File.open(File.join(File.dirname(__FILE__), "score_tomxml_1_spec.musicxml"), 'w') { |f| f.write(mxml.to_xml.string) }

      expect(mxml.to_xml.string.strip).to eq File.read(File.join(File.dirname(__FILE__), "score_tomxml_1_spec.musicxml")).strip
    end

    it 'manages nested scores (unfinished test case)', pending: true do
      expect(1).to eq 0 # TODO unfinished test case
    end

    it 'manages irregular durations (unfinished test case)', pending: true do
      score = Score.new

      # score.at 1, add: { pitch: 60, duration: 5/16r }.extend(PDV)

      score.at 1, add: { pitch: 60, duration: 1/5r }.extend(PDV)
      score.at 1 + 1/5r, add: { pitch: 60, duration: 1/4r }.extend(PDV)
      score.at 1 + 1/5r + 1/4r, add: { pitch: 60, duration: 1/4r }.extend(PDV)
      score.at 1 + 1/5r + 1/4r + 1/4r, add: { pitch: 60, duration: 3/10r }.extend(PDV)

      mxml = score.to_mxml(4, 24,
                           bpm: 90,
                           title: 'work title',
                           creators: { composer: 'Javier Sánchez Yeste' },
                           parts: { piano: { name: 'Piano', abbreviation: 'pno', clefs: { g: 2, f: 4 } } } )

        puts mxml.to_xml.string

      # File.open(File.join(File.dirname(__FILE__), "score_tomxml_2_spec.musicxml"), 'w') { |f| f.write(mxml.to_xml.string) }

      # expect(mxml.to_xml.string.strip).to eq File.read(File.join(File.dirname(__FILE__), "score_tomxml_2_spec.musicxml")).strip

      expect(1).to eq 0 # TODO unfinished test case
    end

    it 'bugfix for score render to_xml not producing output when there is only one part' do
      score = Score.new

      score.at(1r, add: { instrument: :vln1, pitch: 84r, duration: 1+9/16r }.extend(PDV))

      score.at(2+9/16r, add: { instrument: :vln1, pitch: 83r, duration: 1+7/16r }.extend(PDV))

      score.at(4r, add: { instrument: :vln1, pitch: 84r, duration: 1+3/8r }.extend(PDV))

      score.at(5+3/8r, add: { instrument: :vln1, pitch: 83r, duration: 1/4r }.extend(PDV))


      mxml = score.to_mxml(4, 4,
                           bpm: 90,
                           title: 'Title',
                           creators: { composer: 'Composer' },
                           encoding_date: DateTime.new(2020, 11, 24),
                           parts: { vln1: { name: 'Violin 1', abbreviation: 'vln1', clefs: { g: 2 } } },
                           do_log: false)

      # f = File.join(File.dirname(__FILE__), "score_tomxml_3_spec.musicxml")
      # File.open(f, 'w') { |f| f.write(mxml.to_xml.string) }

      expect(mxml.to_xml.string.strip).to eq File.read(File.join(File.dirname(__FILE__), "score_tomxml_3_spec.musicxml")).strip
    end
  end
end
