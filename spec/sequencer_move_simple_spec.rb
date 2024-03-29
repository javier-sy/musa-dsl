require 'spec_helper'

require 'musa-dsl'

RSpec.describe Musa::Sequencer do
  context 'Basic move simple sequencing' do

    it 'Basic move sequencing (every, from, to, duration)' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      c = 0
      move_control = nil

      s.at 1 do
        move_control = s.move every: 1/16r, from: 1, to: 5, duration: 4 + Rational(1, 16) do |value|
          c = value
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

    it 'Basic move sequencing (from, to, step, duration)' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      c = 0
      move_control = nil

      s.at 1 do
        move_control = s.move from: 1, to: 5, duration: 4 + Rational(1, 16), step: 1/16r do |value|
          c = value
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

    it 'Basic move sequencing (from, to, step, every)' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      c = 0
      move_control = nil

      s.at 1 do
        move_control = s.move every: 1/16r, from: 1, to: 5, step: 1/16r do |value|
          c = value
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

    it 'Basic move sequencing (from, step, every, duration)' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      c = 0
      move_control = nil

      s.at 1 do
        move_control = s.move every: 1/16r, from: 1, step: 1/16r, duration: 4 + Rational(1, 16) do |value|
          c = value
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

    it 'Basic move sequencing (from, to, duration) [right_closed interval values]' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      c = 0
      move_control = nil

      s.at 1 do
        move_control = s.move from: 1, to: 2, duration: 4 do |value|
          c = value
        end
      end

      expect(c).to eq(0)
      expect(s.moving.size).to eq 0

      tests_passed = 0

      72.times do
        s.tick

        case s.position
        when 1
          expect(c).to eq(1)
          expect(s.moving).to include move_control

          tests_passed += 1
        when 5 - 1/16r
          expect(c).to eq(2)
          expect(s.moving.size).to eq 0

          tests_passed += 1

        when 5
          expect(c).to eq(2)
          expect(s.moving.size).to eq 0

          tests_passed += 1
        when 5 + 1/16r
          expect(c).to eq(2)
          expect(s.moving.size).to eq 0

          tests_passed += 1

        end
      end

      expect(tests_passed).to eq 4
    end

    it 'Basic move sequencing (from, to, duration) [right open interval values]' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      c = 0
      move_control = nil

      s.at 1 do
        move_control = s.move from: 1, to: 2, duration: 4, right_open: true do |value|
          c = value
        end
      end

      expect(c).to eq(0)
      expect(s.moving.size).to eq 0

      tests_passed = 0

      72.times do
        s.tick

        case s.position
        when 1
          expect(c).to eq(1)
          expect(s.moving).to include move_control

          tests_passed += 1
        when 5 - 1/16r
          expect(c).to eq(1 + 63/64r)
          expect(s.moving.size).to eq 0

          tests_passed += 1

        when 5
          expect(c).to eq(1 + 63/64r)
          expect(s.moving.size).to eq 0

          tests_passed += 1
        when 5 + 1/16r
          expect(c).to eq(1 + 63/64r)
          expect(s.moving.size).to eq 0

          tests_passed += 1

        end
      end

      expect(tests_passed).to eq 4
    end

    it 'Basic move sequencing (from, to, step, duration)' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      c = 0
      move_control = nil

      s.at 1 do
        move_control = s.move from: 1, to: 2, step: 1/4r, duration: 4 do |value|
          c = value
        end
      end

      expect(c).to eq(0)
      expect(s.moving.size).to eq 0

      tests_passed = 0

      72.times do
        s.tick

        case s.position
        when 1
          expect(c).to eq(1)
          expect(s.moving).to include move_control

          tests_passed += 1

        when 4
          expect(c).to eq(2 - 1/4r)
          expect(s.moving).to include move_control

          tests_passed += 1

        when 5 - 1/16r
          expect(c).to eq(2)
          expect(s.moving.size).to eq 0

          tests_passed += 1

        when 5
          expect(c).to eq(2)
          expect(s.moving.size).to eq 0

          tests_passed += 1
        when 5 + 1/16r
          expect(c).to eq(2)
          expect(s.moving.size).to eq 0

          tests_passed += 1

        end
      end

      expect(tests_passed).to eq 5
    end

    it 'Basic move sequencing (from, to, every, duration)' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      c = 0
      move_control = nil

      s.at 1 do
        move_control = s.move from: 1, to: 2, every: 1/4r, duration: 4 do |value|
          c = value
        end
      end

      expect(c).to eq(0)
      expect(s.moving.size).to eq 0

      tests_passed = 0

      72.times do
        s.tick

        case s.position
        when 1
          expect(c).to eq(1)
          expect(s.moving).to include move_control

          tests_passed += 1

        when 5 - 1/16r
          expect(c).to eq(2)
          expect(s.moving.size).to eq 0

          tests_passed += 1

        when 5
          expect(c).to eq(2)
          expect(s.moving.size).to eq 0

          tests_passed += 1
        when 5 + 1/16r
          expect(c).to eq(2)
          expect(s.moving.size).to eq 0

          tests_passed += 1

        end
      end

      expect(tests_passed).to eq 4
    end

    it 'Basic move sequencing (from, to, every, duration) receiving duration, open/closed interval, initial value and final value' do
      s = Musa::Sequencer::BaseSequencer.new 4, 4

      cv = 0
      ct = 0
      cd = 0
      move_control = nil

      s.at 1 do
        move_control = s.move from: 1, to: 2, every: 1/4r, duration: 4 do |value, value_to, duration:, right_open:|
          cv = value
          ct = value_to
          cd = duration
        end
      end

      expect(cv).to eq(0)
      expect(ct).to eq(0)
      expect(cd).to eq(0)

      expect(s.moving.size).to eq 0

      tests_passed = 0

      72.times do
        s.tick

        case s.position
        when 1
          expect(cv).to eq(1)
          #expect(ct).to eq(1)
          expect(s.moving).to include move_control

          tests_passed += 1

        when 5 - 1/16r
          expect(cv).to eq(2)
          expect(s.moving.size).to eq 0

          tests_passed += 1

        when 5
          expect(cv).to eq(2)
          expect(s.moving.size).to eq 0

          tests_passed += 1
        when 5 + 1/16r
          expect(cv).to eq(2)
          expect(s.moving.size).to eq 0

          tests_passed += 1

        end
      end

      expect(tests_passed).to eq 4
    end

    it 'Bugfix: right open interval with same from and to value and step parameter throws an exception because common interval has a nil duration' do
      c = {}
      s = Musa::Sequencer::Sequencer.new(4, 32) do |_|
        _.at 1 do
          _.move from: 0, to: 0, duration: 4, step: 1, right_open: true do |_, value, duration:|
            c[_.position] = [value, duration]
          end
        end
      end

      s.run

      expect(c).to eq({ 1r => [0, 4] })
    end
  end

  it 'Bugfix: right open interval with same from and to value and step parameter sends an incorrect next_value of source value + 1; correct value should be nil' do
    c = {}
    s = Musa::Sequencer::Sequencer.new(4, 32) do |_|
      _.at 1 do
        _.move from: 0, to: 0, duration: 4, step: 1, right_open: true do |_, value, next_value, duration:|
          c[_.position] = [value, next_value, duration]
        end
      end
    end

    s.run

    expect(c).to eq({ 1r => [0, nil, 4] })
  end

  it 'Right open interval with only one step must send a next_value with target value source but execute only once' do
    c = {}
    s = Musa::Sequencer::Sequencer.new(4, 32) do |_|
      _.at 1 do
        _.move from: 0, to: 1, duration: 4, step: 1, right_open: true do |_, value, next_value, duration:|
          c[_.position] = [value, next_value, duration]
        end
      end
    end

    s.run

    expect(c).to eq({ 1r => [0, 1, 4] })
  end

end
