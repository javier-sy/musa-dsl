require 'spec_helper'

require 'musa-dsl'

include Musa::Datasets

RSpec.describe Musa::Datasets::Score do

  context 'Score play' do
    it '...' do
      s = Score.new

      s.at(1, add: { something: 1000, criteria: :a, duration: 1 }.extend(AbsD))
      s.at(1, add: { something: 100, criteria: :a, duration: 3 }.extend(AbsD))
      s.at(2, add: { something: 1, criteria: :a, duration: 3 }.extend(AbsD))
      s.at(3, add: { something: -1, criteria: :b }.extend(AbsD))
      s.at(3.5, add: { something: 99, criteria: :b, duration: 0.5 }.extend(AbsD))
      s.at(4, add: { something: nil, criteria: nil, duration: 3 }.extend(AbsD))
      s.at(5, add: { something: 5, duration: 3 }.extend(AbsD))

      seq = s.play beats_per_bar: 4, ticks_per_beat: 24, at: 1 do |element|
        seq.log "#{element}"
      end

      seq.run
    end

    it '...' do
      s1 = Score.new
      s2 = Score.new

      s2.at(1, add: { something: 7777, criteria: :a, duration: 1 }.extend(AbsD))
      s2.at(2, add: { something: 777, criteria: :a, duration: 3 }.extend(AbsD))
      s2.at(3, add: { something: 77, criteria: :a, duration: 3 }.extend(AbsD))

      s1.at(1, add: { something: 1000, criteria: :a, duration: 1 }.extend(AbsD))
      s1.at(1, add: { something: 100, criteria: :a, duration: 3 }.extend(AbsD))
      s1.at(2, add: { something: 1, criteria: :a, duration: 3 }.extend(AbsD))
      s1.at(3, add: { something: -1, criteria: :b }.extend(AbsD))
      s1.at(3.5, add: { something: 99, criteria: :b, duration: 0.5 }.extend(AbsD))
      s1.at(4, add: { something: nil, criteria: nil, duration: 3 }.extend(AbsD))
      s1.at(4.5, add: s2) # !!!!
      s1.at(5, add: { something: 5, duration: 3 }.extend(AbsD))

      seq = s1.play beats_per_bar: 4, ticks_per_beat: 24, at: 1 do |element|
        seq.log "#{element}"
      end

      seq.run
    end

    it '...' do
      s1 = Score.new

      s1.at(1, add: { something: 1000, criteria: :a, duration: 1 }.extend(AbsD))
      s1.at(1, add: { something: 100, criteria: :a, duration: 3 }.extend(AbsD))
      s1.at(2, add: { something: 1, criteria: :a, duration: 3 }.extend(AbsD))
      s1.at(3, add: { something: -1, criteria: :b }.extend(AbsD))
      s1.at(3.5, add: { something: 99, criteria: :b, duration: 0.5 }.extend(AbsD))
      s1.at(4, add: { something: nil, criteria: nil, duration: 3 }.extend(AbsD))
      s1.at(4.5, add: s1) # !!!!
      s1.at(5, add: { something: 5, duration: 3 }.extend(AbsD))

      seq = s1.play beats_per_bar: 4, ticks_per_beat: 24, at: 1 do |element|
        seq.log "#{element}"
      end

      seq.run
    end

  end
end
