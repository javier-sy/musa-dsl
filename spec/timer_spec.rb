require 'spec_helper'

require 'musa-dsl'

require 'descriptive-statistics'

RSpec.describe Musa::Timer do
  context 'Timer with high precision' do
    it 'Timer runs correctly', slow: true do
      tt = []

      time = 0.001
      times = 1000

      t = Musa::Timer.new(time)

      t.run do
        x = 100.0
        (rand * 10000).to_i.times do |i|
          x *= (x + i.to_f) / x
        end
        tt << Process.clock_gettime(Process::CLOCK_MONOTONIC)
        break if tt.size == times
      end

      offsets1 = (1..(tt.size - 1)).collect { |i| tt[i] - tt[i-1] }
      average1 = DescriptiveStatistics::Stats.new(offsets1).mean

      average_error = ((average1 - time) / time) * 100.0
      expect(average_error).to be < 0.1
    end
  end
end

