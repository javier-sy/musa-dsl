require 'spec_helper'

require 'musa-dsl'

include Musa::Datasets

RSpec.describe Musa::Datasets::Score do

  context 'Dataset compatibility' do
    it 'is an AbsD and has a duration' do
      s = Score.new

      expect(s).to be_a AbsD
      expect(s).to be_a Score

      expect(s[:duration]).to eq 0
      expect(s.duration).to eq 0
    end

    it 'is an AbsD and has a duration' do
      s = Score.new

      s.at(1, add: { something: 1 }.extend(AbsD))

      expect(s[:duration]).to eq 0
      expect(s.duration).to eq 0

      s.at(1, add: { something: 1, duration: 2 }.extend(AbsD))

      expect(s[:duration]).to eq 2
      expect(s.duration).to eq 2

      s.at(2, add: { something: 1, duration: 3 }.extend(AbsD))

      expect(s[:duration]).to eq 4
      expect(s.duration).to eq 4
    end
  end

  context 'Score insert operations' do

    it 'refuses things that are not a Dataset' do
      s = Score.new
      expect { s.at(1, add: { something: 1 }) }.to raise_error(ArgumentError)
    end

    it 'manages event grouping correctly' do
      s = Score.new

      s.at(1, add: { something: 1 }.extend(AbsD))
      s.at(2, add: { something: -1 }.extend(AbsD))
      s.at(1.25, add: { something: 4 }.extend(AbsD))
      s.at(1.125, add: { something: 5 }.extend(AbsD))
      s.at(1.25, add: { something: 100 }.extend(AbsD))

      expect(s.positions).to eq [1r, 1.125r, 1.25r, 2r]

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
      s = Score.new

      s.at(1, add: { something: 1, criteria: :a }.extend(AbsD))
      s.at(1, add: { something: -1, criteria: :b }.extend(AbsD))
      s.at(1, add: { something: 4, criteria: nil }.extend(AbsD))
      s.at(1, add: { something: 5 }.extend(AbsD))
      s.at(1, add: { something: 100, criteria: :a }.extend(AbsD))

      h = s.at(1).group_by_attribute(:criteria)

      expect(h.keys).to eq [:a, :b, nil]

      expect(h[:a]).to eq [{ something: 1, criteria: :a }, { something: 100, criteria: :a }]
      expect(h[:b]).to eq [{ something: -1, criteria: :b }]
      expect(h[nil]).to eq [{ something: 4, criteria: nil }, { something: 5 }]

      l2 = h[:a].select_by_attribute(:something, 1)

      expect(l2).to eq [{ something: 1, criteria: :a }]
    end

    it 'manages select_attribute' do
      s = Score.new

      s.at(1, add: { something: 1, criteria: :a }.extend(AbsD))
      s.at(1, add: { something: -1, criteria: :b }.extend(AbsD))
      s.at(1, add: { something: 4, criteria: nil }.extend(AbsD))
      s.at(1, add: { something: 5 }.extend(AbsD))
      s.at(1, add: { something: 100, criteria: :a }.extend(AbsD))

      l = s.at(1).select_by_attribute(:criteria)
      l2 = s.at(1).select_by_attribute(:criteria, :a)

      expect(l).to eq [{ something: 1, criteria: :a }, { something: -1, criteria: :b }, { something: 100, criteria: :a }]
      expect(l2).to eq [{ something: 1, criteria: :a }, { something: 100, criteria: :a }]

      l3 = l.select_by_attribute(:something, 1)
      expect(l3).to eq [{ something: 1, criteria: :a }]
    end

    it 'manages sort_by_attribute' do
      s = Score.new

      s.at(1, add: { something: 100, criteria: :a }.extend(AbsD))
      s.at(1, add: { something: 1, criteria: :a }.extend(AbsD))
      s.at(1, add: { something: -1, criteria: :b }.extend(AbsD))
      s.at(1, add: { something: nil, criteria: nil }.extend(AbsD))
      s.at(1, add: { something: 5 }.extend(AbsD))

      l = s.at(1).sort_by_attribute(:something)

      expect(l).to eq [{ something: -1, criteria: :b },
                       { something: 1, criteria: :a },
                       { something: 5 },
                       { something: 100, criteria: :a }]

      l3 = l.select_by_attribute(:something, 1)
      expect(l3).to eq [{ something: 1, criteria: :a }]
    end

    it 'manages subset' do
      s = Score.new

      s.at(1, add: { something: 1, criteria: :a }.extend(AbsD))
      s.at(2, add: { something: -1, criteria: :b }.extend(AbsD))
      s.at(3, add: { something: 4, criteria: nil }.extend(AbsD))
      s.at(4, add: { something: 5 }.extend(AbsD))
      s.at(5, add: { something: 100, criteria: :a }.extend(AbsD))

      s2 = s.subset { |dataset| dataset[:criteria] == :a }

      expect(s2.size).to eq 2

      expect(s2.at(1)[0]).to eq({ something: 1, criteria: :a })
      expect(s2.at(5)[0]).to eq({ something: 100, criteria: :a })

      s3 = s2.subset { |dataset| dataset[:something] == 100}

      expect(s3.size).to eq 1

      expect(s2.at(5)[0]).to eq({ something: 100, criteria: :a })
    end
  end

  context 'Score querying operations' do
    s = Score.new

    s.at(1, add: { something: 1000, criteria: :a, duration: 1 }.extend(AbsD))
    s.at(1, add: { something: 100, criteria: :a, duration: 3 }.extend(AbsD))
    s.at(2, add: { something: 1, criteria: :a, duration: 3 }.extend(AbsD))
    s.at(3, add: { something: -1, criteria: :b }.extend(AbsD))
    s.at(3.5, add: { something: 99, criteria: :b, duration: 0.5 }.extend(AbsD))
    s.at(4, add: { something: nil, criteria: nil, duration: 3 }.extend(AbsD))
    s.at(5, add: { something: 5, duration: 3 }.extend(AbsD))

    it 'manages between with some duration' do

      l = s.between(2, 4)

      expect(l).to eq [ { dataset: { something: 100, criteria: :a, duration: 3 },
                          start: 1r, finish: 4r,
                          start_in_interval: 2r, finish_in_interval: 4r },

                        { dataset: { something: 1, criteria: :a, duration: 3 },
                          start: 2r, finish: 5r,
                          start_in_interval: 2r, finish_in_interval: 4r  },

                        { dataset: { something: -1, criteria: :b },
                          start: 3, finish: 3r,
                          start_in_interval: 3r, finish_in_interval: 3r  },

                        { dataset: { something: 99, criteria: :b, duration: 0.5 },
                          start: 3.5r, finish: 4r,
                          start_in_interval: 3.5r, finish_in_interval: 4r  } ]
    end

    it 'manages between with no duration' do

      l = s.between(3, 3)

      expect(l).to eq [ { dataset: { something: 100, criteria: :a, duration: 3 },
                          start: 1r, finish: 4r,
                          start_in_interval: 3r, finish_in_interval: 3r  },
                        { dataset: { something: 1, criteria: :a, duration: 3 },
                          start: 2r, finish: 5r,
                          start_in_interval: 3r, finish_in_interval: 3r  },
                        { dataset: { something: -1, criteria: :b },
                          start: 3, finish: 3r,
                          start_in_interval: 3r, finish_in_interval: 3r  } ]
    end


    it 'manages changes_between with some duration (1)' do
      l = s.changes_between(2, 3)

      expect(l).to eq [ { change: :start,
                          time: 2r,
                          dataset: { something: 1, criteria: :a, duration: 3 },
                          start: 2r,
                          finish: 5r,
                          start_in_interval: 2r,
                          finish_in_interval: 3r,
                          time_in_interval: 2r } ]
    end

    it 'manages changes_between with some duration (2)' do
      l = s.changes_between(3, 4)

      expect(l).to eq [ { change: :start,
                           time: 3r,
                           dataset: { something: -1, criteria: :b },
                           start: 3r,
                           finish: 3r,
                           start_in_interval: 3r,
                           finish_in_interval: 3r,
                           time_in_interval: 3r },
                         { change: :finish,
                           time: 3r,
                           dataset: { something: -1, criteria: :b },
                           start: 3r,
                           finish: 3r,
                           start_in_interval: 3r,
                           finish_in_interval: 3r,
                           time_in_interval: 3r },
                         { change: :start,
                           time: 3.5r,
                           dataset: { something: 99, criteria: :b, duration: 0.5 },
                           start: 3.5r,
                           finish: 4r,
                           start_in_interval: 3.5r,
                           finish_in_interval: 4r,
                           time_in_interval: 3.5r },
                         { change: :finish,
                           time: 4r,
                           dataset: { something: 100, criteria: :a, duration: 3 },
                           start: 1r,
                           finish: 4r,
                           start_in_interval: 3r,
                           finish_in_interval: 4r,
                           time_in_interval: 4r },
                         { change: :finish,
                           time: 4r,
                           dataset: { something: 99, criteria: :b, duration: 0.5 },
                           start: 3.5r,
                           finish: 4r,
                           start_in_interval: 3.5r,
                           finish_in_interval: 4r,
                           time_in_interval: 4r }
                       ]
    end

    it 'manages changes_between with 0 duration' do
      l = s.changes_between(3, 3)

      expect(l).to eq [ { change: :start,
                          time: 3r,
                          dataset: { something: -1, criteria: :b },
                          start: 3r,
                          finish: 3r,
                          start_in_interval: 3r,
                          finish_in_interval: 3r,
                          time_in_interval: 3r },
                        { change: :finish,
                          time: 3r,
                          dataset: { something: -1, criteria: :b },
                          start: 3r,
                          finish: 3r,
                          start_in_interval: 3r,
                          finish_in_interval: 3r,
                          time_in_interval: 3r }
                      ]
    end

    it 'manages finish' do
      expect(s.finish).to eq 8r
    end

    it 'manages duration' do
      expect(s.duration).to eq 7r
    end

    it 'manages Queryable (unfinished test case)' do
      raise NotImplementedError, "test case pending implementation"
    end
    
    it 'manages QueryableByDataset (unfinished test case)' do
      raise NotImplementedError, "test case pending implementation"
    end
  end
end
