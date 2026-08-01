require 'spec_helper'
require 'musa-dsl'

RSpec.describe Musa::Sequencer do
  context 'Basic sequencing' do
    include Musa::Series

    it 'Basic at sequencing' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      c = 0

      s.at 1 do
        c += 1
      end

      s.at 2 do
        c += 1
      end

      expect(c).to eq(0)

      s.tick

      expect(c).to eq(1)

      s.tick

      expect(c).to eq(1)

      14.times do
        s.tick
      end

      expect(c).to eq(1)

      s.tick

      expect(c).to eq(2)

      s.tick

      expect(c).to eq(2)
    end

    it 'At sequencing with events' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      c = 0
      d = 0

      handler = s.at 1 do |control:|
        c += 1
        control.launch :evento, 100
      end

      handler.on :evento do |param|
        d = param
      end

      expect(c).to eq(0)
      expect(d).to eq(0)

      s.tick

      expect(c).to eq(1)
      expect(d).to eq(100)

      15.times do
        s.tick
      end

      expect(c).to eq(1)
      expect(d).to eq(100)
    end

    it 'At sequencing with events (indented 1)' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      c = 0
      d = 0

      handler = s.at 1 do
        s.at 2 do |control:|
          c += 1
          control.launch :evento, 100
        end
      end

      handler.on :evento do |param|
        d = param
      end

      expect(c).to eq(0)
      expect(d).to eq(0)

      s.tick

      expect(c).to eq(0)
      expect(d).to eq(0)

      16.times do
        s.tick
      end

      expect(c).to eq(1)
      expect(d).to eq(100)

      16.times do
        s.tick
      end

      expect(c).to eq(1)
      expect(d).to eq(100)
    end

    it 'At sequencing with events (indented 2)' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      c = 0
      d = 0
      e = 0

      handler = s.at 1 do
        handler2 = s.at 2 do |control:|
          c += 1
          control.launch :evento, 100
        end
        handler2.on :evento do |param|
          d = param
        end
      end

      handler.on :evento do |param|
        e = param
      end

      expect(c).to eq(0)
      expect(d).to eq(0)
      expect(e).to eq(0)

      s.tick

      expect(c).to eq(0)
      expect(d).to eq(0)
      expect(e).to eq(0)

      16.times do
        s.tick
      end

      expect(c).to eq(1)
      expect(d).to eq(100)
      expect(e).to eq(0)

      16.times do
        s.tick
      end

      expect(c).to eq(1)
      expect(d).to eq(100)
      expect(e).to eq(0)
    end

    it 'Basic every sequencing with nil every (should be like an at)' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      c = 0

      s.at 1 do
        s.every nil do
          c += 1
        end
      end

      expect(c).to eq(0)

      s.tick

      expect(c).to eq(1)

      s.tick

      expect(c).to eq(1)

      14.times do
        s.tick
      end

      expect(c).to eq(1)

      s.tick

      expect(c).to eq(1)

      s.tick

      expect(c).to eq(1)

      15.times do
        s.tick
      end

      expect(c).to eq(1)
    end

    it 'Basic every sequencing' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      c = 0

      s.at 1 do
        s.every 1 do
          c += 1
        end
      end

      expect(c).to eq(0)

      s.tick

      expect(c).to eq(1)

      s.tick

      expect(c).to eq(1)

      14.times do
        s.tick
      end

      expect(c).to eq(1)

      s.tick

      expect(c).to eq(2)

      s.tick

      expect(c).to eq(2)

      15.times do
        s.tick
      end

      expect(c).to eq(3)
    end

    it 'Basic every sequencing with control condition' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      c = 0
      d = 0

      s.at 1 do
        control = s.every 1 do
          c += 1
        end

        control.condition do
          c < 3
        end
      end

      expect(c).to eq(0)

      s.tick

      expect(c).to eq(1)

      16.times { s.tick }

      expect(c).to eq(2)

      16.times { s.tick }

      expect(c).to eq(3)

      16.times { s.tick }

      expect(c).to eq(3)
    end

    it 'Bugfix: every sequencing with interval not on tick resolution' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      p = []

      s.at 1 do
        s.every 4/5r, duration: 4 do
          p << s.position
        end
      end

      s.run

      expect(p).to eq [1r, 29/16r, 21/8r, 27/8r, 67/16r, 5r]
    end

    it 'On every handler manual stop the after action is NOT called' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      p = []
      h = nil

      s.at 1 do
        h = s.every 1 do
          p << s.position
        end

        h.after do
          p << s.position
        end
      end

      s.at 3.5 do
        h.stop
      end

      s.at 4.5 do
        h.stop
      end

      s.run

      expect(p).to eq [1r, 2r, 3r]
    end

    it 'Basic play sequencing' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      serie = H value: FOR(from: 0, to: 3), duration: S(Rational(1, 16)).repeat

      c = -1
      d = 0

      p = s.play serie do |value:, control:|
        c = value
      end

      p.after do
        d += 1
      end

      expect(c).to eq(0)
      expect(d).to eq(0)

      s.tick
      expect(c).to eq(1)

      s.tick
      expect(c).to eq(2)

      s.tick
      expect(c).to eq(3)
      expect(d).to eq(0)

      s.tick
      expect(c).to eq(3)
      expect(d).to eq(1)
    end

    it 'Basic play sequencing (II)' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      serie = H value: FOR(from: 0, to: 3), duration: S(Rational(1, 16)).repeat

      c = -1
      d = 0

      p = s.play serie, after: proc { d = 1 } do |value:, control:|
        c = value
      end

      expect(c).to eq(0)
      expect(d).to eq(0)

      s.tick
      expect(c).to eq(1)

      s.tick
      expect(c).to eq(2)

      s.tick
      expect(c).to eq(3)
      expect(d).to eq(0)

      s.tick
      expect(c).to eq(3)
      expect(d).to eq(1)
    end

    it 'Play sequencing with events handled on at control' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      t = FOR(from: 0, to: 3)

      serie1 = H value: FOR(from: 0, to: 3), duration: S(Rational(1, 16)).repeat
      serie2 = H value: FOR(from: 0, to: 3), duration: S(Rational(1, 16)).repeat

      c = 0
      d = 0
      e = 0
      f = 0

      handler = s.at 1 do
        s.play serie1 do |value:, control:|
          c += 1
          if value == 3
            s.play serie2 do |value:, control:|
              d += 1
              control.launch :evento, 100 if value == 3
            end
          end
        end
      end

      handler.on :evento do |value|
        e = value
        f += 1
      end

      expect(c).to eq(0)
      expect(d).to eq(0)
      expect(e).to eq(0)
      expect(f).to eq(0)

      s.tick
      expect(c).to eq(1)
      expect(d).to eq(0)
      expect(e).to eq(0)
      expect(f).to eq(0)

      s.tick
      expect(c).to eq(2)
      expect(d).to eq(0)
      expect(e).to eq(0)
      expect(f).to eq(0)

      s.tick
      expect(c).to eq(3)
      expect(d).to eq(0)
      expect(e).to eq(0)
      expect(f).to eq(0)

      s.tick
      expect(c).to eq(4)
      expect(d).to eq(1)
      expect(e).to eq(0)
      expect(f).to eq(0)

      s.tick
      expect(c).to eq(4)
      expect(d).to eq(2)
      expect(e).to eq(0)
      expect(f).to eq(0)

      s.tick
      expect(c).to eq(4)
      expect(d).to eq(3)
      expect(e).to eq(0)
      expect(f).to eq(0)

      s.tick
      expect(c).to eq(4)
      expect(d).to eq(4)
      expect(e).to eq(100)
      expect(f).to eq(1)

      s.tick
      expect(c).to eq(4)
      expect(d).to eq(4)
      expect(e).to eq(100)
      expect(f).to eq(1)
    end

    it 'Play sequencing with events handled on sequencer' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      t = FOR(from: 0, to: 3)

      serie1 = H value: FOR(from: 0, to: 3), duration: S(Rational(1, 16)).repeat
      serie2 = H value: FOR(from: 0, to: 3), duration: S(Rational(1, 16)).repeat

      c = 0
      d = 0
      e = 0
      f = 0

      s.at 1 do
        s.play serie1 do |value:, control:|
          c += 1
          if value == 3
            s.play serie2 do |value:, control:|
              d += 1
              control.launch :evento, 100 if value == 3
            end
          end
        end
      end

      s.on :evento do |value|
        e = value
        f += 1
      end

      expect(c).to eq(0)
      expect(d).to eq(0)
      expect(e).to eq(0)
      expect(f).to eq(0)

      s.tick
      expect(c).to eq(1)
      expect(d).to eq(0)
      expect(e).to eq(0)
      expect(f).to eq(0)

      s.tick
      expect(c).to eq(2)
      expect(d).to eq(0)
      expect(e).to eq(0)
      expect(f).to eq(0)

      s.tick
      expect(c).to eq(3)
      expect(d).to eq(0)
      expect(e).to eq(0)
      expect(f).to eq(0)

      s.tick
      expect(c).to eq(4)
      expect(d).to eq(1)
      expect(e).to eq(0)
      expect(f).to eq(0)

      s.tick
      expect(c).to eq(4)
      expect(d).to eq(2)
      expect(e).to eq(0)
      expect(f).to eq(0)

      s.tick
      expect(c).to eq(4)
      expect(d).to eq(3)
      expect(e).to eq(0)
      expect(f).to eq(0)

      s.tick
      expect(c).to eq(4)
      expect(d).to eq(4)
      expect(e).to eq(100)
      expect(f).to eq(1)

      s.tick
      expect(c).to eq(4)
      expect(d).to eq(4)
      expect(e).to eq(100)
      expect(f).to eq(1)
    end

    it 'Play sequencing with events (II)' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      t = FOR(from: 0, to: 3)

      serie1 = H value: FOR(from: 0, to: 3), duration: S(Rational(1, 16)).repeat
      serie2 = H value: FOR(from: 0, to: 3), duration: S(Rational(1, 16)).repeat

      c = 0
      d = 0
      e = 0
      f = 0
      g = 0

      handler = s.at 1 do
        handler2 = s.play serie1 do |value:, control:|
          c += 1
          if value == 3
            s.play serie2 do |value:, control:|
              d += 1
              control.launch :evento, 100 if value == 3
            end
          end
        end

        handler2.on :evento do |value|
          e = value
          f += 1
        end
      end

      handler.on :evento do |value|
        g = value
      end

      expect(c).to eq(0)
      expect(d).to eq(0)
      expect(e).to eq(0)
      expect(f).to eq(0)
      expect(g).to eq(0)

      s.tick
      expect(c).to eq(1)
      expect(d).to eq(0)
      expect(e).to eq(0)
      expect(f).to eq(0)
      expect(g).to eq(0)

      s.tick
      expect(c).to eq(2)
      expect(d).to eq(0)
      expect(e).to eq(0)
      expect(f).to eq(0)
      expect(g).to eq(0)

      s.tick
      expect(c).to eq(3)
      expect(d).to eq(0)
      expect(e).to eq(0)
      expect(f).to eq(0)
      expect(g).to eq(0)

      s.tick
      expect(c).to eq(4)
      expect(d).to eq(1)
      expect(e).to eq(0)
      expect(f).to eq(0)
      expect(g).to eq(0)

      s.tick
      expect(c).to eq(4)
      expect(d).to eq(2)
      expect(e).to eq(0)
      expect(f).to eq(0)
      expect(g).to eq(0)

      s.tick
      expect(c).to eq(4)
      expect(d).to eq(3)
      expect(e).to eq(0)
      expect(f).to eq(0)
      expect(g).to eq(0)

      s.tick
      expect(c).to eq(4)
      expect(d).to eq(4)
      expect(e).to eq(100)
      expect(f).to eq(1)
      expect(g).to eq(0)

      s.tick
      expect(c).to eq(4)
      expect(d).to eq(4)
      expect(e).to eq(100)
      expect(f).to eq(1)
      expect(g).to eq(0)
    end

    it 'correct timing on d with forward_duration being different to duration' do
      serie = S({ value_a: 1, duration: 1 }, { value_b: 1, duration: 1 },
          { value_a: 1, duration: 1, forward_duration: 0 },
          { value_b: 1, duration: 1, forward_duration: 0 },
          { value_c: 1, duration: 1 },
          { value_d: 1, duration: 1 })

      s = Musa::Sequencer::BaseSequencer.new 4, 1

      a = b = c = d = 0

      s.at 1 do
        s.play serie do |value_a:, value_b:, value_c:, value_d:|
          a += value_a if value_a
          b += value_b if value_b
          c += value_c if value_c
          d += value_d if value_d
        end
      end

      expect([a, b, c, d]).to eq [0, 0, 0, 0]

      s.tick
      expect([a, b, c, d]).to eq [1, 0, 0, 0]
      3.times { s.tick }
      expect([a, b, c, d]).to eq [1, 0, 0, 0]
      s.tick
      expect([a, b, c, d]).to eq [1, 1, 0, 0]

      3.times { s.tick }
      expect([a, b, c, d]).to eq [1, 1, 0, 0]
      s.tick
      expect([a, b, c, d]).to eq [2, 2, 1, 0]
      4.times { s.tick }
      expect([a, b, c, d]).to eq [2, 2, 1, 1]
    end
  end

  # An event that carries only :forward_duration is an impulse: it has no
  # sounding length of its own and it does have a distance to the next one. It
  # used to be invisible to the wait-mode evaluator, which tested for :duration
  # alone, so a serie of them emptied itself into a single instant (issue #72).
  context 'A serie of pure forward durations' do
    include Musa::Series

    def positions_of(serie)
      sequencer = Musa::Sequencer::BaseSequencer.new(4, 24)
      positions = []

      sequencer.at 1 do
        sequencer.play(serie) { |**| positions << sequencer.position }
      end

      400.times { sequencer.tick }
      positions
    end

    let(:rhythm) { [1/4r, 3/8r, 1/8r] }

    it 'advances the serie exactly as the same rhythm written with durations' do
      only_forward = S(*rhythm.collect { |gap| { forward_duration: gap } })
      both = S(*rhythm.collect { |gap| { duration: gap, forward_duration: gap } })

      expect(positions_of(only_forward)).to eq([1r, 5/4r, 13/8r])
      expect(positions_of(only_forward)).to eq(positions_of(both))
    end

    it 'ends, so its after fires -- which a collapsed serie could not do' do
      sequencer = Musa::Sequencer::BaseSequencer.new(4, 24)
      ended = []

      sequencer.at 1 do
        sequencer.play(S(*rhythm.collect { |gap| { forward_duration: gap } })) { |**| }
                 .after { ended << sequencer.position }
      end

      400.times { sequencer.tick }

      # 1 + 1/4 + 3/8 + 1/8 = 1 + 3/4
      expect(ended).to eq([7/4r])
    end

    it 'is an AbsD, and its duration stays nil rather than borrowing the gap' do
      impulse = { forward_duration: 1/4r }

      expect(Musa::Datasets::AbsD.is_compatible?(impulse)).to be true

      dataset = Musa::Datasets::AbsD.to_AbsD(impulse)
      expect(dataset.forward_duration).to eq(1/4r)
      expect(dataset.duration).to be_nil
      expect(dataset.note_duration).to be_nil
    end

    it 'an element with no duration at all still means "at the same time"' do
      expect(Musa::Datasets::AbsD.is_compatible?({ pitch: 60 })).to be false
      expect(positions_of(S({ pitch: 60 }, { pitch: 62 }))).to eq([1r, 1r])
    end
  end
end
