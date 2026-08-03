# Clock behaviour that needs real time, and therefore cannot live in an example.
#
# WHY THIS FILE EXISTS. An `@example` is executed by tools/doc-examples.rb on
# every run of the suite. Anything that starts a TimerClock, spawns a thread and
# sleeps is a timing test, and putting a timing test into a ratchet measures the
# machine rather than the library. These three came out of
# `spec/inline_doc_transport_spec.rb` when it was audited, and they are the only
# coverage of:
#
#   * the contract a Clock subclass has to honour -- on_start, the run loop,
#     terminate firing on_stop;
#   * `bpm=` taking effect on a clock that is already running;
#   * the running?/started?/paused? state machine of TimerClock.
#
# Everything else that file held is now declared in the documentation of the
# transport subsystem and verified there.

require 'spec_helper'
require 'musa-dsl'

RSpec.describe 'Transport clocks in real time' do
  include Musa::All

  it '@example Creating a simple clock subclass' do
    SimpleClock = Class.new(Musa::Clock::Clock) do
      def run
        @stopped = false
        @run = true
        @on_start.each(&:call)
  
        while @run
          yield if block_given?  # Generate tick
          sleep 0.1
        end
  
        stop  # Fires on_stop callbacks (idempotent)
      end
  
      def terminate
        stop         # Ensures on_stop callbacks fire
        @run = false # Exits the run loop
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
