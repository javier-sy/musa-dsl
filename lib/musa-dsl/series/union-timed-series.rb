require_relative '../datasets/e'

module Musa
  module Series

    extend self

    def UNION(*timed_series)
      UnionTimed.new(timed_series)
    end

    class UnionTimed
      include Serie

      attr_reader :sources

      def initialize(series)
        @sources = if series[0].prototype?
                     series.collect(&:prototype).freeze
                   else
                     series.collect(&:instance)
                   end

        _restart false

        mark_regarding! series[0]
      end

      private def _restart(restart_sources = true)
        @sources.each { |serie| serie.restart } if restart_sources
        @next_values = Array.new(@sources.size)
      end

      private def _next_value

        values = @next_values.each_index.collect { |i| @next_values[i] || (@next_values[i] = @sources[i].next_value) }

        time = values.collect { |_| _&.[](:time) }.compact.min

        if time
          results = values.select { |_| _&.[](:time) == time }

          @next_values.each_index do |i|
            @next_values[i] = nil if @next_values[i]&.[](:time) == time
          end

          { time: time,
            value: results.collect { |_| _[:value] }.inject(:merge) }
        else
          nil
        end

      end

      def infinite?
        !!@sources.find(&:infinite?)
      end
    end

    private_constant :UnionTimed
  end
end
