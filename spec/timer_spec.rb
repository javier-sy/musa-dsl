require 'spec_helper'

require 'musa-dsl'

require 'descriptive-statistics'

module Enumerable
  include DescriptiveStatistics

  # Warning: hacky evil meta programming. Required because classes that have already included
  # Enumerable will not otherwise inherit the statistics methods.
  DescriptiveStatistics.instance_methods.each do |m|
    define_method(m, DescriptiveStatistics.instance_method(m))
  end
end

RSpec.describe Musa::Timer do
  context 'Timer with high precision' do
    it 'Timer runs correctly' do
      t = Musa::Timer.new(-0.000005) # - 0.000005

      tt = []

      time = 0.001
      times = 10000
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      t.every time do
        x = 100.0
        (rand * 10000).to_i.times do |i|
          x *= (x + i)
        end
        tt << Process.clock_gettime(Process::CLOCK_MONOTONIC)
        break if tt.size == times
      end
      total_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start

      offsets = (1..(tt.size - 1)).collect { |i| tt[i] - tt[i-1] }
      average = offsets.mean

      puts "offsets mean = #{offsets.mean}"
      puts "offsets median = #{offsets.median}"
      puts "standard deviation = #{offsets.standard_deviation}"

      puts "average error = #{((average - time) / time) * 100} %"

      errors = offsets.collect {|offset| (offset - average).abs / average }

      #pp offsets

      puts "offset error = #{errors.sum * 100.0 / errors.size} %"

      puts "total time = #{total_time}"
      puts "total time error = #{100.0 * (total_time - time * times) / (time * times)} %"
    end
  end
end

