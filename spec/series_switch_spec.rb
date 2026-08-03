require 'spec_helper'

require 'musa-dsl'

RSpec.describe Musa::Series do
  context 'Selecting between series' do
    include Musa::Series

    # `indexed_series` is a splat, so it is `[]` and not nil when nothing was
    # passed positionally -- and `[]` is truthy. Written as `sources =
    # indexed_series || hash_series`, the documented keyword form never reached
    # the sources at all: it built an empty Array and then raised TypeError
    # trying to index it with a Symbol. Three constructors carried it.
    it 'switch chooses by name as well as by position' do
      expect(S(:a, :b, :a).switch(a: S(1, 2, 3), b: S(10, 20, 30)).i.to_a).to eq [1, 10, 2]
      expect(S(0, 1, 0, 1).switch(S(1, 2, 3), S(10, 20, 30)).i.to_a).to eq [1, 10, 2, 20]
    end

    it 'multiplex chooses by name as well as by position' do
      expect(S(:x, :y, :x).multiplex(x: S(1, 2, 3), y: S(10, 20, 30)).i.to_a).to eq [1, 20, 3]
      expect(S(0, 1, 0, 1).multiplex(S(1, 2, 3), S(10, 20, 30)).i.to_a).to eq [1, 20, 3]
    end

    it 'switch_serie chooses by name as well as by position' do
      expect(S(:p, :q).switch_serie(p: S(1, 2), q: S(9, 8)).i.to_a).to eq [1, 2, 9, 8]
      expect(S(0, 1).switch_serie(S(1, 2), S(9, 8)).i.to_a).to eq [1, 2, 9, 8]
    end

    # The distinction the documentation of these two exists to make, and which
    # it stated backwards: multiplex was described as "like switch but returns
    # composite values", when what it returns is one value like switch does.
    # What differs is who moves.
    it 'switch leaves the unselected series where they were' do
      expect(S(0, 1, 0, 1, 0).switch(S(:a1, :a2, :a3), S(:b1, :b2)).i.to_a)
        .to eq %i[a1 b1 a2 b2 a3]
    end

    it 'multiplex advances every serie, selected or not' do
      expect(S(0, 1, 0, 1, 0).multiplex(S(:a1, :a2, :a3), S(:b1, :b2)).i.to_a)
        .to eq %i[a1 b2 a3]
    end

    it 'multiplex ends when the SELECTED serie has nothing left' do
      # Not when the fastest runs out: while nobody looks at the exhausted one,
      # it goes on.
      expect(S(0, 0, 0, 0).multiplex(S(1, 2, 3, 4), S(9, 9)).i.to_a).to eq [1, 2, 3, 4]

      # But the step that selects it ends everything, and that is why the
      # example above gives three values and not five: the fourth step asked b,
      # which had spent both of its own on the first two steps.
      expect(S(0, 0, 1).multiplex(S(1, 2, 3, 4), S(9, 9)).i.to_a).to eq [1, 2]
    end
  end
end
