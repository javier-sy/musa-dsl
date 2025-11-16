module Musa
  module Extension
    # Refinement that expands Range objects within arrays into their constituent elements.
    #
    # This is particularly useful in musical contexts where arrays may contain both
    # individual values and ranges (like MIDI note ranges or channel ranges), and you
    # need to work with the fully expanded list.
    #
    # ## Use Cases
    #
    # - Expanding MIDI channel specifications: [0, 2..4, 7] → [0, 2, 3, 4, 7]
    # - Expanding note ranges in chord definitions
    # - Processing mixed literal and range values in musical parameters
    # - Any scenario where ranges need to be flattened for iteration
    #
    # @example Basic usage
    #   using Musa::Extension::ExplodeRanges
    #
    #   [1, 3..5, 8].explode_ranges
    #   # => [1, 3, 4, 5, 8]
    #
    # @example MIDI channels
    #   using Musa::Extension::ExplodeRanges
    #
    #   channels = [0, 2..4, 7, 9..10]
    #   channels.explode_ranges
    #   # => [0, 2, 3, 4, 7, 9, 10]
    #
    # @example Mixed with other array methods
    #   using Musa::Extension::ExplodeRanges
    #
    #   [1..3, 5, 7..9].explode_ranges.map { |n| n * 2 }
    #   # => [2, 4, 6, 10, 14, 16, 18]
    #
    # @see Musa::MIDIVoices::MIDIVoices#initialize Uses this for channel expansion
    # @note This refinement must be activated with `using Musa::Extension::ExplodeRanges`
    module ExplodeRanges
      refine Array do
        # Expands all Range objects in the array into their individual elements.
        #
        # Iterates through the array and converts any Range objects to their
        # constituent elements via `to_a`, leaving non-Range elements unchanged.
        # The result is a new flat array.
        #
        # @return [Array] new array with all ranges expanded.
        #
        # @example Empty ranges
        #   [1, (5..4), 8].explode_ranges  # (5..4) is empty
        #   # => [1, 8]
        #
        # @example Exclusive ranges
        #   [1, (3...6), 9].explode_ranges
        #   # => [1, 3, 4, 5, 9]
        #
        # @example Nested arrays are NOT expanded recursively
        #   [1, [2..4], 5].explode_ranges
        #   # => [1, [2..4], 5]  # Inner range NOT expanded
        def explode_ranges
          array = []

          each do |element|
            if element.is_a? Range
              element.to_a.each { |element| array << element }
            else
              array << element
            end
          end

          array
        end
      end
    end
  end
end
