require 'spec_helper'

require 'musa-dsl'

RSpec.describe Musa::Clock do
  context 'Dummy clock, tick count mode' do
    def ticks_yielded_by(clock)
      count = 0
      clock.run { count += 1 }
      count
    end

    it 'yields exactly the number of ticks it was asked for' do
      expect(ticks_yielded_by(Musa::Clock::DummyClock.new(100))).to eq 100
    end

    # The boundary, and the reason this file exists. From 2017 to 2026 the
    # condition read `@ticks -= 1; @ticks.positive?`, which spends a tick on the
    # decision to stop instead of on a turn: `new(100)` yielded 99 and `new(1)`
    # yielded nothing at all. It is the kind of thing that regresses in silence,
    # because every caller in the suite passes a generous budget and stops by
    # other means long before the clock runs out.
    it 'yields one tick for a budget of one' do
      expect(ticks_yielded_by(Musa::Clock::DummyClock.new(1))).to eq 1
    end

    it 'yields nothing for a budget of zero' do
      expect(ticks_yielded_by(Musa::Clock::DummyClock.new(0))).to eq 0
    end

    it 'counts down as it goes, and ends at zero' do
      clock = Musa::Clock::DummyClock.new(3)
      seen = []

      clock.run { seen << clock.ticks }

      expect(seen).to eq [2, 1, 0]
      expect(clock.ticks).to eq(-1)
    end

    it 'can be given more ticks while it is running' do
      clock = Musa::Clock::DummyClock.new(2)
      count = 0

      clock.run do
        count += 1
        clock.ticks += 2 if count == 1
      end

      expect(count).to eq 4
    end
  end

  context 'Dummy clock, condition mode' do
    it 'runs while the block says so, and spends no ticks' do
      remaining = 3
      clock = Musa::Clock::DummyClock.new { (remaining -= 1) >= 0 }

      count = 0
      clock.run { count += 1 }

      expect(count).to eq 3
    end

    it 'refuses to be given both a tick count and a condition' do
      expect { Musa::Clock::DummyClock.new(10) { true } }.to raise_error ArgumentError
    end
  end
end
