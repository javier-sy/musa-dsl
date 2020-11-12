require_relative '../datasets/e'

module Musa
  module Series

    extend self

    def TIMED_UNION(*timed_series)
      TimedUnion.new(timed_series)
    end

    class TimedUnion
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
        @sources_next_values = Array.new(@sources.size)

        @components = nil
        @hash_mode = @array_mode = nil
      end

      private def _next_value
        sources_values = @sources_next_values.each_index.collect do |i|
          @sources_next_values[i] || (@sources_next_values[i] = @sources[i].next_value)
        end

        infer_components(sources_values) if !@components

        time = sources_values.collect { |_| _&.[](:time) }.compact.min

        if time
          selected_values = sources_values.collect { |_| _ if _&.[](:time) == time }

          @sources_next_values.each_index do |i|
            if @sources_next_values[i]&.[](:time) == time
              @sources_next_values[i] = nil
            end
          end

          if @hash_mode
            result = {}
          elsif @array_mode
            result = []
          else # value mode
            result = []
          end

          @components.each do |target_key_or_index, source_placement|
            result[target_key_or_index] = selected_values.dig(*source_placement)
          end

          { time: time,
            value: result }
        else
          nil
        end
      end

      def infinite?
        !!@sources.find(&:infinite?)
      end
    end

    private def infer_components(sources_values)
      @components = {}
      target_index = 0

      sources_values.each_with_index do |source_value, i|
        case source_value[:value]
        when Hash
          @hash_mode = true

          source_value[:value].keys.each do |key|
            @components[key] = [i, :value, key]
          end
        when Array
          @array_mode = true

          (0..source_value[:value].size - 1).each do |index|
            @components[target_index] = [i, :value, index]
            target_index += 1
          end
        else
          @components[target_index] = [i, :value]
          target_index += 1
        end
      end

      raise RuntimeError, "source series values are of incompatible type (can't combine Hash and Array values)" if @array_mode && @hash_mode
    end

    private_constant :TimedUnion
  end
end
