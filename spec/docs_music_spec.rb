require 'docs_helper'

using Musa::Extension::Neumas
using Musa::Extension::Matrix

RSpec.describe 'Music Documentation Examples' do

  context 'Music - Scales & Chords' do
    include Musa::Scales
    include Musa::Chords

    it 'accesses default system and creates scales' do
      # Access default system and tuning
      tuning = Scales.default_system.default_tuning

      # Create scales using available scale kinds
      c_major = tuning.major[60]
      d_minor = tuning.minor[62]
      e_harmonic = tuning.minor_harmonic[64]
      chromatic = tuning.chromatic[60]

      expect(c_major).to be_a(Musa::Scales::Scale)
      expect(d_minor).to be_a(Musa::Scales::Scale)
      expect(e_harmonic).to be_a(Musa::Scales::Scale)
      expect(chromatic).to be_a(Musa::Scales::Scale)
    end

    it 'accesses scale notes by grade and function' do
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]

      # Access by grade
      tonic = c_major[0]
      mediant = c_major[2]
      dominant = c_major[4]

      expect(tonic.pitch).to eq(60)    # C
      expect(mediant.pitch).to eq(64)  # E
      expect(dominant.pitch).to eq(67) # G

      # Access by function name
      expect(c_major.tonic.pitch).to eq(60)
      expect(c_major.supertonic.pitch).to eq(62)
      expect(c_major.mediant.pitch).to eq(64)
      expect(c_major.subdominant.pitch).to eq(65)
      expect(c_major.dominant.pitch).to eq(67)

      # Access by Roman numeral
      expect(c_major[:I].pitch).to eq(60)
      expect(c_major[:V].pitch).to eq(67)
    end

    it 'navigates with octaves and chromatic operations' do
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]

      # Octave navigation
      note = c_major[2].at_octave(1)
      expect(note.pitch).to eq(76)  # E transposed up 1 octave

      # Chromatic operations
      c_sharp = c_major.tonic.sharp
      c_flat = c_major.tonic.flat

      expect(c_sharp.pitch).to eq(61)  # C#
      expect(c_flat.pitch).to eq(59)   # Cb

      # Navigate by semitones
      fifth_up = c_major.tonic.sharp(7)
      third_up = c_major.tonic.sharp(4)

      expect(fifth_up.pitch).to eq(67)  # G
      expect(third_up.pitch).to eq(64)  # E
    end

    it 'calculates frequencies' do
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]

      frequency = c_major.tonic.frequency
      expect(frequency).to be_within(0.01).of(261.63)  # Middle C at A=440
    end

    it 'creates chords from scale degrees' do
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]

      # Create triads
      i_chord = c_major.tonic.chord
      ii_chord = c_major.supertonic.chord
      v_chord = c_major.dominant.chord

      expect(i_chord).to be_a(Musa::Chords::Chord)
      expect(i_chord.pitches).to eq([60, 64, 67])  # C, E, G

      # Create extended chords
      i_seventh = c_major.tonic.chord :seventh
      expect(i_seventh.pitches).to eq([60, 64, 67, 71])  # C, E, G, B
    end

    it 'accesses chord tones and features' do
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      i_chord = c_major.tonic.chord

      # Access chord tones by name
      root = i_chord.root
      third = i_chord.third
      fifth = i_chord.fifth

      expect(root.pitch).to eq(60)
      expect(third.pitch).to eq(64)
      expect(fifth.pitch).to eq(67)

      # Chord features
      expect(i_chord.quality).to eq(:major)
      expect(i_chord.size).to eq(:triad)
    end

    it 'navigates between chord qualities and extensions' do
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      i_chord = c_major.tonic.chord

      # Navigate between chord qualities
      minor_chord = i_chord.with_quality(:minor)
      expect(minor_chord.quality).to eq(:minor)
      expect(minor_chord.pitches).to eq([60, 63, 67])  # C, Eb, G

      diminished = i_chord.with_quality(:diminished)
      expect(diminished.quality).to eq(:diminished)

      # Change chord extensions
      seventh_chord = i_chord.with_size(:seventh)
      expect(seventh_chord.size).to eq(:seventh)
      expect(seventh_chord.pitches.size).to eq(4)
    end

    it 'modifies chord voicings' do
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      i_chord = c_major.tonic.chord

      # Move specific tones to different octaves
      voiced = i_chord.with_move(root: -1, fifth: 1)
      expect(voiced.root.pitch).to eq(48)   # Root down one octave
      expect(voiced.fifth.pitch).to eq(79)  # Fifth up one octave

      # Duplicate tones in other octaves
      doubled = i_chord.with_duplicate(root: -2)
      pitches = doubled.pitches
      expect(pitches).to include(36)  # Root 2 octaves down
      expect(pitches).to include(60)  # Original root

      # Transpose entire chord
      lower = i_chord.octave(-1)
      expect(lower.pitches).to eq([48, 52, 55])  # Whole chord down one octave
    end

    it 'defines and uses custom pentatonic scale kind' do
      # Define custom pentatonic scale kind
      class PentatonicMajorScaleKind < Musa::Scales::ScaleKind
        class << self
          def id
            :pentatonic_major
          end

          def pitches
            [{ functions: [:I, :_1, :tonic], pitch: 0 },
             { functions: [:II, :_2], pitch: 2 },
             { functions: [:III, :_3], pitch: 4 },
             { functions: [:V, :_5], pitch: 7 },
             { functions: [:VI, :_6], pitch: 9 }]
          end

          def grades
            5
          end
        end
      end

      # Register with the 12-tone system
      Scales.et12.register(PentatonicMajorScaleKind)

      # Use the new scale kind
      tuning = Scales.default_system.default_tuning
      c_pentatonic = tuning[:pentatonic_major][60]

      expect(c_pentatonic).to be_a(Musa::Scales::Scale)
      expect(c_pentatonic[0].pitch).to eq(60)  # C
      expect(c_pentatonic[1].pitch).to eq(62)  # D
      expect(c_pentatonic[2].pitch).to eq(64)  # E
      expect(c_pentatonic[3].pitch).to eq(67)  # G
      expect(c_pentatonic[4].pitch).to eq(69)  # A
    end

    it 'defines and registers custom chord definitions' do
      # Register sus4 chord
      Musa::Chords::ChordDefinition.register :sus4_test,
        quality: :suspended,
        size: :triad,
        offsets: { root: 0, fourth: 5, fifth: 7 }

      # Register add9 chord
      Musa::Chords::ChordDefinition.register :add9_test,
        quality: :major,
        size: :extended,
        offsets: { root: 0, third: 4, fifth: 7, ninth: 14 }

      # Verify registrations
      sus4_def = Musa::Chords::ChordDefinition[:sus4_test]
      add9_def = Musa::Chords::ChordDefinition[:add9_test]

      expect(sus4_def).not_to be_nil
      expect(sus4_def.name).to eq(:sus4_test)
      expect(sus4_def.features[:quality]).to eq(:suspended)
      expect(sus4_def.features[:size]).to eq(:triad)

      expect(add9_def).not_to be_nil
      expect(add9_def.name).to eq(:add9_test)
      expect(add9_def.features[:quality]).to eq(:major)
      expect(add9_def.features[:size]).to eq(:extended)
    end
  end


end
