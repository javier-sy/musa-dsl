require 'spec_helper'

require 'musa-dsl'

include Musa::Backboner

RSpec.describe Backboner do
  context 'Backboner grow/prune generation' do

    rules = Backboner.new do
      grow 'make array' do |seed|
        puts "rule make array: seed = #{seed}"
        branch [seed, seed + 10]
      end

      grow 'extend array' do |thing|
        puts "rule extend array #{thing}"
        branch thing.clone.tap { | thing | thing << thing[0] * 10 ** thing.size }
      end

      grow 'even numbers can have +1 possibility' do |thing|
        if thing[0] % 2 == 0
          puts "rule thing[0] % 2 == 0 #{thing}"
          thing.size.times do |i|
            branch thing.clone.tap { |_| _[i] += 1; _ << 123 }
          end
        end
      end

      cut 'only accepted if sum of array is even' do |thing|
        puts "rejection #{thing}"

      end

      ended_when do |thing|
        puts "ended? #{thing}"
        thing.sum > 1000
      end
    end

    it '' do
      pp rules.apply([0, 2]).combinations
    end
  end
end
