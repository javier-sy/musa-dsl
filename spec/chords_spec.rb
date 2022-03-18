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

    it 'Chord features read-only' do
      chord = major.tonic.chord

      expect { chord.features.clear }.to raise_error(FrozenError)
    end

    it 'Basic triad major chord creation' do
      maj3 = major.tonic.chord

      expect(maj3.root.pitch).to eq 60
      expect(maj3.scale).to be major
      expect(maj3.features).to include(quality: :major)

      expect(maj3.root.pitch).to eq 60
      expect(maj3.root.grade).to eq 0
      expect(maj3.root.octave).to eq 0
      expect(maj3.root.scale).to be major

      expect(maj3.third.pitch).to eq 64
      expect(maj3.third.grade).to eq 2
      expect(maj3.third.octave).to eq 0
      expect(maj3.third.scale).to be major

      expect(maj3.fifth(all: true).first.pitch).to eq 67
      expect(maj3.fifth(all: true).first.grade).to eq 4
      expect(maj3.fifth(all: true).first.octave).to eq 0
      expect(maj3.fifth(all: true).first.scale).to be major

      expect { maj3.seventh }.to raise_error(NoMethodError)

      expect(maj3.notes.size).to eq 3
    end

    it 'Basic triad major chord creation' do
      maj3 = major.tonic.chord

      expect(maj3.root.pitch).to eq 60
      expect(maj3.scale).to be major
      expect(maj3.features).to include(quality: :major)

      expect(maj3.root.pitch).to eq 60
      expect(maj3.root.grade).to eq 0
      expect(maj3.root.octave).to eq 0
      expect(maj3.root.scale).to be major

      expect(maj3.third.pitch).to eq 64
      expect(maj3.third.grade).to eq 2
      expect(maj3.third.octave).to eq 0
      expect(maj3.third.scale).to be major

      expect(maj3.fifth.pitch).to eq 67
      expect(maj3.fifth.grade).to eq 4
      expect(maj3.fifth.octave).to eq 0
      expect(maj3.fifth.scale).to be major

      expect(maj3.notes.size).to eq 3
    end

    it 'Basic triad major to minor chord navigation' do
      maj3 = major.tonic.chord

      min3 = maj3.with_quality(:minor)

      expect(min3.root.pitch).to eq 60
      expect(min3.features).to include(quality: :minor)

      expect(min3.scale).to eq nil

      expect(min3.root.pitch).to eq 60
      expect(min3.root.grade).to eq 0
      expect(min3.root.octave).to eq 0
      expect(min3.root.scale).to be major

      expect(min3.third.pitch).to eq 63
      expect(min3.third.grade).to eq 3
      expect(min3.third.octave).to eq 0
      expect(min3.third.scale).to eq chromatic

      expect(min3.fifth.pitch).to eq 67
      expect(min3.fifth.grade).to eq 4
      expect(min3.fifth.octave).to eq 0
      expect(min3.fifth.scale).to be major

      expect(min3.notes.size).to eq 3
    end

    it 'Big chords on major scale over dominant' do
      c = major.dominant.chord :triad

      expect(c.root.pitch).to eq 67
      expect(c.third.pitch).to eq 71
      expect(c.fifth.pitch).to eq 74
      expect { c.seventh }.to raise_error(NoMethodError)

      expect(c.notes.size).to eq 3

      c = major.dominant.chord :seventh, allow_chromatic: false

      expect(c.features).to include(quality: :dominant)

      expect(c.root.pitch).to eq 67
      expect(c.third.pitch).to eq 71
      expect(c.fifth.pitch).to eq 74
      expect(c.seventh.pitch).to eq 77
      expect { c.ninth }.to raise_error(NoMethodError)

      expect(c.notes.size).to eq 4

      c = major.dominant.chord :ninth, :major, allow_chromatic: true

      expect(c.root.pitch).to eq 67
      expect(c.third.pitch).to eq 71
      expect(c.fifth.pitch).to eq 74
      expect(c.seventh.pitch).to eq 78
      expect(c.ninth.pitch).to eq 81
      expect { c.eleventh }.to raise_error(NoMethodError)

      expect(c.notes.size).to eq 5

      c = major.dominant.chord :eleventh, :major, allow_chromatic: true

      expect(c.root.pitch).to eq 67
      expect(c.third.pitch).to eq 71
      expect(c.fifth.pitch).to eq 74
      expect(c.seventh.pitch).to eq 78
      expect(c.ninth.pitch).to eq 81
      expect(c.eleventh.pitch).to eq 84
      expect { c.thirteenth }.to raise_error(NoMethodError)

      expect(c.notes.size).to eq 6
    end

    it 'Notes moved to another absolute octave' do
      c = major.dominant.chord(:seventh, allow_chromatic: false).move(root: -1, third: -1, seventh: 1)

      expect(c.root.pitch).to eq (67 - 12)
      expect(c.third.pitch).to eq 71 - 12
      expect(c.fifth.pitch).to eq 74
      expect(c.seventh.pitch).to eq 77 + 12
      expect { c.ninth }.to raise_error(NoMethodError)
    end

    it 'Notes duplicated to another absolute octave' do
      c = major.dominant.chord(:seventh, allow_chromatic: false).duplicate(root: -2, third: [-1, 1])

      expect(c.root(all: true)[0].pitch).to eq 67
      expect(c.root(all: true)[1].pitch).to eq 67 - 24
      expect(c.root(all: true)[2]).to eq nil
      expect(c.third(all: true)[0].pitch).to eq 71
      expect(c.third(all: true)[1].pitch).to eq 71 - 12
      expect(c.third(all: true)[2].pitch).to eq 71 + 12
      expect(c.third(all: true)[3]).to eq nil
      expect(c.fifth(all: true)[0].pitch).to eq 74
      expect(c.fifth(all: true)[1]).to eq nil
      expect(c.seventh(all: true)[0].pitch).to eq 77
      expect(c.seventh(all: true)[1]).to eq nil
      expect { c.eleventh }.to raise_error(NoMethodError)
    end

    it 'Getting pitches' do
      c = major.dominant.chord(:seventh, allow_chromatic: false).duplicate(root: -2, third: [-1, 1])
      expect(c.pitches).to eq [67, 67 - 24, 71, 71 - 12, 71 + 12, 74, 77].sort
    end

    it 'Chord with notes moved and getting a featured chord from it' do
      c = major.root.chord(:triad, move: { fifth: 1 }).featuring(size: :seventh)
      d = major.root.chord(:triad).move(fifth: 1).featuring(size: :seventh)

      expect(c.pitches).to eq [60, 64, 67 + 12, 71].sort
      expect(d.pitches).to eq [60, 64, 67 + 12, 71].sort
    end

    it 'Chord with notes duplicated and getting a featured chord from it' do
      c = major.root.chord(:triad, duplicate: { fifth: 1 }).featuring(size: :seventh)
      d = major.root.chord(:triad).duplicate(fifth: 1).featuring(size: :seventh)

      expect(c.pitches.sort).to eq [60, 64, 67, 67 + 12, 71].sort
      expect(d.pitches.sort).to eq [60, 64, 67, 67 + 12, 71].sort
    end

    it 'Getting a chord on a different octave' do
      c = major.dominant.chord(:seventh, allow_chromatic: false).duplicate(root: -2, third: [-1, 1])
      d = c.octave(-1).pitches

      expect(d).to eq [67 - 12, 67 - 24 - 12, 71 - 12, 71 - 12 - 12, 71 + 12 - 12, 74 - 12, 77 - 12].sort
    end

    it 'Getting sorted notes pitches' do
      c = major.dominant.chord(:seventh, allow_chromatic: false).duplicate(root: -2, third: [-1, 1])
      expect(c.pitches).to eq [67, 67 - 24, 71, 71 - 12, 71 + 12, 74, 77].sort
      expect(c.notes.collect(&:note).collect(&:pitch)).to eq [67, 67 - 24, 71, 71 - 12, 71 + 12, 74, 77].sort
    end

    it 'Calling chord operations as parameters instead of using explicit methods' do
      vi_m = major.sixth.chord :triad, duplicate: { root: 1 }, move: { third: 1 }
      expect(vi_m.pitches.sort).to eq [69, 72 + 12, 76, 69 + 12].sort
    end

    it 'Bugfix: when a chord has a move operation generating a new chord it changes the original chord' do
      chord = major.root.chord(:seventh)
      expect(chord.pitches.sort).to eq [60, 64, 67, 71]

      other_chord = chord.move root: 1
      expect(other_chord.pitches.sort).to eq [64, 67, 71, 72]

      expect(chord.pitches.sort).to eq [60, 64, 67, 71]
    end
  end
end
