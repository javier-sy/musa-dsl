require 'docs_helper'

using Musa::Extension::Neumas
using Musa::Extension::Matrix

RSpec.describe 'Sequencer Documentation Examples' do

  context 'Sequencer - Temporal Engine' do
    include Musa::All

    it 'demonstrates all sequencer DSL methods in a musical composition' do
      # Setup
      sequencer = Musa::Sequencer::Sequencer.new(4, 24)

      # Define series outside DSL block
      melody = S({ note: 60, duration: 1/2r }, { note: 62, duration: 1/2r },
                 { note: 64, duration: 1/2r }, { note: 65, duration: 1/2r },
                 { note: 67, duration: 1/2r }, { note: 65, duration: 1/2r },
                 { note: 64, duration: 1/2r }, { note: 62, duration: 1/2r })

      # Track events for verification
      section_changes = []
      at_events = []
      wait_events = []
      play_notes = []
      play_positions = []
      every_events = []
      stop_executed = false
      move_values = []
      move_hash_values = []

      # Program sequencer using DSL
      sequencer.with do
        # Custom event handlers (on/launch)
        on :section_change do |name|
          section_changes << name
        end

        # Immediate event (now)
        now do
          launch :section_change, "Start"
        end

        # Absolute positioning (at): event at bar 1
        at 1 do
          at_events << position
        end

        # Relative positioning (wait): event 2 bars later
        wait 2 do
          wait_events << position
        end

        # Play series (play): reproduces series with automatic timing
        at 5 do
          play melody do |note:, duration:, control:|
            play_notes << { note: note, duration: duration }
            play_positions << position
          end
        end

        # Recurring event (every) with stop control
        beat_loop = nil
        at 10 do
          # Store control object to stop it later
          beat_loop = every 2, duration: 10 do
            every_events << position
          end
        end

        # Stop the beat loop at bar 18
        at 18 do
          beat_loop.stop if beat_loop
          stop_executed = true
        end

        # Animated value (move) from 0 to 10 over 4 bars
        at 20 do
          move from: 0, to: 10, duration: 4, every: 1/2r do |value|
            move_values << value.round(2)
          end
        end

        # Multi-parameter animation (move with hash)
        at 25 do
          move from: { pitch: 60, vel: 60 },
               to: { pitch: 72, vel: 100 },
               duration: 2,
               every: 1/4r do |values|
            move_hash_values << { pitch: values[:pitch].round, vel: values[:vel].round }
          end
        end

        # Final event
        at 30 do
          launch :section_change, "End"
          at_events << position
        end
      end

      # Execute sequencer
      sequencer.run

      # Verify section changes (on/launch)
      expect(section_changes).to eq(['Start', 'End'])

      # Verify at: events at specific positions
      expect(at_events).to include(1, 30)

      # Verify wait: event 2 bars after last now/at
      expect(wait_events.size).to eq(1)
      expect(wait_events.first).to be_between(2.9, 3.1)  # Approximately 3

      # Verify play: series played with all notes and durations
      expect(play_notes.size).to eq(8)
      expect(play_notes.map { |n| n[:note] }).to eq([60, 62, 64, 65, 67, 65, 64, 62])
      expect(play_notes.all? { |n| n[:duration] == 1/2r }).to be true

      # Verify notes are played sequentially, not simultaneously
      expect(play_positions.uniq.size).to eq(8)  # All different positions
      expect(play_positions.first).to eq(5)  # Starts at position 5
      expect(play_positions.last).to eq(5 + 7 * 1/2r)  # Last note at 5 + 3.5 = 8.5

      # Verify every: recurring events every 2 bars
      # Should be [10, 12, 14, 16] - stopped at bar 18 before next event at 18
      expect(every_events).to eq([10, 12, 14, 16])

      # Verify stop was executed
      expect(stop_executed).to be true

      # Verify move: animated values from 0 to 10
      expect(move_values.size).to be > 0
      expect(move_values.first).to eq(0.0)
      expect(move_values.last).to eq(10.0)

      # Verify move with hash: multi-parameter animation
      expect(move_hash_values.size).to be > 0
      expect(move_hash_values.first[:pitch]).to eq(60)
      expect(move_hash_values.last[:pitch]).to eq(72)
    end
  end


end
