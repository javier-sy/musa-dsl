require 'spec_helper'

require 'musa-dsl'

RSpec.describe Musa::EquallyTempered12ToneScaleSystem do
  context 'Chords in equally tempered 12 tone scales' do
    scale_system = Musa::Scales[:et12][440.0]

    major = scale_system[:major][60]
    minor = major.octave(-1).relative_minor.scale(:minor)
    chromatic = scale_system[:chromatic][60]

    it 'Basic triad major chord creation' do
      maj3 = major.tonic.chord

      expect(maj3.root.pitch).to eq 60
      expect(maj3.features).to include({quality: :major})

      expect(maj3[0].pitch).to eq 60
      expect(maj3[0].grade).to eq 0
      expect(maj3[0].octave).to eq 0
      expect(maj3[0].scale).to be major

      expect(maj3[1].pitch).to eq 64
      expect(maj3[1].grade).to eq 2
      expect(maj3[1].octave).to eq 0
      expect(maj3[1].scale).to be major

      expect(maj3[2].pitch).to eq 67
      expect(maj3[2].grade).to eq 4
      expect(maj3[2].octave).to eq 0
      expect(maj3[2].scale).to be major

      expect(maj3[3]).to eq nil
      expect(maj3.notes.size).to eq 3
    end

    it 'Basic triad major chord creation from scale, with and without :triad feature' do
      maj3_a = major.tonic.chord
      maj3_b = major.tonic.chord :triad

      expect(maj3_a).to eq maj3_b
    end

    it 'Basic triad major to minor chord navigation' do
      maj3 = major.tonic.chord

      min3 = maj3.minor

      expect(min3.scale).to eq nil
      expect(min3.fundamental.pitch).to eq 60
      expect(min3.features).to include :minor

      expect(min3[0].pitch).to eq 60
      expect(min3[0].grade).to eq 0
      expect(min3[0].octave).to eq 0
      expect(min3[0].scale).to be major

      expect(min3[1].pitch).to eq 63
      expect(min3[1].grade).to eq nil
      expect(min3[1].octave).to eq nil
      expect(min3[1].scale).to eq nil

      expect(min3[2].pitch).to eq 67
      expect(min3[2].grade).to eq 4
      expect(min3[2].octave).to eq 0
      expect(min3[2].scale).to be major

      expect(maj3[3]).to eq nil
      expect(min3.size).to eq 3
      expect(min3.length).to eq 3
    end

    it 'Basic triad major to minor chord navigation with modal change' do
      maj3 = major.tonic.chord

      min3 = maj3.minor

      matches = min3.match(major.tonic.minor, major.relative_minor.minor, chromatic)

      expect(matches.size).to eq 2

      chord = matches[0]

      expect(chord.scale).to be scale_system[:minor][60]
      expect(chord.fundamental.pitch).to eq 60

      expect(chord[0].scale).to be scale_system[:minor][60]
      expect(chord[1].scale).to be scale_system[:minor][60]
      expect(chord[2].scale).to be scale_system[:minor][60]

      chord = matches[1]

      expect(chord.scale).to be scale_system[:chromatic][60]
      expect(chord.fundamental.pitch).to eq 60

      expect(chord[0].scale).to be scale_system[:chromatic][60]
      expect(chord[1].scale).to be scale_system[:chromatic][60]
      expect(chord[2].scale).to be scale_system[:chromatic][60]
    end

    it 'Basic triad chord chromatically defined to major chord navigation' do
      c3 = chromatic.chord_of 0, 3, 7

      maj3 = c3.match(major)

      expect(maj3.scale).to be major
      expect(maj3.fundamental.pitch).to eq 60
      expect(maj3.features).to include :major

      expect(maj3[0].pitch).to eq 60
      expect(maj3[0].octave).to eq 0
      expect(maj3[0].scale).to be major

      expect(maj3[1].pitch).to eq 64
      expect(maj3[1].octave).to eq 0
      expect(maj3[1].scale).to be major

      expect(maj3[2].pitch).to eq 67
      expect(maj3[2].octave).to eq 0
      expect(maj3[2].scale).to be major

      expect(maj3[3]).to eq nil
      expect(maj3.size).to eq 3
      expect(maj3.length).to eq 3
    end

    it '...' do
      c = major.dominant.chord 2

      expect(c[0].pitch).to eq 67
      expect(c[1].pitch).to eq 71
      expect(c[2]).to eq nil

      expect(c.size).to eq 2

      c = major.dominant.chord 3
      expect(c[0].pitch).to eq 67
      expect(c[1].pitch).to eq 71
      expect(c[2].pitch).to eq 74
      expect(c[3]).to eq nil

      expect(c.size).to eq 3

      c = major.dominant.chord :seventh
      cb = major.dominant.chord 4

      expect(c).to be cb

      expect(c[0].pitch).to eq 67
      expect(c[1].pitch).to eq 71
      expect(c[2].pitch).to eq 74
      expect(c[3].pitch).to eq 77
      expect(c[4]).to eq nil

      expect(c.size).to eq 4

      c = major.dominant.chord :ninth
      cb = major.dominant.chord 5

      expect(c).to be cb

      expect(c[0].pitch).to eq 67
      expect(c[1].pitch).to eq 71
      expect(c[2].pitch).to eq 74
      expect(c[3].pitch).to eq 77
      expect(c[4].pitch).to eq 81
      expect(c[5]).to eq nil

      expect(c.size).to eq 5

      c = major.dominant.chord :eleventh
      cb = major.dominant.chord 6

      expect(c).to be cb

      expect(c[0].pitch).to eq 67
      expect(c[1].pitch).to eq 71
      expect(c[2].pitch).to eq 74
      expect(c[3].pitch).to eq 77
      expect(c[4].pitch).to eq 81
      expect(c[5].pitch).to eq 84
      expect(c[6]).to eq nil

      expect(c.size).to eq 6

      c = major.dominant.chord :thirteenth
      cb = major.dominant.chord 7

      expect(c[0].pitch).to eq 67
      expect(c[1].pitch).to eq 71
      expect(c[2].pitch).to eq 74
      expect(c[3].pitch).to eq 77
      expect(c[4].pitch).to eq 81
      expect(c[5].pitch).to eq 84
      expect(c[6].pitch).to eq 88
      expect(c[7]).to eq nil

      expect(c.size).to eq 7
    end

    it '' do
      major.dominant.octave(-1).major.dominant.chord :seventh # V7/V
    end

    it '' do
      c1 = major.tonic.chord inversion: 1

      c1 = major.tonic.chord inversion: 1, duplicate: { fundamental: -1, third: -2 }

      c1 = major.tonic.chord :minor, inversion: 1, duplicate: { fundamental: -1, third: -2 }

      c1 = major.dominant.chord 2, inversion: 1

      c1 = major.dominant.chord 3, inversion: 1

      c1 = major.dominant.chord :seventh, inversion: 1
      c1 = major.dominant.chord 4, inversion: 1

      c1 = major.dominant.chord :ninth, inversion: 1
      c1 = major.dominant.chord 5, inversion: 1

      c1 = major.dominant.chord :eleventh, inversion: 1
      c1 = major.dominant.chord 6, inversion: 1

      c1 = major.dominant.chord :thirteenth, inversion: 1
      c1 = major.dominant.chord 7, inversion: 1
    end

    it '' do

      c = Chord.new root: 60,
                    root: major.tonic,
                    scale_system: scale_system[:major],
                    scale: major,
                    # NO: specie: :major,
                    name: :major, # :minor, :maj7, :min
                    size: 3, # :fifth, :seventh, :sixth?, ...
                    # NO: generative_interval: :third, # :fourth, :fifth?
                    inversion: 1,
                    state: :third,
                    position: :fifth,
                    duplicate: { third: -1 },
                    move: { fifth: 1 },
                    drop: { third: 0 } # drop: :third, drop: [ :third, :root ]


    end
  end
end
