# The interval structure of every scale kind the 12-tone system registers.
#
# WHY THIS FILE EXISTS. Nine of the thirty-two kinds had their structure checked
# somewhere -- the major and minor scales, the Greek modes, chromatic. The other
# twenty-three were registered, documented by name, and never once compared with
# what they are supposed to be. A wrong semitone in one of them would have shown
# up as a piece that sounded odd, months later, with nothing to point at.
#
# The expected column is written from music theory and not read off the code:
# copying `pitches` from the source and asserting it back would pass whatever is
# there. Each row says which scale it is in the terms the scale is defined by --
# "mixolydian with a natural 7", "the 4th mode of melodic minor" -- so that a
# reader can check the numbers against the description rather than against the
# implementation.

require 'spec_helper'
require 'musa-dsl'

RSpec.describe 'Scale kinds: interval structure' do
  # semitones above the root, in order
  STRUCTURES = {
    # --- diatonic and its relatives
    major: [0, 2, 4, 5, 7, 9, 11],
    minor: [0, 2, 3, 5, 7, 8, 10],                 # natural minor: aeolian
    minor_harmonic: [0, 2, 3, 5, 7, 8, 11],        # natural minor with a raised 7
    minor_melodic: [0, 2, 3, 5, 7, 9, 11],         # minor with raised 6 and 7 going up
    major_harmonic: [0, 2, 4, 5, 7, 8, 11],        # major with a flattened 6

    # --- Greek modes
    dorian: [0, 2, 3, 5, 7, 9, 10],
    phrygian: [0, 1, 3, 5, 7, 8, 10],
    lydian: [0, 2, 4, 6, 7, 9, 11],
    mixolydian: [0, 2, 4, 5, 7, 9, 10],
    locrian: [0, 1, 3, 5, 6, 8, 10],

    # --- modes of the melodic minor
    dorian_b2: [0, 1, 3, 5, 7, 9, 10],             # 2nd mode: phrygian with a natural 6
    lydian_augmented: [0, 2, 4, 6, 8, 9, 11],      # 3rd mode: lydian with a raised 5
    lydian_dominant: [0, 2, 4, 6, 7, 9, 10],       # 4th mode: lydian with a flattened 7
    mixolydian_b6: [0, 2, 4, 5, 7, 8, 10],         # 5th mode
    locrian_sharp2: [0, 2, 3, 5, 6, 8, 10],        # 6th mode: locrian with a natural 2
    altered: [0, 1, 3, 4, 6, 8, 10],               # 7th mode: superlocrian

    # --- symmetric
    whole_tone: [0, 2, 4, 6, 8, 10],
    diminished_hw: [0, 1, 3, 4, 6, 7, 9, 10],      # half, whole, half, whole...
    diminished_wh: [0, 2, 3, 5, 6, 8, 9, 11],      # whole, half, whole, half...

    # --- pentatonic and blues
    pentatonic_major: [0, 2, 4, 7, 9],             # major without 4 and 7
    pentatonic_minor: [0, 3, 5, 7, 10],            # its relative
    blues: [0, 3, 5, 6, 7, 10],                    # minor pentatonic plus the blue note
    blues_major: [0, 2, 3, 4, 7, 9],               # major pentatonic plus the blue note

    # --- bebop: eight notes, a passing tone added for eighth-note lines
    bebop_dominant: [0, 2, 4, 5, 7, 9, 10, 11],    # mixolydian with a natural 7
    bebop_major: [0, 2, 4, 5, 7, 8, 9, 11],        # major with a raised 5
    bebop_minor: [0, 2, 3, 5, 7, 9, 10, 11],       # dorian with a natural 7

    # --- ethnic
    double_harmonic: [0, 1, 4, 5, 7, 8, 11],       # byzantine: two augmented seconds
    hungarian_minor: [0, 2, 3, 6, 7, 8, 11],       # harmonic minor with a raised 4
    phrygian_dominant: [0, 1, 4, 5, 7, 8, 10],     # 5th mode of harmonic minor: flamenco
    neapolitan_major: [0, 1, 3, 5, 7, 9, 11],      # flattened 2, otherwise melodic minor
    neapolitan_minor: [0, 1, 3, 5, 7, 8, 11],      # flattened 2, otherwise harmonic minor

    chromatic: (0..11).to_a
  }.freeze

  let(:tuning) { Musa::Scales::Scales.et12[440.0] }

  STRUCTURES.each do |id, semitones|
    it "#{id} is #{semitones.inspect} above its root" do
      scale = tuning[id][60]

      expect((0...semitones.size).map { |grade| scale[grade].pitch - 60 }).to eq semitones
    end
  end

  it 'covers every kind the system registers' do
    registered = Musa::Scales::EquallyTempered12ToneScaleSystem
                 .instance_variable_get(:@scale_kind_classes).keys

    expect(registered.sort).to eq STRUCTURES.keys.sort
  end
end
