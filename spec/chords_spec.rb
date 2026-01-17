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

  context 'Chord-scale navigation' do
    scale_system = Musa::Scales::Scales[:et12][440.0]
    c_major = scale_system[:major][60]

    it 'Scale#contains_chord? returns true for diatonic chord' do
      chord = c_major.dominant.chord :seventh  # G7
      expect(c_major.contains_chord?(chord)).to be true
    end

    it 'Scale#contains_chord? returns false for non-diatonic chord' do
      chord = c_major.tonic.chord.with_quality(:minor)  # Cm (Eb not in C major)
      expect(c_major.contains_chord?(chord)).to be false
    end

    it 'Scale#degree_of_chord returns correct grade' do
      chord = c_major.dominant.chord  # G
      expect(c_major.degree_of_chord(chord)).to eq 4
    end

    it 'Scale#degree_of_chord returns nil for non-diatonic chord' do
      chord = c_major.tonic.chord.with_quality(:minor)  # Cm
      expect(c_major.degree_of_chord(chord)).to be_nil
    end

    it 'Scale#chord_on returns chord with new scale context' do
      g_mixolydian = scale_system[:mixolydian][67]
      chord = c_major.dominant.chord :seventh  # G7
      new_chord = g_mixolydian.chord_on(chord)

      expect(new_chord).not_to be_nil
      expect(new_chord.scale).to eq g_mixolydian
      expect(new_chord.root.pitch).to eq chord.root.pitch
    end

    it 'Scale#chord_on returns nil for non-contained chord' do
      a_major = scale_system[:major][69]
      chord = c_major.dominant.chord :seventh  # G7 (has F natural, not in A major)
      expect(a_major.chord_on(chord)).to be_nil
    end

    it 'ScaleKind#scales_containing finds matching scales' do
      chord = c_major.dominant.chord  # G major triad
      results = scale_system[:major].scales_containing(chord)

      expect(results.length).to eq 3  # C major (V), G major (I), D major (IV)
      expect(results.map { |c| c.scale.root_pitch % 12 }).to contain_exactly(0, 7, 2)
    end

    it 'ScaleSystemTuning#chords_of searches across scale types with metadata filtering' do
      chord = c_major.dominant.chord :seventh  # G7
      results = scale_system.chords_of(chord, family: :diatonic)

      # G7 appears in diatonic scales: C major (V), possibly others
      expect(results).not_to be_empty
      results.each do |result_chord|
        expect(result_chord.scale.kind.class.metadata[:family]).to eq :diatonic
      end
    end

    it 'ScaleSystemTuning#chords_of filters by brightness range' do
      chord = c_major.tonic.chord  # C major triad
      results = scale_system.chords_of(chord, brightness: 0..2)

      expect(results).not_to be_empty
      results.each do |result_chord|
        brightness = result_chord.scale.kind.class.metadata[:brightness]
        expect(brightness).to be_between(0, 2) if brightness
      end
    end

    it 'Chord#in_scales finds all containing scales with metadata filtering' do
      chord = c_major.dominant.chord  # G major triad
      results = chord.in_scales(family: :diatonic)

      expect(results).not_to be_empty
      results.each do |result_chord|
        expect(result_chord.scale).not_to be_nil
        expect(result_chord.root.pitch % 12).to eq(chord.root.pitch % 12)
        expect(result_chord.scale.kind.class.metadata[:family]).to eq :diatonic
      end
    end

    it 'Chord#in_scales without filters searches all scale types' do
      chord = c_major.tonic.chord  # C major triad
      results = chord.in_scales

      # Should find chord in many scales across all families
      expect(results.length).to be > 10
    end

    # Edge cases with chromatic alterations
    it 'handles harmonic minor scale (raised 7th)' do
      a_harmonic_minor = scale_system[:minor_harmonic][69]  # A harmonic minor
      e7 = a_harmonic_minor.dominant.chord :seventh  # E7 with G#

      expect(a_harmonic_minor.contains_chord?(e7)).to be true
      expect(a_harmonic_minor.degree_of_chord(e7)).to eq 4

      # E7 should NOT be in A natural minor (has G natural, not G#)
      a_natural_minor = scale_system[:minor][69]
      expect(a_natural_minor.contains_chord?(e7)).to be false
    end

    it 'handles melodic minor scale' do
      c_melodic_minor = scale_system[:minor_melodic][60]
      # Melodic minor has raised 6th and 7th: C-D-Eb-F-G-A-B

      # Chord on IV degree should have A natural (raised 6th)
      fourth_chord = c_melodic_minor[3].chord  # F-A-C
      expect(c_melodic_minor.contains_chord?(fourth_chord)).to be true
    end

    it 'finds dominant 7th chord across diatonic scales' do
      # G7 (G-B-D-F) should be in C major (as V7) and C harmonic minor (as V7)
      # C harmonic minor has: C-D-Eb-F-G-Ab-B (raised 7th = B natural)
      # G7 pitches (mod 12): G=7, B=11, D=2, F=5 - all present in C harmonic minor
      g7 = c_major.dominant.chord :seventh
      results = g7.in_scales(family: :diatonic)

      # Filter to only C root (pitch 0 mod 12) to verify both major and harmonic minor contain G7
      c_rooted = results.select { |c| c.scale.root_pitch % 12 == 0 }
      scale_kinds = c_rooted.map { |c| c.scale.kind.class.id }
      expect(scale_kinds).to include(:major)
      expect(scale_kinds).to include(:minor_harmonic)
    end

    it 'preserves voicing (move/duplicate) when creating chord_on' do
      chord = c_major.dominant.chord(:seventh).move(root: -1).duplicate(fifth: 1)
      g_mixolydian = scale_system[:mixolydian][67]
      new_chord = g_mixolydian.chord_on(chord)

      expect(new_chord.move).to eq chord.move
      expect(new_chord.duplicate).to eq chord.duplicate
    end
  end
end
