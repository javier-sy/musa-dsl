require 'docs_helper'

using Musa::Extension::Neumas
using Musa::Extension::Matrix

RSpec.describe 'Transport Documentation Examples' do

  context 'Transport - Timing & Clocks' do
    it 'creates different clock types for various timing sources' do
      # TimerClock - internal Ruby timer. What is asked for is what it holds,
      # as exact Rationals and not floats.
      timer_clock = Musa::Clock::TimerClock.new(bpm: 120, ticks_per_beat: 24)
      expect(timer_clock.bpm).to eq 120
      expect(timer_clock.ticks_per_beat).to eq 24

      # DummyClock - runs as fast as it can, for a bounded number of ticks.
      # Careful with the count: it yields ONE FEWER than asked for, because the
      # condition decrements before testing. `new(1)` yields nothing at all.
      dummy_clock = Musa::Clock::DummyClock.new(100)
      ticks = 0
      dummy_clock.run { ticks += 1 }
      expect(ticks).to eq 99

      # ExternalTickClock - one tick per call, whenever somebody calls.
      external_clock = Musa::Clock::ExternalTickClock.new
      seen = 0
      runner = Thread.new { external_clock.run { seen += 1 } }
      sleep 0.05
      3.times { external_clock.tick }
      sleep 0.05
      external_clock.terminate
      runner.join(1)
      expect(seen).to eq 3
    end

    it 'creates transport with lifecycle callbacks and schedules events' do
      # Create clock and transport
      # Position 2 bars = 2 * 24 ticks/beat * 4 beats/bar = 192 ticks
      # Add extra ticks for safety
      clock = Musa::Clock::DummyClock.new(200)
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      # Track lifecycle events
      events = []

      transport.before_begin { events << :before_begin }
      transport.on_start { events << :on_start }
      transport.after_stop { events << :after_stop }

      # Schedule events
      sequencer = transport.sequencer
      sequencer.at 1 do
        events << :event_at_1
      end

      sequencer.at 2 do
        events << :event_at_2
        transport.stop
      end

      # Start transport (runs until stopped)
      transport.start

      # Verify lifecycle callbacks were called in order
      # Note: after_stop calls before_begin again to prepare for next start
      expect(events).to eq([:before_begin, :on_start, :event_at_1, :event_at_2, :after_stop, :before_begin])
    end

    it 'supports manual position control and on_change_position callback' do
      # 4 bars * 24 ticks/beat * 4 beats/bar = 384 ticks
      clock = Musa::Clock::DummyClock.new(400)
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      positions = []
      transport.on_change_position { |seq| positions << seq.position }

      # Schedule event to stop at bar 4
      transport.sequencer.at 4 do
        transport.stop
      end

      transport.start

      # on_change_position fires on seeks, and this run never seeks, so it is
      # not "may be empty": it is empty, and that is the claim.
      expect(positions).to eq([])
    end

    it 'allows changing playback position via change_position_to' do
      # 8 bars * 24 ticks/beat * 4 beats/bar = 768 ticks
      clock = Musa::Clock::DummyClock.new(800)
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      events = []
      positions_changed = []

      transport.on_change_position { |seq| positions_changed << seq.position }

      # Schedule event at position 8
      transport.sequencer.at 8 do
        events << :measure_8
        transport.stop
      end

      # Start from bar 8 (position 8)
      transport.change_position_to(bars: 8)
      transport.start

      # Verify the event at position 8 was executed
      expect(events).to include(:measure_8)
      # One seek, reported at exactly 767/96r -- one tick before bar 8, the
      # position from which the next tick is bar 8. The 0.1 tolerance was
      # standing in for that tick.
      expect(positions_changed).to eq([767/96r])
    end
  end

end
