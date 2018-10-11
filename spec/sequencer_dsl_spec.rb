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

    it 'Basic every sequencing with control' do
      c = 0
      d = 0

      s = Musa::Sequencer.new 4, 4 do
        at 1 do
          every 1 do |control:|
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
      expect(d).to eq(0)

      s.tick

      expect(c).to eq(3)
      expect(d).to eq(0)

      15.times do
        s.tick
      end

      expect(c).to eq(3)
      expect(d).to eq(1)
    end

    it 'Basic play sequencing' do
      serie = H value: FOR(from: 0, to: 3), duration: S(Rational(1, 16)).repeat

      c = -1
      d = 0

      s = Musa::Sequencer.new 4, 4 do
        play serie do |element, control:|
          c = element[:value]

          control.after do # this will be executed 4 times
            d += 1
          end
        end
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
      expect(d).to eq(4)
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

    it 'Basic theme sequencing' do
      Test.c = 0

      class Theme1
        include Musa::Theme

        def initialize(context:, parameter1:, parameter2:)
          super context

          @parameter1 = parameter1
          @parameter2 = parameter2
        end

        def run(parameter3:)
          Test.c = @parameter1 + @parameter2 + parameter3

          wait 1 do
            # puts "tras 1..."
          end
        end
      end

      s = Musa::Sequencer.new 4, 4

      s.theme Theme1, at: S(1, 2, 3), parameter1: 1000, parameter2: 200, parameter3: S(10, 20, 30)

      expect(Test.c).to eq(0)

      s.tick

      expect(Test.c).to eq(1210)

      16.times { s.tick }

      expect(Test.c).to eq(1220)

      15.times { s.tick }

      expect(Test.c).to eq(1220)

      s.tick

      expect(Test.c).to eq(1230)
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

    it 'Event passing on theme' do
      class Theme1
        include Musa::Theme

        def initialize(context:, parameter1:, parameter2:)
          super context

          @parameter1 = parameter1
          @parameter2 = parameter2
        end

        def run(parameter3:)
          launch :event, @parameter1 + @parameter2 + parameter3

          at position + Rational(1, 16) do
            launch :event2, position
          end
        end
      end

      s = Musa::Sequencer.new 4, 4

      s.theme Theme1, at: S(1, 2, 3), parameter1: 1000, parameter2: 200, parameter3: S(10, 20, 30)

      c = 0
      d = 0

      s.with do
        on :event do |param|
          c = param
        end

        on :event2 do |_pos|
          d += 1
        end
      end

      expect(c).to eq(0)
      expect(d).to eq(0)

      s.tick

      expect(c).to eq(1210)
      expect(d).to eq(0)

      s.tick

      expect(c).to eq(1210)
      expect(d).to eq(1)

      15.times { s.tick }

      expect(c).to eq(1220)
      expect(d).to eq(1)

      s.tick

      expect(c).to eq(1220)
      expect(d).to eq(2)

      14.times { s.tick }

      expect(c).to eq(1220)
      expect(d).to eq(2)

      s.tick

      expect(c).to eq(1230)
      expect(d).to eq(2)

      s.tick

      expect(c).to eq(1230)
      expect(d).to eq(3)
    end
  end
end
