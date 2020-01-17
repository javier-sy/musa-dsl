require 'spec_helper'

require 'musa-dsl'

include Musa::Datasets
include Musa::Scales

RSpec.describe Musa::Neumalang do
  context 'Dataset transformations' do

    it 'GDV to PDV' do
      scale = Scales.default_system.default_tuning.major[60]

      expect({ grade: 3, duration: 1, velocity: 4 }.extend(Musa::Datasets::GDV).to_pdv(scale)).to eq(pitch: 60 + 5, duration: 1, velocity: 127)
      expect({ grade: 3, sharps: 1, duration: 1, velocity: 4 }.extend(Musa::Datasets::GDV).to_pdv(scale)).to eq(pitch: 60 + 5 + 1, duration: 1, velocity: 127)
      expect({ grade: 3, sharps: -1, duration: 1, velocity: 4 }.extend(Musa::Datasets::GDV).to_pdv(scale)).to eq(pitch: 60 + 5 - 1, duration: 1, velocity: 127)
      expect({ grade: 8, duration: 1, velocity: -3 }.extend(Musa::Datasets::GDV).to_pdv(scale)).to eq(pitch: 60 + 12 + 2, duration: 1, velocity: 16)
      expect({ grade: 0, duration: 1, velocity: -3, silence: true }.extend(Musa::Datasets::GDV).to_pdv(scale)).to eq(pitch: :silence, duration: 1, velocity: 16)
      expect({ duration: 0 }.extend(Musa::Datasets::GDV).to_pdv(scale)).to eq(duration: 0)
    end

    it 'GDV to PDV (with module alias)' do
      scale = Scales.default_system.default_tuning.major[60]

      expect({ grade: 3, duration: 1, velocity: 4 }.extend(GDV).to_pdv(scale)).to eq(pitch: 60 + 5, duration: 1, velocity: 127)
      expect({ grade: 8, duration: 1, velocity: -3 }.extend(GDV).to_pdv(scale)).to eq(pitch: 60 + 12 + 2, duration: 1, velocity: 16)
      expect({ grade: 8, sharps: 1, duration: 1, velocity: -3 }.extend(GDV).to_pdv(scale)).to eq(pitch: 60 + 12 + 2 + 1, duration: 1, velocity: 16)
      expect({ grade: 8, sharps: -1, duration: 1, velocity: -3 }.extend(GDV).to_pdv(scale)).to eq(pitch: 60 + 12 + 2 - 1, duration: 1, velocity: 16)

      h = { duration: 0 }.extend GDV
      expect(h.to_pdv(scale)).to eq(duration: 0)
    end

    it 'GDV neuma to PDV and back to neuma via GDV::NeumaDecoder' do
      gdv_abs_neumas_1 = '0.o+0.1.p 0.o+1.2.p 3#.o+1.2.p 0.o-1.3.p 2_.o+0.3.fff 1.o+0.2.fff 5.o+1.1/2.ppp silence.1/2.ppp'
      gdv_abs_neumas_2 = '0.o+0.1.p 0.o+1.2.p 3#.o+1.2.p 0.o-1.3.p 1#.o+0.3.fff 1.o+0.2.fff 5.o+1.1/2.ppp silence.1/2.ppp'

      scale = Scales.default_system.default_tuning.major[60]

      decoder = GDV::NeumaDecoder.new scale

      result_gdv = Neumalang.parse(gdv_abs_neumas_1, decode_with: decoder).to_a(recursive: true)

      result_pdv = result_gdv.collect { |g| g.to_pdv(scale) }

      result_gdv2 = result_pdv.collect { |p| p.to_gdv(scale) }

      result_neuma = result_gdv2.collect(&:to_neuma)

      result = result_neuma.join ' '

      expect(result).to eq(gdv_abs_neumas_2)
    end

    it 'GDV neuma to GDVd neuma via GDV::NeumaDecoder' do
      gdv_abs_neumas = '0.1.p 0.2.p 0.3.p 0#.3.p 1.3.p 2_ 2.3.fff 1.2.fff 5.1/2.ppp silence.1'
      gdv_diff_neumas = '0.1.p .+1 .+1 +# +1_ +1_ +#.+fffff -1.-1 +4.-3/2.-fffffff silence.+1/2'

      scale = Scales.default_system.default_tuning.major[60]

      decoder = GDV::NeumaDecoder.new scale

      result_gdv = Neumalang.parse(gdv_abs_neumas, decode_with: decoder).to_a(recursive: true)

      result_gdvd = result_gdv.each_index.collect { |i| result_gdv[i].to_gdvd scale, previous: (i > 0 ? result_gdv[i - 1] : nil) }

      result_neuma = result_gdvd.collect(&:to_neuma)

      result = result_neuma.join ' '

      expect(result).to eq(gdv_diff_neumas)
    end

    it 'GDV neuma to GDVd and back to neuma via GDV::NeumaDifferentialDecoder' do
      gdv_diff_neumas_1 = '0 . +1 2.p +# 2.1/2.p -# -_ silence.+2'
      gdv_diff_neumas_2 = '0 . +1 2.p +# 2.1/2.p _ +# silence.+2'

      decoder = GDVd::NeumaDifferentialDecoder.new

      result_gdvd = Neumalang.parse(gdv_diff_neumas_1, decode_with: decoder).to_a(recursive: true)

      result_neuma = result_gdvd.collect(&:to_neuma)

      result = result_neuma.join ' '

      expect(result).to eq(gdv_diff_neumas_2)
    end

    it 'GDV diff neuma to GDV abs neuma via GDV::NeumaDecoder' do
      gdv_diff_neumas = '0.o+1.1.mf . +1.+o1 2.p +# 2.-o3.1/2.p silence.+1'
      gdv_abs_neumas =  '0.o+1.1.mf 0.o+1.1.mf 1.o+2.1.mf 2.o+2.1.p 3.o+2.1.p 2.o-1.1/2.p silence.o-1.3/2.p'

      scale = Scales.default_system.default_tuning.major[60]

      decoder = GDV::NeumaDecoder.new scale

      result_gdv = Neumalang.parse(gdv_diff_neumas, decode_with: decoder).to_a(recursive: true)

      result_neuma = result_gdv.collect(&:to_neuma)

      result = result_neuma.join ' '

      expect(result).to eq(gdv_abs_neumas)
    end

    it 'GDV diff neuma with sharps and flats to GDV via GDV::NeumaDecoder' do
      gdv_diff_neumas = '0 +3#.1 . -# _ -0#    0 +## +## +## _'

      scale = Scales.default_system.default_tuning.major[60]

      decoder = GDV::NeumaDecoder.new scale

      result_gdv = Neumalang.parse(gdv_diff_neumas, decode_with: decoder).to_a(recursive: true)

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
end
