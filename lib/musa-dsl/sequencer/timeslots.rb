require 'set'

module Musa
  module Sequencer
    class BaseSequencer
      # Sorted time-indexed event storage for sequencer.
      #
      # Timeslots extends Hash to maintain scheduled events indexed by time,
      # with efficient sorted access for sequential playback. Each timeslot
      # (key) maps to an array of events scheduled at that time.
      #
      # ## Implementation
      #
      # Uses a SortedSet to track keys in temporal order, enabling fast
      # lookup of next scheduled event without full hash traversal.
      #
      # ## Usage
      #
      # - **Store**: `timeslots[time] = events` schedules events at time
      # - **Retrieve**: `timeslots[time]` gets events at specific time
      # - **Next**: `first_after(pos)` finds next scheduled time >= position
      # - **Delete**: `delete(time)` removes timeslot and updates sort index
      #
      # ## Time Representation
      #
      # Times are Rational numbers representing musical beats/ticks.
      # Granularity depends on sequencer configuration (tick-based or tickless).
      #
      # @example Scheduling events
      #   timeslots = Timeslots.new
      #   timeslots[0r] = [event1, event2]    # Events at time 0
      #   timeslots[1/2r] = [event3]          # Event at beat 0.5
      #   timeslots[1r] = [event4, event5]    # Events at beat 1
      #
      # @example Finding next event
      #   next_time = timeslots.first_after(0.5)  # => 1r
      #   events = timeslots[next_time]           # => [event4, event5]
      #
      # @api private
      class Timeslots < Hash

        # Creates empty timeslots storage.
        #
        # @param several_variants [Array] optional Hash initialization parameters
        # @api private
        def initialize(*several_variants)
          super
          @sorted_keys = SortedSet.new
        end

        # Stores events at time, maintaining sort index.
        #
        # @param key [Rational] time position
        # @param value [Array, Object] events at this time
        #
        # @return [Array, Object] stored value
        # @api private
        def []=(key, value)
          super
          @sorted_keys << key
        end

        # Removes timeslot, updating sort index.
        #
        # @param key [Rational] time position to remove
        #
        # @return [Array, Object, nil] removed value
        # @api private
        def delete(key)
          super
          @sorted_keys.delete key

        end

        # Finds first scheduled time at or after position.
        #
        # Used by sequencer to find next event to execute during playback.
        #
        # @param position [Rational, nil] search position (nil for first overall)
        #
        # @return [Rational, nil] next scheduled time, or nil if none
        #
        # @example
        #   timeslots[1r] = [:event_a]
        #   timeslots[2r] = [:event_b]
        #   timeslots[3r] = [:event_c]
        #
        #   timeslots.first_after(nil)   # => 1r
        #   timeslots.first_after(0r)    # => 1r
        #   timeslots.first_after(1r)    # => 1r
        #   timeslots.first_after(1.5r)  # => 2r
        #   timeslots.first_after(3r)    # => 3r
        #   timeslots.first_after(4r)    # => nil
        #
        # @api private
        def first_after(position)
          if position.nil?
            @sorted_keys.first
          else
            @sorted_keys.find { |k| k >= position }
          end
        end
      end
    end

    private_constant :Timeslots
  end
end
