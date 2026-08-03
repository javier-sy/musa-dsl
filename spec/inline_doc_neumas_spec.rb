require 'spec_helper'
require 'musa-dsl'

using Musa::Extension::Neumas

RSpec.describe 'Neumas Inline Documentation Examples' do
  include Musa::All

  # The grades a parsed neumas serie yields, absolute or relative. Lets the
  # examples assert WHAT was parsed instead of merely that something was.
  def grades(serie)
    serie.i.to_a(recursive: true).map { |e| e[:gdvd][:abs_grade] || e[:gdvd][:delta_grade] }
  end

  context 'Neumas module (neumas.rb)' do
    using Musa::Extension::Neumas

    it 'Basic neuma parsing' do

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

    it 'Parse with duration and ornaments' do
      # Neuma with varied durations and ornaments
      notation = "(+2_) (+2_2) (+1_/2) (+2_ tr)"
      neumas = notation.to_neumas

      # Access differential values
      first_neuma = neumas.i.to_a.first
      expect(first_neuma[:gdvd][:delta_grade]).to eq(2)
      expect(first_neuma[:gdvd][:delta_sharps]).to eq(-1)
    end

    it 'Compose sections from arrays' do
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

    it '@example Chain multiple parallels' do
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

    it '@example Sequential phrases' do
      melody = [
        "(0) (+2) (+4) (+5)",    # Phrase A
        "(+7) (+5) (+4) (+2)",   # Phrase B
        "(0) (-2) (-4) (-5)"     # Phrase C
      ].to_neumas

      expect(grades(melody)).to eq [0, 2, 4, 5, 7, 5, 4, 2, 0, -2, -4, -5]
    end

    it '@example Mixed element types' do
      intro = "(0) (+2) (+4)".to_neumas
      verse = "(0) (+2) (+2) (-1) (0)"
      chorus = "(+7) (+5) (+7)"

      song = [intro, verse, chorus].to_neumas

      expect(grades(song)).to eq [0, 2, 4, 0, 2, 2, -1, 0, 7, 5, 7]
    end

    it '@example Single element' do
      # Single element returns converted element directly (not merged)
      single = ["(0) (+2) (+4)"].to_neumas

      # "directly" is observable: the same class a bare string parses to
      expect(single.class).to eq "(0) (+2) (+4)".to_neumas.class
      expect(grades(single)).to eq [0, 2, 4]
    end

    it '@example Convert string array' do
      phrases = [
        "(0) (+2) (+4)",
        "(+5) (+7)"
      ].to_neumas

      # Returns MERGE of two parsed series
      expect(grades(phrases)).to eq [0, 2, 4, 5, 7]
    end

    it '@example Mixed types' do
      existing = "(0) (+2)".to_neumas
      combined = [existing, "(+4) (+5)"].to_neumas

      expect(grades(combined)).to eq [0, 2, 4, 5]
    end

    it '@example Single element' do
      single = ["(0) (+2) (+4)"].to_neumas
      # Returns parsed series directly (not merged)

      expect(grades(single)).to eq [0, 2, 4]
    end
  end

  context 'Decoder infrastructure (neuma-decoder.rb)' do

    it '@example Stateful decoding' do
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

    it '@example Create decoder with transcriptor' do
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

    it '@example Using with transcriptor' do
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

  end

  context 'NeumaDifferentialDecoder (neuma-gdvd-decoder.rb)' do
    using Musa::Extension::Neumas

    it '@example Intermediate processing workflow' do
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

    it '@example Create decoder with eighth note base' do
      decoder = Musa::Neumas::Decoders::NeumaDifferentialDecoder.new(base_duration: 1/8r)

      # The base duration is what the decoder is for: it travels with every
      # event it decodes. Asserting the class asserted nothing about it.
      decoded = decoder.decode({ delta_grade: 2 }.extend(Musa::Datasets::GDVd))

      expect(decoded).to eq({ delta_grade: 2 })
      expect(decoded.base_duration).to eq(1/8r)
    end

  end

  context 'String refinement (string-to-neumas.rb)' do
    using Musa::Extension::Neumas

    it '@example Basic parsing' do
      melody = "(0) (+2) (+2) (-1) (0)".to_neumas
      # Returns series of GDVD hashes

      expect(melody.i.to_a(recursive: true).first).to eq({ kind: :gdvd, gdvd: { abs_grade: 0 } })
      expect(grades(melody)).to eq [0, 2, 2, -1, 0]
    end

    it '@example Convert to generative node' do
      node = "(0) (+2) (+2) (-1) (0)".nn  # to_neumas_to_node

      # A single-option final node wrapping the parsed serie: the whole phrase is
      # one alternative, ready to be combined with | and + in a grammar.
      # (The node class lives in a private namespace, so the shape is the claim.)
      expect(node.options.size).to eq(1)
      expect(node.options.first.size).to eq(1)
      expect(node.options.first.first.i.to_a.collect { |e| e[:gdvd] })
        .to eq([{ abs_grade: 0 }, { delta_grade: 2 }, { delta_grade: 2 },
                { delta_grade: -1 }, { abs_grade: 0 }])
    end

    it '@example Parse simple melody' do
      neumas = "(0) (+2) (+2) (-1) (0)".to_neumas

      expect(grades(neumas)).to eq [0, 2, 2, -1, 0]
    end

    it '@example Parse with immediate decoding' do
      # Create a simple decoder
      decoder = Musa::Neumas::Decoders::NeumaDifferentialDecoder.new
      result = "(0) (+2) (+2) (-1) (0)".to_neumas(decode_with: decoder)

      # Decoding unwraps the { kind:, gdvd: } envelope: the elements ARE the gdvd
      expect(result.i.to_a(recursive: true))
        .to eq [{ abs_grade: 0 }, { delta_grade: 2 }, { delta_grade: 2 }, { delta_grade: -1 }, { abs_grade: 0 }]
    end

    it '@example Parse with debug' do
      neumas = "(0) (+2) (+2)".to_neumas(debug: false)

      expect(grades(neumas)).to eq [0, 2, 2]
    end

    it '@example Convert to node for generative grammar' do
      node = "(0) (+2) (+2) (-1) (0)".to_neumas_to_node

      expect(node.options.size).to eq(1)
      expect(node.options.first.first.i.to_a.collect { |e| e[:gdvd] })
        .to eq([{ abs_grade: 0 }, { delta_grade: 2 }, { delta_grade: 2 },
                { delta_grade: -1 }, { abs_grade: 0 }])
    end

  end

  context 'Integration tests' do
    using Musa::Extension::Neumas

    it 'parses and processes complete neuma notation with using refinement' do
      # Parse complex notation
      melody = "(+2_) (+2_2) (+1_/2) (+2_)".to_neumas

      # `_` after a grade is a flat, and repeating it flattens further: `+2__`
      # is a double flat. But `_` between digits is the digit separator Ruby
      # uses, so `+2_2` is the grade +22, NOT +2 twice flattened -- which is
      # what this line records, and why it reads as it does.
      expect(melody.i.to_a.collect { |e| e[:gdvd] })
        .to eq([{ delta_grade: 2, delta_sharps: -1 },
                { delta_grade: 22 },
                { delta_grade: 1, delta_sharps: -1, factor_duration: 1/2r },
                { delta_grade: 2, delta_sharps: -1 }])

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

      # Each voice is a serie, and keeps its own line: the first is absolute at
      # its head and differential afterwards, the second entirely differential.
      expect(parallel[:parallel].collect { |voice| voice[:kind] }).to eq([:serie, :serie])
      expect(parallel[:parallel].collect { |voice| voice[:serie].i.to_a.collect { |e| e[:gdvd] } })
        .to eq([[{ abs_grade: 0 }, { delta_grade: 2 }, { delta_grade: 4 }],
                [{ delta_grade: 7 }, { delta_grade: 5 }, { delta_grade: 7 }]])
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

      # The three phrases become one sequence, in order and complete.
      expect(phrases.i.to_a.collect { |e| e[:gdvd] })
        .to eq([{ abs_grade: 0 }, { delta_grade: 2 }, { delta_grade: 4 },
                { delta_grade: 5 }, { delta_grade: 7 }])

      all_neumas = phrases.i.to_a
      expect(all_neumas.size).to eq(5)
    end
  end
end
