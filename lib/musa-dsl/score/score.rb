require_relative '../datasets'

module Musa::Score

  module Queryable
    def group_by_attribute(attribute)
      group_by { |e| e[attribute] }
    end

    def select_attribute(attribute, value = nil)
      if value.nil?
        select { |e| !e[attribute].nil? }
      else
        select { |e| e[attribute] == value }
      end
    end

    def sort_by_attribute(attribute)
      select_attribute(attribute).sort_by { |e| e[attribute] }
    end
  end

  module QueryableByDataset
    def group_by_dataset_attribute(attribute)
      group_by { |e| e[:dataset][attribute] }
    end

    def select_dataset_attribute(attribute, value = nil)
      if value.nil?
        select { |e| !e[:dataset][attribute].nil? }
      else
        select { |e| e[:dataset][attribute] == value }
      end
    end

    def sort_by_dataset_attribute(attribute)
      select_dataset_attribute(attribute).sort_by { |e| e[:dataset][attribute] }
    end
  end

  private_constant :Queryable

  class Score
    include Enumerable

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
      raise ArgumentError, "#{add} is not a Dataset" unless add&.is_a?(Musa::Datasets::Dataset)

      time = time.rationalize

      slot = @score[time] ||= [].extend(Queryable)

      slot << add

      @indexer << { start: time, finish: time + (add[:duration] || @resolution).rationalize - @resolution, dataset: add }

      nil
    end

    def [](time)
      time = time.rationalize
      @score[time.rationalize] ||= [].extend(Queryable)
    end

    def times
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

    def finish
      @indexer.collect { |i| i[:finish] }.max
    end
  end
end