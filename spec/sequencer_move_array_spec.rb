require 'spec_helper'

require 'musa-dsl'

include Musa::Sequencer

RSpec.describe Musa::Sequencer do
  context 'Basic move array sequencing' do
=begin
    it 'Basic move sequencing (every, from, to, duration)' do
      s = BaseSequencer.new 4, 4

      c = [0, 0, 0]
      move_control = nil

      s.at 1 do
        move_control = s.move every: 1/16r, from: [1, 2, 3], to: [5, 6, 7], duration: 4 + Rational(1, 16) do |values|
          c = values
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

    it 'Basic move sequencing (from, to, step, duration)' do
      s = BaseSequencer.new 4, 4

      c = [0, 0, 0]
      move_control = nil

      s.at 1 do
        move_control = s.move from: [1, 2, 3], to: [5, 6, 7], duration: 4 + Rational(1, 16), step: 1/16r do |value|
          c = value
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

    it 'Basic move sequencing (from, to, step, every)' do
      s = BaseSequencer.new 4, 4

      c = [0, 0, 0]
      move_control = nil

      s.at 1 do
        move_control = s.move every: 1/16r, from: [1, 2, 3], to: [5, 6, 7], step: 1/16r do |value|
          c = value
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
        move_control = s.move every: 1/16r, from: [1, 2, 3], step: 1/16r, duration: 4 + Rational(1, 16) do |value|
          c = value
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

    it 'Basic move sequencing (from, to, duration) [right_closed interval values]' do
      s = BaseSequencer.new 4, 4

      c = [0, 0, 0]
      move_control = nil

      s.at 1 do
        move_control = s.move from: [1, 2, 3], to: [2, 3, 4], duration: 4 do |value|
          c = value
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
        when 5 - 1/16r
          expect(c).to eq([2, 3, 4])
          expect(s.moving.size).to eq 0

          tests_passed += 1

        when 5
          expect(c).to eq([2, 3, 4])
          expect(s.moving.size).to eq 0

          tests_passed += 1
        when 5 + 1/16r
          expect(c).to eq([2, 3, 4])
          expect(s.moving.size).to eq 0

          tests_passed += 1

        end
      end

      expect(tests_passed).to eq 4
    end

    it 'Basic move sequencing (from, to, duration) [right open interval values]' do
      s = BaseSequencer.new 4, 4

      c = [0, 0, 0]
      move_control = nil

      s.at 1 do
        move_control = s.move from: [1, 2, 3], to: [2, 3, 4], duration: 4, right_open: true do |value|
          c = value
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
        when 5 - 1/16r
          expect(c).to eq([1 + 63/64r, 2 + 63/64r, 3 + 63/64r])
          expect(s.moving.size).to eq 0

          tests_passed += 1

        when 5
          expect(c).to eq([1 + 63/64r, 2 + 63/64r, 3 + 63/64r])
          expect(s.moving.size).to eq 0

          tests_passed += 1
        when 5 + 1/16r
          expect(c).to eq([1 + 63/64r, 2 + 63/64r, 3 + 63/64r])
          expect(s.moving.size).to eq 0

          tests_passed += 1

        end
      end

      expect(tests_passed).to eq 4
    end

    it 'Basic move sequencing (from, to, step, duration)' do
      s = BaseSequencer.new 4, 4

      c = [0, 0, 0]
      move_control = nil

      s.at 1 do
        move_control = s.move from: [1, 2, 3], to: [2, 3, 4], step: 1/4r, duration: 4 do |value|
          c = value
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

        when 4
          expect(c).to eq([2 - 1/4r, 3 - 1/4r, 4 - 1/4r])
          expect(s.moving).to include move_control

          tests_passed += 1

        when 5 - 1/16r
          expect(c).to eq([2, 3, 4])
          expect(s.moving.size).to eq 0

          tests_passed += 1

        when 5
          expect(c).to eq([2, 3, 4])
          expect(s.moving.size).to eq 0

          tests_passed += 1
        when 5 + 1/16r
          expect(c).to eq([2, 3, 4])
          expect(s.moving.size).to eq 0

          tests_passed += 1

        end
      end

      expect(tests_passed).to eq 5
    end

    it 'Basic move sequencing (from, to, every, duration)' do
      s = BaseSequencer.new 4, 4

      c = [0, 0, 0]
      move_control = nil

      s.at 1 do
        move_control = s.move from: [1, 2, 3], to: [2, 3, 4], every: 1/4r, duration: 4 do |value|
          c = value
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

        when 5 - 1/16r
          expect(c).to eq([2, 3, 4])
          expect(s.moving.size).to eq 0

          tests_passed += 1

        when 5
          expect(c).to eq([2, 3, 4])
          expect(s.moving.size).to eq 0

          tests_passed += 1
        when 5 + 1/16r
          expect(c).to eq([2, 3, 4])
          expect(s.moving.size).to eq 0

          tests_passed += 1

        end
      end

      expect(tests_passed).to eq 4
    end

    it 'Basic move sequencing (from, to, every, duration) with to: as unique value' do
      s = BaseSequencer.new 4, 4

      c = [0, 0, 0]
      move_control = nil

      s.at 1 do
        move_control = s.move from: [1, 2, 3], to: 4, every: 1/4r, duration: 4 do |value|
          c = value
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
        move_control = s.move from: [1, 2, 3, 1], to: 4, step: 1/4r, duration: 4 do |value|
          c = value
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

    it 'Bugfix: move dont modify from and to parameters' do
      s = BaseSequencer.new 4, 4

      f = [1, 2, 3]
      t = [2, 3, 4]

      s.at 1 do
        s.move from: f, to: t, duration: 4 do |value|
          # ignore
        end
      end

      s.run

      expect(f).to eq([1, 2, 3])
      expect(t).to eq([2, 3, 4])
    end

    it "Bugfix: parallel move didn't executed yield block with correct value parameters when several partially coincidentals every intervals were needed" do
      c = {}

      s = Sequencer.new(4, 32) do |_|
        _.at 1 do
          _.move from: [0, 60], to: [3, 67], duration: 4, step: 1 do |value, duration:, started_ago:|
            c[_.position] = [value, duration, started_ago]
          end
        end
      end

      expect(c.size).to eq 0

      s.run

      expect(c).to eq({
        1r => [ [0, 60], [1, 1/2r], [nil, nil] ],
        1.5r => [ [0, 61], [1, 1/2r], [1/2r, nil] ],
        2r => [ [1, 62], [1, 1/2r], [nil, nil] ],
        2.5r => [ [1, 63], [1, 1/2r], [1/2r, nil] ],
        3r => [ [2, 64], [1, 1/2r], [nil, nil] ],
        3.5r => [ [2, 65], [1, 1/2r], [1/2r, nil] ],
        4r => [ [3, 66], [1, 1/2r], [nil, nil] ],
        4.5r => [ [3, 67], [1, 1/2r], [1/2r, nil] ] })
    end

    it "Bugfix: bad calculation of common_interval" do
      c = {}
      s = Sequencer.new(4, 32) do |_|
        _.at 1 do
          _.move from: [ 0, 0 ],
                 to: [ 0, 3 ],
                 duration: 4, step: 1 do
          |_, value, next_value, duration:, start_before:|

            c[_.position] = value
          end
        end
      end

      s.run

      expect(c).to eq({
                          1r => [0, 0],
                          2r => [0, 1],
                          3r => [0, 2],
                          4r => [0, 3]
                      })
    end

    it 'Bugfix: right open interval with same from and to value and step parameter throws an exception because common interval has a nil duration' do
      c = {}
      s = Sequencer.new(4, 32) do |_|
        _.at 1 do
          _.move from: [0, 0], to: [0, 4], duration: 4, step: 1, right_open: true do |_, value, duration:, started_ago:|
            c[_.position] = { value: value, duration: duration, started_ago: started_ago }
          end
        end
      end

      s.run

      expect(c).to eq({
                          1r => { value: [0, 0], duration: [4, 1], started_ago: [nil, nil] },
                          2r => { value: [0, 1], duration: [4, 1], started_ago: [1, nil] },
                          3r => { value: [0, 2], duration: [4, 1], started_ago: [2, nil] },
                          4r => { value: [0, 3], duration: [4, 1], started_ago: [3, nil] }
                      })
    end
=end
    it 'Different right_open values' do
      c = {}
      s = Sequencer.new(4, 32, log_decimals: 1.3) do |_|
        _.at 1 do
          _.move from: [ 5, 60, 6 ],
                 to: [ 2, 65, 7 ],
                 right_open: [ true, false, true ],
                 duration: 5,
                 step: 1 do |_, value, next_value, right_open:|

            c[_.position] ||= []
            c[_.position] << [value, next_value, right_open]
          end
        end
      end

      s.run

      expect(c).to eq({ 1r        => [[[5, 60, 6], [4, 61, 7], [true, false, true]]],
                        235/128r  => [[[5, 61, 6], [4, 62, 7], [true, false, true]]],
                        341/128r  => [[[4, 62, 6], [3, 63, 7], [true, false, true]]],
                        7/2r      => [[[4, 63, 6], [3, 64, 7], [true, false, true]]],
                        555/128r  => [[[3, 64, 6], [2, 65, 7], [true, false, true]]],
                        661/128r  => [[[3, 65, 6], [2, nil, 7], [true, false, true]]] })
    end
  end
end
