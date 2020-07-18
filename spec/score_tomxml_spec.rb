require 'spec_helper'
require 'musa-dsl'

include Musa::Datasets::Score::ToMXML
include Musa::Datasets

RSpec.describe Musa::Datasets::Score::ToMXML do
  context 'Score to MusicXML time translations' do

    it 'converts durations to note type, dots and tuplet ratios' do
      l = [1/4r, 1, 2, 1/2r, 1/3r, 3/8r, 1/5r, 7/16r, 1/15r, 17/15r, 18/15r, 19/15r]
      r = []

      l.each do |d|
        decomposed = decompose_as_sum_of_simple_durations(d)
        integrated = integrate_as_dotteable_durations(decomposed)
        begin
          extra = integrated.collect { |i| type_and_dots_and_tuplet_ratio(i)}
        rescue ArgumentError => x
          extra = x
        end

        r << { s: d, d: decomposed, i: integrated, e: extra }
      end

      expect(r).to eq \
      [{ s: 1/4r, d: [1/4r], i: [1/4r], e: [["quarter", 0, 1]] },
       { s: 1, d: [1], i: [1], e: [["whole", 0, 1]] },
       { s: 2, d: [2], i: [2], e: [["breve", 0, 1]] },
       { s: 1/2r, d: [1/2r], i: [1/2r], e: [["half", 0, 1]] },
       { s: 1/3r, d: [1/3r], i: [1/3r], e: [["half", 0, 3/2r ]] },
       { s: 3/8r, d: [1/4r, 1/8r], i: [3/8r], e: [["quarter", 1, 1]] },
       { s: 1/5r, d: [1/5r], i: [1/5r], e: [["quarter", 0, 5/4r ]] },
       { s: 7/16r,d: [1/4r, 1/8r, 1/16r], i: [7/16r], e: [["quarter", 2, 1]] },
       { s: 1/15r, d: [1/15r], i: [1/15r], e: [["eighth", 0, 15/8r]] },
       { s: 17/15r, d: [1, 2/15r], i: [1, 2/15r], e: [["whole", 0, 1], ["quarter", 0, 15/8r]] },
       { s: 6/5r, d: [1, 1/5r], i: [1, 1/5r], e: [["whole", 0, 1], ["quarter", 0, 5/4r]] },
       { s: 19/15r, d: [1, 1/5r, 1/15r], i: [1, 1/5r, 1/15r], e: [["whole", 0, 1], ["quarter", 0, 5/4r], ["eighth", 0, 15/8r]]}]
    end
  end

  context 'Score with complexities to MXML generation' do
    it 'converts a pdv + ps with dynamics dataset score to MusicXML (unfinished test case)' do
      score = Score.new(0.125)

      score.at 1, add: { pitch: 60, duration: 1/4r }.extend(PDV)
      score.at 1.25, add: { pitch: 60, duration: 1/4r }.extend(PDV)
      score.at 1.50, add: { pitch: 61, duration: 1/4r }.extend(PDV)
      score.at 1.75, add: { pitch: 60, duration: 1/4r }.extend(PDV)
      score.at 2, add: { pitch: 62, duration: 1r }.extend(PDV)
      score.at 1, add: { type: :crescendo, from: 30, to: 100, duration: 2 }.extend(PS)
      score.at 3, add: { pitch: 63, duration: 1r }.extend(PDV)
      score.at 3, add: { type: :diminuendo, from: nil, to: 20, duration: 2 }.extend(PS)
      score.at 4, add: { pitch: 64, duration: 1r }.extend(PDV)

      mxml = score.to_mxml(4, 24,
                           bpm: 90,
                           title: 'work title',
                           creators: { composer: 'Javier Sánchez Yeste' },
                           parts: { piano: { name: 'Piano', abbreviation: 'pno', clefs: { g: 2, f: 4 } } } )

      # puts mxml.to_xml.string

      # File.open('score_spec_test.musicxml', 'w') { |f| f.write(mxml.to_xml.string) }

      # expect(1).to eq 0 # TODO unfinished test case
    end

    it 'manages irregular durations (unfinished test case)' do
      score = Score.new(1/32r)

      score.at 1, add: { pitch: 60, duration: 5/16r }.extend(PDV)

      mxml = score.to_mxml(4, 24,
                           bpm: 90,
                           title: 'work title',
                           creators: { composer: 'Javier Sánchez Yeste' },
                           parts: { piano: { name: 'Piano', abbreviation: 'pno', clefs: { g: 2, f: 4 } } } )

        # puts mxml.to_xml.string

        # File.open('score_spec_test.musicxml', 'w') { |f| f.write(mxml.to_xml.string) }

      # expect(1).to eq 0 # TODO unfinished test case
    end
  end
end
