require 'spec_helper'

require 'musa-dsl'

RSpec.describe Musa::Scales::EquallyTempered12ToneScaleSystem do
  context 'Chords in equally tempered 12 tone scales' do
    scale_system = Musa::Scales::Scales[:et12][440.0]

    major = scale_system[:major][60]
    minor = major.octave(-1).relative_minor.scale(:minor)
    chromatic = scale_system[:chromatic][60]

    it 'Basic triad major chord creation from scale, with and without :triad feature' do
      maj3_a = major.tonic.chord
      maj3_b = major.tonic.chord :triad

      expect(maj3_a).to eq maj3_b
    end

    it 'Basic triad major chord creation' do
      maj3 = major.tonic.chord

      expect(maj3.root.first.pitch).to eq 60
      expect(maj3.scale).to be major
      expect(maj3.features).to include({quality: :major})

      expect(maj3[0].first.pitch).to eq 60
      expect(maj3[0].first.grade).to eq 0
      expect(maj3[0].first.octave).to eq 0
      expect(maj3[0].first.scale).to be major

      expect(maj3[:third].first.pitch).to eq 64
      expect(maj3[:third].first.grade).to eq 2
      expect(maj3[:third].first.octave).to eq 0
      expect(maj3[:third].first.scale).to be major

      expect(maj3[2].first.pitch).to eq 67
      expect(maj3[2].first.grade).to eq 4
      expect(maj3[2].first.octave).to eq 0
      expect(maj3[2].first.scale).to be major

      expect(maj3[3]).to eq nil
      expect(maj3.notes.size).to eq 3
    end

    it 'Basic triad major to minor chord navigation' do
      maj3 = major.tonic.chord

      min3 = maj3.minor

      expect(min3.root.first.pitch).to eq 60
      expect(min3.features).to include({quality: :minor})

      expect(min3.scale).to eq nil

      expect(min3[:root].first.pitch).to eq 60
      expect(min3[:root].first.grade).to eq 0
      expect(min3[:root].first.octave).to eq 0
      expect(min3[:root].first.scale).to be major

      expect(min3[1].first.pitch).to eq 63
      expect(min3[1].first.grade).to eq 3
      expect(min3[1].first.octave).to eq 0
      expect(min3[1].first.scale).to eq chromatic

      expect(min3[2].first.pitch).to eq 67
      expect(min3[2].first.grade).to eq 4
      expect(min3[2].first.octave).to eq 0
      expect(min3[2].first.scale).to be major

      expect(maj3[3]).to eq nil
      expect(min3.notes.size).to eq 3
    end

    it 'Basic triad major to minor chord navigation with modal change' do
      maj3 = major.tonic.chord

      min3 = maj3.minor

      matches = min3.project_on_all(major.tonic.minor, major.relative_minor.minor, chromatic)

      expect(matches.size).to eq 2

      chord = matches[0]

      expect(chord.root.first.pitch).to eq 60

      expect(chord.scale).to be scale_system[:minor][60]
      expect(chord[0].first.scale).to be scale_system[:minor][60]
      expect(chord[1].first.scale).to be scale_system[:minor][60]
      expect(chord[2].first.scale).to be scale_system[:minor][60]

      chord = matches[1]

      expect(chord.root.first.pitch).to eq 60

      expect(chord.scale).to be scale_system[:chromatic][60]
      expect(chord[0].first.scale).to be scale_system[:chromatic][60]
      expect(chord[1].first.scale).to be scale_system[:chromatic][60]
      expect(chord[2].first.scale).to be scale_system[:chromatic][60]
    end

    it 'Basic triad chord chromatically defined to major chord navigation' do
      c3 = chromatic.chord_of 0, 3, 7

      expect(c3.project_on(major)).to eq nil

      c3 = chromatic.chord_of 0, 4, 7

      maj3 = c3.project_on(major)

      expect(maj3.scale).to be major
      expect(maj3.root.first.pitch).to eq 60
      expect(maj3.features).to include({quality: :major})

      expect(maj3[:root].first.pitch).to eq 60
      expect(maj3[:root].first.octave).to eq 0
      expect(maj3[:root].first.scale).to be major

      expect(maj3[:third].first.pitch).to eq 64
      expect(maj3[:third].first.octave).to eq 0
      expect(maj3[:third].first.scale).to be major

      expect(maj3[:fifth].first.pitch).to eq 67
      expect(maj3[:fifth].first.octave).to eq 0
      expect(maj3[:fifth].first.scale).to be major

      expect(maj3[3]).to eq nil
      expect(maj3.notes.size).to eq 3
    end

    it 'Big chords on major scale over dominant' do
      c = major.dominant.chord :triad

      expect(c[0].first.pitch).to eq 67
      expect(c[1].first.pitch).to eq 71
      expect(c[2].first.pitch).to eq 74
      expect(c[3]).to eq nil

      expect(c.notes.size).to eq 3

      c = major.dominant.chord :seventh, allow_chromatic: false

      expect(c.features).to include({dominant: :dominant})

      expect(c[0].first.pitch).to eq 67
      expect(c[1].first.pitch).to eq 71
      expect(c[2].first.pitch).to eq 74
      expect(c[3].first.pitch).to eq 77
      expect(c[4]).to eq nil

      expect(c.notes.size).to eq 4

      c = major.dominant.chord :ninth, :major

      expect(c[:root].first.pitch).to eq 67
      expect(c[:third].first.pitch).to eq 71
      expect(c[:fifth].first.pitch).to eq 74
      expect(c[:seventh].first.pitch).to eq 78
      expect(c[:ninth].first.pitch).to eq 81
      expect(c[5]).to eq nil

      expect(c.notes.size).to eq 5

      c = major.dominant.chord :eleventh, :major

      expect(c[0].first.pitch).to eq 67
      expect(c[1].first.pitch).to eq 71
      expect(c[2].first.pitch).to eq 74
      expect(c[3].first.pitch).to eq 78
      expect(c[4].first.pitch).to eq 81
      expect(c[5].first.pitch).to eq 84
      expect(c[6]).to eq nil

      expect(c.notes.size).to eq 6
    end

    it 'V7/V chord' do
      chord = major.dominant.octave(-1).major.dominant.chord :seventh, allow_chromatic: false

      expect(chord.features).to include({dominant: :dominant})

      expect(chord.project_on(major)).to eq nil
      expect(chord.project_on(major, allow_chromatic: true).notes.size).to eq 4
    end

    it 'Notes moved to another absolute octave' do
      c = major.dominant.chord(:seventh, allow_chromatic: false).move(root: -1, third: -1, seventh: 1)

      expect(c[0].first.pitch).to eq 67 - 12
      expect(c[1].first.pitch).to eq 71 - 12
      expect(c[2].first.pitch).to eq 74
      expect(c[3].first.pitch).to eq 77 + 12
      expect(c[4]).to eq nil
    end

    it 'Notes duplicated to another absolute octave' do
      c = major.dominant.chord(:seventh, allow_chromatic: false).duplicate(root: -2, third: [-1, 1])

      expect(c[:root][0].pitch).to eq 67
      expect(c[:root][1].pitch).to eq 67 - 24
      expect(c[:root][2]).to eq nil
      expect(c[:third][0].pitch).to eq 71
      expect(c[:third][1].pitch).to eq 71 - 12
      expect(c[:third][2].pitch).to eq 71 + 12
      expect(c[:third][3]).to eq nil
      expect(c[:fifth][0].pitch).to eq 74
      expect(c[:fifth][1]).to eq nil
      expect(c[:seventh][0].pitch).to eq 77
      expect(c[:seventh][1]).to eq nil
      expect(c[4]).to eq nil
    end

    it 'Getting pitches' do
      c = major.dominant.chord(:seventh, allow_chromatic: false).duplicate(root: -2, third: [-1, 1])
      expect(c.pitches).to eq [67, 67 - 24, 71, 71 - 12, 71 + 12, 74, 77]
    end

    it 'test to be refined', pending: true do
      # TODO Complete the test and the functionality
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

    it 'test to be refined', pending: true do
      # TODO Complete the test and the functionality
      c = Chord.new root: major.tonic,
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

      c = Chord.new root: 60,
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
