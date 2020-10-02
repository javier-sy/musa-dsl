require_relative 'e'

require_relative 'score/queriable'
require_relative 'score/to-mxml/to-mxml'
require_relative 'score/render'

require_relative '../core-ext/inspect-nice'

module Musa::Datasets
  class Score
    include Enumerable

    include AbsD
    NaturalKeys = NaturalKeys.freeze

    include ToMXML
    include Queriable
    include Render

    using Musa::Extension::InspectNice

    def initialize(hash = nil)
      raise ArgumentError, "'hash' parameter should be a Hash with time and events information" unless hash.nil? || hash.is_a?(Hash)

      @score = {}
      @indexer = []

      if hash
        hash.sort.each do |k, v|
          raise ArgumentError, "'hash' values for time #{k} should be an Array of events" unless v.is_a?(Array)

          v.each do |vv|
            at(k, add: vv)
          end
        end
      end
    end

    def reset
      @score.clear
      @indexer.clear
    end

    def [](key)
      if NaturalKeys.include?(key) && self.respond_to?(key)
        self.send(key)
      end
    end

    def finish
      @indexer.collect { |i| i[:finish] }.max
    end

    def duration
      (finish || 1r) - 1r
    end

    def at(time, add: nil)
      time = time.rationalize

      if add
        raise ArgumentError, "#{add} is not a Abs dataset" unless add&.is_a?(Musa::Datasets::Abs)

        slot = @score[time] ||= [].extend(QueryableByTimeSlot)

        slot << add

        @indexer << { start: time,
                      finish: time + add.duration.rationalize,
                      dataset: add }

        nil
      else
        @score[time] ||= [].extend(QueryableByTimeSlot)
      end
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

    def to_h
      @score.sort.to_h
    end

    def between(closed_interval_start, open_interval_finish)
      @indexer
        .select { |i| i[:start] < open_interval_finish && i[:finish] > closed_interval_start ||
                      closed_interval_start == open_interval_finish &&
                          i[:start] == i[:finish] &&
                          i[:start] == closed_interval_start }
        .sort_by { |i| i[:start] }
        .collect { |i| { start: i[:start],
                         finish: i[:finish],
                         start_in_interval: i[:start] > closed_interval_start ? i[:start] : closed_interval_start,
                         finish_in_interval: i[:finish] < open_interval_finish ? i[:finish] : open_interval_finish,
                         dataset: i[:dataset] } }.extend(QueryableByDataset)
    end

    # TODO hay que implementar un effective_start y effective_finish con el inicio/fin dentro del bar, no absoluto

    def changes_between(closed_interval_start, open_interval_finish)
      (
        #
        # we have a start event if the element
        # begins between queried interval start (included) and interval finish (excluded)
        #
        @indexer
          .select { |i| i[:start] >= closed_interval_start && i[:start] < open_interval_finish }
          .collect { |i| i.clone.merge({ change: :start, time: i[:start] }) } +

        #
        # we have a finish event if the element interval finishes
        # between queried interval start (excluded) and queried interval finish (included) or
        # element interval finishes exactly on queried interval start
        # but the element interval started before queried interval start
        # (the element is not an instant)
        #
        @indexer
          .select { |i| ( i[:finish] > closed_interval_start ||
                          i[:finish] == closed_interval_start && i[:finish] == i[:start])   &&
                        ( i[:finish] < open_interval_finish ||
                          i[:finish] == open_interval_finish && i[:start] < open_interval_finish) }
          .collect { |i| i.clone.merge({ change: :finish, time: i[:finish] }) } +

        #
        # when the queried interval has no duration (it's an instant) we have a start and a finish event
        # if the element also is an instant exactly coincident with the queried interval
        #
        @indexer
          .select { |i| ( closed_interval_start == open_interval_finish &&
                          i[:start] == closed_interval_start &&
                          i[:finish] == open_interval_finish) }
          .collect { |i| [i.clone.merge({ change: :start, time: i[:start] }),
                          i.clone.merge({ change: :finish, time: i[:finish] })] }
          .flatten(1)
      )
        .sort_by { |i| [ i[:time],
                         i[:start] < i[:finish] && i[:change] == :finish ? 0 : 1] }
        .collect { |i| { change: i[:change],
                         time: i[:time],
                         start: i[:start],
                         finish: i[:finish],
                         start_in_interval: i[:start] > closed_interval_start ? i[:start] : closed_interval_start,
                         finish_in_interval: i[:finish] < open_interval_finish ? i[:finish] : open_interval_finish,
                         time_in_interval: if i[:time] < closed_interval_start
                                             closed_interval_start
                                           elsif i[:time] > open_interval_finish
                                             open_interval_finish
                                           else
                                             i[:time]
                                           end,
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

      filtered_score = Score.new

      @score.each_pair do |time, datasets|
        datasets.each do |dataset|
          filtered_score.at time, add: dataset if yield(dataset)
        end
      end

      filtered_score
    end

    def inspect
      s = StringIO.new

      first_level1 = true

      s.write "Musa::Datasets::Score.new({\n"

      @score.each do |k, v|
        s.write "#{ ", \n" unless first_level1 }  #{ k.inspect } => [\n"
        first_level1 = false
        first_level2 = true

        v.each do |vv|
          s.write "#{ ", \n" unless first_level2 }\t#{ vv }"
          first_level2 = false
        end

        s.write  " ]"
      end
      s.write "\n})"

      s.string
    end
  end
end
