require 'docs_helper'

using Musa::Extension::Neumas
using Musa::Extension::Matrix

RSpec.describe 'Music Documentation Examples' do

  # ChordDefinition's registry is global and has no way to undo a registration,
  # so a spec that adds one leaves it there for everything that runs afterwards.
  # It is not hypothetical: the documentation-examples spec asks
  # `find_by_features(quality: :major, size: :triad)` and got `[:maj, :maj_test]`
  # once these had run. Whatever a spec registers here, it takes away again.
  after do
    definitions = Musa::Chords::ChordDefinition.instance_variable_get(:@definitions)
    %i[sus4_test add9_test].each { |name| definitions&.delete(name) }
  end

  context 'Music - Scales & Chords' do
    include Musa::Scales
    include Musa::Chords

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

  end

end
