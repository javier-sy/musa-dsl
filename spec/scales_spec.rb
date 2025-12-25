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

  context 'Greek modes (church modes)' do
    scale_system = Musa::Scales::Scales[:et12][440.0]

    it 'Dorian mode pitch structure and functions' do
      # D Dorian: D E F G A B C (minor with major 6th)
      scale = scale_system[:dorian][62]

      expect(scale.kind.class.id).to eq :dorian
      expect(scale.kind.class.grades).to eq 7
      expect(scale.root.pitch).to eq 62

      # Test pitch structure: 0,2,3,5,7,9,10
      expect(scale[0].pitch).to eq 62  # D (tonic)
      expect(scale[1].pitch).to eq 64  # E (supertonic, +2)
      expect(scale[2].pitch).to eq 65  # F (mediant, +3)
      expect(scale[3].pitch).to eq 67  # G (subdominant, +5)
      expect(scale[4].pitch).to eq 69  # A (dominant, +7)
      expect(scale[5].pitch).to eq 71  # B (submediant, +9 - major 6th)
      expect(scale[6].pitch).to eq 72  # C (subtonic, +10)

      # Test function access (lowercase for minor mode)
      expect(scale[:i].pitch).to eq 62
      expect(scale[:vi].pitch).to eq 71  # Major 6th (characteristic of Dorian)
      expect(scale.tonic.pitch).to eq 62
      expect(scale.dominant.pitch).to eq 69
    end

    it 'Phrygian mode pitch structure and functions' do
      # E Phrygian: E F G A B C D (minor with minor 2nd)
      scale = scale_system[:phrygian][64]

      expect(scale.kind.class.id).to eq :phrygian
      expect(scale.kind.class.grades).to eq 7
      expect(scale.root.pitch).to eq 64

      # Test pitch structure: 0,1,3,5,7,8,10
      expect(scale[0].pitch).to eq 64  # E (tonic)
      expect(scale[1].pitch).to eq 65  # F (supertonic, +1 - minor 2nd)
      expect(scale[2].pitch).to eq 67  # G (mediant, +3)
      expect(scale[3].pitch).to eq 69  # A (subdominant, +5)
      expect(scale[4].pitch).to eq 71  # B (dominant, +7)
      expect(scale[5].pitch).to eq 72  # C (submediant, +8)
      expect(scale[6].pitch).to eq 74  # D (subtonic, +10)

      # Test function access (lowercase for minor mode)
      expect(scale[:i].pitch).to eq 64
      expect(scale[:ii].pitch).to eq 65  # Minor 2nd (characteristic of Phrygian)
      expect(scale.tonic.pitch).to eq 64
    end

    it 'Lydian mode pitch structure and functions' do
      # F Lydian: F G A B C D E (major with augmented 4th)
      scale = scale_system[:lydian][65]

      expect(scale.kind.class.id).to eq :lydian
      expect(scale.kind.class.grades).to eq 7
      expect(scale.root.pitch).to eq 65

      # Test pitch structure: 0,2,4,6,7,9,11
      expect(scale[0].pitch).to eq 65  # F (tonic)
      expect(scale[1].pitch).to eq 67  # G (supertonic, +2)
      expect(scale[2].pitch).to eq 69  # A (mediant, +4)
      expect(scale[3].pitch).to eq 71  # B (subdominant, +6 - augmented 4th)
      expect(scale[4].pitch).to eq 72  # C (dominant, +7)
      expect(scale[5].pitch).to eq 74  # D (submediant, +9)
      expect(scale[6].pitch).to eq 76  # E (leading, +11)

      # Test function access (uppercase for major mode)
      expect(scale[:I].pitch).to eq 65
      expect(scale[:IV].pitch).to eq 71  # Augmented 4th (characteristic of Lydian)
      expect(scale.tonic.pitch).to eq 65
    end

    it 'Mixolydian mode pitch structure and functions' do
      # G Mixolydian: G A B C D E F (major with minor 7th)
      scale = scale_system[:mixolydian][67]

      expect(scale.kind.class.id).to eq :mixolydian
      expect(scale.kind.class.grades).to eq 7
      expect(scale.root.pitch).to eq 67

      # Test pitch structure: 0,2,4,5,7,9,10
      expect(scale[0].pitch).to eq 67  # G (tonic)
      expect(scale[1].pitch).to eq 69  # A (supertonic, +2)
      expect(scale[2].pitch).to eq 71  # B (mediant, +4)
      expect(scale[3].pitch).to eq 72  # C (subdominant, +5)
      expect(scale[4].pitch).to eq 74  # D (dominant, +7)
      expect(scale[5].pitch).to eq 76  # E (submediant, +9)
      expect(scale[6].pitch).to eq 77  # F (subtonic, +10 - minor 7th)

      # Test function access (uppercase for major mode)
      expect(scale[:I].pitch).to eq 67
      expect(scale[:VII].pitch).to eq 77  # Minor 7th (characteristic of Mixolydian)
      expect(scale.tonic.pitch).to eq 67
    end

    it 'Locrian mode pitch structure and functions' do
      # B Locrian: B C D E F G A (diminished 5th and minor 2nd)
      scale = scale_system[:locrian][71]

      expect(scale.kind.class.id).to eq :locrian
      expect(scale.kind.class.grades).to eq 7
      expect(scale.root.pitch).to eq 71

      # Test pitch structure: 0,1,3,5,6,8,10
      expect(scale[0].pitch).to eq 71  # B (tonic)
      expect(scale[1].pitch).to eq 72  # C (supertonic, +1 - minor 2nd)
      expect(scale[2].pitch).to eq 74  # D (mediant, +3)
      expect(scale[3].pitch).to eq 76  # E (subdominant, +5)
      expect(scale[4].pitch).to eq 77  # F (dominant, +6 - diminished 5th)
      expect(scale[5].pitch).to eq 79  # G (submediant, +8)
      expect(scale[6].pitch).to eq 81  # A (subtonic, +10)

      # Test function access (lowercase for minor/diminished mode)
      expect(scale[:i].pitch).to eq 71
      expect(scale[:ii].pitch).to eq 72  # Minor 2nd (characteristic of Locrian)
      expect(scale[:v].pitch).to eq 77   # Diminished 5th (characteristic of Locrian)
      expect(scale.tonic.pitch).to eq 71
    end

    it 'Access Greek modes by symbol and method' do
      sst = Musa::Scales::Scales.et12[440.0]

      expect(sst.dorian).to be sst[:dorian]
      expect(sst.phrygian).to be sst[:phrygian]
      expect(sst.lydian).to be sst[:lydian]
      expect(sst.mixolydian).to be sst[:mixolydian]
      expect(sst.locrian).to be sst[:locrian]

      expect(sst.dorian[62]).to be sst[:dorian][62]
    end

    it 'Extended degrees (viii-xiii) for Greek modes' do
      scale = scale_system[:dorian][62]

      # Extended degrees should wrap to next octave
      expect(scale[7].pitch).to eq 62 + 12   # viii = tonic + octave
      expect(scale[8].pitch).to eq 64 + 12   # ix = supertonic + octave
      expect(scale[9].pitch).to eq 65 + 12   # x = mediant + octave
      expect(scale[10].pitch).to eq 67 + 12  # xi = subdominant + octave
      expect(scale[11].pitch).to eq 69 + 12  # xii = dominant + octave
      expect(scale[12].pitch).to eq 71 + 12  # xiii = submediant + octave
    end
  end

  context 'ScaleKind metadata system' do
    let(:scale_system) { Musa::Scales::Scales[:et12][440.0] }
    let(:major_kind) { scale_system[:major].class }
    let(:dorian_kind) { scale_system[:dorian].class }
    let(:minor_kind) { scale_system[:minor].class }

    describe 'intrinsic_metadata' do
      it 'derives id from scale structure' do
        expect(major_kind.intrinsic_metadata[:id]).to eq :major
        expect(dorian_kind.intrinsic_metadata[:id]).to eq :dorian
      end

      it 'derives grades from scale structure' do
        expect(major_kind.intrinsic_metadata[:grades]).to eq 7
        expect(dorian_kind.intrinsic_metadata[:grades]).to eq 7
      end

      it 'derives pitches from scale structure' do
        expect(major_kind.intrinsic_metadata[:pitches]).to include(0, 2, 4, 5, 7, 9, 11)
      end

      it 'calculates intervals between degrees' do
        # Major scale intervals within first octave: W-W-H-W-W-W-H = 2-2-1-2-2-2-1
        expect(major_kind.intrinsic_metadata[:intervals]).to eq [2, 2, 1, 2, 2, 2, 1]
      end

      it 'detects leading tone (pitch 11)' do
        expect(major_kind.intrinsic_metadata[:has_leading_tone]).to be true
        expect(minor_kind.intrinsic_metadata[:has_leading_tone]).to be false
      end

      it 'detects tritone (pitch 6)' do
        expect(scale_system[:lydian].class.intrinsic_metadata[:has_tritone]).to be true
        expect(major_kind.intrinsic_metadata[:has_tritone]).to be false
      end

      it 'detects symmetric patterns' do
        whole_tone = scale_system[:whole_tone].class
        expect(whole_tone.intrinsic_metadata[:symmetric]).to eq :equal
      end
    end

    describe 'base_metadata' do
      it 'returns defined base metadata for major scale' do
        expect(major_kind.base_metadata[:family]).to eq :diatonic
        expect(major_kind.base_metadata[:brightness]).to eq 0
        expect(major_kind.base_metadata[:character]).to include(:bright)
      end

      it 'returns defined base metadata for greek modes' do
        expect(dorian_kind.base_metadata[:family]).to eq :greek_modes
        expect(dorian_kind.base_metadata[:brightness]).to eq(-1)
        expect(dorian_kind.base_metadata[:parent]).to eq({ scale: :major, degree: 2 })
      end

      it 'returns empty hash for parent scale (base_metadata has nil parent)' do
        expect(major_kind.base_metadata[:parent]).to be_nil
      end
    end

    describe 'custom_metadata' do
      after { major_kind.reset_custom_metadata }

      it 'allows extending with custom metadata' do
        major_kind.extend_metadata(my_tag: :favorite, rating: 5)
        expect(major_kind.custom_metadata[:my_tag]).to eq :favorite
        expect(major_kind.custom_metadata[:rating]).to eq 5
      end

      it 'merges multiple extend_metadata calls' do
        major_kind.extend_metadata(tag1: :a)
        major_kind.extend_metadata(tag2: :b)
        expect(major_kind.custom_metadata).to include(tag1: :a, tag2: :b)
      end

      it 'can be reset' do
        major_kind.extend_metadata(temp: :data)
        major_kind.reset_custom_metadata
        expect(major_kind.custom_metadata).to be_empty
      end
    end

    describe 'metadata (combined)' do
      after { major_kind.reset_custom_metadata }

      it 'combines all three layers' do
        major_kind.extend_metadata(user_note: 'my favorite')

        metadata = major_kind.metadata

        # Intrinsic
        expect(metadata[:grades]).to eq 7
        # Base
        expect(metadata[:family]).to eq :diatonic
        # Custom
        expect(metadata[:user_note]).to eq 'my favorite'
      end

      it 'custom overrides base which overrides intrinsic' do
        major_kind.extend_metadata(family: :my_custom_family)
        expect(major_kind.metadata[:family]).to eq :my_custom_family
      end
    end

    describe 'metadata queries' do
      after { major_kind.reset_custom_metadata }

      it 'has_metadata? checks key existence' do
        expect(major_kind.has_metadata?(:family)).to be true
        expect(major_kind.has_metadata?(:nonexistent)).to be false
      end

      it 'has_metadata? checks value match' do
        expect(major_kind.has_metadata?(:family, :diatonic)).to be true
        expect(major_kind.has_metadata?(:family, :other)).to be false
      end

      it 'has_metadata? checks array inclusion' do
        expect(major_kind.has_metadata?(:character, :bright)).to be true
        expect(major_kind.has_metadata?(:character, :nonexistent)).to be false
      end

      it 'metadata_value returns specific value' do
        expect(major_kind.metadata_value(:family)).to eq :diatonic
        expect(major_kind.metadata_value(:brightness)).to eq 0
      end
    end

    describe 'Scales.extend_metadata helper' do
      after { major_kind.reset_custom_metadata }

      it 'extends metadata by scale kind ID' do
        Musa::Scales::Scales.extend_metadata(:major, custom_field: :value)
        expect(major_kind.metadata[:custom_field]).to eq :value
      end
    end
  end

  context 'ScaleSystemTuning#scale_kinds' do
    let(:tuning) { Musa::Scales::Scales[:et12][440.0] }

    it 'returns all scale kinds without arguments' do
      result = tuning.scale_kinds
      expect(result).to be_an(Array)
      expect(result.size).to eq 32
      expect(result.first).to be_a(Musa::Scales::ScaleKind)
    end

    it 'filters by single metadata value' do
      result = tuning.scale_kinds(family: :diatonic)
      ids = result.map { |k| k.class.id }
      expect(ids).to include(:major, :minor, :minor_harmonic, :major_harmonic)
      expect(ids).not_to include(:dorian, :blues)
    end

    it 'filters by range' do
      result = tuning.scale_kinds(brightness: 0..2)
      result.each do |kind|
        brightness = kind.class.metadata[:brightness]
        expect(brightness).to be_between(0, 2) if brightness
      end
    end

    it 'filters by character array inclusion' do
      result = tuning.scale_kinds(character: :jazz)
      expect(result).not_to be_empty
      result.each do |kind|
        expect(kind.class.metadata[:character]).to include(:jazz)
      end
    end

    it 'filters with block' do
      result = tuning.scale_kinds { |klass| klass.intrinsic_metadata[:has_leading_tone] }
      expect(result).not_to be_empty
      result.each do |kind|
        expect(kind.class.intrinsic_metadata[:has_leading_tone]).to be true
      end
    end

    it 'combines metadata criteria and block' do
      result = tuning.scale_kinds(family: :greek_modes) { |klass| klass.metadata[:brightness]&.negative? }
      ids = result.map { |k| k.class.id }
      expect(ids).to include(:dorian, :phrygian, :locrian)
      expect(ids).not_to include(:lydian, :mixolydian)
    end

    it 'returns empty array when no matches' do
      result = tuning.scale_kinds(family: :nonexistent_family)
      expect(result).to eq []
    end
  end
end
