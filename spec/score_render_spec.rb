require 'spec_helper'

require 'musa-dsl'

RSpec.describe Musa::Datasets::Score do
  context 'Score play on sequencer' do
    it 'relative position on sequencer start position should render at position -1 tick' do
      s = Musa::Datasets::Score.new
      seq = Musa::Sequencer::Sequencer.new 4, 24
      r = {}

      s.at(1, add: { something: 1, duration: 1 }.extend(Musa::Datasets::AbsD))

      s.render on: seq do |element|
        r[seq.position] = element[:something]
      end

      seq.run

      expect(r).to eq({ 95/96r => 1 })
    end

    it 'relative position on sequencer position 2' do
      s = Musa::Datasets::Score.new
      seq = Musa::Sequencer::Sequencer.new 4, 24
      r = {}

      s.at(1, add: { something: 1, duration: 1 }.extend(Musa::Datasets::AbsD))

      seq.position = 2

      s.render on: seq do |element|
        r[seq.position] = element[:something]
      end

      seq.run

      expect(r).to eq({ 2r => 1 })
    end
  end

  context 'Nested scores' do
    s1 = Musa::Datasets::Score.new
    s2 = Musa::Datasets::Score.new
    s3 = Musa::Datasets::Score.new

    s2.at(1, add: { something: 7777 }.extend(Musa::Datasets::AbsD))
    s2.at(1.5, add: { something: 777 }.extend(Musa::Datasets::AbsD))
    s2.at(2, add: { something: 77 }.extend(Musa::Datasets::AbsD))
    s2.at(4, add: { something: 7 }.extend(Musa::Datasets::AbsD))

    s1.at(1, add: { something: 1000 }.extend(Musa::Datasets::AbsD))
    s1.at(2, add: { something: 100 }.extend(Musa::Datasets::AbsD))
    s1.at(2.5, add: s2)
    s1.at(3, add: { something: 10 }.extend(Musa::Datasets::AbsD))

    s3.at(1, add: { something: 1000 }.extend(Musa::Datasets::AbsD))
    s3.at(2, add: { something: 100 }.extend(Musa::Datasets::AbsD))
    s3.at(2.5, add: s3)
    s3.at(3, add: { something: 10 }.extend(Musa::Datasets::AbsD))
    s3.at(4, add: { something: 1 }.extend(Musa::Datasets::AbsD))

    it 'score with nested score duration' do
      expect(s2.duration).to eq 3r
      expect(s1.duration).to eq 4.5r
    end

    it 'score with nested score render' do
      seq = Musa::Sequencer::Sequencer.new 4, 24
      r = {}

      seq.at 1 do
        s1.render on: seq do |element|
          r[seq.position] ||= []
          r[seq.position] << element[:something]
        end
      end

      seq.run

      expect(r).to eq({
                       1r => [1000],
                       2r => [100],
                       2.5r => [7777],
                       3r => [10, 777],
                       3.5r => [77],
                       5.5r => [7]
                      })
    end

    it 'score with recursively nested score render' do
      s1 = Musa::Datasets::Score.new

      seq = Musa::Sequencer::Sequencer.new 4, 24
      r = {}

      seq.at 1 do
        s3.render on: seq do |element|
          r[seq.position] ||= []
          r[seq.position] << element[:something]
        end
      end

      (4*24*6).times { seq.tick }

      expect(r).to eq({
                          1r => [1000],
                          2r => [100],
                          2.5r => [1000],
                          3r => [10],
                          3.5r => [100],
                          4r => [1, 1000],
                          4.5r => [10],
                          5r => [100],
                          5.5r => [1, 1000],
                          6r => [10],
                          6.5r => [100]
                      })

    end

  end
end
