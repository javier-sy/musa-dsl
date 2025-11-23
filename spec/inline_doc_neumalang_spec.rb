require 'spec_helper'
require 'musa-dsl'

RSpec.describe 'Neumalang Inline Documentation Examples' do
  include Musa::All
  using Musa::Extension::Neumas

  context 'Neumalang module documentation (neumalang.rb)' do
    it 'example from line 145 - Basic parsing (simple melody)' do
      neumas = Musa::Neumalang::Neumalang.parse("(0) (+2) (+2) (-1) (0)")
      # Returns serie of GDVD neuma objects

      # Access the series
      expect(neumas.i.to_a.size).to eq(5)
      expect(neumas.i.to_a[0][:gdvd][:abs_grade]).to eq(0)
      expect(neumas.i.to_a[1][:gdvd][:delta_grade]).to eq(2)
    end

    it 'example from line 154 - With decoder' do
      scale = Musa::Scales::Scales.et12[440.0].major[60]
      decoder = Musa::Neumas::Decoders::NeumaDecoder.new(
        scale,
        base_duration: 1/4r
      )

      gdvs = Musa::Neumalang::Neumalang.parse(
        "(0) (+2) (+2) (-1) (0)",
        decode_with: decoder
      )
      # Returns serie of GDV events

      # Verify GDV format (decoded from GDVD)
      gdv_array = gdvs.i.to_a
      expect(gdv_array.size).to eq(5)
      # First note should have grade 0
      expect(gdv_array[0][:grade]).to eq(0)
      # Duration should be base_duration (1/4)
      expect(gdv_array[0][:duration]).to eq(1/4r)
    end

    it 'example from line 937 - Parse simple notation' do
      neumas = Musa::Neumalang::Neumalang.parse("(0) (+2) (+2) (-1) (0)")
      # => Serie of GDVD neuma objects

      expect(neumas).to respond_to(:i)
      expect(neumas.i.to_a.size).to eq(5)
      expect(neumas.i.to_a[0][:kind]).to eq(:gdvd)
    end

    it 'example from line 941 - Parse with decoder (immediate GDV conversion)' do
      scale = Musa::Scales::Scales.et12[440.0].major[60]
      decoder = Musa::Neumas::Decoders::NeumaDecoder.new(
        scale,
        base_duration: 1/4r
      )

      gdvs = Musa::Neumalang::Neumalang.parse(
        "(0) (+2) (+2) (-1) (0)",
        decode_with: decoder
      )
      # => Serie of GDV events ready for playback

      gdv_array = gdvs.i.to_a
      expect(gdv_array.size).to eq(5)

      # Should be GDV format (not GDVD)
      expect(gdv_array[0]).to have_key(:grade)
      expect(gdv_array[0]).to have_key(:duration)
      expect(gdv_array[0]).to have_key(:velocity)
    end

    it 'example from line 954 - Parse file' do
      # Create temporary file
      require 'tempfile'

      file = Tempfile.new(['melody', '.neuma'])
      begin
        file.write("(0) (+2) (+4) (+5) (+7)")
        file.close

        neumas = Musa::Neumalang::Neumalang.parse(File.open(file.path))

        neuma_array = neumas.i.to_a
        expect(neuma_array.size).to eq(5)
        expect(neuma_array[0][:gdvd][:abs_grade]).to eq(0)
        expect(neuma_array[1][:gdvd][:delta_grade]).to eq(2)
      ensure
        file.unlink
      end
    end

    it 'example from line 958 - Debug parsing' do
      # Test without actually printing (debug mode dumps to stdout)
      expect {
        neumas = Musa::Neumalang::Neumalang.parse(
          "(0) (+2) (+2)",
          debug: false  # Don't actually print in tests
        )
        # Prints parse tree to stdout (when debug: true)

        expect(neumas.i.to_a.size).to eq(3)
      }.not_to raise_error
    end

    it 'example from parse_file method - Parse neuma file' do
      require 'tempfile'

      file = Tempfile.new(['theme', '.neuma'])
      begin
        file.write("(0) (+2) (+4) (+5) (+7) (+9)")
        file.close

        neumas = Musa::Neumalang::Neumalang.parse_file(file.path)

        expect(neumas.i.to_a.size).to eq(6)
      ensure
        file.unlink
      end
    end

    it 'example from parse_file method - Parse file with decoder' do
      require 'tempfile'

      file = Tempfile.new(['theme', '.neuma'])
      begin
        file.write("(0) (+2) (+4) (+5) (+7)")
        file.close

        scale = Musa::Scales::Scales.et12[440.0].major[60]
        decoder = Musa::Neumas::Decoders::NeumaDecoder.new(scale)
        gdvs = Musa::Neumalang::Neumalang.parse_file(
          file.path,
          decode_with: decoder
        )

        gdv_array = gdvs.i.to_a
        expect(gdv_array.size).to eq(5)
        expect(gdv_array[0]).to have_key(:grade)
      ensure
        file.unlink
      end
    end
  end

  context 'Neumalang features from docs_neumas_spec.rb examples' do
    it 'parses neuma notation with durations' do
      # Test individual examples from existing docs
      melody = "(0) (+2) (+2) (-1) (0)"
      rhythm = "(+2 1) (+2 2) (+1 1/2) (+2 1)"

      # Parse simple melody
      melody_neumas = melody.to_neumas
      expect(melody_neumas).to respond_to(:i)
      expect(melody_neumas.i.to_a.size).to eq(5)

      # Parse rhythm with durations
      rhythm_neumas = rhythm.to_neumas
      rhythm_array = rhythm_neumas.i.to_a
      expect(rhythm_array.size).to eq(4)
      expect(rhythm_array[0][:gdvd][:abs_duration]).to eq(1)
      expect(rhythm_array[1][:gdvd][:abs_duration]).to eq(2)
      expect(rhythm_array[2][:gdvd][:abs_duration]).to eq(1/2r)
    end

    it 'parses complete song example with parallel voices using | operator' do
      # Complete example from README - parallel voices using | operator
      song = "(0 1 mf) (+2 1 mp) (+4 2 p) (+5 1/2 mf) (+7 1 f)" |
             "(+7 2 p) (+5 1 mp) (+7 1 mf) (+9 1/2 f) (+12 2 ff)"

      # Verify it's a parallel structure
      expect(song).to be_a(Hash)
      expect(song[:kind]).to eq(:parallel)
      expect(song[:parallel].size).to eq(2)

      # Test Voice 1 directly from parallel structure
      voice1_serie = song[:parallel][0][:serie]
      voice1_array = voice1_serie.i.to_a

      expect(voice1_array.size).to eq(5)

      # First note: grade 0, duration 1, velocity mf
      expect(voice1_array[0][:gdvd][:abs_grade]).to eq(0)
      expect(voice1_array[0][:gdvd][:abs_duration]).to eq(1)
      expect(voice1_array[0][:gdvd][:abs_velocity]).to eq(1)  # mf = 1

      # Third note: grade +4, duration 2, velocity p
      expect(voice1_array[2][:gdvd][:delta_grade]).to eq(4)
      expect(voice1_array[2][:gdvd][:abs_duration]).to eq(2)
      expect(voice1_array[2][:gdvd][:abs_velocity]).to eq(-1)  # p = -1

      # Test Voice 2 directly from parallel structure
      voice2_serie = song[:parallel][1][:serie]
      voice2_array = voice2_serie.i.to_a

      expect(voice2_array.size).to eq(5)

      # First note: grade +7, duration 2, velocity p
      expect(voice2_array[0][:gdvd][:delta_grade]).to eq(7)
      expect(voice2_array[0][:gdvd][:abs_duration]).to eq(2)
      expect(voice2_array[0][:gdvd][:abs_velocity]).to eq(-1)  # p = -1
    end

    it 'parses duration notation correctly' do
      # Test various duration formats with absolute durations
      neumas = "(0 1) (0 2) (0 1/2) (0 1/4)".to_neumas

      neuma_array = neumas.i.to_a
      expect(neuma_array.size).to eq(4)

      # Check absolute durations
      expect(neuma_array[0][:gdvd][:abs_duration]).to eq(1)
      expect(neuma_array[1][:gdvd][:abs_duration]).to eq(2)
      expect(neuma_array[2][:gdvd][:abs_duration]).to eq(1/2r)
      expect(neuma_array[3][:gdvd][:abs_duration]).to eq(1/4r)
    end

    it 'parses velocity/dynamics notation correctly' do
      # Test dynamics: pp, p, mp, mf, f, ff, fff
      neumas = "(0 pp) (0 p) (0 mp) (0 mf) (0 f) (0 ff) (0 fff)".to_neumas

      neuma_array = neumas.i.to_a
      expect(neuma_array.size).to eq(7)

      # Check velocities: ppp=-3, pp=-2, p=-1, mp=0, mf=1, f=2, ff=3, fff=4
      expect(neuma_array[0][:gdvd][:abs_velocity]).to eq(-2)  # pp
      expect(neuma_array[1][:gdvd][:abs_velocity]).to eq(-1)  # p
      expect(neuma_array[2][:gdvd][:abs_velocity]).to eq(0)   # mp
      expect(neuma_array[3][:gdvd][:abs_velocity]).to eq(1)   # mf
      expect(neuma_array[4][:gdvd][:abs_velocity]).to eq(2)   # f
      expect(neuma_array[5][:gdvd][:abs_velocity]).to eq(3)   # ff
      expect(neuma_array[6][:gdvd][:abs_velocity]).to eq(4)   # fff
    end

    it 'parses mixed absolute and relative grades' do
      # Mix of absolute and relative
      neumas = "(0) (+2) (4) (+1)".to_neumas

      neuma_array = neumas.i.to_a
      expect(neuma_array.size).to eq(4)

      # First is absolute
      expect(neuma_array[0][:gdvd]).to have_key(:abs_grade)
      expect(neuma_array[0][:gdvd][:abs_grade]).to eq(0)

      # Second is relative
      expect(neuma_array[1][:gdvd]).to have_key(:delta_grade)
      expect(neuma_array[1][:gdvd][:delta_grade]).to eq(2)

      # Third is absolute
      expect(neuma_array[2][:gdvd]).to have_key(:abs_grade)
      expect(neuma_array[2][:gdvd][:abs_grade]).to eq(4)

      # Fourth is relative
      expect(neuma_array[3][:gdvd]).to have_key(:delta_grade)
      expect(neuma_array[3][:gdvd][:delta_grade]).to eq(1)
    end

    it 'handles whitespace and formatting' do
      # Whitespace should be ignored
      neumas1 = "(0) (+2) (+4)".to_neumas
      neumas2 = "(0)  (+2)    (+4)".to_neumas
      neumas3 = "(0)
                 (+2)
                 (+4)".to_neumas

      expect(neumas1.i.to_a.size).to eq(3)
      expect(neumas2.i.to_a.size).to eq(3)
      expect(neumas3.i.to_a.size).to eq(3)
    end

    it 'parses symbol values' do
      # Symbol: :symbol_name
      neumas = ":test_symbol".to_neumas

      neuma_array = neumas.i.to_a
      expect(neuma_array.size).to eq(1)

      expect(neuma_array[0][:kind]).to eq(:value)
      expect(neuma_array[0][:value]).to eq(:test_symbol)
    end

    it 'parses string values' do
      # String: "text"
      neumas = '"hello world"'.to_neumas

      neuma_array = neumas.i.to_a
      expect(neuma_array.size).to eq(1)

      expect(neuma_array[0][:kind]).to eq(:value)
      expect(neuma_array[0][:value]).to eq("hello world")
    end

    it 'parses numeric values' do
      # Numbers: 42, 3.14
      neumas = "42 3.14".to_neumas

      neuma_array = neumas.i.to_a
      expect(neuma_array.size).to eq(2)

      expect(neuma_array[0][:kind]).to eq(:value)
      expect(neuma_array[0][:value]).to eq(42)

      expect(neuma_array[1][:kind]).to eq(:value)
      expect(neuma_array[1][:value]).to be_within(0.01).of(3.14)
    end

    it 'parses special values (nil, true, false)' do
      # Special keywords
      neumas = "nil true false".to_neumas

      neuma_array = neumas.i.to_a
      expect(neuma_array.size).to eq(3)

      expect(neuma_array[0][:kind]).to eq(:value)
      expect(neuma_array[0][:value]).to be_nil

      expect(neuma_array[1][:kind]).to eq(:value)
      expect(neuma_array[1][:value]).to be true

      expect(neuma_array[2][:kind]).to eq(:value)
      expect(neuma_array[2][:value]).to be false
    end
  end

  context 'Integration with other subsystems' do
    it 'integrates with NeumaDecoder for GDV conversion' do
      scale = Musa::Scales::Scales.et12[440.0].major[60]
      decoder = Musa::Neumas::Decoders::NeumaDecoder.new(
        scale,
        base_duration: 1r
      )

      neumas = "(0) (+2) (+4) (+5) (+7)".to_neumas
      gdvs = Musa::Neumalang::Neumalang.parse("(0) (+2) (+4) (+5) (+7)", decode_with: decoder)

      # Without decoder: GDVD format
      expect(neumas.i.to_a[0]).to have_key(:gdvd)

      # With decoder: GDV format
      expect(gdvs.i.to_a[0]).to have_key(:grade)
      expect(gdvs.i.to_a[0]).to have_key(:duration)
      expect(gdvs.i.to_a[0]).to have_key(:velocity)
    end

    it 'integrates with Series for sequential playback' do
      neumas = "(0) (+2) (+4) (+5) (+7)".to_neumas

      # Neumas parse returns series-like object
      expect(neumas).to respond_to(:i)

      # Can convert to array and count
      count = neumas.i.to_a.size
      expect(count).to eq(5)
    end

    it 'handles error on invalid notation' do
      # Invalid notation should raise ParseError
      expect {
        "invalid {{{".to_neumas
      }.to raise_error(Citrus::ParseError)
    end

    it 'handles error on wrong input type' do
      # Only String or File allowed
      expect {
        Musa::Neumalang::Neumalang.parse(123)
      }.to raise_error(ArgumentError, /Only String or File allowed/)
    end
  end

  context 'Real-world usage patterns' do
    it 'parses simple melody with rhythm and dynamics' do
      melody = "(0 1 p) (+2 1 mp) (+4 2 mf) (+5 1/2 f) (+7 2 ff)".to_neumas

      melody_array = melody.i.to_a
      expect(melody_array.size).to eq(5)

      # Each note should have duration
      melody_array.each do |note|
        expect(note[:gdvd]).to have_key(:abs_duration)
      end

      # Each note should have velocity
      melody_array.each do |note|
        expect(note[:gdvd]).to have_key(:abs_velocity)
      end

      # Dynamics should increase
      expect(melody_array[0][:gdvd][:abs_velocity]).to eq(-1)  # p
      expect(melody_array[1][:gdvd][:abs_velocity]).to eq(0)   # mp
      expect(melody_array[2][:gdvd][:abs_velocity]).to eq(1)   # mf
      expect(melody_array[3][:gdvd][:abs_velocity]).to eq(2)   # f
      expect(melody_array[4][:gdvd][:abs_velocity]).to eq(3)   # ff
    end

    it 'parses two-voice harmony using | operator' do
      harmony = "(0 1) (+2 1) (+4 1) (+5 1)" | "(+4 1) (+5 1) (+7 1) (+9 1)"

      expect(harmony).to be_a(Hash)
      expect(harmony[:kind]).to eq(:parallel)
      expect(harmony[:parallel].size).to eq(2)

      melody = harmony[:parallel][0][:serie].i.to_a
      bass = harmony[:parallel][1][:serie].i.to_a

      expect(melody.size).to eq(4)
      expect(bass.size).to eq(4)
    end

    it 'parses complete musical phrase' do
      phrase = "(0 1 mp) (+2 1 mf) (+4 2 f) (+5 1/2 f) (+7 2 ff) (+9 1 p) (+7 1 mp) (0 2 p)".to_neumas

      phrase_array = phrase.i.to_a
      expect(phrase_array.size).to eq(8)

      # Each note has duration
      phrase_array.each do |note|
        expect(note[:gdvd]).to have_key(:abs_duration)
      end

      # Each note has velocity
      phrase_array.each do |note|
        expect(note[:gdvd]).to have_key(:abs_velocity)
      end
    end
  end
end
