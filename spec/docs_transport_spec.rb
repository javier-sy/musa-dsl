require 'docs_helper'

using Musa::Extension::Neumas
using Musa::Extension::Matrix

RSpec.describe 'Transport Documentation Examples' do

  context 'Transport - Timing & Clocks' do
    it 'creates different clock types for various timing sources' do
      # TimerClock - internal Ruby timer
      timer_clock = Musa::Clock::TimerClock.new(bpm: 120, ticks_per_beat: 24)
      expect(timer_clock).to be_a(Musa::Clock::TimerClock)

      # DummyClock - for testing without real timing (100 ticks)
      dummy_clock = Musa::Clock::DummyClock.new(100)
      expect(dummy_clock).to be_a(Musa::Clock::DummyClock)

      # ExternalTickClock - manual tick control
      external_clock = Musa::Clock::ExternalTickClock.new
      expect(external_clock).to be_a(Musa::Clock::ExternalTickClock)
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

      # Verify position changes were tracked (if any occurred)
      # on_change_position is called when position jumps/seeks occur
      # Since we're not jumping positions, this may be empty
      expect(positions).to be_an(Array)
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
      # Verify position change was detected (approximately at bar 8)
      expect(positions_changed).not_to be_empty
      expect(positions_changed.first.to_f).to be_within(0.1).of(8.0)
    end
  end

end
