require 'spec_helper'

require 'musa-dsl'
require 'pp'

include Musa::Series

module Test
  @c = nil
  def self.c=(value)
    @c = value
  end

  def self.c
    @c
  end
end

RSpec.describe Musa::Sequencer do
  context 'DSL Sequencing' do

    it 'Basic configuration and querying' do
      c = 0

      s = Musa::Sequencer.new 4, 4 do
        at 1 do
          every 1 do
            c += 1
          end
        end
      end

      expect(s.beats_per_bar).to eq(4)
      expect(s.ticks_per_beat).to eq(4)
      expect(s.ticks_per_bar).to eq(16)
    end

    it 'Basic at sequencing' do
      c = 0

      s = Musa::Sequencer.new 4, 4 do
        at 1 do
          every 1 do
            c += 1
          end
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

    it 'Basic wait sequencing with a serie' do
      c = 0
      w = S(1, 1, 1)
      s = Musa::Sequencer.new 4, 4 do
        at 1 do
          wait w do
            c += 1
          end
        end
      end

      expect(c).to eq(0)

      s.tick

      expect(c).to eq(0)

      15.times do
        s.tick
      end

      expect(c).to eq(0)

      s.tick

      expect(c).to eq(1)

      s.tick

      expect(c).to eq(1)

      15.times do
        s.tick
      end

      expect(c).to eq(2)

      15.times do
        s.tick
      end

      expect(c).to eq(2)

      s.tick

      expect(c).to eq(3)

      15.times do
        s.tick
      end

      expect(c).to eq(3)

      s.tick

      expect(c).to eq(3)

      30.times do
        s.tick
      end

      expect(c).to eq(3)
    end

    it 'Basic wait sequencing with a serie and a with: serie parameter' do
      w = S(1, 1, 1)
      p = S(10, 20, 30, 40)

      c = 0
      pp = nil

      s = Musa::Sequencer.new 4, 4 do
        at 1 do
          wait w, with: p do |with|
            c += 1
            pp = with
          end
        end
      end

      expect(c).to eq(0)
      expect(pp).to eq(nil)

      s.tick

      expect(c).to eq(0)
      expect(pp).to eq(nil)

      15.times do
        s.tick
      end

      expect(c).to eq(0)
      expect(pp).to eq(nil)

      s.tick

      expect(c).to eq(1)
      expect(pp).to eq(10)

      s.tick

      expect(c).to eq(1)
      expect(pp).to eq(10)

      15.times do
        s.tick
      end

      expect(c).to eq(2)
      expect(pp).to eq(20)

      15.times do
        s.tick
      end

      expect(c).to eq(2)
      expect(pp).to eq(20)

      s.tick

      expect(c).to eq(3)
      expect(pp).to eq(30)

      15.times do
        s.tick
      end

      expect(c).to eq(3)
      expect(pp).to eq(30)

      s.tick

      expect(c).to eq(3)
      expect(pp).to eq(30)

      30.times do
        s.tick
      end

      expect(c).to eq(3)
      expect(pp).to eq(30)
    end

    it 'Basic every sequencing with control' do
      c = 0
      d = 0

      every_control = nil

      s = Musa::Sequencer.new 4, 4 do
        at 1 do
          every_control = every 1 do |control:|
            c += 1

            if c == 2
              control.after do
                d = 1
              end
            end

            control.stop if c == 3
          end
        end
      end

      expect(c).to eq(0)
      expect(s.everying.size).to eq 0

      s.tick

      expect(c).to eq(1)
      expect(s.everying).to include(every_control)

      s.tick

      expect(c).to eq(1)
      expect(s.everying).to include(every_control)

      14.times do
        s.tick
      end

      expect(c).to eq(1)
      expect(s.everying).to include(every_control)

      s.tick

      expect(c).to eq(2)
      expect(s.everying).to include(every_control)

      s.tick

      expect(c).to eq(2)
      expect(s.everying).to include(every_control)

      15.times do
        s.tick
      end

      expect(c).to eq(3)
      expect(d).to eq(0)
      expect(s.everying).to include(every_control)

      s.tick

      expect(c).to eq(3)
      expect(d).to eq(0)
      expect(s.everying).to include(every_control)

      15.times do
        s.tick
      end

      expect(c).to eq(3)
      expect(d).to eq(1)
      expect(s.everying.size).to eq 0
    end

    it 'Basic move sequencing' do

      c = 0
      move_control = nil

      s = Musa::Sequencer.new 4, 4 do
        at 1 do
          move_control = move every: 1/16r, from: 1, to: 5, duration: 4 + Rational(1, 16) do |value|
            c = value
          end
        end
      end

      expect(c).to eq(0)
      expect(s.moving.size).to eq 0

      s.tick

      expect(c).to eq(1)
      expect(s.moving).to include move_control

      s.tick

      expect(c).to eq(1 + Rational(1, 16))
      expect(s.moving).to include move_control

      14.times do
        s.tick
      end

      expect(c).to eq(1 + Rational(15, 16))
      expect(s.moving).to include move_control

      s.tick

      expect(c).to eq(Rational(2))
      expect(s.moving).to include move_control

      s.tick

      15.times do
        s.tick
      end

      expect(c).to eq(Rational(3))
      expect(s.moving).to include move_control

      (16 * 2).times do
        s.tick
      end

      expect(c).to eq(Rational(5))
      expect(s.moving).to include move_control

      s.tick

      expect(c).to eq(Rational(5))
      expect(s.moving.size).to eq 0
    end

    it 'Basic play sequencing' do
      serie = H value: FOR(from: 0, to: 3), duration: S(Rational(1, 16)).repeat

      c = -1
      d = 0

      play_control = nil

      s = Musa::Sequencer.new 4, 4

      expect(s.playing.size).to eq 0

      s.with do
        play_control = play serie do |element, control:|
          c = element[:value]

          control.after do # this will be executed 4 times
            d += 1
          end
        end
      end

      expect(c).to eq(0)
      expect(d).to eq(0)
      expect(s.playing).to include(play_control)

      s.tick
      expect(c).to eq(1)
      expect(s.playing).to include(play_control)

      s.tick
      expect(c).to eq(2)
      expect(s.playing).to include(play_control)

      s.tick
      expect(c).to eq(3)
      expect(d).to eq(0)
      expect(s.playing).to include(play_control)

      s.tick
      expect(c).to eq(3)
      expect(d).to eq(4)
      expect(s.playing.size).to eq 0
    end

    it 'Play sequencing with event syncing' do
      serie = H value: FOR(from: 0, to: 3), duration: S(Rational(1, 16)).repeat

      serie += S(wait_event: :event_to_wait)

      serie += H value: FOR(from: 4, to: 7), duration: S(Rational(1, 16)).repeat

      c = 0
      d = 0
      inner_control = nil
      cat = cplay = nil

      s = Musa::Sequencer.new 4, 4 do
        cat = at 1 do
          play serie do |element, control:|
            inner_control = control
            c = element[:value] if element[:value]
          end
        end
      end

      s.tick
      expect(c).to eq(0)
      expect(d).to eq(0)

      s.tick
      expect(c).to eq(1)
      expect(d).to eq(0)

      s.tick
      expect(c).to eq(2)
      expect(d).to eq(0)

      s.tick
      expect(c).to eq(3)
      expect(d).to eq(0)

      s.tick
      expect(c).to eq(3)
      expect(d).to eq(0)

      16.times { s.tick }

      s.tick
      expect(c).to eq(3)
      expect(d).to eq(0)

      s.now do
        inner_control.launch :event_to_wait
      end

      expect(c).to eq(4)
      expect(d).to eq(0)

      s.tick
      expect(c).to eq(5)
      expect(d).to eq(0)

      s.tick
      expect(c).to eq(6)
      expect(d).to eq(0)

      s.tick
      expect(c).to eq(7)
      expect(d).to eq(0)

      s.tick
      expect(c).to eq(7)
      expect(d).to eq(0)
    end

    it 'Play sequencing with event syncing (II)' do
      serie = H value: FOR(from: 0, to: 3), duration: S(Rational(1, 16)).repeat

      serie += S(wait_event: :event_to_wait)

      serie += H value: FOR(from: 4, to: 7), duration: S(Rational(1, 16)).repeat

      c = 0
      d = 0
      inner_control = nil
      cat = cplay = nil

      s = Musa::Sequencer.new 4, 4 do
        cat = at 1 do
          cplay = play serie do |element, control:|
            c = element[:value] if element[:value]
          end
        end
      end

      s.tick
      expect(c).to eq(0)
      expect(d).to eq(0)

      s.tick
      expect(c).to eq(1)
      expect(d).to eq(0)

      s.tick
      expect(c).to eq(2)
      expect(d).to eq(0)

      s.tick
      expect(c).to eq(3)
      expect(d).to eq(0)

      s.tick
      expect(c).to eq(3)
      expect(d).to eq(0)

      16.times { s.tick }

      s.tick
      expect(c).to eq(3)
      expect(d).to eq(0)

      s.now do
        cplay.launch :event_to_wait
      end

      expect(c).to eq(4)
      expect(d).to eq(0)

      s.tick
      expect(c).to eq(5)
      expect(d).to eq(0)

      s.tick
      expect(c).to eq(6)
      expect(d).to eq(0)

      s.tick
      expect(c).to eq(7)
      expect(d).to eq(0)

      s.tick
      expect(c).to eq(7)
      expect(d).to eq(0)
    end
  end

  context 'Advanced sequencing' do
    it 'Event passing on at' do
      s = Musa::Sequencer.new 4, 4

      c = 0
      d = 0

      control = s.at 1 do
        c += 1
        launch :event, 100
      end

      control.on :event do |param|
        d += param
      end

      expect(c).to eq(0)
      expect(d).to eq(0)

      s.tick
      expect(c).to eq(1)
      expect(d).to eq(100)

      s.tick
      expect(c).to eq(1)
      expect(d).to eq(100)
    end

    it 'Event passing on at with event listener on sequencer' do
      c = 0
      d = 0

      s = Musa::Sequencer.new 4, 4

      s.with do
        at 1 do
          c += 1
          now do
            launch :event, 100
          end
        end

        on :event do |param|
          d += param
        end
      end

      expect(c).to eq(0)
      expect(d).to eq(0)

      s.tick
      expect(c).to eq(1)
      expect(d).to eq(100)

      s.tick
      expect(c).to eq(1)
      expect(d).to eq(100)
    end

    it 'Event passing on at with inner at' do
      s = Musa::Sequencer.new 4, 4

      c = 0
      d = 0
      e = 0

      control2in = []

      control0 = s.at 1 do
        c += 1

        control1 = at 2 do
          launch :event, 100
        end

        control2 = at 2 do
          launch :event, 100
        end

        control2.on :event do |param|
          e += param
        end
      end

      control0.on :event do |param|
        d += param
      end

      expect(c).to eq(0)
      expect(d).to eq(0)
      expect(e).to eq(0)

      s.tick
      expect(c).to eq(1)
      expect(d).to eq(0)
      expect(d).to eq(0)

      95.times { s.tick }

      expect(c).to eq(1)
      expect(d).to eq(100)
      expect(e).to eq(100)

      s.tick
      expect(c).to eq(1)
      expect(d).to eq(100)
      expect(e).to eq(100)
    end

    it 'Play sequencing with handlers: consecutive at calls should be on the same handler; not create subhandlers' do
      s = Musa::Sequencer.new 4, 4

      ss = FOR(from: 1, to: 100).map { |i| { pitch: i, duration: 1/4r } }

      ids = []
      h = nil
      hid = nil

      s.with do
        h = play ss do |pd|
          ids << sequencer.event_handler.id
        end
        hid = h.id
      end

      s.tick while !s.empty?

      expect(hid).to eq(ids.last)
      expect(ids.size).to eq(100)
    end
  end
end
