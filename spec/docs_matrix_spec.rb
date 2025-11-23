require 'docs_helper'

using Musa::Extension::Neumas
using Musa::Extension::Matrix

RSpec.describe 'Matrix Documentation Examples' do

  context 'Matrix - Sonic Gesture Conversion' do
    it 'converts matrix to P format for sequencer playback' do
      # Matrix representing a melodic gesture: [time, pitch]
      melody_matrix = Matrix[[0, 60], [1, 62], [2, 64]]

      # Convert to P format for sequencer playback
      p_sequence = melody_matrix.to_p(time_dimension: 0)

      expect(p_sequence).to be_an(Array)
      expect(p_sequence.size).to eq(1)

      # Result format: [[pitch1], duration1, [pitch2], duration2, [pitch3]]
      first_p = p_sequence[0]
      expect(first_p).to eq([[60], 1, [62], 1, [64]])
    end

    it 'converts multi-parameter matrix (time, pitch, velocity) to P format' do
      # Multi-parameter example: [time, pitch, velocity]
      gesture = Matrix[[0, 60, 100], [0.5, 62, 110], [1, 64, 120]]
      p_with_velocity = gesture.to_p(time_dimension: 0)

      expect(p_with_velocity).to be_an(Array)
      expect(p_with_velocity.size).to eq(1)

      # Result: [[pitch, velocity], duration, [pitch, velocity], duration, [pitch, velocity]]
      first_p = p_with_velocity[0]
      expect(first_p).to eq([[60, 100], 0.5, [62, 110], 0.5, [64, 120]])
    end

    it 'condenses connected gestures that share endpoints' do
      # Two phrases that connect at [1, 62]
      phrase1 = Matrix[[0, 60], [1, 62]]
      phrase2 = Matrix[[1, 62], [2, 64], [3, 65]]

      # Matrices that share endpoints are automatically merged
      merged = [phrase1, phrase2].to_p(time_dimension: 0)

      expect(merged).to be_an(Array)
      expect(merged.size).to eq(1)

      # Both phrases merged into continuous sequence
      first_p = merged[0]
      expect(first_p).to eq([[[60], 1, [62], 1, [64], 1, [65]]])
    end
  end


end
