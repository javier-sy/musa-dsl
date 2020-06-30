require_relative '../lib/musa-dsl'

require 'matrix'

include Musa::Sequencer
include Musa::Datasets
include Musa::Score

using Musa::Extension::Matrix

# [bar, pitch, intensity, instrument]
line = Matrix[ [0 * 4, 60, 50, 0],
               [10 * 4, 65, 50, 0],
               [15 * 4, 65, 70, 0],
               [20 * 4, 65, 80, 3],
               [25 * 4, 60, 70, -2],
               [30 * 4, 60, 50, 0] ]


score = Score.new(0.25)

sequencer = Sequencer.new(4, 24) do |_|
  _.at 1 do |_|
    line.to_p(0).each do |p|
      _.play p.to_ps_serie do |thing|
        score.at _.position, add: thing

        _.move from: thing[:from], to: thing[:to],
               duration: thing[:duration], every: 1/4r,
               right_open: thing[:right_open] do |value_a, value_b, duration:, right_open:|


          # puts "#{_.position} value_a = #{value_a} value_b = #{value_b} duration = #{duration} right_open = #{right_open}"
        end
      end
    end
  end
end

sequencer.run

score.each do |thing|
  puts "thing = #{thing}"
end
