require 'docs_helper'

using Musa::Extension::Neumas
using Musa::Extension::Matrix

RSpec.describe 'Music Inline Documentation Examples' do

  # ChordDefinition's registry is global and has no way to undo a registration,
  # so a spec that adds one leaves it there for everything that runs afterwards.
  # It is not hypothetical: the documentation-examples spec asks
  # `find_by_features(quality: :major, size: :triad)` and got `[:maj, :maj_test]`
  # once these had run. Whatever a spec registers here, it takes away again.
  after do
    definitions = Musa::Chords::ChordDefinition.instance_variable_get(:@definitions)
    %i[maj_test dom7_test].each { |name| definitions&.delete(name) }
  end

  include Musa::Scales
  include Musa::Chords

  context 'Scale Documentation' do

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

  end

end
