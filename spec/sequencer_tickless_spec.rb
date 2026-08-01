require 'spec_helper'

require 'musa-dsl'

RSpec.describe Musa::Sequencer do
  context 'Basic tickless sequencing' do
    include Musa::Series

    it 'Basic at sequencing' do
      s = Musa::Sequencer::BaseSequencer.new

      c = 0

      s.at 1 do
        c = 1
      end

      s.at 3 do
        c = 3
      end

      s.at 2 do
        c = 2
      end

      expect(c).to eq(0)
      expect(s.size).to eq 3
      expect(s.position).to eq nil

      s.tick

      expect(c).to eq(1)
      expect(s.size).to eq 2
      expect(s.position).to eq 1

      s.tick

      expect(c).to eq(2)
      expect(s.size).to eq 1
      expect(s.position).to eq 2

      s.tick

      expect(c).to eq(3)
      expect(s.size).to eq 0
      expect(s.position).to eq 3

      # Ticking an exhausted schedule does nothing at all. It used to put the
      # position back to nil -- the value that means "before the first event" --
      # so time ran backwards and the sequencer could not be moved again
      # (issue #76).
      s.tick

      expect(c).to eq(3)
      expect(s.size).to eq 0
      expect(s.position).to eq 3

      s.tick

      expect(c).to eq(3)
      expect(s.size).to eq 0
      expect(s.position).to eq 3
    end

    it 'Runs until finished' do
      s = Musa::Sequencer::BaseSequencer.new
      c = []

      s.at 1 do
        s.move from: 100, to: 101, duration: 4, step: 1 do |value|
          c << [s.position, value]
        end
      end

      s.run

      expect(c).to eq [[1, 100], [3, 101]]
    end

    it 'Move with duration but without time increment limitation should raise exception' do
      s = Musa::Sequencer::BaseSequencer.new
      c = []

      s.at 1 do
        expect do
          s.move from: 1, to: 2, duration: 4 do |value|
            c << value
          end
        end.to raise_error(ArgumentError)
      end

      s.run
    end
  end

  # In a tickless sequencer nil means two opposite things, and the code used to
  # compare it as if it were a position: `@position` is nil BEFORE the first
  # event, and `first_after` returns nil when there is nothing left AFTER the
  # last one. The beginning of time and the end of the schedule (issue #76).
  context 'Fast-forwarding a tickless sequencer' do
    def sequencer_with(*positions)
      sequencer = Musa::Sequencer::BaseSequencer.new
      fired = []

      positions.each { |position| sequencer.at(position) { fired << position } }

      [sequencer, fired]
    end

    it 'can be moved before it has ticked, which is when seeking is wanted' do
      sequencer, fired = sequencer_with(5/4r, 3/2r, 11/4r)

      expect(sequencer.position).to be_nil

      sequencer.position = 2r

      expect(fired).to eq([5/4r, 3/2r])
      expect(sequencer.position).to eq(2r)
    end

    it 'can be moved past the end of the schedule' do
      sequencer, fired = sequencer_with(1r, 2r)

      sequencer.position = 9r

      expect(fired).to eq([1r, 2r])
      expect(sequencer.position).to eq(9r)
    end

    it 'can be moved with nothing scheduled at all' do
      sequencer = Musa::Sequencer::BaseSequencer.new

      sequencer.position = 2r

      expect(sequencer.position).to eq(2r)
    end

    it 'switches fast-forward off again even when the jump runs out of events' do
      sequencer, = sequencer_with(1r)
      log = []
      sequencer.on_fast_forward { |entering| log << entering }

      sequencer.position = 9r

      # It used to be left switched on: the loop raised on the nil that means
      # "no more events", after the events had run and before the off call.
      expect(log).to eq([true, false])
    end

    it 'moves the position along with the events it runs on the way' do
      sequencer = Musa::Sequencer::BaseSequencer.new
      seen = []

      [5/4r, 3/2r].each { |position| sequencer.at(position) { seen << sequencer.position } }

      sequencer.position = 2r

      # Not the position the jump started from, and certainly not nil.
      expect(seen).to eq([5/4r, 3/2r])
    end

    it 'still refuses to move back' do
      sequencer, = sequencer_with(1r)
      sequencer.tick

      expect { sequencer.position = 1/2r }.to raise_error(ArgumentError, /cannot move back/)
    end
  end

  context 'Ticking a tickless sequencer past its last event' do
    it 'leaves the position where it was instead of resetting it to nil' do
      sequencer = Musa::Sequencer::BaseSequencer.new
      sequencer.at(1r) { }
      sequencer.at(2r) { }

      4.times { sequencer.tick }

      expect(sequencer.position).to eq(2r)

      # And having gone past the end does not make it unmovable again.
      expect { sequencer.position = 3r }.not_to raise_error
    end

    it 'does not call before_tick with a nil position' do
      sequencer = Musa::Sequencer::BaseSequencer.new
      positions = []
      sequencer.before_tick { |position| positions << position }
      sequencer.at(1r) { }

      3.times { sequencer.tick }

      expect(positions).to eq([1r])
    end
  end
end
