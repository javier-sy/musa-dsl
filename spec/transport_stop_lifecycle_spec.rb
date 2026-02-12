require 'spec_helper'
require 'musa-dsl'

RSpec.describe 'Transport Stop/Terminate Lifecycle (Issue #67)' do
  context 'DummyClock' do
    it 'transport.stop from event fires after_stop callbacks' do
      clock = Musa::Clock::DummyClock.new(200)
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      after_stop_called = false
      transport.after_stop { after_stop_called = true }

      transport.sequencer.at 2 do
        transport.stop
      end

      transport.start

      expect(after_stop_called).to be true
    end

    it 'transport.stop from event resets sequencer' do
      clock = Musa::Clock::DummyClock.new(200)
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      position_at_stop = nil
      transport.after_stop { |seq| position_at_stop = seq.position }

      transport.sequencer.at 2 do
        transport.stop
      end

      transport.start

      expect(position_at_stop).to be_a(Rational)
    end

    it 'natural termination fires after_stop callbacks' do
      clock = Musa::Clock::DummyClock.new(10)
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      after_stop_called = false
      transport.after_stop { after_stop_called = true }

      transport.start

      expect(after_stop_called).to be true
    end

    it 'stop is idempotent — callbacks fire only once' do
      clock = Musa::Clock::DummyClock.new(200)
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      stop_count = 0
      transport.after_stop { stop_count += 1 }

      transport.sequencer.at 2 do
        transport.stop
        transport.stop  # Second call should be no-op
      end

      transport.start

      expect(stop_count).to eq(1)
    end
  end

  context 'ExternalTickClock' do
    it 'transport.stop fires after_stop callbacks' do
      clock = Musa::Clock::ExternalTickClock.new
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      after_stop_called = false
      transport.after_stop { after_stop_called = true }

      thread = Thread.new { transport.start }
      sleep 0.1

      50.times { clock.tick }

      transport.stop
      thread.join(2) || thread.kill

      expect(after_stop_called).to be true
    end
  end

  context 'TimerClock' do
    it 'transport.stop from event fires after_stop callbacks' do
      clock = Musa::Clock::TimerClock.new(bpm: 120, ticks_per_beat: 24)
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      after_stop_called = false
      transport.after_stop { after_stop_called = true }

      transport.sequencer.at 2 do
        transport.stop
      end

      thread = Thread.new { transport.start }
      sleep 0.1
      clock.start

      thread.join(10) || thread.kill

      expect(after_stop_called).to be true
    end

    it 'terminate is idempotent — callbacks fire only once' do
      clock = Musa::Clock::TimerClock.new(bpm: 120, ticks_per_beat: 24)
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      stop_count = 0
      transport.after_stop { stop_count += 1 }

      transport.sequencer.at 2 do
        transport.stop
      end

      thread = Thread.new { transport.start }
      sleep 0.1
      clock.start

      thread.join(10) || thread.kill

      expect(stop_count).to eq(1)
    end
  end

  context 'Clock base class contract' do
    it 'all clock subclasses respond to stop' do
      clocks = [
        Musa::Clock::DummyClock.new(1),
        Musa::Clock::ExternalTickClock.new,
        Musa::Clock::TimerClock.new(bpm: 120, ticks_per_beat: 24),
        Musa::Clock::InputMidiClock.new
      ]

      clocks.each do |clock|
        expect(clock).to respond_to(:stop)
      end
    end
  end
end
