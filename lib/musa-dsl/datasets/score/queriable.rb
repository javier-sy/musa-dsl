module Musa::Datasets
  class Score
    # Query extensions for Score result sets.
    #
    # Queriable provides mixins that extend query results from Score methods
    # with convenient filtering, grouping, and sorting capabilities.
    #
    # Two result types are supported:
    # - **Time slot queries**: Direct event arrays from {Score#at}
    # - **Interval queries**: Result hashes from {Score#between} and {Score#changes_between}
    #
    # These modules are applied automatically to query results and provide
    # chainable query methods for further filtering.
    #
    # The examples below are written against a score holding a chord at 0r and a
    # single note at 1r:
    #
    #     score = Score.new({ 0r => [{ pitch: 60, duration: 1r, velocity: 1 }.extend(PDV),
    #                                { pitch: 64, duration: 1r, staccato: true }.extend(PDV)],
    #                         1r => [{ pitch: 67, duration: 1r }.extend(PDV)] })
    #     events = score.at(0r)
    #     results = score.between(0r, 4r)
    #
    # @see Score Score class using these modules
    module Queriable
      # Query methods for time slot arrays.
      #
      # QueryableByTimeSlot extends Arrays returned by {Score#at} with query methods.
      # Each event in the array is a dataset (hash) with musical attributes.
      #
      # Methods access attributes directly on events.
      #
      # @example Group events by pitch
      #   events = score.at(0r)  # Returns array extended with QueryableByTimeSlot
      #   events.group_by_attribute(:pitch)
      #   # => { 60 => [{ pitch: 60, duration: (1/1), velocity: 1 }],
      #   #      64 => [{ pitch: 64, duration: (1/1), staccato: true }] }
      #
      # @example Select events with attribute
      #   events.select_by_attribute(:staccato)
      #   # => [{ pitch: 64, duration: (1/1), staccato: true }]
      #
      #   # By presence, not by truth: an attribute set to false would be kept.
      #
      # @example Select by value
      #   events.select_by_attribute(:velocity, 1)
      #   # => [{ pitch: 60, duration: (1/1), velocity: 1 }]
      #
      # @api private
      module QueryableByTimeSlot
        # Groups events by attribute value.
        #
        # @param attribute [Symbol] attribute to group by
        #
        # @return [Hash{Object => Array}] grouped events, values extended with QueryableByTimeSlot
        #
        # @example Group by grade
        #   by_grade = events.group_by_attribute(:grade)
        #   # => { 0 => [events with grade 0], 2 => [events with grade 2] }
        def group_by_attribute(attribute)
          group_by { |e| e[attribute] }.transform_values! { |e| e.extend(QueryableByTimeSlot) }
        end

        # Selects events by attribute presence or value.
        #
        # Without value: selects events where attribute is not nil.
        # With value: selects events where attribute equals value.
        #
        # @param attribute [Symbol] attribute to filter by
        # @param value [Object, nil] optional value to match
        #
        # @return [Array] filtered events, extended with QueryableByTimeSlot
        #
        # @example Select with attribute present
        #   events.select_by_attribute(:staccato)
        #   # => [{ pitch: 64, duration: (1/1), staccato: true }]
        #
        # @example Select by specific value
        #   events.select_by_attribute(:pitch, 60)
        #   # => [{ pitch: 60, duration: (1/1), velocity: 1 }]
        def select_by_attribute(attribute, value = nil)
          if value.nil?
            select { |e| !e[attribute].nil? }
          else
            select { |e| e[attribute] == value }
          end.extend(QueryableByTimeSlot)
        end

        # Sorts events by attribute value.
        #
        # First filters to events with the attribute, then sorts by its value.
        #
        # @param attribute [Symbol] attribute to sort by
        #
        # @return [Array] sorted events, extended with QueryableByTimeSlot
        #
        # @example Sort by pitch
        #   events.sort_by_attribute(:pitch).map { |e| e[:pitch] }  # => [60, 64]
        #
        #   # It filters before it sorts: an event without the attribute is not
        #   # sorted last, it is dropped.
        def sort_by_attribute(attribute)
          select_by_attribute(attribute).sort_by { |e| e[attribute] }.extend(QueryableByTimeSlot)
        end
      end

      private_constant :QueryableByTimeSlot

      # Query methods for interval query results.
      #
      # QueryableByDataset extends Arrays returned by {Score#between} and
      # {Score#changes_between} with query methods. Each element is a hash
      # containing timing info and a :dataset key with the event.
      #
      # Methods access attributes through the :dataset key.
      #
      # @example Interval query result structure
      #   results = score.between(0r, 4r)
      #   results.first
      #   # => { start: (0/1), finish: (1/1),
      #   #      start_in_interval: (0/1), finish_in_interval: (1/1),
      #   #      dataset: { pitch: 60, duration: (1/1), velocity: 1 } }
      #
      # @example Group by pitch
      #   results.group_by_attribute(:pitch).keys  # => [60, 64, 67]
      #
      #   # Grouped by event[:dataset][:pitch], and the 67 at 1r is here too:
      #   # `between` is an interval, not a time slot.
      #
      # @example Select with custom condition
      #   high = results.subset { |event| event[:pitch] > 60 }
      #   high.map { |r| r[:dataset][:pitch] }  # => [64, 67]
      #
      #   # The block is given the DATASET; what comes back is the wrapper. This
      #   # is the one asymmetry of the module, and the reason the two are not
      #   # the same call.
      #
      # @api private
      module QueryableByDataset
        # Groups results by dataset attribute value.
        #
        # @param attribute [Symbol] dataset attribute to group by
        #
        # @return [Hash{Object => Array}] grouped results, values extended with QueryableByDataset
        #
        # @example Group by velocity
        #   by_velocity = results.group_by_attribute(:velocity)
        #   # => { 0 => [results with velocity 0], 1 => [results with velocity 1] }
        def group_by_attribute(attribute)
          group_by { |e| e[:dataset][attribute] }.transform_values! { |e| e.extend(QueryableByDataset) }
        end

        # Selects results by dataset attribute presence or value.
        #
        # Without value: selects where dataset attribute is not nil.
        # With value: selects where dataset attribute equals value.
        #
        # @param attribute [Symbol] dataset attribute to filter by
        # @param value [Object, nil] optional value to match
        #
        # @return [Array] filtered results, extended with QueryableByDataset
        #
        # @example Select with attribute
        #   results.select_by_attribute(:staccato).map { |r| r[:dataset][:pitch] }
        #   # => [64]
        #
        # @example Select by value
        #   results.select_by_attribute(:velocity, 1).map { |r| r[:dataset][:pitch] }
        #   # => [60]
        #
        #   # Over an attribute these events do not carry, nothing raises and
        #   # nothing matches:
        #   results.select_by_attribute(:grade, 0)  # => []
        def select_by_attribute(attribute, value = nil)
          if value.nil?
            select { |e| !e[:dataset][attribute].nil? }
          else
            select { |e| e[:dataset][attribute] == value }
          end.extend(QueryableByDataset)
        end

        # Filters results by custom condition on dataset.
        #
        # @yieldparam dataset [Hash] event dataset
        # @yieldreturn [Boolean] true to include result
        #
        # @return [Array] filtered results, extended with QueryableByDataset
        #
        # @raise [ArgumentError] if no block given
        #
        # @example Filter by pitch range
        #   results.subset { |event| event[:pitch] > 60 && event[:pitch] < 72 }
        #         .map { |r| r[:dataset][:pitch] }
        #   # => [64, 67]
        #
        # @example Filter by multiple conditions
        #   results.subset { |event| event[:velocity] == 1 && event[:pitch] < 64 }
        #         .map { |r| r[:dataset][:pitch] }
        #   # => [60]
        #
        #   # An event without :velocity does not raise -- nil fails the
        #   # comparison and it is simply not selected.
        def subset
          raise ArgumentError, "subset needs a block with the inclusion condition on the dataset" unless block_given?
          select { |e| yield e[:dataset] }.extend(QueryableByDataset)
        end

        # Sorts results by dataset attribute value.
        #
        # First filters to results with the attribute, then sorts by its value.
        #
        # @param attribute [Symbol] dataset attribute to sort by
        #
        # @return [Array] sorted results, extended with QueryableByDataset
        #
        # @example Sort by start time within interval
        #   results.sort_by_attribute(:pitch).map { |r| r[:dataset][:pitch] }
        #   # => [60, 64, 67]
        def sort_by_attribute(attribute)
          select_by_attribute(attribute).sort_by { |e| e[:dataset][attribute] }.extend(QueryableByDataset)
        end
      end

      private_constant :QueryableByDataset
    end
  end; end
