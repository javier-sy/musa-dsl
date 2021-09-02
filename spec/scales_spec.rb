require 'spec_helper'

require 'musa-dsl'

RSpec.describe Musa::Scales::EquallyTempered12ToneScaleSystem do
  context 'Equally tempered 12 semitones scales' do
    scale_system = Musa::Scales::Scales[:et12][440.0]

    it 'Access to ScaleSystems by :symbol and by .method' do
      sst1 = Musa::Scales::Scales[:et12][440.0]
      sst2 = Musa::Scales::Scales.et12[440.0]

      expect(sst1).to be sst2
    end

    it 'Access to ScaleKind by :symbol and by .method' do
      sst = Musa::Scales::Scales.et12[440.0]

      expect(sst.major).to be sst[:major]
    end

    it 'Access to Scale by :symbol and by .method' do
      sst = Musa::Scales::Scales.et12[440.0]

      expect(sst.major).to be sst[:major]
      expect(sst.major[60]).to be sst[:major][60]
    end

    it 'Access to default scale system an default tuning' do
      ss = Musa::Scales::Scales[:et12]
      sst = Musa::Scales::Scales[:et12][440.0]

      expect(ss).to be Musa::Scales::Scales.default_system
      expect(sst).to be Musa::Scales::Scales.default_system.default_tuning
      expect(sst.chromatic).to be Musa::Scales::Scales.default_system.default_tuning.chromatic
    end

    it 'Access to intervals with ScaleSystem and tuning' do
      expect(Musa::Scales::Scales.default_system.offset_of_interval(:m2)).to eq 1
      expect(Musa::Scales::Scales.default_system.default_tuning.offset_of_interval(:m2)).to eq 1
    end

    it 'Access to intervals' do
      scale = scale_system[:major][60]

      expect(scale.offset_of_interval(:m2)).to eq 1
    end

    it 'Sharp and flat to natural note (eval pitch and scale)' do
      scale = scale_system[:major][60]

      expect(scale[0].sharp(0)).to be scale[0]

      expect(scale[0].sharp.pitch).to eq 61
      expect(scale[0].sharp.scale).to be scale.chromatic

      expect(scale[0].sharp(2).pitch).to eq 62
      expect(scale[0].sharp(2).scale).to be scale

      expect(scale[0].flat.pitch).to eq 59
      expect(scale[0].flat.scale).to be scale

      expect(scale[0].flat(2).pitch).to eq 58
      expect(scale[0].flat(2).scale).to be scale.chromatic
    end

    it 'Sharp and flat to natural note (eval grade and scale)' do
      scale = scale_system[:major][60]

      expect(scale[0].sharp(0)).to be scale[0]

      expect(scale[0].sharp.grade).to eq 1
      expect(scale[0].sharp.scale).to be scale.chromatic

      expect(scale[0].sharp(2).grade).to eq 1
      expect(scale[0].sharp(2).scale).to be scale

      expect(scale[0].flat.grade).to eq 6
      expect(scale[0].flat.octave).to eq -1
      expect(scale[0].flat.scale).to be scale

      expect(scale[0].flat(2).grade).to eq 10
      expect(scale[0].flat.octave).to eq -1
      expect(scale[0].flat(2).scale).to be scale.chromatic
    end

    it 'Repeated sharp and flat to natural note' do
      scale = scale_system[:major][60]

      a = scale[0].sharp
      expect(a.pitch).to eq 61
      expect(a.scale).to be scale.chromatic

      b = a.sharp
      expect(b.pitch).to eq 62
      expect(b.scale).to be scale

      c = b.sharp
      expect(c.pitch).to eq 63
      expect(c.scale).to be scale.chromatic

      d = c.sharp
      expect(d.pitch).to eq 64
      expect(d.scale).to be scale
    end

    it 'Intervals up and down with named intervals' do
      scale = scale_system[:major][60]

      expect(scale[0].up(:m2).pitch).to eq 61
      expect(scale[0].up(:m2).scale).to be scale.chromatic

      expect(scale[0].up(:M2).pitch).to eq 62
      expect(scale[0].up(:M2).scale).to be scale

      expect(scale[0].down(:m2).pitch).to eq 59
      expect(scale[0].down(:m2).scale).to be scale

      expect(scale[0].down(:M2).pitch).to eq 58
      expect(scale[0].down(:M2).scale).to be scale.chromatic
    end

    it 'Intervals up with named intervals with chromatic movements' do
      scale = scale_system[:major][60]

      a = scale[0].up(:m2)

      expect(a.pitch).to eq 61
      expect(a.scale).to be scale.chromatic

      b = a.up(:m2)

      expect(b.pitch).to eq 62
      expect(b.scale).to be scale

      c = b.up(:M3)
      expect(c.pitch).to eq 66
      expect(c.scale).to be scale.chromatic
    end

    it 'Intervals up and down with numeric intervals' do
      scale = scale_system[:major][60]

      expect(scale[0].up(0)).to be scale[0]

      expect(scale[0].up(1, :chromatic).pitch).to eq 61
      expect(scale[0].up(1, :chromatic).scale).to be scale.chromatic

      expect(scale[0].up(1).pitch).to eq 62
      expect(scale[0].up(1).scale).to be scale

      expect(scale[0].down(1).pitch).to eq 59
      expect(scale[0].down(1).scale).to be scale

      expect(scale[0].down(2, :chromatic).pitch).to eq 58
      expect(scale[0].down(2, :chromatic).scale).to be scale.chromatic

      expect(scale[0].down(2).pitch).to eq 57
      expect(scale[0].down(2).scale).to be scale
    end

    it 'Basic grade to pitch conversion' do
      scale = scale_system.major[60]

      expect(scale[0].grade).to eq 0
      expect(scale[0].octave).to eq 0

      expect(scale[7].grade).to eq 0
      expect(scale[7].octave).to eq 1

      expect(scale[8].grade).to eq 1
      expect(scale[8].octave).to eq 1

      expect(scale[8].octave(0).grade).to eq 1
      expect(scale[8].octave(0).octave).to eq 1
    end

    it 'Basic major scale pitch and functions' do
      scale = scale_system[:major][60]

      expect(scale.kind.class.id).to eq :major
      expect(scale.kind.class.grades).to eq 7
      expect(scale.root.pitch).to eq 60
      expect(scale.root.scale).to be scale

      expect(scale[0].grade).to eq 0
      expect(scale[0].octave).to eq 0

      expect(scale[0].pitch).to eq 60
      expect(scale[:I].pitch).to eq 60
      expect(scale.I.pitch).to eq 60
      expect(scale.tonic.pitch).to eq 60

      expect(scale[:tonic].pitch).to eq 60
      expect(scale.tonic.pitch).to eq 60

      expect(scale[:I].functions).to include :tonic

      expect(scale[:V].pitch).to eq 67
      expect(scale[4].pitch).to eq 67
      expect(scale[:dominant].pitch).to eq 67
      expect(scale.dominant.pitch).to eq 67

      expect(scale[:V].functions).to include :dominant

      expect(scale[:I].octave(-1).pitch).to eq 48
      expect(scale[:I].octave(-1).octave).to eq -1
      expect(scale[:I].octave(-1).grade).to eq 0
      expect(scale.tonic.octave(-1).grade).to eq 0

      expect(scale[0].octave(-1).pitch).to eq 48
    end

    it 'Basic minor scale pitch and functions' do
      scale = scale_system[:minor][60]

      expect(scale.kind.class.id).to eq :minor
      expect(scale.root.pitch).to eq 60

      expect(scale[:i].functions).to include :tonic

      expect(scale[:iii].pitch).to eq 63
      expect(scale[2].pitch).to eq 63

      expect(scale[:dominant].pitch).to eq 67

      expect(scale[:v].functions).to include :dominant
    end

    it 'Basic frequency testing' do
      scale = scale_system[:major][60]

      expect(scale[:VI].frequency).to eq 440.0
      expect(scale[:VI].pitch).to eq 69
      expect(scale[:VI].octave(-1).frequency).to eq 220.0
      expect(scale[:VI].octave(-1).pitch).to eq 69 - 12
    end

    it 'Basic scale navigation' do
      scale = scale_system[:major][60]

      scale2 = scale.relative_minor.octave(-1).scale(:minor)
      scale3 = scale.relative_minor.octave(-1).minor

      expect(scale2).to eq scale3

      expect(scale2.kind.class.id).to eq :minor
      expect(scale2.root.pitch).to eq 57
      expect(scale2.root.scale).to eq scale2
      expect(scale2.relative_major.major).to eq scale

      expect(scale2.tonic.pitch).to eq 57
    end

    it 'Basic scale notes projection' do
      scale = scale_system[:major][60]
      scale2 = scale_system[:chromatic][61]

      expect(scale[0].on(scale2).grade).to eq 11
      expect(scale[0].on(scale2).octave).to eq -1
      expect(scale[0].on(scale2).pitch).to eq 60

      expect(scale[0].octave(-1).on(scale2).grade).to eq 11
      expect(scale[0].octave(-1).on(scale2).octave).to eq -2
      expect(scale[0].octave(-1).on(scale2).pitch).to eq 48
    end

    it 'Getting a chromatic scale from a non-chromatic scale' do
      scale = scale_system[:major][60]

      expect(scale.chromatic).to be scale_system[:chromatic][60]
    end
  end
end
