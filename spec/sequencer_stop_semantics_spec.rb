require 'spec_helper'
require 'musa-dsl'

RSpec.describe 'Sequencer on_stop/after semantics' do
  include Musa::Series

  context 'every' do
    it 'after does NOT fire on manual stop' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      after_called = false
      h = nil

      s.at 1 do
        h = s.every 1r do
          # loop body
        end

        h.after { after_called = true }
      end

      s.at 3 do
        h.stop
      end

      s.run

      expect(after_called).to be false
    end

    it 'after fires on natural termination (duration)' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      after_called = false

      s.at 1 do
        h = s.every 1r, duration: 2r do
          # loop body
        end

        h.after { after_called = true }
      end

      s.run

      expect(after_called).to be true
    end

    it 'on_stop fires on manual stop' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      on_stop_called = false
      h = nil

      s.at 1 do
        h = s.every 1r do
          # loop body
        end

        h.on_stop { on_stop_called = true }
      end

      s.at 3 do
        h.stop
      end

      s.run

      expect(on_stop_called).to be true
    end

    it 'on_stop fires on natural termination (duration)' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      on_stop_called = false

      s.at 1 do
        h = s.every 1r, duration: 2r do
          # loop body
        end

        h.on_stop { on_stop_called = true }
      end

      s.run

      expect(on_stop_called).to be true
    end
  end

  context 'play' do
    it 'after does NOT fire on manual stop' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      after_called = false
      h = nil

      serie = S({ value: 1, duration: 1 },
                { value: 2, duration: 1 },
                { value: 3, duration: 1 },
                { value: 4, duration: 1 },
                { value: 5, duration: 1 })

      s.at 1 do
        h = s.play serie do |value:, duration:|
          # play body
        end

        h.after { after_called = true }
      end

      s.at 2.5 do
        h.stop
      end

      s.run

      expect(after_called).to be false
    end

    it 'after fires on natural termination (series exhausted)' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      after_called = false

      serie = S({ value: 1, duration: 1 },
                { value: 2, duration: 1 })

      s.at 1 do
        h = s.play serie do |value:, duration:|
          # play body
        end

        h.after { after_called = true }
      end

      s.run

      expect(after_called).to be true
    end

    it 'on_stop fires on manual stop' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      on_stop_called = false
      h = nil

      serie = S({ value: 1, duration: 1 },
                { value: 2, duration: 1 },
                { value: 3, duration: 1 },
                { value: 4, duration: 1 },
                { value: 5, duration: 1 })

      s.at 1 do
        h = s.play serie do |value:, duration:|
          # play body
        end

        h.on_stop { on_stop_called = true }
      end

      s.at 2.5 do
        h.stop
      end

      s.run

      expect(on_stop_called).to be true
    end

    it 'on_stop fires on natural termination (series exhausted)' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      on_stop_called = false

      serie = S({ value: 1, duration: 1 },
                { value: 2, duration: 1 })

      s.at 1 do
        h = s.play serie do |value:, duration:|
          # play body
        end

        h.on_stop { on_stop_called = true }
      end

      s.run

      expect(on_stop_called).to be true
    end
  end

  context 'move' do
    it 'after does NOT fire on manual stop' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      after_called = false
      h = nil

      s.at 1 do
        h = s.move from: 0, to: 100, duration: 4r, every: 1r do |_value|
          # move body
        end

        h.after { after_called = true }
      end

      s.at 2.5 do
        h.stop
      end

      s.run

      expect(after_called).to be false
    end

    it 'after fires on natural termination (duration)' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      after_called = false

      s.at 1 do
        h = s.move from: 0, to: 100, duration: 2r, every: 1r do |_value|
          # move body
        end

        h.after { after_called = true }
      end

      s.run

      expect(after_called).to be true
    end

    it 'on_stop fires on manual stop' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      on_stop_called = false
      h = nil

      s.at 1 do
        h = s.move from: 0, to: 100, duration: 4r, every: 1r do |_value|
          # move body
        end

        h.on_stop { on_stop_called = true }
      end

      s.at 2.5 do
        h.stop
      end

      s.run

      expect(on_stop_called).to be true
    end

    it 'on_stop fires on natural termination (duration)' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      on_stop_called = false

      s.at 1 do
        h = s.move from: 0, to: 100, duration: 2r, every: 1r do |_value|
          # move body
        end

        h.on_stop { on_stop_called = true }
      end

      s.run

      expect(on_stop_called).to be true
    end
  end

  context 'integration' do
    it 'every self-relaunch with after does NOT relaunch on manual stop' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      launch_count = 0
      h = nil

      s.at 1 do
        h = s.every 1r do
          launch_count += 1
        end

        h.after do
          # This would relaunch if after fired on manual stop
          launch_count = 999
        end
      end

      s.at 3.5 do
        h.stop
      end

      s.run

      expect(launch_count).to be < 999
      expect(launch_count).to eq 3
    end

    it 'play on_stop: parameter fires on natural termination' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      on_stop_called = false

      serie = S({ value: 1, duration: 1 },
                { value: 2, duration: 1 })

      s.at 1 do
        s.play serie, on_stop: proc { on_stop_called = true } do |value:, duration:|
          # play body
        end
      end

      s.run

      expect(on_stop_called).to be true
    end
  end
end
