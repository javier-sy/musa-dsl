require 'spec_helper'

require 'musa-dsl'

RSpec.describe Musa::Sequencer do
  context 'Basic tickless sequencing' do
    include Musa::Series

    it 'Basic at sequencing' do
      s = Musa::Sequencer::BaseSequencer.new

      c = 0

      s.at 1 do
        c = 1
      end

      s.at 3 do
        c = 3
      end

      s.at 2 do
        c = 2
      end

      expect(c).to eq(0)
      expect(s.size).to eq 3
      expect(s.position).to eq nil

      s.tick

      expect(c).to eq(1)
      expect(s.size).to eq 2
      expect(s.position).to eq 1

      s.tick

      expect(c).to eq(2)
      expect(s.size).to eq 1
      expect(s.position).to eq 2

      s.tick

      expect(c).to eq(3)
      expect(s.size).to eq 0
      expect(s.position).to eq 3

      s.tick

      expect(c).to eq(3)
      expect(s.size).to eq 0
      expect(s.position).to eq nil

      s.tick

      expect(c).to eq(3)
      expect(s.size).to eq 0
      expect(s.position).to eq nil
    end

    it 'Runs until finished' do
      s = Musa::Sequencer::BaseSequencer.new
      c = []

      s.at 1 do
        s.move from: 100, to: 101, duration: 4, step: 1 do |value|
          c << [s.position, value]
        end
      end

      s.run

      expect(c).to eq [[1, 100], [3, 101]]
    end

    it 'Move with duration but without time increment limitation should raise exception' do
      s = Musa::Sequencer::BaseSequencer.new
      c = []

      s.at 1 do
        expect do
          s.move from: 1, to: 2, duration: 4 do |value|
            c << value
          end
        end.to raise_error(ArgumentError)
      end

      s.run
    end
  end
end
