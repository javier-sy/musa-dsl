require_relative 'e'

module Musa::Datasets
  class Score
    include Enumerable

    require_relative 'score-to-mxml/to-mxml'
    include Musa::Datasets::Score::ToMXML

    def initialize(resolution)
      @resolution = resolution.rationalize
      @score = {}
      @indexer = []
    end

    attr_reader :resolution

    def reset
      @score.clear
      @indexer.clear
    end

    def at(time, add:)
      raise ArgumentError, "#{add} is not a Abs dataset" unless add&.is_a?(Musa::Datasets::Abs)

      time = time.rationalize

      slot = @score[time] ||= [].extend(QueryableByTimeSlot)

      slot << add

      @indexer << { start: time,
                    finish: time + (add.duration || @resolution).rationalize - @resolution,
                    dataset: add }

      nil
    end

    def [](time)
      time = time.rationalize
      @score[time.rationalize] ||= [].extend(QueryableByTimeSlot)
    end

    def size
      @score.keys.size
    end

    def positions
      @score.keys.sort
    end

    def each(&block)
      @score.sort.each(&block)
    end

    def between(closed_interval_start, open_interval_finish)
      @indexer
          .select { |i| i[:start] <= closed_interval_start && i[:finish] >= closed_interval_start ||
                        i[:start] < open_interval_finish && i[:finish] >= open_interval_finish ||
                        i[:start] >= closed_interval_start && i[:finish] < open_interval_finish }
          .sort_by { |i| i[:start] }
          .collect { |i| { start: i[:start], finish: i[:finish], dataset: i[:dataset] } }.extend(QueryableByDataset)
    end

    def changes_between(closed_interval_start, open_interval_finish)
      ( @indexer
          .select { |i| i[:start] >= closed_interval_start && i[:start] < open_interval_finish }
          .collect { |i| i.clone.merge({ change: :start, time: i[:start] }) } +
        @indexer
          .select { |i| i[:finish] >= closed_interval_start && i[:finish] < open_interval_finish }
          .collect { |i| i.clone.merge({ change: :finish, time: i[:finish] }) } )
        .sort_by { |i| i[:time] }
        .collect { |i| { change: i[:change], time: i[:time],
                         start: i[:start],
                         finish: i[:finish],
                         dataset: i[:dataset] } }.extend(QueryableByDataset)
    end

    def values_of(attribute)
      values = Set[]
      @score.each_value do |slot|
        slot.each { |dataset| values << dataset[attribute] }
      end
      values
    end

    def subset
      raise ArgumentError, "subset needs a block with the inclusion condition on the dataset" unless block_given?

      filtered_score = Score.new(@resolution)

      @score.each_pair do |time, datasets|
        datasets.each do |dataset|
          filtered_score.at time, add: dataset if yield(dataset)
        end
      end

      filtered_score
    end

    def finish
      @indexer.collect { |i| i[:finish] }.max
    end
  end

  module QueryableByTimeSlot
    def group_by_attribute(attribute)
      group_by { |e| e[attribute] }.transform_values! { |e| e.extend(QueryableByTimeSlot) }
    end

    def select_by_attribute(attribute, value = nil)
      if value.nil?
        select { |e| !e[attribute].nil? }
      else
        select { |e| e[attribute] == value }
      end.extend(QueryableByTimeSlot)
    end

    def sort_by_attribute(attribute)
      select_by_attribute(attribute).sort_by { |e| e[attribute] }.extend(QueryableByTimeSlot)
    end
  end

  private_constant :QueryableByTimeSlot

  module QueryableByDataset
    def group_by_attribute(attribute)
      group_by { |e| e[:dataset][attribute] }.transform_values! { |e| e.extend(QueryableByDataset) }
    end

    def select_by_attribute(attribute, value = nil)
      if value.nil?
        select { |e| !e[:dataset][attribute].nil? }
      else
        select { |e| e[:dataset][attribute] == value }
      end.extend(QueryableByDataset)
    end

    def subset
      raise ArgumentError, "subset needs a block with the inclusion condition on the dataset" unless block_given?
      select { |e| yield e[:dataset] }.extend(QueryableByDataset)
    end

    def sort_by_attribute(attribute)
      select_by_attribute(attribute).sort_by { |e| e[:dataset][attribute] }.extend(QueryableByDataset)
    end
  end

  private_constant :QueryableByDataset
end
