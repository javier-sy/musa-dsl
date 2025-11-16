require_relative 'e'

require_relative 'score/queriable'
require_relative 'score/to-mxml/to-mxml'
require_relative 'score/render'

require_relative '../core-ext/inspect-nice'

module Musa::Datasets
  # Time-indexed container for musical events.
  #
  # Score organizes musical events along a timeline, storing them at specific
  # time points and providing efficient queries for time intervals.
  # Implements {Enumerable} for iteration over time slots.
  #
  # ## Purpose
  #
  # Score provides:
  # - **Time-indexed storage**: Events organized by start time (Rational)
  # - **Interval queries**: Find events in time ranges ({#between}, {#changes_between})
  # - **Duration tracking**: Automatically tracks event durations
  # - **Export formats**: MusicXML export via {ToMXML}
  # - **Rendering**: MIDI rendering via {Render}
  # - **Filtering**: Create subsets via {#subset}
  #
  # ## Structure
  #
  # Internally maintains two structures:
  # - **@score**: Hash mapping time → Array of events
  # - **@indexer**: Array of { start, finish, dataset } for interval queries
  #
  # ## Event Requirements
  #
  # Events must:
  # - Extend {Abs} (absolute values, not deltas)
  # - Have a :duration key (from {AbsD})
  #
  # ## Time Representation
  #
  # All times are stored as Rational numbers for exact arithmetic:
  #
  #     score.at(0r, add: event)    # At time 0
  #     score.at(1/4r, add: event)  # At quarter note
  #
  # @example Create empty score
  #   score = Musa::Datasets::Score.new
  #
  # @example Create from hash
  #   score = Score.new({
  #     0r => [{ pitch: 60, duration: 1.0 }.extend(PDV)],
  #     1r => [{ pitch: 64, duration: 1.0 }.extend(PDV)]
  #   })
  #
  # @example Add events
  #   score = Score.new
  #   gdv1 = { grade: 0, duration: 1.0 }.extend(GDV)
  #   gdv2 = { grade: 2, duration: 1.0 }.extend(GDV)
  #   score.at(0r, add: gdv1)
  #   score.at(1r, add: gdv2)
  #
  # @example Query time interval
  #   events = score.between(0r, 2r)
  #   # Returns all events starting in [0, 2) or overlapping interval
  #
  # @example Filter events
  #   high_notes = score.subset { |event| event[:pitch] > 60 }
  #
  # @example Get all positions
  #   score.positions  # => [0r, 1r, 2r, ...]
  #
  # @example Get duration
  #   score.duration  # => Latest finish time - 1r
  #
  # @see Abs Absolute events (required for score)
  # @see AbsD Duration events (provides :duration)
  # @see ToMXML MusicXML export
  # @see Render MIDI rendering
  # @see Queriable Query capabilities
  class Score
    include Enumerable

    include AbsD
    NaturalKeys = NaturalKeys.freeze

    include ToMXML
    include Queriable
    include Render

    using Musa::Extension::InspectNice

    # Creates new score.
    #
    # @param hash [Hash{Rational => Array<Abs>}, nil] optional initial events
    #   Hash mapping times to arrays of events
    #
    # @raise [ArgumentError] if hash values aren't Arrays
    #
    # @example Empty score
    #   score = Score.new
    #
    # @example With initial events
    #   score = Score.new({
    #     0r => [{ pitch: 60, duration: 1.0 }.extend(PDV)],
    #     1r => [{ pitch: 64, duration: 1.0 }.extend(PDV)]
    #   })
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

    # Clears all events from score.
    #
    # @return [void]
    #
    # @example
    #   score.reset
    #   score.size  # => 0
    def reset
      @score.clear
      @indexer.clear
    end

    # Gets attribute value.
    #
    # Supports accessing natural keys like :duration, :finish.
    #
    # @param key [Symbol] attribute name
    # @return [Object, nil] attribute value
    #
    # @api private
    def [](key)
      if NaturalKeys.include?(key) && self.respond_to?(key)
        self.send(key)
      end
    end

    # Returns latest finish time of all events.
    #
    # @return [Rational, nil] latest finish time, or nil if score is empty
    #
    # @example
    #   score.at(0r, add: { duration: 2.0 }.extend(AbsD))
    #   score.finish  # => 2r
    def finish
      @indexer.collect { |i| i[:finish] }.max
    end

    # Returns total duration of score.
    #
    # Calculated as finish time minus 1.
    #
    # @return [Rational] total duration
    #
    # @example
    #   score.at(0r, add: { duration: 2.0 }.extend(AbsD))
    #   score.duration  # => 1r (finish 2r - 1r)
    def duration
      (finish || 1r) - 1r
    end

    # Adds event at time or gets time slot.
    #
    # Without add parameter, returns array of events at that time.
    # With add parameter, adds event to that time slot.
    #
    # @param time [Numeric] time position (converted to Rational)
    # @param add [Abs, nil] event to add (must extend {Abs} and have :duration)
    #
    # @return [Array<Abs>, nil] time slot if no add, nil if adding
    #
    # @raise [ArgumentError] if add is not an Abs dataset
    #
    # @example Add event
    #   gdv = { grade: 0, duration: 1.0 }.extend(GDV)
    #   score.at(0r, add: gdv)
    #
    # @example Get time slot
    #   events = score.at(0r)  # => Array of events at time 0
    #
    # @example Multiple events at same time (chord)
    #   score.at(0r, add: { pitch: 60, duration: 1.0 }.extend(PDV))
    #   score.at(0r, add: { pitch: 64, duration: 1.0 }.extend(PDV))
    #   score.at(0r).size  # => 2
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

    # Returns number of time positions.
    #
    # @return [Integer] number of distinct time positions
    #
    # @example
    #   score.at(0r, add: event1)
    #   score.at(0r, add: event2)  # Same time
    #   score.at(1r, add: event3)  # Different time
    #   score.size  # => 2 (two time positions)
    def size
      @score.keys.size
    end

    # Returns all time positions sorted.
    #
    # @return [Array<Rational>] sorted time positions
    #
    # @example
    #   score.at(1r, add: event1)
    #   score.at(0r, add: event2)
    #   score.positions  # => [0r, 1r]
    def positions
      @score.keys.sort
    end

    # Iterates over time slots in order.
    #
    # Yields [time, events] pairs sorted by time.
    # Implements {Enumerable}.
    #
    # @yieldparam time [Rational] time position
    # @yieldparam events [Array<Abs>] events at that time
    #
    # @return [void]
    #
    # @example
    #   score.each do |time, events|
    #     puts "At #{time}: #{events.size} event(s)"
    #   end
    def each(&block)
      @score.sort.each(&block)
    end

    # Converts to hash representation.
    #
    # @return [Hash{Rational => Array<Abs>}] time → events mapping
    #
    # @example
    #   hash = score.to_h
    #   # => { 0r => [event1, event2], 1r => [event3] }
    def to_h
      @score.sort.to_h
    end

    # Queries events overlapping time interval.
    #
    # Returns events that are active (playing) during the interval [start, finish).
    # Interval uses closed start (included) and open finish (excluded).
    #
    # Events are included if they:
    # - Start before interval finish AND finish after interval start
    # - OR are instant events (start == finish) at interval instant
    #
    # @param closed_interval_start [Rational] interval start (included)
    # @param open_interval_finish [Rational] interval finish (excluded)
    #
    # @return [Array<Hash>] array of event info hashes with:
    #   - **:start**: Event start time
    #   - **:finish**: Event finish time
    #   - **:start_in_interval**: Effective start within interval
    #   - **:finish_in_interval**: Effective finish within interval
    #   - **:dataset**: The event dataset
    #
    # @example Query bar
    #   events = score.between(0r, 4r)
    #   # Returns all events overlapping [0, 4)
    #
    # @example Long note spans interval
    #   score.at(0r, add: { duration: 10.0 }.extend(AbsD))
    #   events = score.between(2r, 4r)
    #   # Event included (started before 4, finishes after 2)
    #   # start_in_interval: 2r, finish_in_interval: 4r
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

    # Queries start/finish change events in interval.
    #
    # Returns timeline of note-on/note-off style events for the interval.
    # Useful for real-time rendering or event-based processing.
    #
    # Returns events sorted by time, with :finish events before :start
    # events at the same time (to avoid gaps).
    #
    # @param closed_interval_start [Rational] interval start (included)
    # @param open_interval_finish [Rational] interval finish (excluded)
    #
    # @return [Array<Hash>] array of change event hashes with:
    #   - **:change**: :start or :finish
    #   - **:time**: When change occurs
    #   - **:start**: Event start time
    #   - **:finish**: Event finish time
    #   - **:start_in_interval**: Effective start within interval
    #   - **:finish_in_interval**: Effective finish within interval
    #   - **:time_in_interval**: Effective change time within interval
    #   - **:dataset**: The event dataset
    #
    # @example Get all changes in bar
    #   changes = score.changes_between(0r, 4r)
    #   changes.each do |change|
    #     case change[:change]
    #     when :start
    #       puts "Note ON at #{change[:time]}"
    #     when :finish
    #       puts "Note OFF at #{change[:time]}"
    #     end
    #   end
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

    # Collects all values for an attribute.
    #
    # Returns set of all unique values across all events.
    #
    # @param attribute [Symbol] attribute key
    #
    # @return [Set] set of unique values
    #
    # @example Get all pitches
    #   pitches = score.values_of(:pitch)
    #   # => #<Set: {60, 64, 67}>
    #
    # @example Get all grades
    #   grades = score.values_of(:grade)
    #   # => #<Set: {0, 2, 4}>
    def values_of(attribute)
      values = Set[]
      @score.each_value do |slot|
        slot.each { |dataset| values << dataset[attribute] }
      end
      values
    end

    # Creates filtered subset of score.
    #
    # Returns new Score containing only events matching the condition.
    #
    # @yieldparam dataset [Abs] each event dataset
    # @yieldreturn [Boolean] true to include event
    #
    # @return [Score] new filtered score
    #
    # @raise [ArgumentError] if no block given
    #
    # @example Filter by pitch
    #   high_notes = score.subset { |event| event[:pitch] > 60 }
    #
    # @example Filter by attribute presence
    #   staccato_notes = score.subset { |event| event[:staccato] }
    #
    # @example Filter by grade
    #   tonic_notes = score.subset { |event| event[:grade] == 0 }
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

    # Returns formatted string representation.
    #
    # Produces multiline representation suitable for inspection.
    #
    # @return [String] formatted score representation
    #
    # @api private
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
