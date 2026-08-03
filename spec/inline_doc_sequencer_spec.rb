require 'spec_helper'
require 'musa-dsl'

RSpec.describe 'Sequencer Inline Documentation Examples' do
  include Musa::All

  context 'BaseSequencer (base-sequencer.rb)' do

    it '@example Tickless sequencer' do
      seq = Musa::Sequencer::BaseSequencer.new  # Tickless mode

      executed = []

      seq.at(1) { executed << "Position 1" }
      seq.at(1.5) { executed << "Position 1.5" }

      seq.tick    # Jumps to position 1
      expect(executed).to eq(["Position 1"])

      seq.tick  # Jumps to position 1.5
      expect(executed).to eq(["Position 1", "Position 1.5"])
    end

    it '@example Playing series' do
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

    it '@example Resetting sequencer state' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      # Schedule some events
      seq.at(1) { }
      seq.at(2) { }
      seq.every(1, till: 8) { }

      # Two `at` and the first pulse of the `every`.
      expect(seq.size).to eq(3)
      expect(seq.empty?).to be false

      # Reset clears everything
      seq.reset

      expect(seq.size).to eq(0)
      expect(seq.empty?).to be true
      # Position after reset is before first tick (1 - tick_duration)
      expect(seq.position).to be < 1
    end

    it 'Linear fade with move' do
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

    it '@example Advancing time with tick' do
      sequencer = Musa::Sequencer::BaseSequencer.new(4, 96)

      initial_position = sequencer.position

      sequencer.tick  # Advance one tick (1/384 of a bar)

      expect(sequencer.position).to eq(initial_position + 1/384r)
    end

  end

  context 'TicklessBasedTiming (base-sequencer-tickless-based.rb)' do
    it '@example Creating tickless sequencer' do
      sequencer = Musa::Sequencer::BaseSequencer.new  # No tick parameters

      expect(sequencer.ticks_per_bar).to eq(Float::INFINITY)
      expect(sequencer.tick_duration).to eq(0r)
      expect(sequencer.position).to be_nil  # before first event
    end

    it '@example Complex polyrhythm (5 against 7)' do
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

    it '@example Event-driven progression' do
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

  end

  context 'Play operations (base-sequencer-implementation-play.rb)' do
    it 'Basic series playback' do
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

    it '@example Basic play control' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      # Each element carries its own duration: that is what makes play walk time.
      series = S({ pitch: 60, duration: 1r }, { pitch: 62, duration: 1r },
                 { pitch: 64, duration: 1r }, { pitch: 65, duration: 1r },
                 { pitch: 67, duration: 1r })
      played_notes = []
      after_executed = []
      stopped_at = []

      control = seq.play(series) do |pitch:, duration:|
        played_notes << { pitch: pitch, position: seq.position }
      end

      control.on_stop { stopped_at << seq.position }
      control.after(2r) { after_executed << seq.position }

      seq.run

      # One note per bar, from the position before bar 1 onwards.
      expect(played_notes.collect { |n| n[:pitch] }).to eq([60, 62, 64, 65, 67])
      expect(played_notes.collect { |n| n[:position] })
        .to eq([95/96r, 191/96r, 287/96r, 383/96r, 479/96r])

      # The play ends one bar after its last note, and `after` fires two bars later.
      expect(stopped_at).to eq([575/96r])
      expect(after_executed).to eq([767/96r])
    end

    it 'completes its control even when the whole serie resolves in one instant' do
      # Elements with no :duration all fire in the same instant, so the serie
      # unwinds inside the `play` call and the control reaches the caller
      # already over. `on_stop` and `after` used to be registered on it a moment
      # too late and never ran at all -- and `after` is the documented way to
      # chain sections, so the chain stopped silently (issue #84).
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      fired = []
      stopped = []
      afters = []

      control = seq.play(S({ pitch: 60 }, { pitch: 62 })) { |pitch:| fired << seq.position }
      control.on_stop { stopped << seq.position }
      control.after(2r) { afters << seq.position }

      400.times { seq.tick }

      expect(fired).to eq([95/96r, 95/96r])
      expect(stopped).to eq([95/96r])
      expect(afters).to eq([95/96r + 2r])
    end

    it 'chains a section after a chord written as a serie' do
      # A chord voiced note by note is a serie of `forward_duration: 0`
      # elements, which is what AbsD documents that key for, and the whole serie
      # then resolves in one instant.
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)
      log = []

      chord = S(*[60, 64, 67].collect { |p| { pitch: p, duration: 2r, forward_duration: 0r } })

      seq.at(1) do
        seq.play(chord) { |pitch:, **| log << [:note, pitch] }
           .after(2r) { log << [:next_section, seq.position] }
      end

      600.times { seq.tick }

      expect(log).to eq([[:note, 60], [:note, 64], [:note, 67], [:next_section, 3r]])
    end
  end

  context 'PlayEval modes (base-sequencer-implementation-play-helper.rb)' do

    it ':at mode plays each element where the element says, not where its predecessor did' do
      # This used to be off by one: the :at travelled in the continuation, which
      # is when the NEXT element is fetched, so these three sounded at 95/96r,
      # 1r and 5r (issue #82).
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      played_notes = []

      seq.play(S({ pitch: 60, at: 1r }, { pitch: 62, at: 5r }, { pitch: 64, at: 9r }),
               mode: :at) do |pitch:|
        played_notes << { pitch: pitch, position: seq.position }
      end

      1200.times { seq.tick }

      expect(played_notes).to eq([{ pitch: 60, position: 1r },
                                  { pitch: 62, position: 5r },
                                  { pitch: 64, position: 9r }])
    end

  end

  context 'Every operations (base-sequencer-implementation-every.rb)' do
    it 'Every 1 beat for 4 beat duration' do
      seq = Musa::Sequencer::BaseSequencer.new(4, 24)

      ticks = []

      seq.every(1r, duration: 4r) { ticks << seq.position }

      seq.run

      # Duration 4r means it runs for 4 bars, resulting in 4 executions
      expect(ticks.size).to eq(4)
      # First execution happens at first tick position (just before 1r)
      expect(ticks.first).to be < 1
    end

  end

  context 'Sequencer DSL (sequencer-dsl.rb)' do

    it '@example Comparison: with DSL context vs external context' do
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
