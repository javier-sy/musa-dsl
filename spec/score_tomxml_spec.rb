require 'spec_helper'
require 'musa-dsl'

RSpec.describe Musa::Datasets::Score::ToMXML do
  context 'Score with complexities to MXML generation' do

    # Gaps between events are filled with rests, and the code that does it had
    # no test: `to_mxml` raised `uninitialized constant ...ToMXML::PDV` for one
    # shape of gap only -- between two events inside the same bar (issue #69).
    # Whole-bar gaps and a bar that starts late take other paths and worked, so
    # the defect needed a particular figure to be seen at all. All four shapes
    # are covered here.
    def notes_and_rests(*events)
      score = Musa::Datasets::Score.new

      events.each do |at, duration, pitch|
        score.at(at, add: { pitch: pitch, duration: duration }.extend(Musa::Datasets::PDV))
      end

      xml = score.to_mxml(4, 24, bpm: 120, title: 'gaps',
                          parts: { p1: { name: 'Part', clefs: { g: 2 } } },
                          do_log: false).to_xml.string

      xml.scan(%r{<note>.*?</note>}m).collect do |note|
        type = note[%r{<type>(\w+)}, 1]
        note.include?('<rest') ? "rest #{type}" : "#{note[%r{<step>(\w)}, 1]}#{note[%r{<octave>(\d)}, 1]} #{type}"
      end
    end

    it 'fills a gap between two events inside the same bar' do
      expect(notes_and_rests([1r, 1/4r, 60], [1 + 1/2r, 1/4r, 64]))
        .to eq(['C4 quarter', 'rest quarter', 'E4 quarter', 'rest quarter'])
    end

    it 'fills a gap of whole bars' do
      expect(notes_and_rests([1r, 1r, 60], [3r, 1r, 64]))
        .to eq(['C4 whole', 'rest whole', 'E4 whole', 'rest whole'])
    end

    it 'fills the head of a bar whose first event starts late' do
      expect(notes_and_rests([1 + 1/2r, 1/4r, 60]))
        .to eq(['rest half', 'C4 quarter', 'rest quarter'])
    end

    it 'fills several gaps in one bar' do
      # The trailing whole rest is the empty bar to_mxml always closes with.
      expect(notes_and_rests([1r, 1/4r, 60], [1 + 1/2r, 1/4r, 64], [1 + 3/4r, 1/4r, 67]))
        .to eq(['C4 quarter', 'rest quarter', 'E4 quarter', 'G4 quarter', 'rest whole'])
    end

    it 'converts a pdv + ps with dynamics dataset score to MusicXML' do
      score = Musa::Datasets::Score.new

      score.at 1, add: { pitch: 60, duration: 1/4r }.extend(Musa::Datasets::PDV)
      score.at 1.25, add: { pitch: 60, duration: 1/4r }.extend(Musa::Datasets::PDV)
      score.at 1.50, add: { pitch: 61, duration: 1/4r }.extend(Musa::Datasets::PDV)
      score.at 1.75, add: { pitch: 60, duration: 1/4r }.extend(Musa::Datasets::PDV)
      score.at 2, add: { pitch: 62, duration: 1r }.extend(Musa::Datasets::PDV)
      score.at 1, add: { type: :crescendo, from: 4, to: 9, duration: 2 }.extend(Musa::Datasets::PS)
      score.at 3, add: { pitch: 63, duration: 1r }.extend(Musa::Datasets::PDV)
      score.at 3, add: { type: :diminuendo, from: nil, to: 4, duration: 2 }.extend(Musa::Datasets::PS)
      score.at 4, add: { pitch: 64, duration: 1r }.extend(Musa::Datasets::PDV)

      mxml = score.to_mxml(4, 24,
                           bpm: 90,
                           title: 'work title',
                           creators: { composer: 'Javier Sánchez Yeste' },
                           encoding_date: DateTime.new(2020, 7, 31),
                           parts: { piano: { name: 'Piano', abbreviation: 'pno', clefs: { g: 2, f: 4 } } },
                           do_log: false)

      # File.open(File.join(File.dirname(__FILE__), "score_tomxml_1_spec.musicxml"), 'w') { |f| f.write(mxml.to_xml.string) }

      expect(mxml.to_xml.string.strip).to eq File.read(File.join(File.dirname(__FILE__), 'score_tomxml_1_spec.musicxml')).strip
    end

    it 'manages nested scores (unfinished test case)',
       pending: 'nested scores is an advanced feature not yet fulyy implemented' do

      raise NotImplementedError, 'test case pending implementation'
    end

    it 'manages irregular durations (unfinished test case)',
       pending: 'irregular durations, when combined, are difficult to handle to generate a nice output, need more thinking' do
      score = Musa::Datasets::Score.new

      # score.at 1, add: { pitch: 60, duration: 5/16r }.extend(PDV)

      score.at 1, add: { pitch: 60, duration: 1/5r }.extend(Musa::Datasets::PDV)
      score.at 1 + 1/5r, add: { pitch: 60, duration: 1/4r }.extend(Musa::Datasets::PDV)
      score.at 1 + 1/5r + 1/4r, add: { pitch: 60, duration: 1/4r }.extend(Musa::Datasets::PDV)
      score.at 1 + 1/5r + 1/4r + 1/4r, add: { pitch: 60, duration: 3/10r }.extend(Musa::Datasets::PDV)

      mxml = score.to_mxml(4, 24,
                           bpm: 90,
                           title: 'work title',
                           creators: { composer: 'Javier Sánchez Yeste' },
                           parts: { piano: { name: 'Piano', abbreviation: 'pno', clefs: { g: 2, f: 4 } } } )

        puts mxml.to_xml.string

      # File.open(File.join(File.dirname(__FILE__), "score_tomxml_2_spec.musicxml"), 'w') { |f| f.write(mxml.to_xml.string) }

      # expect(mxml.to_xml.string.strip).to eq File.read(File.join(File.dirname(__FILE__), "score_tomxml_2_spec.musicxml")).strip

      raise NotImplementedError, 'test case pending implementation'
    end

    it 'bugfix for score render to_xml not producing output when there is only one part' do
      score = Musa::Datasets::Score.new

      score.at(1r, add: { instrument: :vln1, pitch: 84r, duration: 1+9/16r }.extend(Musa::Datasets::PDV))

      score.at(2+9/16r, add: { instrument: :vln1, pitch: 83r, duration: 1+7/16r }.extend(Musa::Datasets::PDV))

      score.at(4r, add: { instrument: :vln1, pitch: 84r, duration: 1+3/8r }.extend(Musa::Datasets::PDV))

      score.at(5+3/8r, add: { instrument: :vln1, pitch: 83r, duration: 1/4r }.extend(Musa::Datasets::PDV))


      mxml = score.to_mxml(4, 4,
                           bpm: 90,
                           title: 'Title',
                           creators: { composer: 'Composer' },
                           encoding_date: DateTime.new(2020, 11, 24),
                           parts: { vln1: { name: 'Violin 1', abbreviation: 'vln1', clefs: { g: 2 } } },
                           do_log: false)

      # f = File.join(File.dirname(__FILE__), "score_tomxml_3_spec.musicxml")
      # File.open(f, 'w') { |f| f.write(mxml.to_xml.string) }

      expect(mxml.to_xml.string.strip).to eq File.read(File.join(File.dirname(__FILE__), 'score_tomxml_3_spec.musicxml')).strip
    end
  end

  # Durations are fractions of a BAR and figures are named in fractions of a
  # WHOLE NOTE. A bar measures beats_per_bar / beat_type whole notes, so the two
  # coincide only in 4/4 -- which is why one number served for both, and why
  # everything outside 4/4 was named wrong (issue #70).
  context 'Meters other than 4/4' do
    def render(beats_per_bar, ticks_per_beat, duration, beat_type: nil)
      score = Musa::Datasets::Score.new
      score.at(1r, add: { instrument: :p, pitch: 60, duration: duration }.extend(Musa::Datasets::PDV))

      xml = score.to_mxml(beats_per_bar, ticks_per_beat, beat_type: beat_type,
                          parts: { p: { name: 'P' } }).to_xml.string
      note = xml[/<note>.*?<\/note>/m].to_s

      { divisions: xml[/<divisions>(\d+)/, 1].to_i,
        beats: xml[/<beats>(\d+)/, 1].to_i,
        beat_type: xml[/<beat-type>(\d+)/, 1].to_i,
        duration: note[/<duration>(\d+)/, 1].to_i,
        type: note[/<type>(\w+)/, 1],
        dots: note.scan('<dot').size }
    end

    it 'names a quarter of a bar by what it is in each meter' do
      # The same written duration, which sounds for a quarter of a bar in all of
      # them, and is a different figure in each.
      expect(render(4, 24, 1/4r).slice(:duration, :type, :dots))
        .to eq(duration: 24, type: 'quarter', dots: 0)

      expect(render(3, 24, 1/4r).slice(:duration, :type, :dots))
        .to eq(duration: 18, type: 'eighth', dots: 1)   # 18/24 of a quarter

      expect(render(2, 24, 1/4r).slice(:duration, :type, :dots))
        .to eq(duration: 12, type: 'eighth', dots: 0)

      expect(render(6, 24, 1/4r).slice(:duration, :type, :dots))
        .to eq(duration: 36, type: 'quarter', dots: 1)
    end

    it 'writes a real quarter note in every meter, without calling it a tuplet' do
      # A quarter note is a third of a 3/4 bar. That used to raise
      # NotImplementedError: read as a fraction of a whole note, a third is a
      # triplet.
      [[4, 1/4r], [3, 1/3r], [2, 1/2r], [6, 1/6r]].each do |beats_per_bar, duration|
        expect(render(beats_per_bar, 24, duration).slice(:duration, :type, :dots))
          .to eq({ duration: 24, type: 'quarter', dots: 0 }), "in #{beats_per_bar}/4"
      end
    end

    it 'writes the bar itself as the figure the bar is' do
      expect(render(4, 24, 1r).slice(:type, :dots)).to eq(type: 'whole', dots: 0)
      expect(render(3, 24, 1r).slice(:type, :dots)).to eq(type: 'half', dots: 1)
      expect(render(6, 24, 1r, beat_type: 8).slice(:type, :dots)).to eq(type: 'half', dots: 1)
    end

    it 'takes the beat type, so 6/8 is a 6/8 and its beat is an eighth' do
      result = render(6, 24, 1/6r, beat_type: 8)

      expect(result[:beats]).to eq(6)
      expect(result[:beat_type]).to eq(8)

      # MusicXML counts divisions per QUARTER, and in 6/8 a quarter holds two
      # beats of 24 ticks.
      expect(result[:divisions]).to eq(48)
      expect(result.slice(:duration, :type, :dots)).to eq(duration: 24, type: 'eighth', dots: 0)
    end

    it 'refuses a grid that cannot be expressed in whole divisions' do
      expect { render(2, 25, 1/2r, beat_type: 2) }
        .to raise_error(ArgumentError, /divisions must be whole/)
    end
  end
end
