require 'spec_helper'
require 'musa-dsl'

RSpec.describe 'Transport Inline Documentation Examples' do
  include Musa::All

  context 'Clock (clock.rb)' do
    it 'example from line 50 - Creating a simple clock subclass' do
      class SimpleClock < Musa::Clock::Clock
        def run
          @run = true
          @on_start.each(&:call)

          while @run
            yield if block_given?  # Generate tick
            sleep 0.1
          end

          @on_stop.each(&:call)
        end

        def terminate
          @run = false
        end
      end

      clock = SimpleClock.new
      started = false
      stopped = false

      clock.on_start { started = true }
      clock.on_stop { stopped = true }

      # Run clock in background thread for a moment
      ticks = 0
      thread = Thread.new do
        clock.run { ticks += 1 }
      end

      sleep 0.25  # Let it tick a few times
      clock.terminate
      thread.join

      expect(started).to be true
      expect(stopped).to be true
      expect(ticks).to be > 0
    end

    it 'example from line 93 - on_start callback' do
      clock = Musa::Clock::DummyClock.new(10)
      started = false

      clock.on_start { started = true }

      # Run in thread to avoid blocking
      thread = Thread.new { clock.run { } }
      sleep 0.1
      clock.terminate
      thread.join

      expect(started).to be true
    end

    it 'example from line 106 - on_stop callback' do
      clock = Musa::Clock::DummyClock.new(5)
      stopped = false

      clock.on_stop { stopped = true }

      # Run the clock (it will stop after 5 ticks)
      clock.run { }

      expect(stopped).to be true
    end

    it 'example from line 123 - on_change_position callback' do
      clock = Musa::Clock::ExternalTickClock.new
      position_changes = []

      clock.on_change_position do |bars:, beats:, midi_beats:|
        position_changes << { bars: bars, beats: beats, midi_beats: midi_beats }
      end

      # Manually trigger position change
      @on_change_position = clock.instance_variable_get(:@on_change_position)
      @on_change_position.each { |block| block.call(bars: 2, beats: nil, midi_beats: nil) }

      expect(position_changes.size).to eq(1)
      expect(position_changes.first[:bars]).to eq(2)
    end
  end

  context 'DummyClock (dummy-clock.rb)' do
    it 'example from line 25 - Fixed tick count' do
      clock = Musa::Clock::DummyClock.new(100)  # Exactly 100 ticks
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      ticks = 0
      transport.sequencer.every(1) { ticks += 1 }

      transport.start  # Runs 100 ticks, then stops

      expect(ticks).to be > 0
    end

    it 'example from line 30 - Custom condition' do
      continue_running = true
      clock = Musa::Clock::DummyClock.new { continue_running }
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      ticks = 0
      transport.sequencer.every(1) do
        ticks += 1
        continue_running = false if ticks >= 5
      end

      transport.start  # Runs while continue_running? is true

      expect(ticks).to eq(5)
    end

    it 'example from line 36 - Testing specific sequences' do
      ticks = 0
      some_condition = true
      clock = Musa::Clock::DummyClock.new { ticks < 50 || some_condition }

      transport = Musa::Transport::Transport.new(clock, 4, 24)

      transport.sequencer.every(1) do
        ticks += 1
        some_condition = false if ticks >= 60
      end

      transport.start
      # Runs minimum 50 ticks, then checks some_condition

      expect(ticks).to be >= 50
    end
  end

  context 'ExternalTickClock (external-tick-clock.rb)' do
    it 'example from line 28 - Manual stepping' do
      clock = Musa::Clock::ExternalTickClock.new
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      executed = []
      transport.sequencer.at(1) { executed << "tick 1" }
      transport.sequencer.at(2) { executed << "tick 2" }

      # Start in background thread
      thread = Thread.new { transport.start }
      sleep 0.1  # Let transport initialize

      # Later, from external source:
      100.times { clock.tick }  # Advances ticks manually

      transport.stop
      thread.join

      expect(executed).to include("tick 1", "tick 2")
    end

    it 'example from line 38 - Integration with game loop' do
      clock = Musa::Clock::ExternalTickClock.new
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      ticks_generated = 0
      transport.sequencer.every(1) { ticks_generated += 1 }

      # Start in background
      thread = Thread.new { transport.start }
      sleep 0.1

      # In game update loop:
      delta_time = 0.016  # 60 FPS
      frames = 0

      10.times do
        frames += 1
        if frames % 2 == 0  # Every other frame
          clock.tick
        end
      end

      transport.stop
      thread.join

      expect(ticks_generated).to be > 0
    end

    it 'example from line 50 - Testing' do
      clock = Musa::Clock::ExternalTickClock.new
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      executed = []

      # Schedule some events
      transport.sequencer.at(1) { executed << "Tick 0" }
      transport.sequencer.at(2) { executed << "Tick 1" }

      # Start in background
      thread = Thread.new { transport.start }
      sleep 0.1

      # Generate ticks to advance sequencer
      100.times { clock.tick }

      transport.stop
      thread.join

      expect(executed).to include("Tick 0")
      expect(executed).to include("Tick 1")
    end
  end

  context 'InputMidiClock (input-midi-clock.rb)' do
    it 'example from line 40 - Basic setup (without actual MIDI)' do
      # Note: This test simulates the setup without requiring actual MIDI hardware
      # In real use, you would use: input = MIDICommunications::Input.all.first

      # Create clock without input (will wait for assignment)
      clock = Musa::Clock::InputMidiClock.new

      expect(clock).to be_a(Musa::Clock::InputMidiClock)
      expect(clock.input).to be_nil
    end

    it 'example from line 47 - Dynamic input assignment' do
      clock = Musa::Clock::InputMidiClock.new  # No input yet

      expect(clock.input).to be_nil

      # Later: clock.input = MIDICommunications::Input.all.first
      # For testing, we just verify the input setter exists
      expect(clock).to respond_to(:input=)
    end

    it 'example from line 54 - Checking performance' do
      clock = Musa::Clock::InputMidiClock.new

      # time_table shows histogram: X ms took Y ticks
      expect(clock.time_table).to eq([])  # Empty initially
    end
  end

  context 'TimerClock (timer-clock.rb)' do
    it 'example from line 38 - Basic setup with BPM' do
      clock = Musa::Clock::TimerClock.new(bpm: 120, ticks_per_beat: 24)
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      expect(clock.bpm).to eq(120r)
      expect(clock.ticks_per_beat).to eq(24r)
    end

    it 'example from line 43 - With timing correction' do
      # Correction compensates for system-specific timing offsets
      clock = Musa::Clock::TimerClock.new(bpm: 140, ticks_per_beat: 24, correction: -0.001)

      expect(clock.bpm).to eq(140r)
    end

    it 'example from line 48 - Dynamic tempo changes' do
      clock = Musa::Clock::TimerClock.new(bpm: 120, ticks_per_beat: 24)

      expect(clock.bpm).to eq(120r)

      # ... later, while running:
      clock.bpm = 140  # Tempo change takes effect immediately

      expect(clock.bpm).to eq(140r)
    end

    it 'example from line 69 - All equivalent clock configurations' do
      # All equivalent for 120 BPM, 24 ticks/beat:
      clock1 = Musa::Clock::TimerClock.new(bpm: 120, ticks_per_beat: 24)
      clock2 = Musa::Clock::TimerClock.new(bpm: 120, ticks_per_beat: 24)  # Same as clock1
      clock3 = Musa::Clock::TimerClock.new(60.0 / (120 * 24), ticks_per_beat: 24)  # period as positional arg

      expect(clock1.bpm).to eq(clock2.bpm)
      expect(clock1.bpm).to eq(clock3.bpm)
      expect(clock1.ticks_per_beat).to eq(clock2.ticks_per_beat)
      expect(clock1.ticks_per_beat).to eq(clock3.ticks_per_beat)
    end

    it 'example from line 143 - Tempo automation' do
      clock = Musa::Clock::TimerClock.new(bpm: 120, ticks_per_beat: 24)

      expect(clock.bpm).to eq(120r)

      clock.bpm = 140  # Speed up!

      expect(clock.bpm).to eq(140r)
    end
  end

  context 'Timer (timer.rb)' do
    it 'example from line 30 - Internal use by TimerClock' do
      timer = Musa::Clock::Timer.new(0.02083)  # ~48 ticks/second

      expect(timer.period).to eq(Rational(2083, 100000))
    end

    it 'example from line 50 - 120 BPM, 24 ticks per beat' do
      period = 60.0 / (120 * 24)  # 0.02083 seconds
      timer = Musa::Clock::Timer.new(period)

      expect(timer.period.to_f).to be_within(0.001).of(0.02083)
    end
  end

  context 'Transport (transport.rb)' do
    it 'example from line 49 - Basic setup with TimerClock' do
      clock = Musa::Clock::TimerClock.new(bpm: 120, ticks_per_beat: 24)
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      executed = []

      # Schedule events
      transport.sequencer.at(1) { executed << "Start!" }
      transport.sequencer.at(4) do
        executed << "Bar 4"
        transport.stop
      end

      # Start transport in background (blocks waiting for clock activation)
      thread = Thread.new { transport.start }
      sleep 0.1  # Let transport initialize

      # Activate clock from external control
      clock.start  # Now ticks begin generating

      # Wait for completion (max 10 seconds)
      thread.join(10) || thread.kill

      expect(executed).to include("Start!", "Bar 4")
    end

    it 'example from line 63 - With lifecycle callbacks' do
      clock = Musa::Clock::DummyClock.new(200)
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      lifecycle = []

      transport.before_begin { lifecycle << "Initializing..." }
      transport.on_start { lifecycle << "Started!" }
      transport.after_stop { lifecycle << "Stopped, cleaning up..." }

      transport.sequencer.at 4 do
        transport.stop
      end

      transport.start

      expect(lifecycle).to include("Initializing...", "Started!", "Stopped, cleaning up...")
    end

    it 'example from line 104 - With parameters' do
      clock = Musa::Clock::DummyClock.new(100)

      executed = []

      transport = Musa::Transport::Transport.new(
        clock, 4, 24,
        on_start: ->(seq) { executed << "Started at #{seq.position}" }
      )

      transport.sequencer.at 2 do
        transport.stop
      end

      transport.start

      expect(executed.first).to match(/Started at/)
    end

    it 'example from line 105 - With callback methods' do
      clock = Musa::Clock::DummyClock.new(100)

      setup_done = false
      recording_started = false
      recording_saved = false

      transport = Musa::Transport::Transport.new(clock, 4, 24)
      transport.before_begin { setup_done = true }
      transport.on_start { recording_started = true }
      transport.after_stop { recording_saved = true }

      transport.sequencer.at 2 do
        transport.stop
      end

      transport.start

      expect(setup_done).to be true
      expect(recording_started).to be true
      expect(recording_saved).to be true
    end

    it 'example from line 177 - before_begin callback' do
      clock = Musa::Clock::DummyClock.new(100)
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      initialized_position = nil

      transport.before_begin do |seq|
        initialized_position = seq.position
      end

      transport.sequencer.at 2 do
        transport.stop
      end

      transport.start

      expect(initialized_position).to be_a(Rational)
    end

    it 'example from line 194 - on_start callback' do
      clock = Musa::Clock::DummyClock.new(100)
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      start_positions = []

      transport.on_start do |seq|
        start_positions << seq.position
      end

      transport.sequencer.at 2 do
        transport.stop
      end

      transport.start

      expect(start_positions.size).to eq(1)
      expect(start_positions.first).to be_a(Rational)
    end

    it 'example from line 210 - after_stop callback' do
      clock = Musa::Clock::DummyClock.new(100)
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      stopped_position = nil
      cleanup_done = false

      transport.after_stop do |seq|
        stopped_position = seq.position
        cleanup_done = true
      end

      transport.sequencer.at 2 do
        transport.stop
      end

      transport.start

      expect(stopped_position).to be_a(Rational)
      expect(cleanup_done).to be true
    end

    it 'example from line 228 - on_change_position callback' do
      clock = Musa::Clock::DummyClock.new(400)
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      position_jumps = []

      transport.on_change_position do |seq|
        position_jumps << seq.position
      end

      # Schedule event at position 8
      transport.sequencer.at 8 do
        transport.stop
      end

      # Jump to bar 8
      transport.change_position_to(bars: 8)
      transport.start

      expect(position_jumps).not_to be_empty
      expect(position_jumps.first).to be_within(0.1).of(8.0)
    end

    it 'example from line 269 - Jump to bar 8' do
      clock = Musa::Clock::DummyClock.new(400)
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      executed = []

      transport.sequencer.at 8 do
        executed << "Bar 8"
        transport.stop
      end

      transport.change_position_to(bars: 8)
      transport.start

      expect(executed).to include("Bar 8")
    end

    it 'example from line 272 - MIDI Song Position Pointer' do
      clock = Musa::Clock::DummyClock.new(400)
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      executed = []

      transport.sequencer.at 4 do
        executed << "Bar 4"
        transport.stop
      end

      transport.change_position_to(midi_beats: 96)  # Bar 4 in 4/4
      transport.start

      expect(executed).to include("Bar 4")
    end
  end

  context 'Integration tests' do
    it 'complete workflow with DummyClock and lifecycle' do
      # Create clock and transport
      clock = Musa::Clock::DummyClock.new(200)
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      # Track all events
      events = []

      transport.before_begin { events << :before_begin }
      transport.on_start { events << :on_start }
      transport.after_stop { events << :after_stop }

      # Schedule musical events
      transport.sequencer.at(1) { events << :bar_1 }
      transport.sequencer.at(2) { events << :bar_2 }
      transport.sequencer.at(3) do
        events << :bar_3
        transport.stop
      end

      transport.start

      expect(events).to include(:before_begin, :on_start, :bar_1, :bar_2, :bar_3, :after_stop)
      # Verify order: before_begin -> on_start -> events -> after_stop -> before_begin (for next start)
      expect(events.index(:before_begin)).to be < events.index(:on_start)
      expect(events.index(:on_start)).to be < events.index(:bar_1)
      expect(events.index(:bar_3)).to be < events.index(:after_stop)
    end

    it 'TimerClock with tempo changes' do
      clock = Musa::Clock::TimerClock.new(bpm: 120, ticks_per_beat: 24)
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      tempo_at_start = nil
      tempo_changed = false

      transport.on_start do
        tempo_at_start = clock.bpm
      end

      transport.sequencer.at 1 do
        clock.bpm = 140
        tempo_changed = true
      end

      transport.sequencer.at 2 do
        transport.stop
      end

      # Start transport in background
      thread = Thread.new { transport.start }
      sleep 0.1

      # Activate clock
      clock.start

      # Wait for completion
      thread.join(10) || thread.kill

      expect(tempo_at_start).to eq(120r)
      expect(tempo_changed).to be true
      expect(clock.bpm).to eq(140r)
    end

    it 'ExternalTickClock with precise control' do
      clock = Musa::Clock::ExternalTickClock.new
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      ticks_executed = []
      transport.sequencer.every(1) do
        ticks_executed << transport.sequencer.position
      end

      # Start in background
      thread = Thread.new { transport.start }
      sleep 0.1

      # Manually generate 10 ticks
      10.times { clock.tick; sleep 0.01 }

      transport.stop
      thread.join

      expect(ticks_executed.size).to be > 0
    end

    it 'position changes and callbacks' do
      clock = Musa::Clock::DummyClock.new(400)
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      positions_changed = []
      events = []
      fast_forward_states = []

      transport.on_change_position do |seq|
        positions_changed << seq.position
      end

      transport.sequencer.on_fast_forward do |is_starting|
        fast_forward_states << is_starting
      end

      transport.sequencer.at(1) { events << :bar_1 }
      transport.sequencer.at(5) { events << :bar_5 }
      transport.sequencer.at(8) do
        events << :bar_8
        transport.stop
      end

      # Jump to bar 5 and start
      # IMPORTANT: This fast-forwards through bars 1-5, executing ALL intermediate events
      transport.change_position_to(bars: 5)
      transport.start

      # Fast-forward executes all intermediate events
      expect(events).to include(:bar_1, :bar_5, :bar_8)

      # on_change_position callback was called at new position
      expect(positions_changed).not_to be_empty

      # on_fast_forward callbacks were triggered (true when starting, false when ending)
      expect(fast_forward_states).to eq([true, false])
    end

    it 'multiple callbacks of same type' do
      clock = Musa::Clock::DummyClock.new(100)
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      callbacks_executed = []

      transport.on_start { callbacks_executed << :start_1 }
      transport.on_start { callbacks_executed << :start_2 }
      transport.on_start { callbacks_executed << :start_3 }

      transport.sequencer.at 2 do
        transport.stop
      end

      transport.start

      expect(callbacks_executed).to eq([:start_1, :start_2, :start_3])
    end

    it 'DummyClock with condition block and state' do
      state = { continue: true, ticks: 0 }

      clock = Musa::Clock::DummyClock.new { state[:continue] }
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      transport.sequencer.every(1) do
        state[:ticks] += 1
        state[:continue] = false if state[:ticks] >= 10
      end

      transport.start

      expect(state[:ticks]).to eq(10)
    end

    it 'clock state management' do
      clock = Musa::Clock::TimerClock.new(bpm: 120, ticks_per_beat: 24)

      expect(clock.running?).to be_falsy
      expect(clock.started?).to be_falsy
      expect(clock.paused?).to be_falsy

      # Start in background - add tick counter so clock has something to do
      ticks = 0
      thread = Thread.new { clock.run { ticks += 1 } }
      sleep 0.1

      expect(clock.running?).to be true

      clock.start
      sleep 0.1

      expect(clock.started?).to be true
      expect(clock.paused?).to be_falsy

      clock.pause
      sleep 0.1

      expect(clock.started?).to be true
      expect(clock.paused?).to be true

      clock.continue
      sleep 0.1

      expect(clock.paused?).to be_falsy

      clock.terminate
      thread.join(2) || thread.kill  # Timeout de 2 segundos por seguridad

      expect(ticks).to be > 0  # Verificar que generó ticks
    end
  end
end
