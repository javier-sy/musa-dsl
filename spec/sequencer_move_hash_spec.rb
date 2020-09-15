require 'spec_helper'

require 'musa-dsl'

include Musa::Sequencer

RSpec.describe Musa::Sequencer do
  context 'Basic move hash sequencing' do

    it 'Basic move sequencing (every, from, to, duration)' do
      s = BaseSequencer.new 4, 4

      c = {a: 0, b: 0, c: 0}
      move_control = nil

      s.at 1 do
        move_control = s.move every: 1 / 16r, from: {a: 1, b: 2, c: 3}, to: {a: 5, b: 6, c: 7}, duration: 4 + Rational(1, 16) do |values|
          c = values
        end
      end

      expect(c).to eq({a: 0, b: 0, c: 0})
      expect(s.moving.size).to eq 0

      s.tick

      expect(c).to eq({a: 1, b: 2, c: 3})
      expect(s.moving).to include move_control

      s.tick

      expect(c).to eq({a: 1 + Rational(1, 16), b: 2 + Rational(1, 16), c: 3 + Rational(1, 16)})
      expect(s.moving).to include move_control

      14.times do
        s.tick
      end

      expect(c).to eq({a: 1 + Rational(15, 16), b: 2 + Rational(15, 16), c: 3 + Rational(15, 16)})
      expect(s.moving).to include move_control

      s.tick

      expect(c).to eq({a: Rational(2), b: Rational(3), c: Rational(4)})
      expect(s.moving).to include move_control

      s.tick

      15.times do
        s.tick
      end

      expect(c).to eq({a: Rational(3), b: Rational(4), c: Rational(5)})
      expect(s.moving).to include move_control

      (16 * 2 - 1).times do
        s.tick
      end

      expect(c).to eq({a: 5r - 1 / 16r, b: 6r - 1 / 16r, c: 7r - 1 / 16r})
      expect(s.moving).to include move_control

      s.tick

      expect(c).to eq({a: Rational(5), b: Rational(6), c: Rational(7)})
      expect(s.moving.size).to eq 0

      s.tick

      expect(c).to eq({a: Rational(5), b: Rational(6), c: Rational(7)})
      expect(s.moving.size).to eq 0
    end

    it 'Basic move sequencing (from, to, step, duration)' do
      s = BaseSequencer.new 4, 4

      c = {a: 0, b: 0, c: 0}
      move_control = nil

      s.at 1 do
        move_control = s.move from: {a: 1, b: 2, c: 3}, to: {a: 5, b: 6, c: 7}, duration: 4 + Rational(1, 16), step: {a: 1/16r, b: 1/16r, c: 1/16r} do |value|
          c = value
        end
      end

      expect(c).to eq({a: 0, b: 0, c: 0})
      expect(s.moving.size).to eq 0

      s.tick

      expect(c).to eq({a: 1, b: 2, c: 3})
      expect(s.moving).to include move_control

      s.tick

      expect(c).to eq({a: 1 + Rational(1, 16), b: 2 + Rational(1, 16), c: 3 + Rational(1, 16)})
      expect(s.moving).to include move_control

      14.times do
        s.tick
      end

      expect(c).to eq({a: 1 + Rational(15, 16), b: 2 + Rational(15, 16), c: 3 + Rational(15, 16)})
      expect(s.moving).to include move_control

      s.tick

      expect(c).to eq({a: Rational(2), b: Rational(3), c: Rational(4)})
      expect(s.moving).to include move_control

      s.tick

      15.times do
        s.tick
      end

      expect(c).to eq({a: Rational(3), b: Rational(4), c: Rational(5)})
      expect(s.moving).to include move_control

      (16 * 2 - 1).times do
        s.tick
      end

      expect(c).to eq({a: 5r - 1 / 16r, b: 6r - 1 / 16r, c: 7r - 1 / 16r})
      expect(s.moving).to include move_control

      s.tick

      expect(c).to eq({a: Rational(5), b: Rational(6), c: Rational(7)})
      expect(s.moving.size).to eq 0

      s.tick

      expect(c).to eq({a: Rational(5), b: Rational(6), c: Rational(7)})
      expect(s.moving.size).to eq 0
    end

    it 'Basic move sequencing (from, to, step, every)' do
      s = BaseSequencer.new 4, 4

      c = [0, 0, 0]
      move_control = nil

      s.at 1 do
        move_control = s.move every: 1/16r, from: {a: 1, b: 2, c: 3}, to: {a: 5, b: 6, c: 7}, step: 1/16r do |value|
          c = [value[:a], value[:b], value[:c]]
        end
      end

      expect(c).to eq([0, 0, 0])
      expect(s.moving.size).to eq 0

      s.tick

      expect(c).to eq([1, 2, 3])
      expect(s.moving).to include move_control

      s.tick

      expect(c).to eq([1 + Rational(1, 16), 2 + Rational(1, 16), 3 + Rational(1, 16)])
      expect(s.moving).to include move_control

      14.times do
        s.tick
      end

      expect(c).to eq([1 + Rational(15, 16), 2 + Rational(15, 16), 3 + Rational(15, 16)])
      expect(s.moving).to include move_control

      s.tick

      expect(c).to eq([Rational(2), Rational(3), Rational(4)])
      expect(s.moving).to include move_control

      s.tick

      15.times do
        s.tick
      end

      expect(c).to eq([Rational(3), Rational(4), Rational(5)])
      expect(s.moving).to include move_control

      (16 * 2 - 1).times do
        s.tick
      end

      expect(c).to eq([5r - 1/16r, 6r - 1/16r, 7r - 1/16r])
      expect(s.moving).to include move_control

      s.tick

      expect(c).to eq([Rational(5), Rational(6), Rational(7)])
      expect(s.moving.size).to eq 0

      s.tick

      expect(c).to eq([Rational(5), Rational(6), Rational(7)])
      expect(s.moving.size).to eq 0
    end

    it 'Basic move sequencing (from, step, every, duration)' do
      s = BaseSequencer.new 4, 4

      c = [0, 0, 0]
      move_control = nil

      s.at 1 do
        move_control = s.move every: 1/16r, from: {a: 1, b: 2, c: 3}, step: 1/16r, duration: 4 + Rational(1, 16) do |value|
          c = [value[:a], value[:b], value[:c]]
        end
      end

      expect(c).to eq([0, 0, 0])
      expect(s.moving.size).to eq 0

      s.tick

      expect(c).to eq([1, 2, 3])
      expect(s.moving).to include move_control

      s.tick

      expect(c).to eq([1 + Rational(1, 16), 2 + Rational(1, 16), 3 + Rational(1, 16)])
      expect(s.moving).to include move_control

      14.times do
        s.tick
      end

      expect(c).to eq([1 + Rational(15, 16), 2 + Rational(15, 16), 3 + Rational(15, 16)])
      expect(s.moving).to include move_control

      s.tick

      expect(c).to eq([Rational(2), Rational(3), Rational(4)])
      expect(s.moving).to include move_control

      s.tick

      15.times do
        s.tick
      end

      expect(c).to eq([Rational(3), Rational(4), Rational(5)])
      expect(s.moving).to include move_control

      (16 * 2 - 1).times do
        s.tick
      end

      expect(c).to eq([5r - 1/16r, 6r - 1/16r, 7r - 1/16r])
      expect(s.moving).to include move_control

      s.tick

      expect(c).to eq([Rational(5), Rational(6), Rational(7)])
      expect(s.moving.size).to eq 0

      s.tick

      expect(c).to eq([Rational(5), Rational(6), Rational(7)])
      expect(s.moving.size).to eq 0
    end

    it 'Basic move sequencing (from, to, every, duration) with to: as unique value' do
      s = BaseSequencer.new 4, 4

      c = [0, 0, 0]
      move_control = nil

      s.at 1 do
        move_control = s.move from: {a: 1, b: 2, c: 3}, to: 4, every: 1/4r, duration: 4 do |value|
          c = [value[:a], value[:b], value[:c]]
        end
      end

      expect(c).to eq([0, 0, 0])
      expect(s.moving.size).to eq 0

      tests_passed = 0

      72.times do
        s.tick

        case s.position
        when 1
          expect(c).to eq([1, 2, 3])
          expect(s.moving).to include move_control

          tests_passed += 1

        when 4 # seguro?
          expect(c).to eq([3r + 2/5r, 3 + 3/5r, 3 + 4/5r])
          expect(s.moving).to include move_control

          tests_passed += 1

        when 5 - 1/16r
          expect(c).to eq([4, 4, 4])
          expect(s.moving.size).to eq 0

          tests_passed += 1

        when 5
          expect(c).to eq([4, 4, 4])
          expect(s.moving.size).to eq 0

          tests_passed += 1
        when 5 + 1/16r
          expect(c).to eq([4, 4, 4])
          expect(s.moving.size).to eq 0

          tests_passed += 1

        end
      end

      expect(tests_passed).to eq 5
    end

    it 'Basic move sequencing (from, to, step, duration) with to: as unique value' do
      s = BaseSequencer.new 4, 4

      c = [0, 0, 0, 0]
      move_control = nil

      s.at 1 do
        move_control = s.move from: {a: 1, b: 2, c: 3, d: 1}, to: 4, step: 1/4r, duration: 4 do |value|
          c = [value[:a], value[:b], value[:c], value[:d]]
        end
      end

      expect(c).to eq([0, 0, 0, 0])
      expect(s.moving.size).to eq 0

      tests_passed = 0

      72.times do
        s.tick

        case s.position
        when 1
          expect(c).to eq([1, 2, 3, 1])
          expect(s.moving).to include move_control

          tests_passed += 1

        when 24/16r
          expect(c).to eq([1 + 1/4r, 2 + 1/4r, 3, 1 + 1/4r])
          expect(s.moving).to include move_control

        when 4
          expect(c).to eq([3 + 1/4r, 3 + 1/2r, 3 + 3/4r, 3 + 1/4r])
          expect(s.moving).to include move_control

          tests_passed += 1

        when 5 - 1/4r - 2/16r
          expect(c).to eq([3 + 3/4r, 4, 4, 3 + 3/4r])
          expect(s.moving).to include move_control

          tests_passed += 1

        when 5 - 1/4r
          expect(c).to eq([4, 4, 4, 4])
          expect(s.moving.size).to eq 0

          tests_passed += 1

        when 5
          expect(c).to eq([4, 4, 4, 4])
          expect(s.moving.size).to eq 0

          tests_passed += 1
        when 5 + 1/4r
          expect(c).to eq([4, 4, 4, 4])
          expect(s.moving.size).to eq 0

          tests_passed += 1
        end
      end

      expect(tests_passed).to eq 6
    end
  end
end
