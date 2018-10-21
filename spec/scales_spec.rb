require 'spec_helper'

require 'musa-dsl'

RSpec.describe Musa::EquallyTempered12ToneScaleSystem do
  context 'Equally tempered 12 semitones scales' do
    scale_system = Musa::Scales[:et12][440.0]

    it 'Access to ScaleSystems by :symbol and by .method' do
      sst1 = Musa::Scales[:et12][440.0]
      sst2 = Musa::Scales.et12[440.0]

      expect(sst1).to be sst2
    end

    it 'Access to ScaleKind by :symbol and by .method' do
      sst = Musa::Scales.et12[440.0]

      expect(sst.major).to be sst[:major]
    end

    it 'Access to Scale by :symbol and by .method' do
      sst = Musa::Scales.et12[440.0]

      expect(sst.major).to be sst[:major]
      expect(sst.major[60]).to be sst[:major][60]
    end

    it 'Basic major scale pitch and functions' do
      scale = scale_system[:major][60]

      expect(scale.kind.class.id).to eq :major
      expect(scale.kind.class.grades).to eq 7
      expect(scale.based_on.pitch).to eq 60
      expect(scale.based_on.scale).to be scale

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
      expect(scale.based_on.pitch).to eq 60

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
      expect(scale2.based_on.pitch).to eq 57
      expect(scale2.based_on.scale).to eq scale2
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
