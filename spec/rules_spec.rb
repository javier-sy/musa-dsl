require 'spec_helper'

require 'musa-dsl'

RSpec.describe Musa::Rules do
  context 'Rules grow/prune generation (without parameters)' do

    rules = Musa::Rules::Rules.new do
      grow 'make array' do |seed|
        #puts "rule make array: seed = #{seed} created = #{[seed, seed + 10]}"
        #puts "rule make array: seed = #{seed} created = #{[seed, seed + 11]}"

        branch [seed, seed + 10]
        branch [seed, seed + 11]
      end

      grow 'extend array' do |thing|

        branch x = thing.clone.tap { |thing| thing << thing[0] * 10 ** thing.size + thing[1] }

        #puts "rule extend array: thing = #{thing} branch = #{x}"
      end

      grow '+1 possibility' do |thing|
        (thing.size + 1).times do |i|
          branch x = thing.clone.tap { |_| _.prepend -1; _[i] += 1   }
          #puts "rule +1: thing = #{thing} branch = #{x}"
        end
      end

      cut 'rejected when last element is odd' do |thing|
        prune if thing.last % 2 == 0
        #puts "rejection: #{thing} = #{thing.last % 2 == 0}"

      end

      ended_when do |thing|
        #puts "ended? #{thing} = #{thing.size == 3}"
        thing.size == 4
      end
    end

    it 'test' do
      expect(rules.apply([0, 1, 2]).combinations).to eq \
      [[[0, 0, 11, 11], [0, 1, 11, 111], [0, 2, 13, 213]],
       [[0, 0, 11, 11], [0, 1, 11, 111], [-1, 3, 13, 213]],
       [[0, 0, 11, 11], [0, 1, 11, 111], [-1, 2, 14, 213]],
       [[0, 0, 11, 11], [-1, 2, 11, 111], [0, 2, 13, 213]],
       [[0, 0, 11, 11], [-1, 2, 11, 111], [-1, 3, 13, 213]],
       [[0, 0, 11, 11], [-1, 2, 11, 111], [-1, 2, 14, 213]],
       [[0, 0, 11, 11], [-1, 1, 12, 111], [0, 2, 13, 213]],
       [[0, 0, 11, 11], [-1, 1, 12, 111], [-1, 3, 13, 213]],
       [[0, 0, 11, 11], [-1, 1, 12, 111], [-1, 2, 14, 213]],
       [[-1, 1, 11, 11], [0, 1, 11, 111], [0, 2, 13, 213]],
       [[-1, 1, 11, 11], [0, 1, 11, 111], [-1, 3, 13, 213]],
       [[-1, 1, 11, 11], [0, 1, 11, 111], [-1, 2, 14, 213]],
       [[-1, 1, 11, 11], [-1, 2, 11, 111], [0, 2, 13, 213]],
       [[-1, 1, 11, 11], [-1, 2, 11, 111], [-1, 3, 13, 213]],
       [[-1, 1, 11, 11], [-1, 2, 11, 111], [-1, 2, 14, 213]],
       [[-1, 1, 11, 11], [-1, 1, 12, 111], [0, 2, 13, 213]],
       [[-1, 1, 11, 11], [-1, 1, 12, 111], [-1, 3, 13, 213]],
       [[-1, 1, 11, 11], [-1, 1, 12, 111], [-1, 2, 14, 213]],
       [[-1, 0, 12, 11], [0, 1, 11, 111], [0, 2, 13, 213]],
       [[-1, 0, 12, 11], [0, 1, 11, 111], [-1, 3, 13, 213]],
       [[-1, 0, 12, 11], [0, 1, 11, 111], [-1, 2, 14, 213]],
       [[-1, 0, 12, 11], [-1, 2, 11, 111], [0, 2, 13, 213]],
       [[-1, 0, 12, 11], [-1, 2, 11, 111], [-1, 3, 13, 213]],
       [[-1, 0, 12, 11], [-1, 2, 11, 111], [-1, 2, 14, 213]],
       [[-1, 0, 12, 11], [-1, 1, 12, 111], [0, 2, 13, 213]],
       [[-1, 0, 12, 11], [-1, 1, 12, 111], [-1, 3, 13, 213]],
       [[-1, 0, 12, 11], [-1, 1, 12, 111], [-1, 2, 14, 213]]]
    end
  end

  context 'Rules grow/prune generation (with parameters)' do

    rules = Musa::Rules::Rules.new do
      grow 'make array' do |seed, increment:|
        #puts "rule make array: seed = #{seed} created = #{[seed, seed + 10]}"
        #puts "rule make array: seed = #{seed} created = #{[seed, seed + 11]}"

        branch [seed, seed + increment]
        branch [seed, seed + increment + 1]
      end

      grow 'extend array' do |thing, increment:|

        branch x = thing.clone.tap { |thing| thing << thing[0] * increment ** thing.size + thing[1] }

        #puts "rule extend array: thing = #{thing} branch = #{x}"
      end

      grow '+1 possibility' do |thing|
        (thing.size + 1).times do |i|
          branch x = thing.clone.tap { |_| _.prepend -1; _[i] += 1   }
          #puts "rule +1: thing = #{thing} branch = #{x}"
        end
      end

      cut 'rejected when last element is odd' do |thing|
        prune if thing.last % 2 == 0
        #puts "rejection: #{thing} = #{thing.last % 2 == 0}"

      end

      ended_when do |thing|
        #puts "ended? #{thing} = #{thing.size == 3}"
        thing.size == 4
      end
    end

    it 'test' do
      expect(rules.apply([0, 1, 2], increment: 10).combinations).to eq \
      [[[0, 0, 11, 11], [0, 1, 11, 111], [0, 2, 13, 213]],
       [[0, 0, 11, 11], [0, 1, 11, 111], [-1, 3, 13, 213]],
       [[0, 0, 11, 11], [0, 1, 11, 111], [-1, 2, 14, 213]],
       [[0, 0, 11, 11], [-1, 2, 11, 111], [0, 2, 13, 213]],
       [[0, 0, 11, 11], [-1, 2, 11, 111], [-1, 3, 13, 213]],
       [[0, 0, 11, 11], [-1, 2, 11, 111], [-1, 2, 14, 213]],
       [[0, 0, 11, 11], [-1, 1, 12, 111], [0, 2, 13, 213]],
       [[0, 0, 11, 11], [-1, 1, 12, 111], [-1, 3, 13, 213]],
       [[0, 0, 11, 11], [-1, 1, 12, 111], [-1, 2, 14, 213]],
       [[-1, 1, 11, 11], [0, 1, 11, 111], [0, 2, 13, 213]],
       [[-1, 1, 11, 11], [0, 1, 11, 111], [-1, 3, 13, 213]],
       [[-1, 1, 11, 11], [0, 1, 11, 111], [-1, 2, 14, 213]],
       [[-1, 1, 11, 11], [-1, 2, 11, 111], [0, 2, 13, 213]],
       [[-1, 1, 11, 11], [-1, 2, 11, 111], [-1, 3, 13, 213]],
       [[-1, 1, 11, 11], [-1, 2, 11, 111], [-1, 2, 14, 213]],
       [[-1, 1, 11, 11], [-1, 1, 12, 111], [0, 2, 13, 213]],
       [[-1, 1, 11, 11], [-1, 1, 12, 111], [-1, 3, 13, 213]],
       [[-1, 1, 11, 11], [-1, 1, 12, 111], [-1, 2, 14, 213]],
       [[-1, 0, 12, 11], [0, 1, 11, 111], [0, 2, 13, 213]],
       [[-1, 0, 12, 11], [0, 1, 11, 111], [-1, 3, 13, 213]],
       [[-1, 0, 12, 11], [0, 1, 11, 111], [-1, 2, 14, 213]],
       [[-1, 0, 12, 11], [-1, 2, 11, 111], [0, 2, 13, 213]],
       [[-1, 0, 12, 11], [-1, 2, 11, 111], [-1, 3, 13, 213]],
       [[-1, 0, 12, 11], [-1, 2, 11, 111], [-1, 2, 14, 213]],
       [[-1, 0, 12, 11], [-1, 1, 12, 111], [0, 2, 13, 213]],
       [[-1, 0, 12, 11], [-1, 1, 12, 111], [-1, 3, 13, 213]],
       [[-1, 0, 12, 11], [-1, 1, 12, 111], [-1, 2, 14, 213]]]
    end
  end
end
