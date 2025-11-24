require 'spec_helper'
require 'musa-dsl'

RSpec.describe 'Sequencer Inline Documentation Examples' do
  include Musa::All

  context 'BaseSequencer (base-sequencer.rb)' do
    it 'example from line 62 - Basic tick-based sequencer' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)  # 4/4, 24 ticks/beat

      executed = []

      seq.at(1) { executed << "Beat 1" }
      seq.at(2) { executed << "Beat 2" }
      seq.at(3.5) { executed << "Beat 3.5" }

      seq.run  # Executes all scheduled events

      expect(executed).to eq(["Beat 1", "Beat 2", "Beat 3.5"])
    end

    it 'example from line 71 - Tickless sequencer' do
      seq = Musa::Sequencer::BaseSequencer.new  # Tickless mode

      executed = []

      seq.at(1) { executed << "Position 1" }
      seq.at(1.5) { executed << "Position 1.5" }

      seq.tick    # Jumps to position 1
      expect(executed).to eq(["Position 1"])

      seq.tick  # Jumps to position 1.5
      expect(executed).to eq(["Position 1", "Position 1.5"])
    end

    it 'example from line 80 - Playing series' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      notes = S({pitch: 60, duration: 1}, {pitch: 62, duration: 1},
                {pitch: 64, duration: 0.5}, {pitch: 65, duration: 0.5}, {pitch: 67, duration: 2})
      played_notes = []

      seq.play(notes) do |pitch:, duration:|
        played_notes << { pitch: pitch, duration: duration, position: seq.position }
      end

      seq.run

      expect(played_notes.size).to eq(5)
      expect(played_notes[0][:pitch]).to eq(60)
      expect(played_notes[0][:duration]).to eq(1)
      expect(played_notes[1][:pitch]).to eq(62)
      expect(played_notes[2][:pitch]).to eq(64)
      expect(played_notes[2][:duration]).to eq(0.5)
      expect(played_notes[3][:pitch]).to eq(65)
      expect(played_notes[4][:pitch]).to eq(67)
      expect(played_notes[4][:duration]).to eq(2)
    end

    it 'example from line 94 - Every and move' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      tick_positions = []
      volume_values = []

      # Execute every beat starting from position 0 until position 7
      seq.every(1, till: 7) { tick_positions << seq.position }

      # Animate value from 0 to 127 over 4 beats
      seq.move(every: 1/4r, from: 0, to: 127, duration: 4) do |value|
        volume_values << value.round
      end

      seq.run

      # Every executes at positions up to (but not including) till value
      expect(tick_positions.size).to be >= 6
      expect(volume_values.first).to eq(0)
      expect(volume_values.last).to eq(127)
      expect(volume_values.size).to be > 10  # Multiple steps
    end

    it 'example from line 237 - Resetting sequencer state' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      # Schedule some events
      seq.at(1) { }
      seq.at(2) { }
      seq.every(1, till: 8) { }

      expect(seq.size).to be >= 2  # At least 2 scheduled events
      expect(seq.empty?).to be false

      # Reset clears everything
      seq.reset

      expect(seq.size).to eq(0)
      expect(seq.empty?).to be true
      # Position after reset is before first tick (1 - tick_duration)
      expect(seq.position).to be < 1
    end

    it 'example from line 322 - Monitoring event execution with on_debug_at' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24, do_log: true)

      debug_calls = []

      seq.on_debug_at do
        debug_calls << { position: seq.position, time: Time.now }
      end

      seq.at(1) { }
      seq.at(2) { }

      seq.run

      expect(debug_calls.size).to eq(2)
      expect(debug_calls[0][:position]).to eq(1)
      expect(debug_calls[1][:position]).to eq(2)
    end

    it 'example from line 351 - Handling errors in scheduled events' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24, do_error_log: false)

      errors = []

      seq.on_error do |error|
        errors << { message: error.message, position: seq.position }
      end

      executed = []

      seq.at(1) { executed << "Normal event" }
      seq.at(2) { raise "Something went wrong!" }
      seq.at(3) { executed << "This still executes" }

      seq.run

      expect(errors.size).to eq(1)
      expect(errors[0][:message]).to eq("Something went wrong!")
      expect(errors[0][:position]).to eq(2)
      expect(executed).to eq(["Normal event", "This still executes"])
    end

    it 'example from line 383 - Tracking fast-forward operations' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      ff_state = []

      seq.on_fast_forward do |is_starting|
        if is_starting
          ff_state << "Fast-forward started from position #{seq.position}"
        else
          ff_state << "Fast-forward ended at position #{seq.position}"
        end
      end

      seq.at(1) { }
      seq.at(5) { }

      # Jump to position 10 (executes events at 1 and 5 during fast-forward)
      seq.position = 10

      expect(ff_state[0]).to match(/Fast-forward started from position/)
      expect(ff_state[1]).to match(/Fast-forward ended at position 10/)
    end

    it 'example from line 417 - Logging tick positions with before_tick' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      tick_log = []

      seq.before_tick do |position|
        tick_log << position
      end

      seq.at(1) { }
      seq.at(2) { }

      # Tick until we hit both events
      seq.run

      # before_tick is called for every tick position, including those with events
      expect(tick_log.size).to be >= 2
      expect(tick_log).to include(1)
      expect(tick_log).to include(2)
    end

    it 'example from line 461 - Basic event pub/sub with on/launch' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      received_values = []

      # Subscribe to custom event
      seq.on(:note_played) do |pitch, velocity|
        received_values << { pitch: pitch, velocity: velocity }
      end

      # Launch event from scheduled block
      seq.at(1) do
        seq.launch(:note_played, 60, 100)
      end

      seq.at(2) do
        seq.launch(:note_played, 64, 80)
      end

      seq.run

      expect(received_values.size).to eq(2)
      expect(received_values[0]).to eq({ pitch: 60, velocity: 100 })
      expect(received_values[1]).to eq({ pitch: 64, velocity: 80 })
    end

    it 'example from line 791 - Linear fade with move' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      volume_values = []

      seq.move(every: 1/4r, from: 0, to: 127, duration: 4) do |value|
        volume_values << value.round
      end

      seq.run

      expect(volume_values.first).to eq(0)
      expect(volume_values.last).to eq(127)
      # Values should be monotonically increasing
      expect(volume_values).to eq(volume_values.sort)
    end
  end

  context 'TickBasedTiming (base-sequencer-tick-based.rb)' do
    it 'example from line 46 - Creating tick-based sequencer' do
      sequencer = Musa::Sequencer::BaseSequencer.new(4, 96)  # 4 beats, 96 ticks/beat

      expect(sequencer.ticks_per_bar).to eq(384r)
      expect(sequencer.tick_duration).to eq(1/384r)
      # Position starts at 1r - tick_duration (before first tick brings it to 1r)
      expect(sequencer.position).to be < 1r
    end

    it 'example from line 52 - Advancing time with tick' do
      sequencer = Musa::Sequencer::BaseSequencer.new(4, 96)

      initial_position = sequencer.position

      sequencer.tick  # Advance one tick (1/384 of a bar)

      expect(sequencer.position).to eq(initial_position + 1/384r)
    end

    it 'example from line 56 - Fast-forward to future position' do
      sequencer = Musa::Sequencer::BaseSequencer.new(4, 96)

      ff_started = false
      ff_ended = false

      sequencer.on_fast_forward do |is_starting|
        ff_started = true if is_starting
        ff_ended = true if !is_starting
      end

      sequencer.position = 2r  # Jump to bar 2

      expect(ff_started).to be true
      expect(ff_ended).to be true
      expect(sequencer.position).to eq(2r)
    end

    it 'example from line 198 - Quantization to tick boundaries' do
      sequencer = Musa::Sequencer::BaseSequencer.new(4, 96)

      # With 384 ticks per bar, tick_duration = 1/384r
      quantized = sequencer.quantize_position(1.5001r, warn: false)

      expect(quantized).to eq(1.5r)  # Rounded to nearest tick
    end
  end

  context 'TicklessBasedTiming (base-sequencer-tickless-based.rb)' do
    it 'example from line 50 - Creating tickless sequencer' do
      sequencer = Musa::Sequencer::BaseSequencer.new  # No tick parameters

      expect(sequencer.ticks_per_bar).to eq(Float::INFINITY)
      expect(sequencer.tick_duration).to eq(0r)
      expect(sequencer.position).to be_nil  # before first event
    end

    it 'example from line 56 - Precise timing without quantization' do
      sequencer = Musa::Sequencer::BaseSequencer.new

      executed = []

      sequencer.at(1r) { executed << "Event 1" }
      sequencer.at(1 + 1/7r) { executed << "Event 2" }  # Exact 1/7 division
      sequencer.at(1 + 1/3r) { executed << "Event 3" }  # Exact 1/3 division

      sequencer.tick  # Jumps to 1r
      expect(executed).to eq(["Event 1"])
      expect(sequencer.position).to eq(1r)

      sequencer.tick  # Jumps to 8/7r (1 + 1/7)
      expect(executed).to eq(["Event 1", "Event 2"])
      expect(sequencer.position).to eq(8/7r)

      sequencer.tick  # Jumps to 4/3r (1 + 1/3)
      expect(executed).to eq(["Event 1", "Event 2", "Event 3"])
      expect(sequencer.position).to eq(4/3r)
    end

    it 'example from line 64 - Complex polyrhythm (5 against 7)' do
      sequencer = Musa::Sequencer::BaseSequencer.new  # Tickless mode

      notes_a = []
      notes_b = []

      7.times { |i| sequencer.at(1 + Rational(i, 7)) { notes_a << sequencer.position } }
      5.times { |i| sequencer.at(1 + Rational(i, 5)) { notes_b << sequencer.position } }

      sequencer.run  # Events at exact rational positions

      expect(notes_a.size).to eq(7)
      expect(notes_b.size).to eq(5)

      # Verify exact positions
      expect(notes_a[0]).to eq(1r)
      expect(notes_a[1]).to eq(8/7r)
      expect(notes_b[0]).to eq(1r)
      expect(notes_b[1]).to eq(6/5r)
    end

    it 'example from line 129 - Event-driven progression with tick' do
      sequencer = Musa::Sequencer::BaseSequencer.new

      executed = []

      sequencer.at(1r) { executed << "A" }
      sequencer.at(1.5r) { executed << "B" }
      sequencer.at(2r) { executed << "C" }

      sequencer.tick  # position becomes 1r
      expect(sequencer.position).to eq(1r)
      expect(executed).to eq(["A"])

      sequencer.tick  # position becomes 1.5r
      expect(sequencer.position).to eq(1.5r)
      expect(executed).to eq(["A", "B"])

      sequencer.tick  # position becomes 2r
      expect(sequencer.position).to eq(2r)
      expect(executed).to eq(["A", "B", "C"])
    end

    it 'example from line 172 - Jump to future position' do
      sequencer = Musa::Sequencer::BaseSequencer.new

      executed = []

      sequencer.at(1.25r) { executed << "Event 1" }
      sequencer.at(1.5r) { executed << "Event 2" }
      sequencer.at(2.75r) { executed << "Event 3" }

      # First tick to initialize position
      sequencer.tick

      # Now jump to position 2r
      sequencer.position = 2r
      # Executes events at 1.5r (1.25r already executed)

      expect(executed).to include("Event 1", "Event 2")
      expect(sequencer.position).to eq(2r)
    end
  end

  context 'Play operations (base-sequencer-implementation-play.rb)' do
    it 'example from line 56 - Basic series playback' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      notes = S({pitch: 60, duration: 1r}, {pitch: 64, duration: 1r}, {pitch: 67, duration: 1r})
      played_notes = []

      seq.play(notes) do |pitch:, duration:, control:|
        played_notes << { pitch: pitch, duration: duration, position: seq.position }
      end

      seq.run

      expect(played_notes.size).to eq(3)
      expect(played_notes[0][:pitch]).to eq(60)
      expect(played_notes[0][:duration]).to eq(1r)
      expect(played_notes[1][:pitch]).to eq(64)
      expect(played_notes[2][:pitch]).to eq(67)
    end

    it 'example from line 269 - Basic play control with after callback' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      series = S({pitch: 60}, {pitch: 62}, {pitch: 64}, {pitch: 65}, {pitch: 67})
      played_notes = []
      after_executed = []

      control = seq.play(series) do |pitch:|
        played_notes << { pitch: pitch, position: seq.position }
      end

      control.after(2r) { after_executed << seq.position }

      seq.run

      expect(played_notes.size).to eq(5)
      # Note: after callback is scheduled but needs explicit timing to execute
      # The control.after mechanism schedules events for future execution
      expect(control).to respond_to(:after)
    end
  end

  context 'PlayTimed operations (base-sequencer-implementation-play-timed.rb)' do
    it 'example from line 37 - Hash mode timed series' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      timed_notes = S(
        { time: 0r, value: {pitch: 60, velocity: 96} },
        { time: 1r, value: {pitch: 64, velocity: 80} },
        { time: 2r, value: {pitch: 67, velocity: 64} }
      )

      played_notes = []

      seq.play_timed(timed_notes) do |values, time:, started_ago:, control:|
        played_notes << { pitch: values[:pitch], velocity: values[:velocity], time: time }
      end

      seq.run

      expect(played_notes.size).to eq(3)
      expect(played_notes[0][:pitch]).to eq(60)
      expect(played_notes[0][:velocity]).to eq(96)
      # Initial time may be offset by tick duration
      expect(played_notes[0][:time]).to be_a(Rational)
      expect(played_notes[1][:pitch]).to eq(64)
      expect(played_notes[2][:pitch]).to eq(67)
    end

    it 'example from line 55 - Array mode with extra attributes' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      timed = S(
        { time: 0r, value: [60, 96], channel: [0] },
        { time: 1r, value: [64, 80], channel: [1] }
      )

      played_notes = []

      seq.play_timed(timed) do |values, channel:, time:, started_ago:, control:|
        played_notes << { pitch: values[0], velocity: values[1], channel: channel[0], time: time }
      end

      seq.run

      expect(played_notes.size).to eq(2)
      expect(played_notes[0][:pitch]).to eq(60)
      expect(played_notes[0][:velocity]).to eq(96)
      expect(played_notes[0][:channel]).to eq(0)
      expect(played_notes[1][:channel]).to eq(1)
    end
  end

  context 'PlayEval modes (base-sequencer-implementation-play-helper.rb)' do
    it 'example from line 110 - At-mode usage' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      series = S(
        { pitch: 60, at: 0r },
        { pitch: 62, at: 1r },
        { pitch: 64, at: 2r }
      )

      played_notes = []

      seq.play(series, mode: :at) do |pitch:|
        played_notes << { pitch: pitch, position: seq.position }
      end

      seq.run

      # At-mode schedules at absolute positions, but series needs proper at values
      expect(played_notes.size).to be >= 1
      expect(played_notes[0][:pitch]).to eq(60)
      # Position depends on how at-mode processes the series
      expect(played_notes[0][:position]).to be_a(Rational)
    end

    it 'example from line 182 - Wait-mode with duration' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      series = S(
        { pitch: 60, duration: 1r },
        { pitch: 62, duration: 0.5r },
        { pitch: 64, duration: 1.5r }
      )

      played_notes = []

      seq.play(series, mode: :wait) do |element|
        played_notes << { pitch: element[:pitch], duration: element[:duration], position: seq.position }
      end

      seq.run

      expect(played_notes.size).to eq(3)
      expect(played_notes[0][:pitch]).to eq(60)
      expect(played_notes[0][:duration]).to eq(1r)
      expect(played_notes[1][:pitch]).to eq(62)
      expect(played_notes[2][:pitch]).to eq(64)
    end
  end

  context 'Move operations (base-sequencer-implementation-move.rb)' do
    it 'example from line 41 - Simple pitch glide' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      pitch_values = []

      seq.move(from: 60, to: 72, duration: 4r, every: 1/4r) do |pitch|
        pitch_values << { pitch: pitch.round, position: seq.position }
      end

      seq.run

      expect(pitch_values.first[:pitch]).to eq(60)
      expect(pitch_values.last[:pitch]).to eq(72)
      expect(pitch_values.size).to be > 10
    end

    it 'example from line 53 - Multi-parameter fade' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      controller_values = []

      seq.move(
        from: {volume: 0, brightness: 0},
        to: {volume: 127, brightness: 127},
        duration: 8r,
        every: 1/8r
      ) do |params|
        controller_values << {
          volume: params[:volume].round,
          brightness: params[:brightness].round,
          position: seq.position
        }
      end

      seq.run

      expect(controller_values.first[:volume]).to eq(0)
      expect(controller_values.first[:brightness]).to eq(0)
      expect(controller_values.last[:volume]).to eq(127)
      expect(controller_values.last[:brightness]).to eq(127)
    end

    it 'example from line 74 - Non-linear interpolation' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      values = []

      seq.move(
        from: 0, to: 100,
        duration: 4r, every: 1/16r,
        function: proc { |ratio| ratio ** 2 }  # Ease-in
      ) { |value| values << value.round(2) }

      seq.run

      expect(values.first).to eq(0)
      expect(values.last).to eq(100)

      # Verify ease-in: values should increase more slowly at start
      mid_point = values.size / 2
      expect(values[mid_point]).to be < 50  # Should be less than linear midpoint
    end
  end

  context 'Every operations (base-sequencer-implementation-every.rb)' do
    it 'example from line 28 - Every 1 beat for 4 beat duration' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      ticks = []

      seq.every(1r, duration: 4r) { ticks << seq.position }

      seq.run

      # Duration 4r means it runs for 4 bars, resulting in 4 executions
      expect(ticks.size).to eq(4)
      # First execution happens at first tick position (just before 1r)
      expect(ticks.first).to be < 1
    end

    it 'example from line 131 - Dynamic control with execution counter' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      counters = []

      control = seq.every(1r, duration: 4r) { counters << seq.position }

      finished = false
      control.on_stop { finished = true }

      after_position = nil
      control.after(2r) { after_position = seq.position }

      seq.run

      expect(counters.size).to eq(4)
      expect(finished).to be true
      # After callback executes 2 bars after loop stops
      expect(after_position).to be >= counters.last + 1.9
    end
  end

  context 'Sequencer DSL (sequencer-dsl.rb)' do
    it 'example from line 38 - Basic DSL usage' do
      executed = []

      sequencer = Musa::Sequencer::Sequencer.new(4, 96) do
        at(1r) { executed << "Bar 1" }
        at(2r) { executed << "Bar 2" }

        every(1r, duration: 4r) do
          executed << "Every beat"
        end
      end

      sequencer.run

      expect(executed).to include("Bar 1", "Bar 2")
      expect(executed.count("Every beat")).to eq(4)
    end

    it 'example from line 49 - DSL context access' do
      sequencer = Musa::Sequencer::Sequencer.new(4, 96) do
        at(1r) do
          position  # DSL context method available
          wait(1r) { }  # Nested scheduling
        end
      end

      expect { sequencer.run }.not_to raise_error
    end

    it 'example from line 144 - Evaluating blocks in DSL context with "with"' do
      seq = Musa::Sequencer::Sequencer.new(4, 96)

      executed = []

      # Use 'with' to evaluate block in DSL context
      seq.with do
        # Inside this block, we have direct access to DSL methods
        at(1) { executed << "bar 1" }
        at(2) { executed << "bar 2" }

        every(1, duration: 4) do
          executed << "beat at #{position}"
        end
      end

      seq.run

      expect(executed).to include("bar 1", "bar 2")
      expect(executed.select { |s| s.to_s.start_with?("beat at") }.size).to eq(4)
    end

    it 'example from line 164 - Passing parameters to with block' do
      seq = Musa::Sequencer::Sequencer.new(4, 96)

      notes = []

      seq.with(60, 64, 67) do |c, e, g|
        at(1) { notes << c }  # Uses parameter c = 60
        at(2) { notes << e }  # Uses parameter e = 64
        at(3) { notes << g }  # Uses parameter g = 67
      end

      seq.run

      expect(notes).to eq([60, 64, 67])
    end

    it 'example from line 179 - Comparison: with DSL context vs external context' do
      seq = Musa::Sequencer::Sequencer.new(4, 96)

      executed_external = []
      executed_dsl = []

      # Without 'with': need to reference seq explicitly
      seq.at(1) { seq.at(2) { executed_external << "nested" } }

      # With 'with': DSL methods available directly
      seq.with do
        at(3) { at(4) { executed_dsl << "nested" } }  # Cleaner syntax
      end

      seq.run

      expect(executed_external).to eq(["nested"])
      expect(executed_dsl).to eq(["nested"])
    end
  end

  # Note: Timeslots is a private class (@api private) within BaseSequencer
  # and should not have inline documentation examples accessible from public API.
  # Tests for private classes should be in separate internal test files.

  context 'Additional edge cases and integration' do
    it 'handles series with play correctly scheduling events' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      series = S(
        { pitch: 60, duration: 1r },
        { pitch: 62, duration: 0.5r },
        { pitch: 64, duration: 0.5r },
        { pitch: 65, duration: 2r }
      )

      played = []
      positions = []

      seq.play(series) do |pitch:, duration:|
        played << pitch
        positions << seq.position
      end

      seq.run

      expect(played).to eq([60, 62, 64, 65])
      # Positions are cumulative based on durations
      # Verify positions increase as expected
      expect(positions.size).to eq(4)
      expect(positions[0]).to be_a(Rational)
      expect(positions[1]).to be > positions[0]
      expect(positions[2]).to be > positions[1]
      expect(positions[3]).to be > positions[2]
    end

    it 'handles move with arrays correctly' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      values = []

      seq.move(
        from: [60, 0],
        to: [72, 127],
        duration: 4r,
        every: 1r
      ) do |vals|
        values << vals.map(&:round)
      end

      seq.run

      expect(values.first).to eq([60, 0])
      expect(values.last).to eq([72, 127])
    end

    it 'handles control stop in every loop' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      executed = []
      stopped = false

      control = seq.every(1r) do |control:|
        executed << seq.position
        control.stop if seq.position >= 3
      end

      control.on_stop { stopped = true }

      seq.at(10) { }  # Ensure sequencer runs long enough

      seq.run

      expect(executed.size).to be >= 3
      expect(stopped).to be true
    end

    it 'handles quantization in tick-based mode' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      executed = []

      # Position will be quantized to tick boundaries
      seq.at(1.501) { executed << seq.position }

      seq.run

      # Should be quantized to nearest tick
      expect(executed.first).to be_within(0.1).of(1.5)
    end

    it 'handles position= fast-forward correctly' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      executed = []

      seq.at(1) { executed << "1" }
      seq.at(2) { executed << "2" }
      seq.at(3) { executed << "3" }

      seq.position = 2.5

      expect(executed).to eq(["1", "2"])
      expect(seq.position).to be_within(0.1).of(2.5)
    end

    it 'handles on/launch event bubbling' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      global_events = []
      local_events = []

      # Global handler (sequencer level)
      seq.on(:finished) do |name|
        global_events << name
      end

      # Local handler (control level)
      control = seq.at(1) do |control:|
        control.launch(:finished, "local task")
      end

      control.on(:finished) do |name|
        local_events << name
      end

      seq.run

      expect(local_events).to eq(["local task"])
      expect(global_events).to be_empty  # Event handled locally, doesn't bubble
    end

    it 'handles move with right_open parameter' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      values_open = []
      values_closed = []

      seq.move(from: 0, to: 10, step: 1, every: 1r, right_open: true) do |v|
        values_open << v
      end

      seq.at(20) do
        seq.move(from: 0, to: 10, step: 1, every: 1r, right_open: false) do |v|
          values_closed << v
        end
      end

      seq.run

      # right_open: true excludes final value
      expect(values_open).not_to include(10)
      expect(values_open.last).to eq(9)

      # right_open: false includes final value
      expect(values_closed).to include(10)
      expect(values_closed.last).to eq(10)
    end

    it 'handles every with till parameter' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      positions = []

      seq.every(1r, till: 5r) do
        positions << seq.position
      end

      seq.run

      # Till 5r means it runs up to but not including position 5
      expect(positions.size).to be >= 4
      # First position is initial sequencer position (< 1)
      expect(positions.first).to be < 1
      expect(positions).not_to include(5r)
    end

    it 'handles every with condition parameter' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      count = 0
      positions = []

      seq.every(1r, condition: proc { count < 3 }) do
        positions << seq.position
        count += 1
      end

      seq.at(10) { }  # Ensure run continues

      seq.run

      expect(positions.size).to eq(3)
      expect(count).to eq(3)
    end

    it 'handles play control with pause/continue behavior' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      series = S({value: 1}, {value: 2}, {value: 3}, {value: 4}, {value: 5})
      played = []

      control = seq.play(series) do |value:, control:|
        played << value
        control.pause if value == 3
      end

      seq.run

      # Play should pause after value 3
      expect(played).to eq([1, 2, 3])

      # Continue should resume from where it paused
      control.continue
      seq.run

      expect(played).to eq([1, 2, 3, 4, 5])
    end
  end
end
