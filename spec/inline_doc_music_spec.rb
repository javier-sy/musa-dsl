require 'docs_helper'

using Musa::Extension::Neumas
using Musa::Extension::Matrix

RSpec.describe 'Music Inline Documentation Examples' do
  include Musa::Scales
  include Musa::Chords

  context 'Scales Module Documentation' do
    it 'demonstrates Scales registry access by symbol' do
      # From Scales module @example: Accessing scale systems
      system = Scales[:et12]

      expect(system).to eq(Musa::Scales::EquallyTempered12ToneScaleSystem)
    end

    it 'demonstrates Scales registry access by method' do
      # From Scales module @example: Accessing scale systems
      system = Scales.et12

      expect(system).to eq(Musa::Scales::EquallyTempered12ToneScaleSystem)
    end

    it 'demonstrates Scales registry default system access' do
      # From Scales module @example: Accessing scale systems
      system = Scales.default_system

      expect(system).to eq(Musa::Scales::EquallyTempered12ToneScaleSystem)
    end

    it 'demonstrates working with tunings' do
      # From Scales module @example: Working with tunings
      tuning = Scales[:et12][440.0]

      expect(tuning).to be_a(Musa::Scales::ScaleSystemTuning)
      expect(tuning.a_frequency).to eq(440.0)
    end

    it 'demonstrates baroque pitch tuning' do
      # From Scales module @example: Working with tunings
      baroque = Scales[:et12][415.0]

      expect(baroque).to be_a(Musa::Scales::ScaleSystemTuning)
      expect(baroque.a_frequency).to eq(415.0)
    end

    it 'demonstrates building scales' do
      # From Scales module @example: Building scales
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      a_minor = tuning.minor[69]

      expect(c_major).to be_a(Musa::Scales::Scale)
      expect(c_major.root_pitch).to eq(60)
      expect(a_minor).to be_a(Musa::Scales::Scale)
      expect(a_minor.root_pitch).to eq(69)
    end
  end

  context 'ScaleSystem Documentation' do
    it 'demonstrates ScaleSystem.id' do
      # From ScaleSystem @example
      id = Musa::Scales::EquallyTempered12ToneScaleSystem.id

      expect(id).to eq(:et12)
    end

    it 'demonstrates ScaleSystem.notes_in_octave' do
      # From ScaleSystem @example
      notes = Musa::Scales::EquallyTempered12ToneScaleSystem.notes_in_octave

      expect(notes).to eq(12)
    end

    it 'demonstrates ScaleSystem.part_of_tone_size' do
      # From ScaleSystem @example
      size = Musa::Scales::EquallyTempered12ToneScaleSystem.part_of_tone_size

      expect(size).to eq(1)
    end

    it 'demonstrates ScaleSystem.intervals' do
      # From ScaleSystem @example
      intervals = Musa::Scales::EquallyTempered12ToneScaleSystem.intervals

      expect(intervals[:M3]).to eq(4)  # major third = 4 semitones
      expect(intervals[:P5]).to eq(7)  # perfect fifth = 7 semitones
      expect(intervals[:m7]).to eq(10) # minor seventh = 10 semitones
    end

    it 'demonstrates equal temperament frequency calculation for A440' do
      # From EquallyTempered12ToneScaleSystem @example: Standard A440 tuning
      frequency = Musa::Scales::EquallyTempered12ToneScaleSystem.frequency_of_pitch(69, nil, 440.0)

      expect(frequency).to be_within(0.01).of(440.0)
    end

    it 'demonstrates equal temperament frequency calculation for middle C' do
      # From EquallyTempered12ToneScaleSystem @example: Standard A440 tuning
      frequency = Musa::Scales::EquallyTempered12ToneScaleSystem.frequency_of_pitch(60, nil, 440.0)

      expect(frequency).to be_within(0.01).of(261.63)
    end

    it 'demonstrates baroque tuning frequency calculation' do
      # From EquallyTempered12ToneScaleSystem @example: Baroque tuning
      frequency = Musa::Scales::EquallyTempered12ToneScaleSystem.frequency_of_pitch(69, nil, 415.0)

      expect(frequency).to be_within(0.01).of(415.0)
    end

    it 'demonstrates ScaleSystem tuning access with standard pitch' do
      # From ScaleSystem @example
      tuning = Musa::Scales::EquallyTempered12ToneScaleSystem[440.0]

      expect(tuning).to be_a(Musa::Scales::ScaleSystemTuning)
      expect(tuning.a_frequency).to eq(440.0)
    end

    it 'demonstrates ScaleSystem tuning access with baroque pitch' do
      # From ScaleSystem @example
      baroque = Musa::Scales::EquallyTempered12ToneScaleSystem[415.0]

      expect(baroque).to be_a(Musa::Scales::ScaleSystemTuning)
      expect(baroque.a_frequency).to eq(415.0)
    end

    it 'demonstrates ScaleSystem tuning access with modern high pitch' do
      # From ScaleSystem @example
      modern = Musa::Scales::EquallyTempered12ToneScaleSystem[442.0]

      expect(modern).to be_a(Musa::Scales::ScaleSystemTuning)
      expect(modern.a_frequency).to eq(442.0)
    end

    it 'demonstrates offset_of_interval' do
      # From ScaleSystem @example
      offset = Musa::Scales::EquallyTempered12ToneScaleSystem.offset_of_interval(:P5)

      expect(offset).to eq(7)
    end
  end

  context 'ScaleSystemTuning Documentation' do
    it 'demonstrates standard usage' do
      # From ScaleSystemTuning @example: Standard usage
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      a_minor = tuning.minor[69]

      expect(c_major).to be_a(Musa::Scales::Scale)
      expect(a_minor).to be_a(Musa::Scales::Scale)
    end

    it 'demonstrates historical pitch' do
      # From ScaleSystemTuning @example: Historical pitch
      baroque = Scales[:et12][415.0]
      scale = baroque.major[60]

      expect(scale).to be_a(Musa::Scales::Scale)
      expect(scale.kind.tuning.a_frequency).to eq(415.0)
    end
  end

  context 'ScaleKind Documentation' do
    it 'demonstrates ScaleKind.id for MajorScaleKind' do
      # From ScaleKind @example
      id = Musa::Scales::MajorScaleKind.id

      expect(id).to eq(:major)
    end

    it 'demonstrates ScaleKind.chromatic? for ChromaticScaleKind' do
      # From ScaleKind @example
      is_chromatic = Musa::Scales::ChromaticScaleKind.chromatic?
      is_major_chromatic = Musa::Scales::MajorScaleKind.chromatic?

      expect(is_chromatic).to be true
      expect(is_major_chromatic).to be false
    end

    it 'demonstrates ScaleKind.grades for MajorScaleKind' do
      # From ScaleKind @example
      grades = Musa::Scales::MajorScaleKind.grades

      expect(grades).to eq(7)
    end

    it 'demonstrates ScaleKind.grade_of_function' do
      # From ScaleKind @example
      tonic_grade = Musa::Scales::MajorScaleKind.grade_of_function(:tonic)
      dominant_grade = Musa::Scales::MajorScaleKind.grade_of_function(:dominant)
      v_grade = Musa::Scales::MajorScaleKind.grade_of_function(:V)

      expect(tonic_grade).to eq(0)
      expect(dominant_grade).to eq(4)
      expect(v_grade).to eq(4)
    end

    it 'demonstrates creating scales from scale kind' do
      # From ScaleKind @example
      tuning = Scales.default_system.default_tuning
      major_kind = tuning[:major]
      c_major = major_kind[60]
      g_major = major_kind[67]

      expect(c_major).to be_a(Musa::Scales::Scale)
      expect(c_major.root_pitch).to eq(60)
      expect(g_major).to be_a(Musa::Scales::Scale)
      expect(g_major.root_pitch).to eq(67)
    end

    it 'demonstrates default_root' do
      # From ScaleKind @example
      tuning = Scales.default_system.default_tuning
      default = tuning.major.default_root

      expect(default).to be_a(Musa::Scales::Scale)
      expect(default.root_pitch).to eq(60)
    end

    it 'demonstrates absolut' do
      # From ScaleKind @example
      tuning = Scales.default_system.default_tuning
      absolut = tuning.major.absolut

      expect(absolut).to be_a(Musa::Scales::Scale)
      expect(absolut.root_pitch).to eq(0)
    end
  end

  context 'Scale Documentation' do
    it 'demonstrates basic scale access' do
      # From Scale @example: Basic scale access
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]

      expect(c_major.tonic.pitch).to eq(60)
      expect(c_major.dominant.pitch).to eq(67)
      expect(c_major[:III].pitch).to eq(64)
    end

    it 'demonstrates chromatic alterations' do
      # From Scale @example: Chromatic alterations
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]

      expect(c_major[:'I#'].pitch).to eq(61)
      expect(c_major[:V_].pitch).to eq(66)
    end

    it 'demonstrates building chords from scale' do
      # From Scale @example: Building chords
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]

      i_chord = c_major.tonic.chord
      v_seventh = c_major.dominant.chord :seventh

      expect(i_chord).to be_a(Musa::Chords::Chord)
      expect(v_seventh).to be_a(Musa::Chords::Chord)
    end

    it 'demonstrates Scale#root' do
      # From Scale @example
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]

      expect(c_major.root.pitch).to eq(60)
    end

    it 'demonstrates Scale#chromatic' do
      # From Scale @example
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      chromatic = c_major.chromatic

      expect(chromatic).to be_a(Musa::Scales::Scale)
      expect(chromatic.root_pitch).to eq(60)
      expect(chromatic.kind.class).to eq(Musa::Scales::ChromaticScaleKind)
    end

    it 'demonstrates Scale#absolut' do
      # From Scale @example
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      absolut = c_major.absolut

      expect(absolut).to be_a(Musa::Scales::Scale)
      expect(absolut.root_pitch).to eq(0)
    end

    it 'demonstrates Scale#octave' do
      # From Scale @example
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]

      higher = c_major.octave(1)
      lower = c_major.octave(-1)

      # Scale.octave transposes by grades (7 for major scale), not by semitones
      expect(higher.root_pitch).to eq(60 + 7)
      expect(lower.root_pitch).to eq(60 - 7)
    end

    it 'demonstrates numeric access to scale degrees' do
      # From Scale @example
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]

      expect(c_major[0].pitch).to eq(60)  # Tonic
      expect(c_major[4].pitch).to eq(67)  # Dominant
    end

    it 'demonstrates function name access to scale degrees' do
      # From Scale @example
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]

      expect(c_major[:tonic].pitch).to eq(60)
      expect(c_major[:dominant].pitch).to eq(67)
      expect(c_major[:mediant].pitch).to eq(64)
    end

    it 'demonstrates Roman numeral access to scale degrees' do
      # From Scale @example
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]

      expect(c_major[:I].pitch).to eq(60)
      expect(c_major[:V].pitch).to eq(67)
      expect(c_major[:IV].pitch).to eq(65)
    end

    it 'demonstrates accidentals in scale degree access' do
      # From Scale @example
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]

      expect(c_major[:'I#'].pitch).to eq(61)
      expect(c_major[:V_].pitch).to eq(66)
      expect(c_major['II##'].pitch).to eq(64)
    end

    it 'demonstrates note_of_pitch with diatonic note' do
      # From Scale @example
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      note = c_major.note_of_pitch(64)

      expect(note).not_to be_nil
      expect(note.pitch).to eq(64)
    end

    it 'demonstrates note_of_pitch with chromatic note' do
      # From Scale @example
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      note = c_major.note_of_pitch(63, allow_chromatic: true)

      expect(note).not_to be_nil
      expect(note.pitch).to eq(63)
    end

    it 'demonstrates note_of_pitch with allow_nearest' do
      # From Scale @example
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      note = c_major.note_of_pitch(63, allow_nearest: true)

      expect(note).not_to be_nil
      expect([62, 64]).to include(note.pitch)
    end

    it 'demonstrates offset_of_interval' do
      # From Scale @example
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]

      expect(c_major.offset_of_interval(:P5)).to eq(7)
      expect(c_major.offset_of_interval(:M3)).to eq(4)
    end
  end

  context 'NoteInScale Documentation' do
    it 'demonstrates basic usage' do
      # From NoteInScale @example: Basic usage
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      tonic = c_major.tonic

      expect(tonic.pitch).to eq(60)
      expect(tonic.frequency).to be_within(0.01).of(261.63)
    end

    it 'demonstrates interval navigation with named intervals' do
      # From NoteInScale @example: Interval navigation
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      tonic = c_major.tonic

      expect(tonic.up(:P5).pitch).to eq(67)
      expect(tonic.up(4, :natural).pitch).to eq(67)  # 4 scale degrees up from tonic is dominant (G)
    end

    it 'demonstrates chromatic alterations with sharp' do
      # From NoteInScale @example: Chromatic alterations
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      tonic = c_major.tonic

      expect(tonic.sharp.pitch).to eq(61)
    end

    it 'demonstrates chromatic alterations with flat' do
      # From NoteInScale @example: Chromatic alterations
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      tonic = c_major.tonic

      expect(tonic.flat.pitch).to eq(59)
    end

    it 'demonstrates chord building from note' do
      # From NoteInScale @example: Chord building
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      tonic = c_major.tonic

      triad = tonic.chord
      seventh = tonic.chord :seventh

      expect(triad).to be_a(Musa::Chords::Chord)
      expect(seventh).to be_a(Musa::Chords::Chord)
    end

    it 'demonstrates NoteInScale#functions' do
      # From NoteInScale @example
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]

      functions = c_major.tonic.functions

      expect(functions).to include(:I, :_1, :tonic, :first)
    end

    it 'demonstrates NoteInScale#octave query' do
      # From NoteInScale @example: Query octave
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      note = c_major[0]

      expect(note.octave).to eq(0)
    end

    it 'demonstrates NoteInScale#at_octave transpose relative' do
      # From NoteInScale @example: Transpose relative
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      note = c_major[0]

      up = note.at_octave(1)
      down = note.at_octave(-1)

      expect(up.pitch).to eq(72)
      expect(down.pitch).to eq(48)
    end

    it 'demonstrates NoteInScale#at_octave transpose absolute' do
      # From NoteInScale @example: Transpose absolute
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      note = c_major[0].at_octave(1)

      absolute = note.at_octave(2, absolute: true)

      expect(absolute.pitch).to eq(84)  # Octave 2, regardless of current octave 1
    end

    it 'demonstrates NoteInScale#background_note' do
      # From NoteInScale @example
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      c_sharp = c_major.tonic.sharp

      expect(c_sharp.background_note.pitch).to eq(60)
    end

    it 'demonstrates NoteInScale#wide_grade' do
      # From NoteInScale @example
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      note = c_major[0].at_octave(1)

      expect(note.wide_grade).to eq(7)
    end

    it 'demonstrates NoteInScale#up with natural interval' do
      # From NoteInScale @example
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      note = c_major.tonic

      up_2 = note.up(2, :natural)

      expect(up_2.pitch).to eq(64)
    end

    it 'demonstrates NoteInScale#up with chromatic interval by symbol' do
      # From NoteInScale @example
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      note = c_major.tonic

      up_p5 = note.up(:P5)

      expect(up_p5.pitch).to eq(67)
    end

    it 'demonstrates NoteInScale#down' do
      # From NoteInScale @example
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      note = c_major[4]  # Dominant (G)

      down_2 = note.down(2, :natural)
      down_p5 = note.down(:P5)

      expect(down_2.pitch).to eq(64)
      expect(down_p5.pitch).to eq(60)
    end

    it 'demonstrates NoteInScale#sharp with default count' do
      # From NoteInScale @example
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      note = c_major.tonic

      sharp = note.sharp

      expect(sharp.pitch).to eq(61)
    end

    it 'demonstrates NoteInScale#sharp with count' do
      # From NoteInScale @example
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      note = c_major.tonic

      sharp_2 = note.sharp(2)

      expect(sharp_2.pitch).to eq(62)
    end

    it 'demonstrates NoteInScale#flat with default count' do
      # From NoteInScale @example
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      note = c_major.tonic

      flat = note.flat

      expect(flat.pitch).to eq(59)
    end

    it 'demonstrates NoteInScale#flat with count' do
      # From NoteInScale @example
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      note = c_major.tonic

      flat_2 = note.flat(2)

      expect(flat_2.pitch).to eq(58)
    end

    it 'demonstrates NoteInScale#frequency' do
      # From NoteInScale @example
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]

      frequency = c_major.tonic.frequency

      expect(frequency).to be_within(0.01).of(261.63)
    end

    it 'demonstrates NoteInScale#scale query' do
      # From NoteInScale @example: Query current scale
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      note = c_major.tonic

      scale = note.scale

      expect(scale).to be_a(Musa::Scales::Scale)
      expect(scale.kind.class).to eq(Musa::Scales::MajorScaleKind)
    end

    it 'demonstrates NoteInScale#as_root_of' do
      # From NoteInScale @example: Create scale with note as root
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      note = c_major.tonic

      # as_root_of(:minor) returns the Scale, not a NoteInScale
      minor_scale = note.as_root_of(:minor)

      expect(minor_scale).to be_a(Musa::Scales::Scale)
      expect(minor_scale.kind.class).to eq(Musa::Scales::MinorNaturalScaleKind)
    end

    it 'demonstrates NoteInScale dynamic scale methods' do
      # From NoteInScale @example: Dynamic method
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      note = c_major.tonic

      # Dynamic methods return Scale objects, not NoteInScale
      minor_scale = note.minor
      major_scale = note.major

      expect(minor_scale).to be_a(Musa::Scales::Scale)
      expect(minor_scale.kind.class).to eq(Musa::Scales::MinorNaturalScaleKind)
      expect(major_scale).to be_a(Musa::Scales::Scale)
      expect(major_scale.kind.class).to eq(Musa::Scales::MajorScaleKind)
    end

    it 'demonstrates NoteInScale#on' do
      # From NoteInScale @example
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      c_minor = tuning.minor[60]
      c_major_tonic = c_major.tonic

      note_in_minor = c_major_tonic.on(c_minor)

      expect(note_in_minor).not_to be_nil
      expect(note_in_minor.pitch).to eq(60)
      expect(note_in_minor.scale).to eq(c_minor)
    end

    it 'demonstrates NoteInScale#chord default triad' do
      # From NoteInScale @example: Default triad
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      note = c_major.tonic

      chord = note.chord

      expect(chord).to be_a(Musa::Chords::Chord)
    end

    it 'demonstrates NoteInScale#chord with specified size' do
      # From NoteInScale @example: Specified size
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      note = c_major.tonic

      seventh = note.chord :seventh
      ninth = note.chord :ninth

      expect(seventh).to be_a(Musa::Chords::Chord)
      expect(ninth).to be_a(Musa::Chords::Chord)
    end

    it 'demonstrates NoteInScale#chord with features hash' do
      # From NoteInScale @example: With features
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      note = c_major.tonic

      # Need allow_chromatic for notes not in the scale
      chord1 = note.chord(quality: :minor, size: :seventh, allow_chromatic: true)
      chord2 = note.chord(:minor, :seventh, allow_chromatic: true)

      expect(chord1).to be_a(Musa::Chords::Chord)
      expect(chord2).to be_a(Musa::Chords::Chord)
    end

    it 'demonstrates NoteInScale#chord with voicing' do
      # From NoteInScale @example: With voicing
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      note = c_major.tonic

      chord = note.chord :seventh, move: {root: -1}, duplicate: {fifth: 1}

      expect(chord).to be_a(Musa::Chords::Chord)
    end
  end

  context 'ChordDefinition Documentation' do
    it 'demonstrates defining a major triad' do
      # From ChordDefinition @example: Defining a major triad
      Musa::Chords::ChordDefinition.register :maj_test,
        quality: :major,
        size: :triad,
        offsets: { root: 0, third: 4, fifth: 7 }

      definition = Musa::Chords::ChordDefinition[:maj_test]

      expect(definition).not_to be_nil
      expect(definition.name).to eq(:maj_test)
    end

    it 'demonstrates defining a dominant seventh' do
      # From ChordDefinition @example: Defining a dominant seventh
      Musa::Chords::ChordDefinition.register :dom7_test,
        quality: :dominant,
        size: :seventh,
        offsets: { root: 0, third: 4, fifth: 7, seventh: 10 }

      definition = Musa::Chords::ChordDefinition[:dom7_test]

      expect(definition).not_to be_nil
      expect(definition.name).to eq(:dom7_test)
    end

    it 'demonstrates ChordDefinition.[] access' do
      # From ChordDefinition @example
      maj = Musa::Chords::ChordDefinition[:maj]
      min7 = Musa::Chords::ChordDefinition[:min7]

      expect(maj).to be_a(Musa::Chords::ChordDefinition)
      expect(min7).to be_a(Musa::Chords::ChordDefinition)
    end

    it 'demonstrates features_from conversion' do
      # From ChordDefinition @example
      features = Musa::Chords::ChordDefinition.features_from([:major, :triad])

      expect(features).to eq({ quality: :major, size: :triad })
    end

    it 'demonstrates find_by_features' do
      # From ChordDefinition @example
      definitions = Musa::Chords::ChordDefinition.find_by_features(quality: :major, size: :triad)

      expect(definitions).to be_an(Array)
      expect(definitions.first).to be_a(Musa::Chords::ChordDefinition)
    end

    it 'demonstrates find_by_pitches' do
      # From ChordDefinition @example
      definition = Musa::Chords::ChordDefinition.find_by_pitches([60, 64, 67])

      expect(definition).to be_a(Musa::Chords::ChordDefinition)
      expect(definition.name).to eq(:maj)
    end

    it 'demonstrates ChordDefinition#pitches' do
      # From ChordDefinition @example
      chord_def = Musa::Chords::ChordDefinition[:maj]
      pitches = chord_def.pitches(60)

      expect(pitches).to eq([60, 64, 67])
    end

    it 'demonstrates ChordDefinition#in_scale?' do
      # From ChordDefinition @example
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      maj_def = Musa::Chords::ChordDefinition[:maj]

      in_scale = maj_def.in_scale?(c_major, chord_root_pitch: 60)

      expect(in_scale).to be true
    end

    it 'demonstrates ChordDefinition#matches with C major' do
      # From ChordDefinition @example
      maj_def = Musa::Chords::ChordDefinition[:maj]

      expect(maj_def.matches([60, 64, 67])).to be true
    end

    it 'demonstrates ChordDefinition#matches with C minor' do
      # From ChordDefinition @example
      maj_def = Musa::Chords::ChordDefinition[:maj]

      expect(maj_def.matches([60, 63, 67])).to be false
    end
  end

  context 'Chord Documentation' do
    it 'demonstrates basic triad creation' do
      # From Chord @example: Basic triad creation
      tuning = Scales.default_system.default_tuning
      scale = tuning.major[60]
      chord = scale.tonic.chord

      expect(chord.root.pitch).to eq(60)
      expect(chord.third.pitch).to eq(64)
      expect(chord.fifth.pitch).to eq(67)
    end

    it 'demonstrates seventh chord creation' do
      # From Chord @example: Seventh chord
      tuning = Scales.default_system.default_tuning
      scale = tuning.major[60]
      chord = scale.tonic.chord :seventh

      expect(chord.seventh.pitch).to eq(71)
    end

    it 'demonstrates voicing with move and duplicate' do
      # From Chord @example: Voicing with move and duplicate
      tuning = Scales.default_system.default_tuning
      scale = tuning.major[60]
      chord = scale.dominant.chord(:seventh)
        .with_move(root: -1, third: -1)
        .with_duplicate(fifth: [0, 1])

      expect(chord).to be_a(Musa::Chords::Chord)
    end

    it 'demonstrates feature navigation' do
      # From Chord @example: Feature navigation
      tuning = Scales.default_system.default_tuning
      scale = tuning.major[60]
      maj_triad = scale.tonic.chord
      min_triad = maj_triad.with_quality(:minor)
      maj_seventh = maj_triad.with_size(:seventh)

      expect(min_triad).to be_a(Musa::Chords::Chord)
      expect(maj_seventh).to be_a(Musa::Chords::Chord)
    end

    it 'demonstrates Chord.with_root with note from scale' do
      # From Chord @example: With note from scale
      tuning = Scales.default_system.default_tuning
      scale = tuning.major[60]
      chord = Musa::Chords::Chord.with_root(scale.tonic, name: :maj7)

      expect(chord).to be_a(Musa::Chords::Chord)
    end

    it 'demonstrates Chord.with_root with MIDI pitch and scale' do
      # From Chord @example: With MIDI pitch and scale
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      chord = Musa::Chords::Chord.with_root(60, scale: c_major, name: :min)

      expect(chord).to be_a(Musa::Chords::Chord)
    end

    it 'demonstrates Chord.with_root with scale degree' do
      # From Chord @example: With scale degree
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      chord = Musa::Chords::Chord.with_root(:dominant, scale: c_major, quality: :dominant, size: :seventh)

      expect(chord).to be_a(Musa::Chords::Chord)
    end

    it 'demonstrates Chord.with_root with features instead of name' do
      # From Chord @example: With features instead of name
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      chord = Musa::Chords::Chord.with_root(60, scale: c_major, quality: :major, size: :triad)

      expect(chord).to be_a(Musa::Chords::Chord)
    end

    it 'demonstrates Chord.with_root with voicing parameters' do
      # From Chord @example: With voicing parameters
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      chord = Musa::Chords::Chord.with_root(60, scale: c_major, name: :maj7,
                                           move: {root: -1}, duplicate: {fifth: 1})

      expect(chord).to be_a(Musa::Chords::Chord)
    end

    it 'demonstrates Chord#notes' do
      # From Chord @example
      tuning = Scales.default_system.default_tuning
      scale = tuning.major[60]
      chord = scale.tonic.chord

      chord.notes.each do |chord_grade_note|
        expect(chord_grade_note.grade).to be_a(Symbol)
        expect(chord_grade_note.note.pitch).to be_a(Integer)
      end
    end

    it 'demonstrates Chord#pitches all pitches' do
      # From Chord @example: All pitches
      tuning = Scales.default_system.default_tuning
      scale = tuning.major[60]
      chord = scale.tonic.chord

      pitches = chord.pitches

      expect(pitches).to eq([60, 64, 67])
    end

    it 'demonstrates Chord#pitches specific positions' do
      # From Chord @example: Specific positions
      tuning = Scales.default_system.default_tuning
      scale = tuning.major[60]
      chord = scale.tonic.chord

      pitches = chord.pitches(:root, :third)

      expect(pitches).to eq([60, 64])
    end

    it 'demonstrates Chord#features' do
      # From Chord @example
      tuning = Scales.default_system.default_tuning
      scale = tuning.major[60]
      chord = scale.tonic.chord

      features = chord.features

      expect(features).to include(quality: :major, size: :triad)
    end

    it 'demonstrates Chord#featuring change size' do
      # From Chord @example: Change size
      tuning = Scales.default_system.default_tuning
      scale = tuning.major[60]
      chord = scale.tonic.chord

      seventh = chord.featuring(size: :seventh)

      expect(seventh).to be_a(Musa::Chords::Chord)
    end

    it 'demonstrates Chord#featuring change quality' do
      # From Chord @example: Change quality
      tuning = Scales.default_system.default_tuning
      scale = tuning.major[60]
      chord = scale.tonic.chord

      # Need allow_chromatic for non-diatonic notes
      minor = chord.featuring(quality: :minor, allow_chromatic: true)

      expect(minor).to be_a(Musa::Chords::Chord)
    end

    it 'demonstrates Chord#featuring change multiple features' do
      # From Chord @example: Change multiple features
      tuning = Scales.default_system.default_tuning
      scale = tuning.major[60]
      chord = scale.tonic.chord

      # Need allow_chromatic for non-diatonic notes
      dom_ninth = chord.featuring(quality: :dominant, size: :ninth, allow_chromatic: true)

      expect(dom_ninth).to be_a(Musa::Chords::Chord)
    end

    it 'demonstrates Chord#octave move chord down' do
      # From Chord @example: Move chord down one octave
      tuning = Scales.default_system.default_tuning
      scale = tuning.major[60]
      chord = scale.tonic.chord

      lower = chord.octave(-1)

      expect(lower).to be_a(Musa::Chords::Chord)
    end

    it 'demonstrates Chord#octave move chord up' do
      # From Chord @example: Move chord up two octaves
      tuning = Scales.default_system.default_tuning
      scale = tuning.major[60]
      chord = scale.tonic.chord

      higher = chord.octave(2)

      expect(higher).to be_a(Musa::Chords::Chord)
    end

    it 'demonstrates Chord#with_move root down seventh up' do
      # From Chord @example: Move root down, seventh up
      tuning = Scales.default_system.default_tuning
      scale = tuning.major[60]
      chord = scale.tonic.chord :seventh

      voiced = chord.with_move(root: -1, seventh: 1)

      expect(voiced).to be_a(Musa::Chords::Chord)
    end

    it 'demonstrates Chord#with_move drop voicing' do
      # From Chord @example: Drop voicing
      tuning = Scales.default_system.default_tuning
      scale = tuning.major[60]
      chord = scale.tonic.chord :seventh

      dropped = chord.with_move(third: -1, seventh: -1)

      expect(dropped).to be_a(Musa::Chords::Chord)
    end

    it 'demonstrates Chord#with_duplicate root two octaves down' do
      # From Chord @example: Duplicate root two octaves down
      tuning = Scales.default_system.default_tuning
      scale = tuning.major[60]
      chord = scale.tonic.chord

      doubled = chord.with_duplicate(root: -2)

      expect(doubled).to be_a(Musa::Chords::Chord)
    end

    it 'demonstrates Chord#with_duplicate third in multiple octaves' do
      # From Chord @example: Duplicate third in multiple octaves
      tuning = Scales.default_system.default_tuning
      scale = tuning.major[60]
      chord = scale.tonic.chord

      expanded = chord.with_duplicate(third: [-1, 1])

      expect(expanded).to be_a(Musa::Chords::Chord)
    end

    it 'demonstrates Chord#with_duplicate multiple positions' do
      # From Chord @example: Duplicate multiple positions
      tuning = Scales.default_system.default_tuning
      scale = tuning.major[60]
      chord = scale.tonic.chord

      expanded = chord.with_duplicate(root: -1, fifth: 1)

      expect(expanded).to be_a(Musa::Chords::Chord)
    end
  end

  context 'Scale Kinds Documentation' do
    it 'demonstrates ChromaticScaleKind usage' do
      # From ChromaticScaleKind usage example
      tuning = Scales[:et12][440.0]
      chromatic = tuning[:chromatic][60]

      expect(chromatic._1.pitch).to eq(60)
      expect(chromatic._2.pitch).to eq(61)
      expect(chromatic._3.pitch).to eq(62)
    end

    it 'demonstrates MajorScaleKind usage for scale degrees' do
      # From MajorScaleKind usage example
      tuning = Scales[:et12][440.0]
      c_major = tuning[:major][60]

      expect(c_major.tonic.pitch).to eq(60)
      expect(c_major.dominant.pitch).to eq(67)
      expect(c_major.VI.pitch).to eq(69)
    end

    it 'demonstrates MajorScaleKind relative minor access' do
      # From MajorScaleKind usage example
      tuning = Scales[:et12][440.0]
      c_major = tuning[:major][60]

      relative_minor_root = c_major.relative_minor
      a_minor = relative_minor_root.as_root_of(:minor)

      expect(relative_minor_root.pitch).to eq(69)
      expect(a_minor).to be_a(Musa::Scales::Scale)
    end

    it 'demonstrates MinorNaturalScaleKind usage' do
      # From MinorNaturalScaleKind usage example
      tuning = Scales[:et12][440.0]
      a_minor = tuning[:minor][69]

      expect(a_minor.tonic.pitch).to eq(69)
      expect(a_minor.dominant.pitch).to eq(76)
      expect(a_minor.iii.pitch).to eq(72)
    end

    it 'demonstrates MinorNaturalScaleKind relative major access' do
      # From MinorNaturalScaleKind usage example
      tuning = Scales[:et12][440.0]
      a_minor = tuning[:minor][69]

      relative_major_root = a_minor.relative_major
      c_major = relative_major_root.as_root_of(:major)

      expect(relative_major_root.pitch).to eq(72)
      expect(c_major).to be_a(Musa::Scales::Scale)
    end

    it 'demonstrates MinorHarmonicScaleKind usage with raised 7th' do
      # From MinorHarmonicScaleKind usage example
      tuning = Scales[:et12][440.0]
      a_harmonic_minor = tuning[:minor_harmonic][69]

      expect(a_harmonic_minor.vii.pitch).to eq(80)  # G# (raised)
      expect(a_harmonic_minor.vi.pitch).to eq(77)   # F
    end
  end
end
