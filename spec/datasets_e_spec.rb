require 'spec_helper'

require 'musa-dsl'


RSpec.describe Musa::Datasets do
  context 'Dataset GDV-GDVd-PDV transformations' do
    it 'GDV to PDV' do
      scale = Musa::Scales::Scales.default_system.default_tuning.major[60]

      expect({ grade: 3, duration: 1, velocity: 4 }.extend(Musa::Datasets::GDV).to_pdv(scale)).to eq(pitch: 60 + 5, duration: 1, velocity: 127)
      expect({ grade: 3, sharps: 1, duration: 1, velocity: 4 }.extend(Musa::Datasets::GDV).to_pdv(scale)).to eq(pitch: 60 + 5 + 1, duration: 1, velocity: 127)
      expect({ grade: 3, sharps: -1, duration: 1, velocity: 4 }.extend(Musa::Datasets::GDV).to_pdv(scale)).to eq(pitch: 60 + 5 - 1, duration: 1, velocity: 127)
      expect({ grade: 8, duration: 1, velocity: -3 }.extend(Musa::Datasets::GDV).to_pdv(scale)).to eq(pitch: 60 + 12 + 2, duration: 1, velocity: 16)
      expect({ grade: 0, duration: 1, velocity: -3, silence: true }.extend(Musa::Datasets::GDV).to_pdv(scale)).to eq(pitch: :silence, duration: 1, velocity: 16)
      expect({ duration: 0 }.extend(Musa::Datasets::GDV).to_pdv(scale)).to eq(duration: 0)
    end

    it 'GDV to PDV (with module alias)' do
      scale = Musa::Scales::Scales.default_system.default_tuning.major[60]

      expect({ grade: 3, duration: 1, velocity: 4 }.extend(Musa::Datasets::GDV).to_pdv(scale)).to eq(pitch: 60 + 5, duration: 1, velocity: 127)
      expect({ grade: 8, duration: 1, velocity: -3 }.extend(Musa::Datasets::GDV).to_pdv(scale)).to eq(pitch: 60 + 12 + 2, duration: 1, velocity: 16)
      expect({ grade: 8, sharps: 1, duration: 1, velocity: -3 }.extend(Musa::Datasets::GDV).to_pdv(scale)).to eq(pitch: 60 + 12 + 2 + 1, duration: 1, velocity: 16)
      expect({ grade: 8, sharps: -1, duration: 1, velocity: -3 }.extend(Musa::Datasets::GDV).to_pdv(scale)).to eq(pitch: 60 + 12 + 2 - 1, duration: 1, velocity: 16)

      h = { duration: 0 }.extend Musa::Datasets::GDV
      expect(h.to_pdv(scale)).to eq(duration: 0)
    end

    it 'GDV neumas to PDV and back to neumas via GDV::NeumaDecoder' do
      # Only the enharmonics move: 2_ comes back as 1#. The dynamics survive --
      # p used to come back as mp here, which is the drift this expectation
      # recorded until issue #86 was fixed.
      gdv_abs_neumas_1 = '(0 o0 1 p) (0 o1 2 p) (3# o1 2 p) (0 o-1 3 p) (2_ o0 3 fff) (1 o0 2 fff) (5 o1 1/2 ppp) (silence 1/2 ppp)'
      gdv_abs_neumas_2 = '(0 o0 1 p) (0 o1 2 p) (3# o1 2 p) (0 o-1 3 p) (1# o0 3 fff) (1 o0 2 fff) (5 o1 1/2 ppp) (silence 1/2 ppp)'

      scale = Musa::Scales::Scales.default_system.default_tuning.major[60]

      decoder = Musa::Neumas::Decoders::NeumaDecoder.new scale

      result_gdv = Musa::Neumalang::Neumalang.parse(gdv_abs_neumas_1, decode_with: decoder).to_a(recursive: true)

      result_pdv = result_gdv.collect { |g| g.to_pdv(scale) }

      result_gdv2 = result_pdv.collect { |p| p.to_gdv(scale) }

      result_neuma = result_gdv2.collect(&:to_neuma)

      result = result_neuma.join ' '

      expect(result).to eq(gdv_abs_neumas_2)
    end

    it 'GDV neumas to GDVd neumas via GDV::NeumaDecoder' do
      gdv_abs_neumas = '(0 1 p) (0 2 p) (0 3 p) (0# 3 p) (1 3 p) (2_) (2 3 fff) (1 2 fff) (5 1/2 ppp) (silence 1)'
      gdv_diff_neumas = '(0 1 p) (. +1) (. +1) (+#) (+1_) (+1_) (+# +fffff) (-1 -1) (+4 -3/2 -fffffff) (silence +1/2)'

      scale = Musa::Scales::Scales.default_system.default_tuning.major[60]

      decoder = Musa::Neumas::Decoders::NeumaDecoder.new scale

      result_gdv = Musa::Neumalang::Neumalang.parse(gdv_abs_neumas, decode_with: decoder).to_a(recursive: true)

      result_gdvd = result_gdv.each_index.collect { |i| result_gdv[i].to_gdvd scale, previous: (i > 0 ? result_gdv[i - 1] : nil) }

      result_neuma = result_gdvd.collect(&:to_neuma)

      result = result_neuma.join ' '

      expect(result).to eq(gdv_diff_neumas)
    end

    it 'GDV diff neumas to GDV abs neumas via GDV::NeumaDecoder' do
      gdv_diff_neumas = '(0 o1 1 mf) (.) (+1 +o1) (2 p) (+#) (2 -o3 1/2 p) (silence +1)'
      gdv_abs_neumas =  '(0 o1 1 mf) (0 o1 1 mf) (1 o2 1 mf) (2 o2 1 p) (3 o2 1 p) (2 o-1 1/2 p) (silence o-1 3/2 p)'

      scale = Musa::Scales::Scales.default_system.default_tuning.major[60]

      decoder = Musa::Neumas::Decoders::NeumaDecoder.new scale

      result_gdv = Musa::Neumalang::Neumalang.parse(gdv_diff_neumas, decode_with: decoder).to_a(recursive: true)

      result_neuma = result_gdv.collect(&:to_neuma)

      result = result_neuma.join ' '

      expect(result).to eq(gdv_abs_neumas)
    end

    it 'GDV diff neumas with sharps and flats to GDV via GDV::NeumaDecoder' do
      gdv_diff_neumas = '(0) (+3# 1) (.) (-#) (_) (-0#)    (0) (+##) (+##) (+##) (_)'

      scale = Musa::Scales::Scales.default_system.default_tuning.major[60]

      decoder = Musa::Neumas::Decoders::NeumaDecoder.new scale

      result_gdv = Musa::Neumalang::Neumalang.parse(gdv_diff_neumas, decode_with: decoder).to_a(recursive: true)

      c = -1

      expect(result_gdv[c += 1]).to eq(grade: 0, octave: 0, duration: 1/4r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 3, sharps: 1, octave: 0, duration: 1/4r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 3, sharps: 1, octave: 0, duration: 1/4r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 3, octave: 0, duration: 1/4r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 2, octave: 0, duration: 1/4r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 1, sharps: 1, octave: 0, duration: 1/4r, velocity: 1)

      expect(result_gdv[c += 1]).to eq(grade: 0, octave: 0, duration: 1/4r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 1, octave: 0, duration: 1/4r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 2, octave: 0, duration: 1/4r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 3, sharps: 1, octave: 0, duration: 1/4r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 3, octave: 0, duration: 1/4r, velocity: 1)
    end
  end

  # A rest survived one conversion and died on the next: `PDV#to_gdv` wrote
  # `grade: :silence`, which nothing in the library reads, while everything --
  # the neuma decoder that produces silences, `to_pdv`, `to_neuma`, `to_gdvd` --
  # uses the `:silence` KEY (issue #80). There was no spec for the round trip.
  context 'Rests through the conversions' do
    let(:scale) { Musa::Scales::Scales.default_system.default_tuning.major[60] }
    let(:decoder) { Musa::Neumas::Decoders::NeumaDecoder.new(scale, base_duration: 1/4r) }

    def parsed_silence
      Musa::Neumalang::Neumalang.parse('(silence 4)', decode_with: decoder)
                                .to_a(recursive: true).first
    end

    it 'survives PDV -> GDV -> PDV' do
      pdv = { pitch: :silence, duration: 1r, velocity: 80 }.extend(Musa::Datasets::PDV)

      gdv = pdv.to_gdv(scale)

      expect(gdv).to eq(silence: true, duration: 1r, velocity: 1)
      expect(gdv.to_pdv(scale)).to eq(pdv)
    end

    it 'survives the trip that starts at the parser' do
      gdv = parsed_silence

      expect(gdv).to eq(grade: 0, octave: 0, duration: 1r, velocity: 1, silence: true)

      pdv = gdv.to_pdv(scale)
      expect(pdv).to eq(pitch: :silence, duration: 1r, velocity: 80)

      # What used to raise here: the GDV came back with `grade: :silence` and no
      # :silence key, and to_pdv called scale[:silence].
      expect(pdv.to_gdv(scale).to_pdv(scale)).to eq(pdv)
    end

    it 'is the key that says so, with or without the grade it silences' do
      with_grade = { grade: 0, octave: 0, duration: 1r, silence: true }.extend(Musa::Datasets::GDV)
      without = { silence: true, duration: 1r }.extend(Musa::Datasets::GDV)

      expect(with_grade.to_pdv(scale)).to eq(pitch: :silence, duration: 1r)
      expect(without.to_pdv(scale)).to eq(pitch: :silence, duration: 1r)
    end

    it 'reaches the notation and the delta encoding the same way' do
      gdv = { silence: true, duration: 1r }.extend(Musa::Datasets::GDV)
      gdv.base_duration = 1/4r

      expect(gdv.to_neuma.to_s).to eq('(silence 4)')
      expect(gdv.to_gdvd(scale)[:abs_grade]).to eq(:silence)
    end

    it 'stays a rest when it opens a delta-encoded sequence' do
      # With no previous element to be a delta from, to_gdvd wrote the grade the
      # rest silences: a silence opening a sequence came out as an audible note.
      gdv = parsed_silence

      gdvd = gdv.to_gdvd(scale)
      gdvd.base_duration = 1/4r

      expect(gdvd[:abs_grade]).to eq(:silence)
      expect(gdvd.to_neuma.to_s).to eq('(silence 4 mf)')
    end

    it 'a note is unchanged by the same round trip' do
      gdv = Musa::Neumalang::Neumalang.parse('(2 4 mf)', decode_with: decoder)
                                      .to_a(recursive: true).first

      expect(gdv.to_pdv(scale).to_gdv(scale)).to eq(gdv)
    end
  end

  # GDVd is not compression: a passage written as movement from a previous event
  # says nothing about where it starts, so it can start anywhere. Which means
  # the first event of a sequence has nothing before it, and that is exactly the
  # one the reading half could not take (issue #88).
  context 'The first event of a differential sequence' do
    let(:scale) { Musa::Scales::Scales.default_system.default_tuning.major[60] }
    let(:decoder) { Musa::Neumas::Decoders::NeumaDecoder.new(scale, base_duration: 1/4r) }

    def parsed(neuma)
      Musa::Neumalang::Neumalang.parse(neuma, decode_with: decoder).to_a(recursive: true).first
    end

    it 'closes the pair: written with no previous, read with no previous' do
      gdv = parsed('(2 4 mf)')

      gdvd = gdv.to_gdvd(scale)

      # Fully absolute: nothing in it is relative, so nothing is missing.
      expect(gdvd).to eq(abs_grade: 2, abs_duration: 1r, abs_velocity: 1)
      expect(gdvd.to_gdv(scale)).to eq(grade: 2, duration: 1r, velocity: 1)
    end

    it 'reads a rest opening a sequence as a rest' do
      gdvd = parsed('(silence 4)').to_gdvd(scale)

      expect(gdvd.to_gdv(scale)[:silence]).to be true
    end

    it 'still refuses a movement with nothing to move from' do
      gdvd = { delta_grade: 2 }.extend(Musa::Datasets::GDVd)
      gdvd.base_duration = 1/4r

      expect { gdvd.to_gdv(scale) }.to raise_error(ArgumentError)
    end

    it 'is the same movement read from another base, which is what it is for' do
      motif = %w[(+1) (+2) (-1)].collect do |neuma|
        Musa::Neumalang::Neumalang.parse(neuma).to_a(recursive: true)
                                  .first[:gdvd].extend(Musa::Datasets::GDVd)
      end

      from_c = motif.inject([{ grade: 0, octave: 0 }.extend(Musa::Datasets::GDV)]) do |gdvs, step|
        gdvs << step.to_gdv(scale, previous: gdvs.last)
      end

      from_e = motif.inject([{ grade: 2, octave: 0 }.extend(Musa::Datasets::GDV)]) do |gdvs, step|
        gdvs << step.to_gdv(scale, previous: gdvs.last)
      end

      expect(from_c.collect { |g| g[:grade] }).to eq([0, 1, 3, 2])
      expect(from_e.collect { |g| g[:grade] }).to eq([2, 3, 5, 4])
    end
  end

  # The whole dynamics table, written out, so that it stops depending on prose.
  #
  # It depended on prose and the prose was wrong three times over: `velocity_of`
  # announced ppp at -5 and mf at 0 while returning "ff" and "mp"; PDV's mapping
  # table named every step two places towards the soft end; and GDV carried a
  # second, identical copy of the method, which is how one of them came to be
  # corrected and the other not (issue #74).
  context 'Velocity and its dynamics markings' do
    let(:scale) { Musa::Scales::Scales.default_system.default_tuning.major[60] }
    let(:decoder) { Musa::Neumas::Decoders::NeumaDecoder.new(scale, base_duration: 1/4r) }

    def neuma_of(velocity)
      gdv = { grade: 0, duration: 1/4r, velocity: velocity }.extend(Musa::Datasets::GDV)
      gdv.base_duration = 1/4r
      gdv.to_neuma.to_s
    end

    def velocity_of_neuma(dynamics)
      Musa::Neumalang::Neumalang.parse("(0 1 #{dynamics})", decode_with: decoder)
                                .to_a(recursive: true).first[:velocity]
    end

    # Zero is mp and one is mf. Not a convention chosen by the printer: it is
    # what the parser reads and what VELOCITY_MAP encodes (64 and 80).
    TABLE = { -5 => 'ppppp', -4 => 'pppp', -3 => 'ppp', -2 => 'pp', -1 => 'p',
              0 => 'mp', 1 => 'mf', 2 => 'f', 3 => 'ff', 4 => 'fff' }.freeze

    it 'prints every dynamic of the numeric range VELOCITY_MAP covers' do
      expect(TABLE.keys).to eq((-5..4).to_a)
      expect(Musa::Datasets::GDV::VELOCITY_MAP.size).to eq(TABLE.size)

      expect(TABLE.keys.to_h { |velocity| [velocity, neuma_of(velocity)] })
        .to eq(TABLE.transform_values { |name| "(0 1 #{name})" })
    end

    it 'never names a soft dynamic with a loud one, at either end' do
      # The bug: an index below the start of an eight-entry table wrapped round
      # to its end, so the softest came back as the loudest.
      expect(neuma_of(-4)).to eq('(0 1 pppp)')
      expect(neuma_of(-5)).to eq('(0 1 ppppp)')
      expect(neuma_of(-9)).to eq('(0 1 ppppppppp)')

      # And above the table it returned nil, printing an empty attribute.
      expect(neuma_of(5)).to eq('(0 1 ffff)')
      expect(neuma_of(9)).to eq('(0 1 ffffffff)')
    end

    it 'is the exact inverse of what the parser reads, over and beyond the table' do
      (-9..9).each do |velocity|
        printed = neuma_of(velocity)[/(\S+)\)\z/, 1]

        expect(velocity_of_neuma(printed)).to eq(velocity),
                                              "velocity #{velocity} printed as #{printed.inspect}, " \
                                              "which parses back as #{velocity_of_neuma(printed)}"
      end
    end

    it 'agrees with the MIDI mapping in both directions' do
      TABLE.each_key do |velocity|
        midi = Musa::Datasets::GDV::VELOCITY_MAP[velocity + 5]

        gdv = { grade: 0, duration: 1/4r, velocity: velocity }.extend(Musa::Datasets::GDV)
        gdv.base_duration = 1/4r
        expect(gdv.to_pdv(scale)[:velocity]).to eq(midi)

        pdv = { pitch: 60, duration: 1/4r, velocity: midi }.extend(Musa::Datasets::PDV)
        expect(pdv.to_gdv(scale)[:velocity]).to eq(velocity)
      end
    end

    # p used to be the one dynamic that did not come back: VELOCITY_MAP put it
    # at MIDI 49 while to_gdv's own copy of the bands closed the previous one at
    # 48, so 49 read back as mp and a note recorded at 49 came out at 64 (issue
    # #86). The bands are derived from the map now, so they cannot drift apart.
    it 'derives the MIDI bands from the map, so every dynamic contains its own velocity' do
      bands = Musa::Datasets::GDV::VELOCITY_BANDS

      expect(bands.size).to eq(Musa::Datasets::GDV::VELOCITY_MAP.size)

      Musa::Datasets::GDV::VELOCITY_MAP.each_with_index do |midi, index|
        expect(bands[index]).to cover(midi)
      end

      # And they tile 1..127 with no gap and no overlap.
      expect(bands.first.first).to eq(1)
      expect(bands.last.last).to eq(127)
      expect(bands.each_cons(2).all? { |a, b| b.first == a.last + 1 }).to be true
    end

    it 'floors a fractional velocity, as GDV interpolates them' do
      expect(neuma_of(-2.5)).to eq('(0 1 ppp)')
      expect(neuma_of(0.5)).to eq('(0 1 mp)')
      expect(neuma_of(3.5)).to eq('(0 1 ff)')
    end

    # GDVd reaches Helper#velocity_of directly; GDV used to shadow it with a
    # copy. One method, one table, one place to be wrong.
    it 'GDV and GDVd name the same velocity the same way' do
      gdvd = { delta_grade: 0, abs_velocity: -4 }.extend(Musa::Datasets::GDVd)
      gdvd.base_duration = 1/4r

      expect(gdvd.to_neuma.to_s).to include('pppp')
      expect(neuma_of(-4)).to include('pppp')
    end
  end
end
