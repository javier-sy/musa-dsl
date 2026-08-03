require 'spec_helper'
require 'musa-dsl'

RSpec.describe 'MusicXML Builder Inline Documentation Examples' do

  context 'Part (part.rb)' do
  end

  context 'Time (attributes.rb)' do

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

  context 'Forward (backup-forward.rb)' do
  end

  context 'Metronome (direction.rb)' do
  end

  context 'Dynamics (direction.rb)' do
  end

  context 'PartGroup (part-group.rb)' do

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
