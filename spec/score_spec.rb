require 'spec_helper'

require 'musa-dsl'

include Musa::Score
include Musa::Datasets

RSpec.describe Musa::Score do
  context 'Score' do
    it 'refuses things that are not a Dataset' do
      s = Score.new(0.125)
      expect { s.at(1, add: { something: 1 }) }.to raise_error(ArgumentError)
    end

    it 'manages event agrupation correctly' do
      s = Score.new(0.125)

      s.at(1, add: { something: 1 }.extend(Dataset))
      s.at(2, add: { something: -1 }.extend(Dataset))
      s.at(1.25, add: { something: 4 }.extend(Dataset))
      s.at(1.125, add: { something: 5 }.extend(Dataset))
      s.at(1.25, add: { something: 100 }.extend(Dataset))

      expect(s.times).to eq [1r, 1.125r, 1.25r, 2r]

      t = []
      x = []

      s.each do |time, things|
        t << time
        x << things
      end

      expect(t).to eq [1r, 1.125r, 1.25r, 2r]

      expect(x[0]).to eq [{ something: 1 }]
      expect(x[1]).to eq [{ something: 5 }]
      expect(x[2]).to eq [{ something: 4 }, { something: 100 }]
      expect(x[3]).to eq [{ something: -1 }]
      expect(x[3]).to eq [{ something: -1 }]
    end

    it 'manages group_by' do
      s = Score.new(0.125)

      s.at(1, add: { something: 1, criteria: :a }.extend(Dataset))
      s.at(1, add: { something: -1, criteria: :b }.extend(Dataset))
      s.at(1, add: { something: 4, criteria: nil }.extend(Dataset))
      s.at(1, add: { something: 5 }.extend(Dataset))
      s.at(1, add: { something: 100, criteria: :a }.extend(Dataset))

      h = s[1].group_by_attribute(:criteria)

      expect(h.keys).to eq [:a, :b, nil]

      expect(h[:a]).to eq [{ something: 1, criteria: :a }, { something: 100, criteria: :a }]
      expect(h[:b]).to eq [{ something: -1, criteria: :b }]
      expect(h[nil]).to eq [{ something: 4, criteria: nil }, { something: 5 }]
    end

    it 'manages select_attribute' do
      s = Score.new(0.125)

      s.at(1, add: { something: 1, criteria: :a }.extend(Dataset))
      s.at(1, add: { something: -1, criteria: :b }.extend(Dataset))
      s.at(1, add: { something: 4, criteria: nil }.extend(Dataset))
      s.at(1, add: { something: 5 }.extend(Dataset))
      s.at(1, add: { something: 100, criteria: :a }.extend(Dataset))

      l = s[1].select_attribute(:criteria)
      l2 = s[1].select_attribute(:criteria, :a)

      expect(l).to eq [{ something: 1, criteria: :a }, { something: -1, criteria: :b }, { something: 100, criteria: :a }]
      expect(l2).to eq [{ something: 1, criteria: :a }, { something: 100, criteria: :a }]
    end

    it 'manages sort_by_attribute' do
      s = Score.new(0.125)

      s.at(1, add: { something: 100, criteria: :a }.extend(Dataset))
      s.at(1, add: { something: 1, criteria: :a }.extend(Dataset))
      s.at(1, add: { something: -1, criteria: :b }.extend(Dataset))
      s.at(1, add: { something: nil, criteria: nil }.extend(Dataset))
      s.at(1, add: { something: 5 }.extend(Dataset))

      l = s[1].sort_by_attribute(:something)

      expect(l).to eq [{ something: -1, criteria: :b }, { something: 1, criteria: :a }, { something: 5 }, { something: 100, criteria: :a }]
    end

    it 'manages between' do
      s = Score.new(0.125)

      s.at(1, add: { something: 1000, criteria: :a, duration: 1 }.extend(D))
      s.at(1, add: { something: 100, criteria: :a, duration: 3 }.extend(D))
      s.at(2, add: { something: 1, criteria: :a, duration: 3 }.extend(D))
      s.at(3, add: { something: -1, criteria: :b }.extend(Dataset))
      s.at(3.5, add: { something: 99, criteria: :b, duration: 0.5 }.extend(D))
      s.at(4, add: { something: nil, criteria: nil, duration: 3 }.extend(D))
      s.at(5, add: { something: 5, duration: 3 }.extend(D))

      l = s.between(2, 4)

      expect(l).to eq [ { dataset: { something: 100, criteria: :a, duration: 3 }, start: 1r, finish: 3.875r },
                        { dataset: { something: 1, criteria: :a, duration: 3 }, start: 2r, finish: 4.875r },
                        { dataset: { something: -1, criteria: :b }, start: 3, finish: 3r },
                        { dataset: { something: 99, criteria: :b, duration: 0.5 }, start: 3.5r, finish: 3.875r } ]

    end

    it 'manages finish' do
      s = Score.new(0.125)

      s.at(2, add: { something: 1, criteria: :a, duration: 3 }.extend(D))
      s.at(1, add: { something: 1000, criteria: :a, duration: 1 }.extend(D))
      s.at(4, add: { something: nil, criteria: nil, duration: 3 }.extend(D))
      s.at(1, add: { something: 100, criteria: :a, duration: 3 }.extend(D))
      s.at(3, add: { something: -1, criteria: :b }.extend(Dataset))
      s.at(5, add: { something: 5, duration: 3 }.extend(D))
      s.at(3.5, add: { something: 99, criteria: :b, duration: 0.5 }.extend(D))
      s.at(4, add: { something: nil, criteria: nil, duration: 3 }.extend(D))

      expect(s.finish).to eq 7.875r
    end

    it 'manages Queryable' do
      # todo
    end
    it 'manages QueryableByDataset' do
      # todo
    end
  end
end
