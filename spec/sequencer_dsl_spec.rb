require 'spec_helper'

require 'musa-dsl'
require 'pp'

RSpec.describe Musa::Sequencer do
  context 'DSL Sequencing' do
    include Musa::Series

    it 'Basic configuration and querying' do
      c = 0
      p = 0

      s = Musa::Sequencer::Sequencer.new 4, 4 do
        at 1 do
          every 1 do
            c += 1
          end
        end
      end

      s.before_tick do |new_position|
        p = new_position
      end

      expect(s.beats_per_bar).to eq(4)
      expect(s.ticks_per_beat).to eq(4)
      expect(s.ticks_per_bar).to eq(16)

      expect(p).to eq(0)

      s.tick

      expect(p).to eq(1r)

      s.tick

      expect(p).to eq(1 + 1/16r)

      s.tick

      expect(p).to eq(1 + 2/16r)
    end

    it 'Multithread position change while holding external ticks' do
      c = 0
      p = 0

      s = Musa::Sequencer::Sequencer.new 4, 4 do
        at 1 do
          every 1 do
            c += 1
          end
        end
      end

      s.before_tick do |new_position|
        p = new_position
      end

      expect(s.beats_per_bar).to eq(4)
      expect(s.ticks_per_beat).to eq(4)
      expect(s.ticks_per_bar).to eq(16)

      expect(p).to eq(0)

      s.tick

      expect(s.position).to eq(1)

      p1 = p2 = nil

      t1 = Thread.new do
        s.position = 200
        p1 = s.position
      end

      sleep(0.001) while s.position < 50

      t2 = Thread.new do
        100.times { s.tick; Thread.pass }
        p2 = s.position
      end

      sleep(0.1) while !p1 || !p2

      expect(p1).to eq(200r + Rational(100, 16))
      expect(p2).to be > 1r + Rational(100, 16)

    end

    it 'With works as yield (all inner _ passed)' do
      c = 0
      @d = 0

      s = Musa::Sequencer::Sequencer.new 4, 4 do |_|
        _.at 1 do |_|
          _.every 1 do |_|
            c += 1
            @d += 1
          end
        end
      end

      16.times do
        s.tick
      end

      expect(c).to eq 1
      expect(@d).to eq 1

      s.tick

      expect(c).to eq 2
      expect(@d).to eq 2
    end

    it 'With works as instance_eval' do
      c = 0
      @d = 0
      error = false

      s = Musa::Sequencer::Sequencer.new 4, 4, do_error_log: false do
        at 1 do
          every 1 do
            c += 1
            @d += 1
          end
        end
      end

      s.on_error do
        error = true
      end

      s.tick

      expect(error).to be true

      15.times do
        s.tick
      end

      expect(c).to eq 1
      expect(@d).to eq 0

      s.tick

      expect(c).to eq 2
      expect(@d).to eq 0
    end

    it 'Basic at sequencing' do
      c = 0

      s = Musa::Sequencer::Sequencer.new 4, 4 do
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
      s = Musa::Sequencer::Sequencer.new 4, 4 do
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

    it 'On every handler manual stop the after action is NOT called' do
      p = []
      h = nil

      s = Musa::Sequencer::Sequencer.new(4, 4) do
        at 1 do
          h = every 1 do
            p << position
          end

          h.after do
            p << position
          end
        end

        at 3.5r do
          h.stop
        end

        at 4.5r do
          h.stop
        end
      end

      s.run

      expect(p).to eq [1r, 2r, 3r]
    end

    it 'Basic move sequencing' do

      c = 0
      move_control = nil

      s = Musa::Sequencer::Sequencer.new 4, 4 do
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

      (16 * 2 - 1).times do
        s.tick
      end

      expect(c).to eq(5r - 1/16r)
      expect(s.moving).to include move_control

      s.tick

      expect(c).to eq(Rational(5))
      expect(s.moving.size).to eq 0

      s.tick

      expect(c).to eq(Rational(5))
      expect(s.moving.size).to eq 0
    end

    it 'Basic move sequencing with function and right open interval' do
      c = []
      move_control = nil

      function = proc { |factor| factor * factor }

      s = Musa::Sequencer::Sequencer.new 4, 4 do
        at 1 do
          move_control = move from: 1, to: 2, duration: 2, function: function, right_open: true do |value|
            c << value
          end
        end
      end

      until s.empty?
        s.tick
      end

      expect(c).to eq [1r,
                      1025/1024r,
                      257/256r,
                      1033/1024r,
                      65/64r,
                      1049/1024r,
                      265/256r,
                      1073/1024r,
                      17/16r,
                      1105/1024r,
                      281/256r,
                      1145/1024r,
                      73/64r,
                      1193/1024r,
                      305/256r,
                      1249/1024r,
                      5/4r,
                      1313/1024r,
                      337/256r,
                      1385/1024r,
                      89/64r,
                      1465/1024r,
                      377/256r,
                      1553/1024r,
                      25/16r,
                      1649/1024r,
                      425/256r,
                      1753/1024r,
                      113/64r,
                      1865/1024r,
                      481/256r,
                      1985/1024r]
    end

    it 'Basic play sequencing' do
      serie = H value: FOR(from: 0, to: 3), duration: S(Rational(1, 16)).repeat

      c = -1
      d = 0

      play_control = nil

      s = Musa::Sequencer::Sequencer.new 4, 4

      expect(s.playing.size).to eq 0

      s.with do
        play_control = play serie do |value:, control:|
          c = value

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

      s = Musa::Sequencer::Sequencer.new 4, 4 do
        cat = at 1 do
          play serie do |value:, control:|
            inner_control = control
            c = value if value
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

      s = Musa::Sequencer::Sequencer.new 4, 4 do
        cat = at 1 do
          cplay = play serie do |value:, control:|
            c = value if value
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
    include Musa::Series

    it 'Event passing on at' do
      s = Musa::Sequencer::Sequencer.new 4, 4

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

      s = Musa::Sequencer::Sequencer.new 4, 4

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
      s = Musa::Sequencer::Sequencer.new 4, 4

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
      s = Musa::Sequencer::Sequencer.new 4, 4

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
