require 'spec_helper'

require 'musa-dsl'

include Musa::Backboner

RSpec.describe Backboner do
  context 'Backboner grow/prune generation' do

    rules = Backboner.new do
      grow 'make array' do |seed|
        puts "rule make array: seed = #{seed}"
        branch [seed, seed + 10]
        branch [seed, seed + 11]
      end

      grow 'extend array' do |thing|
        puts "rule extend array #{thing}"
        branch thing.clone.tap { | thing | thing << thing[0] * 10 ** thing.size + thing[1] }
      end

      grow '+1 possibility' do |thing|
        puts "rule thing[0] % 2 == 0 #{thing}"
        thing.size.times do |i|
          branch thing.clone.tap { |_| _[i] += 1 }
        end
      end

      cut 'rejected when last element is odd' do |thing|
        puts "rejection #{thing}"
        prune if thing.last % 2 == 0
      end

      ended_when do |thing|
        puts "ended? #{thing}"
        thing.size == 4
      end
    end

    it '' do
      pp rules.apply([0, 1, 2]).combinations
    end
  end
end
