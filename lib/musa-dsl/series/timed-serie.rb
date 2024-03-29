require_relative '../datasets/e'

require_relative 'base-series'

module Musa
  module Series::Constructors
    def TIMED_UNION(*array_of_timed_series, **hash_of_timed_series)
      raise ArgumentError, 'Can\'t union an array of series with a hash of series' if array_of_timed_series.any? && hash_of_timed_series.any?

      if array_of_timed_series.any?
        TimedUnionOfArrayOfTimedSeries.new(array_of_timed_series)
      elsif hash_of_timed_series.any?
        TimedUnionOfHashOfTimedSeries.new(hash_of_timed_series)
      else
        raise ArgumentError, 'Missing argument series'
      end
    end

    class TimedUnionOfArrayOfTimedSeries
      include Series::Serie.with(sources: true)

      def initialize(series)
        self.sources = series
        init
      end

      private def _init
        @sources_next_values = Array.new(@sources.size)
        @components = nil
      end

      private def _restart
        @sources.each(&:restart)
      end

      private def _next_value
        sources_values = @sources_next_values.each_index.collect do |i|
          @sources_next_values[i] || (@sources_next_values[i] = @sources[i].next_value)
        end

        @components, @hash_mode, @array_mode = infer_components(sources_values) unless @components

        time = sources_values.collect { |_| _&.[](:time) }.compact.min

        if time
          selected_values = sources_values.collect { |_| _ if _&.[](:time) == time }

          @sources_next_values.each_index do |i|
            if @sources_next_values[i]&.[](:time) == time
              @sources_next_values[i] = nil
            end
          end

          result = { time: time }

          @components.each do |attribute_name, components|
            result[attribute_name] = if @hash_mode
                                       {}
                                     elsif @array_mode
                                       []
                                     else # value mode
                                       []
                                     end

            components.each do |target_key_or_index, source_placement|
              result[attribute_name][target_key_or_index] = selected_values.dig(*source_placement)
            end
          end

          result.extend(Musa::Datasets::AbsTimed)
        else
          nil
        end
      end

      def infinite?
        !!@sources.find(&:infinite?)
      end

      private def infer_components(sources_values)
        other_attributes = Set[]

        sources_values.each do |source_value|
          (source_value.keys - [:time, :value]).each { |_| other_attributes << _ }
        end

        components = {}
        components[:value] = {}

        hash_mode = array_mode = nil

        other_attributes.each do |attribute_name|
          components[attribute_name] = {}
        end

        target_index = 0

        sources_values.each_with_index do |source_value, i|
          case source_value[:value]
          when Hash
            hash_mode = true

            source_value[:value].each_key do |key|
              raise "Value: key #{key} already used" unless components[:value][key].nil?

              components[:value][key] = [i, :value, key]

              other_attributes.each do |attribute_name|
                raise "Attribute #{attribute_name}: key #{key} already used" unless components[attribute_name][key].nil?

                components[attribute_name][key] = [i, attribute_name, key]
              end
            end
          when Array
            array_mode = true

            (0..source_value[:value].size - 1).each do |index|
              components[:value][target_index] = [i, :value, index]

              other_attributes.each do |attribute_name|
                components[attribute_name][target_index] = [i, attribute_name, index]
              end

              target_index += 1
            end
          else
            components[:value][target_index] = [i, :value]

            other_attributes.each do |attribute_name|
              components[attribute_name][target_index] = [i, attribute_name]
            end

            target_index += 1
          end
        end

        raise "source series values are of incompatible type (can't combine Hash and Array values)" if array_mode && hash_mode

        [components, hash_mode, array_mode]
      end
    end

    private_constant :TimedUnionOfArrayOfTimedSeries

    class TimedUnionOfHashOfTimedSeries
      include Series::Serie.with(sources: true)

      def initialize(series)
        self.sources = series
        init
      end

      def sources=(series)
        super
        @components = series.keys
      end

      private def _init
        @sources_next_values = @components.collect { |k| [k, nil] }.to_h
        @other_attributes = nil
      end

      private def _restart
        @sources.each_value(&:restart)
      end

      private def _next_value
        sources_values = {}

        @components.each do |key|
          sources_values[key] = @sources_next_values[key] || (@sources_next_values[key] = @sources[key].next_value)
        end

        @other_attributes ||= infer_other_attributes(sources_values)

        time = sources_values.values.collect { |_| _&.[](:time) }.compact.min

        if time
          selected_values = sources_values.transform_values { |_| _ if _&.[](:time) == time }

          @sources_next_values.each_key do |key|
            if @sources_next_values[key]&.[](:time) == time
              @sources_next_values[key] = nil
            end
          end

          result = { time: time, value: {} }

          @other_attributes.each do |attribute_name|
            result[attribute_name] = {}
          end

          @components.each do |component|
            result[:value][component] = selected_values[component]&.[](:value)

            @other_attributes.each do |attribute_name|
              result[attribute_name][component] = selected_values[component]&.[](attribute_name)
            end
          end

          result.extend(Musa::Datasets::AbsTimed)
        else
          nil
        end
      end

      def infinite?
        !!@sources.find(&:infinite?)
      end

      private def infer_other_attributes(sources_values)
        other_attributes = Set[]

        sources_values.each_value do |source_value|
          (source_value.keys - [:time, :value]).each do |attribute_name|
            other_attributes << attribute_name
          end
        end

        other_attributes
      end
    end

    private_constant :TimedUnionOfHashOfTimedSeries
  end

  module Series::Operations
    def flatten_timed
      TimedFlattener.new(self)
    end

    def compact_timed
      TimedCompacter.new(self)
    end

    def union_timed(*other_timed_series, key: nil, **other_key_timed_series)
      if key && other_key_timed_series.any?
        Series::Constructors.TIMED_UNION(key => self, **other_key_timed_series)

      elsif other_timed_series.any? && other_key_timed_series.empty?
        Series::Constructors.TIMED_UNION(self, *other_timed_series)

      else
        raise ArgumentError, 'Can\'t union an array of series with a hash of series'
      end
    end

    class TimedFlattener
      include Series::Serie.with(source: true)

      def initialize(serie)
        self.source = serie
        init
      end

      private def _restart
        @source.restart
      end

      private def _next_value
        source_value = @source.next_value

        if !source_value.nil?
          time = source_value[:time]
          source_value_value = source_value[:value]

          source_value_extra = (source_value.keys - [:time, :value]).collect do |attribute_name|
            [attribute_name, source_value[attribute_name]]
          end.to_h

          case source_value_value
          when Hash
            result = {}
            source_value_value.each_pair do |key, value|
              result[key] = { time: time, value: value }.extend(Musa::Datasets::AbsTimed)

              source_value_extra.each do |attribute_name, attribute_value|
                result[key][attribute_name] = attribute_value[key]
              end
            end

          when Array
            result = []
            source_value_value.each_index do |index|
              result[index] = { time: time, value: source_value_value[index] }.extend(Musa::Datasets::AbsTimed)

              source_value_extra.each do |attribute_name, attribute_value|
                result[index][attribute_name] = attribute_value[index]
              end
            end
          else
            result = source_value.clone.extend(Musa::Datasets::AbsTimed)
          end

          result.extend(Musa::Datasets::AbsTimed)
        else
          nil
        end
      end

      def infinite?
        @source.infinite?
      end
    end

    private_constant :TimedFlattener
  end

  class TimedCompacter
    include Series::Serie.with(source: true)

    def initialize(serie)
      self.source = serie
      init
    end

    private def _restart
      @source.restart
    end

    private def _next_value
      while (source_value = @source.next_value) && skip_value?(source_value[:value]); end
      source_value
    end

    def infinite?
      @source.infinite?
    end

    private def skip_value?(timed_value)
      case timed_value
      when Hash
        timed_value.all? { |_, v| v.nil? }
      when Array
        timed_value.all?(&:nil?)
      else
        timed_value.nil?
      end
    end
  end

  private_constant :TimedCompacter
end

