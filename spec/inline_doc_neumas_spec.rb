require 'spec_helper'
require 'musa-dsl'

using Musa::Extension::Neumas

RSpec.describe 'Neumas Inline Documentation Examples' do
  include Musa::All

  context 'Neumas module (neumas.rb)' do
    using Musa::Extension::Neumas

    it 'example from line 151 - Basic neuma parsing' do

      # Parse simple melody notation
      melody = "(0) (+2) (+2) (-1) (0)".to_neumas

      # Iterate through parsed neumas
      gdvd_values = []
      melody.i.to_a.each do |neuma|
        gdvd_values << neuma[:gdvd]
      end

      expect(gdvd_values).not_to be_empty
      expect(gdvd_values.size).to eq(5)
    end

    it 'example from line 162 - Parse with duration and ornaments' do
      # Neuma with varied durations and ornaments
      notation = "(+2_) (+2_2) (+1_/2) (+2_ tr)"
      neumas = notation.to_neumas

      # Access differential values
      first_neuma = neumas.i.to_a.first
      expect(first_neuma[:gdvd][:delta_grade]).to eq(2)
      expect(first_neuma[:gdvd][:delta_sharps]).to eq(-1)
    end

    it 'example from line 175 - Create parallel voices' do
      # Define individual voice lines
      soprano = "(0) (+2) (+4) (+5) (+7)"
      alto = "(-2) (0) (+2) (+3) (+5)"
      tenor = "(-5) (-3) (-1) (0) (+2)"
      bass = "(-9) (-7) (-5) (-4) (-2)"

      # Combine into parallel (polyphonic) structure
      satb = soprano | alto | tenor | bass

      # Verify structure
      expect(satb[:kind]).to eq(:parallel)
      expect(satb[:parallel].size).to eq(4)
    end

    it 'example from line 191 - Compose sections from arrays' do
      # Define musical sections
      verse = "(0) (+2) (+2) (-1) (0)"
      chorus = "(+7) (+5) (+7) (+5) (+4)"
      bridge = "(+2) (+4) (+5) (+4) (+2)"

      # Create song structure (verse-chorus-verse-chorus-bridge-chorus)
      song = [verse, chorus, verse, chorus, bridge, chorus].to_neumas

      # Count total neumas
      total_count = song.i.to_a.size
      expect(total_count).to be > 0
    end

    it 'example from line 269 - Create parallel from neumas' do
      melody = "(0) (+2) (+4)"
      bass = "(-7) (-5) (-3)"
      harmony = melody | bass

      expect(harmony[:kind]).to eq(:parallel)
      expect(harmony[:parallel].size).to eq(2)
    end

    it 'example from line 274 - Chain multiple parallels' do
      soprano = "(0) (+2) (+4)"
      alto = "(-2) (0) (+2)"
      tenor = "(-5) (-3) (-1)"
      bass = "(-9) (-7) (-5)"

      satb = soprano | alto | tenor | bass

      expect(satb[:kind]).to eq(:parallel)
      expect(satb[:parallel].size).to eq(4)
    end
  end

  context 'Array refinement (array-to-neumas.rb)' do
    using Musa::Extension::Neumas

    it 'example from line 44 - Sequential phrases' do
      melody = [
        "(0) (+2) (+4) (+5)",    # Phrase A
        "(+7) (+5) (+4) (+2)",   # Phrase B
        "(0) (-2) (-4) (-5)"     # Phrase C
      ].to_neumas

      expect(melody).to respond_to(:i)
    end

    it 'example from line 52 - Mixed element types' do
      intro = "(0) (+2) (+4)".to_neumas
      verse = "(0) (+2) (+2) (-1) (0)"
      chorus = "(+7) (+5) (+7)"

      song = [intro, verse, chorus].to_neumas

      expect(song).to respond_to(:i)
    end

    it 'example from line 62 - Single element' do
      # Single element returns converted element directly (not merged)
      single = ["(0) (+2) (+4)"].to_neumas

      expect(single).to respond_to(:i)
    end

    it 'example from line 98 - Convert string array' do
      phrases = [
        "(0) (+2) (+4)",
        "(+5) (+7)"
      ].to_neumas

      # Returns MERGE of two parsed series
      expect(phrases).to respond_to(:i)
    end

    it 'example from line 107 - Mixed types' do
      existing = "(0) (+2)".to_neumas
      combined = [existing, "(+4) (+5)"].to_neumas

      expect(combined).to respond_to(:i)
    end

    it 'example from line 113 - Single element' do
      single = ["(0) (+2) (+4)"].to_neumas
      # Returns parsed series directly (not merged)

      expect(single).to respond_to(:i)
    end
  end

  context 'Decoder infrastructure (neuma-decoder.rb)' do
    it 'example from line 92 - Basic decoder creation' do
      # Create a mock scale object
      scale = Object.new
      decoder = Musa::Neumas::Decoders::NeumaDecoder.new(
        scale,
        base_duration: 1/4r
      )

      # Decoder maintains state for differential processing
      expect(decoder.base[:grade]).to eq(0)
      expect(decoder.base[:duration]).to eq(1/4r)
    end

    it 'example from line 215 - Stateful decoding' do
      decoder = Musa::Neumas::Decoders::NeumaDifferentialDecoder.new(
        base_duration: 1/4r
      )

      # Create mock GDVD object
      gdvd1 = Object.new
      def gdvd1.clone; self; end
      def gdvd1.base_duration=(val); @bd = val; end

      result = decoder.decode(gdvd1)
      # Returns processed GDVD with base_duration set
      expect(result).to eq(gdvd1)
    end

    it 'example from line 235 - Create decoder with base state' do
      base_state = { grade: 0, octave: 0, duration: 1/4r, velocity: 1 }
      decoder = Musa::Neumas::Decoders::Decoder.new(base_state)

      # Decoder maintains state
      expect(decoder.base[:grade]).to eq(0)
      expect(decoder.base[:duration]).to eq(1/4r)
    end

    it 'example from line 299 - Create decoder with transcriptor' do
      base_state = { grade: 0, octave: 0, duration: 1/4r, velocity: 1 }

      # Create mock transcriptor
      transcriptor = Object.new
      def transcriptor.transcript(gdv); [gdv, gdv.clone]; end

      decoder = Musa::Neumas::Decoders::Decoder.new(
        base_state,
        transcriptor: transcriptor
      )

      # Transcriptor can expand events (e.g., ornaments)
      expect(decoder.transcriptor).to eq(transcriptor)
    end
  end

  context 'NeumaDecoder (neuma-gdv-decoder.rb)' do
    it 'example from line 39 - Create decoder with mock scale' do
      # Create a simple mock scale object
      scale = Object.new
      decoder = Musa::Neumas::Decoders::NeumaDecoder.new(
        scale,
        base_duration: 1/4r
      )

      # Decoder properties
      expect(decoder.scale).to eq(scale)
      expect(decoder.base_duration).to eq(1/4r)
    end

    it 'example from line 51 - Using with transcriptor' do
      scale = Object.new

      # Create mock transcriptor
      transcriptor = Object.new
      def transcriptor.transcript(gdv); [gdv]; end

      decoder = Musa::Neumas::Decoders::NeumaDecoder.new(
        scale,
        base_duration: 1/4r,
        transcriptor: transcriptor
      )

      # Transcriptor will process decoded events
      expect(decoder.transcriptor).to eq(transcriptor)
    end

    it 'example from line 107 - Create decoder with scale' do
      scale = Object.new
      decoder = Musa::Neumas::Decoders::NeumaDecoder.new(
        scale,
        base_duration: 1/4r
      )

      # Check initial state
      expect(decoder.base[:grade]).to eq(0)
      expect(decoder.base[:duration]).to eq(1/4r)
    end

    it 'example from line 118 - Custom initial state' do
      scale = Object.new
      decoder = Musa::Neumas::Decoders::NeumaDecoder.new(
        scale,
        base: { grade: 2, octave: 1, duration: 1/8r, velocity: 0.8 }
      )

      # Verify custom state
      expect(decoder.base[:grade]).to eq(2)
      expect(decoder.base[:octave]).to eq(1)
    end
  end

  context 'NeumaDifferentialDecoder (neuma-gdvd-decoder.rb)' do
    using Musa::Extension::Neumas

    it 'example from line 31 - Process GDVD' do
      decoder = Musa::Neumas::Decoders::NeumaDifferentialDecoder.new(
        base_duration: 1/4r
      )

      # Create mock GDVD object
      gdvd = Object.new
      def gdvd.clone; self; end
      def gdvd.base_duration=(val); @bd = val; @bd; end
      def gdvd.base_duration; @bd; end

      result = decoder.decode(gdvd)
      # Still differential, not converted to absolute
      expect(result).to eq(gdvd)
      expect(result.base_duration).to eq(1/4r)
    end

    it 'example from line 39 - Intermediate processing workflow' do
      # Process neumas in differential format before final conversion
      neumas = "(0) (+2) (+2) (-1) (0)".to_neumas
      differential_decoder = Musa::Neumas::Decoders::NeumaDifferentialDecoder.new

      # Process each neuma (keeping differential format)
      gdvds = []
      neumas.i.to_a.each do |neuma|
        gdvd = differential_decoder.decode(neuma[:gdvd])
        gdvds << gdvd
      end

      # GDVD objects still have differential values
      # Can transform them before converting to absolute GDV
      expect(gdvds).not_to be_empty
      expect(gdvds.size).to eq(5)
    end

    it 'example from line 85 - Create decoder with eighth note base' do
      decoder = Musa::Neumas::Decoders::NeumaDifferentialDecoder.new(base_duration: 1/8r)

      expect(decoder).to be_a(Musa::Neumas::Decoders::NeumaDifferentialDecoder)
    end

    it 'example from line 101 - Process differential neuma' do
      decoder = Musa::Neumas::Decoders::NeumaDifferentialDecoder.new(base_duration: 1/4r)

      # Create mock GDVD object
      gdvd = Object.new
      def gdvd.clone; self; end
      def gdvd.base_duration=(val); @bd = val; end
      def gdvd.base_duration; @bd; end

      result = decoder.process(gdvd)
      expect(result.base_duration).to eq(1/4r)
    end
  end

  context 'String refinement (string-to-neumas.rb)' do
    using Musa::Extension::Neumas

    it 'example from line 80 - Basic parsing' do
      melody = "(0) (+2) (+2) (-1) (0)".to_neumas
      # Returns series of GDVD hashes

      expect(melody).to respond_to(:i)
    end

    it 'example from line 85 - With ornaments' do
      ornate = "(+2tr) (+3mor) (-1st)".to_neumas

      expect(ornate).to respond_to(:i)
    end

    it 'example from line 90 - Parallel voices' do
      harmony = "(0) (+2) (+4)" | "(+7) (+5) (+7)"

      expect(harmony[:kind]).to eq(:parallel)
    end

    it 'example from line 95 - Convert to generative node' do
      node = "(0) (+2) (+2) (-1) (0)".nn  # to_neumas_to_node

      expect(node).to respond_to(:next)
    end

    it 'example from line 133 - Parse simple melody' do
      neumas = "(0) (+2) (+2) (-1) (0)".to_neumas

      expect(neumas).to respond_to(:i)
    end

    it 'example from line 137 - Parse with immediate decoding' do
      # Create a simple decoder
      decoder = Musa::Neumas::Decoders::NeumaDifferentialDecoder.new
      result = "(0) (+2) (+2) (-1) (0)".to_neumas(decode_with: decoder)

      expect(result).to respond_to(:i)
    end

    it 'example from line 142 - Parse with debug' do
      neumas = "(0) (+2) (+2)".to_neumas(debug: false)

      expect(neumas).to respond_to(:i)
    end

    it 'example from line 158 - Convert to node for generative grammar' do
      node = "(0) (+2) (+2) (-1) (0)".to_neumas_to_node

      expect(node).to respond_to(:next)
    end

    it 'example from line 179 - Two-voice harmony' do
      melody = "(0) (+2) (+4) (+5)"
      bass = "(-7) (-5) (-3) (-1)"
      harmony = melody | bass

      expect(harmony[:kind]).to eq(:parallel)
      expect(harmony[:parallel].size).to eq(2)
    end
  end

  context 'Integration tests' do
    using Musa::Extension::Neumas

    it 'parses and processes complete neuma notation with using refinement' do
      # Parse complex notation
      melody = "(+2_) (+2_2) (+1_/2) (+2_)".to_neumas

      # Verify series structure
      expect(melody).to respond_to(:i)

      # Count neumas
      neumas_array = melody.i.to_a
      expect(neumas_array.size).to eq(4)

      # Verify GDVD structure
      first_neuma = neumas_array.first
      expect(first_neuma).to have_key(:gdvd)
      expect(first_neuma[:gdvd][:delta_grade]).to eq(2)
    end

    it 'creates and processes parallel structures' do
      voice1 = "(0) (+2) (+4)"
      voice2 = "(+7) (+5) (+7)"

      parallel = voice1 | voice2

      expect(parallel).to be_a(Hash)
      expect(parallel[:kind]).to eq(:parallel)
      expect(parallel[:parallel]).to be_an(Array)
      expect(parallel[:parallel].size).to eq(2)

      # Each voice should be a serie
      parallel[:parallel].each do |voice|
        expect(voice[:kind]).to eq(:serie)
        expect(voice[:serie]).to respond_to(:i)
      end
    end

    it 'uses decoder to maintain differential state' do
      decoder = Musa::Neumas::Decoders::NeumaDifferentialDecoder.new(
        base_duration: 1/4r
      )

      # Create multiple mock GDVD objects
      gdvd1 = Object.new
      def gdvd1.clone; self; end
      def gdvd1.base_duration=(val); @bd = val; end

      gdvd2 = Object.new
      def gdvd2.clone; self; end
      def gdvd2.base_duration=(val); @bd = val; end

      result1 = decoder.decode(gdvd1)
      result2 = decoder.decode(gdvd2)

      expect(result1).to eq(gdvd1)
      expect(result2).to eq(gdvd2)
    end

    it 'creates subcontexts for independent decoding' do
      scale = Object.new
      decoder = Musa::Neumas::Decoders::NeumaDecoder.new(
        scale,
        base_duration: 1/4r
      )

      subcontext = decoder.subcontext

      expect(subcontext).to be_a(Musa::Neumas::Decoders::NeumaDecoder)
      expect(subcontext.scale).to eq(scale)
      expect(subcontext.base_duration).to eq(1/4r)
    end

    it 'verifies array to_neumas merges multiple elements' do
      phrases = ["(0) (+2)", "(+4) (+5)", "(+7)"].to_neumas

      # Should merge all phrases into one series
      expect(phrases).to respond_to(:i)

      # Verify all elements are present
      all_neumas = phrases.i.to_a
      expect(all_neumas.size).to be >= 3
    end
  end
end
