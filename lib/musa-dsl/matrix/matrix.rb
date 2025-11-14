require 'matrix'

require_relative '../datasets/p'
require_relative '../sequencer'

module Musa
  # Matrix utilities for Musa DSL.
  #
  # This module provides matrix-related functionality, primarily through
  # refinements to Ruby's Array and Matrix classes.
  #
  # @see Musa::Extension::Matrix
  module Matrix
    ## TODO should exist this module?
  end

  module Extension
    # Refinements for Array and Matrix classes to support musical structure conversions.
    #
    # These refinements add methods to convert between matrix representations and
    # Musa's P (point sequence) format, which is used extensively in the DSL for
    # representing musical gestures and trajectories.
    #
    # ## Background
    #
    # In Musa DSL, musical gestures are often represented as sequences of points
    # in multidimensional space, where dimensions can represent time, pitch, velocity,
    # or other musical parameters. The P format provides a compact representation
    # suitable for sequencer playback and transformation.
    #
    # ## Matrix to P Conversion
    #
    # A matrix of points (rows = time steps, columns = parameters) can be converted
    # to P format where:
    # - One dimension represents time (usually the first column)
    # - Other dimensions represent musical parameters
    # - Each P is an array extended with P module
    # - The P contains alternating values (arrays extended with V) and durations (numbers):
    #   [value1, duration1, value2, duration2, ..., valueN].extend(P)
    #
    # ## Use Cases
    #
    # - Converting recorded MIDI data to playable sequences
    # - Transforming algorithmic compositions from matrix form to time-based sequences
    # - Merging fragmented musical gestures that share connection points
    # - Decomposing complex trajectories into simpler monotonic segments
    #
    # @example Basic matrix conversion
    #   using Musa::Extension::Matrix
    #
    #   # Matrix: [time, pitch]
    #   matrix = Matrix[[0, 60], [1, 62], [2, 64]]
    #   p_sequences = matrix.to_p(time_dimension: 0)
    #   # Returns an array with one P:
    #   #   [[60], 1, [62], 1, [64]].extend(P)
    #   # Where [60], [62], [64] are arrays extended with V module
    #
    # @example Multi-dimensional musical parameters
    #   using Musa::Extension::Matrix
    #
    #   # Matrix: [time, pitch, velocity]
    #   matrix = Matrix[[0, 60, 100], [0.5, 62, 110], [1, 64, 120]]
    #   p_sequences = matrix.to_p(time_dimension: 0, keep_time: false)
    #   # Returns an array with one P:
    #   #   [[60, 100], 0.5, [62, 110], 0.5, [64, 120]].extend(P)
    #   # Time dimension removed, used only for duration calculation
    #
    # @example Condensing connected matrices
    #   using Musa::Extension::Matrix
    #
    #   # Two phrases that connect at [1, 62]
    #   phrase1 = Matrix[[0, 60], [1, 62]]
    #   phrase2 = Matrix[[1, 62], [2, 64], [3, 65]]
    #
    #   [phrase1, phrase2].to_p(time_dimension: 0)
    #   # Returns an array with one P (merged):
    #   #   [[60], 1, [62], 1, [64], 1, [65]].extend(P)
    #   # Both phrases merged into one continuous sequence
    #
    # @see Musa::Datasets::P
    # @see Musa::Datasets::V
    # @note These refinements must be activated with `using Musa::Extension::Matrix`
    #   in the scope where you want to use them.
    module Matrix
      refine Array do
        # Creates a hash mapping values to their indices in the array.
        #
        # This method scans the array and builds an inverted index where each
        # unique value maps to an array of positions where it appears.
        #
        # @return [Hash{Object => Array<Integer>}] hash where keys are array values
        #   and values are arrays of indices.
        #
        # @example
        #   [10, 20, 10, 30, 20].indexes_of_values
        #   # => { 10 => [0, 2], 20 => [1, 4], 30 => [3] }
        def indexes_of_values
          indexes = {}

          size.times do |i|
            indexes[self[i]] ||= []
            indexes[self[i]] << i
          end

          indexes
        end

        # Converts an array of matrices to an array of P sequences.
        #
        # This method processes each matrix in the array, first condensing matrices
        # that share common endpoints, then converting each resulting matrix to
        # P (point sequence) format.
        #
        # @param time_dimension [Integer] index of the dimension to treat as time.
        # @param keep_time [Boolean, nil] whether to preserve the time dimension in the output.
        #   When false or nil, the time dimension is removed and used only for duration calculations.
        #
        # @return [Array<Musa::Datasets::P>] array of P sequences, one per condensed matrix.
        #
        # @see #condensed_matrices
        # @see ::Matrix#to_p
        def to_p(time_dimension:, keep_time: nil)
          condensed_matrices.collect { |m| m.to_p(time_dimension: time_dimension, keep_time: keep_time) }
        end

        # Condenses matrices that share common boundary rows.
        #
        # This method merges matrices that have matching first or last rows,
        # effectively connecting musical gestures that share endpoints. This is
        # particularly useful for creating continuous trajectories from fragmented
        # matrix segments.
        #
        # The algorithm compares each matrix with all previously processed matrices,
        # looking for matches at either the beginning or end of the row sequence.
        # When a match is found, the matrices are merged.
        #
        # @return [Array<::Matrix>] condensed array of matrices with shared boundaries merged.
        #
        # @example
        #   # Matrix A ends where Matrix B begins -> they merge
        #   a = Matrix[[0, 60], [1, 62]]
        #   b = Matrix[[1, 62], [2, 64]]
        #   [a, b].condensed_matrices
        #   # => [Matrix[[0, 60], [1, 62], [2, 64]]]
        def condensed_matrices
          condensed = []

          each do |other|
            if condensed.empty?
              condensed << other
            else
              done = false
              condensed.each do |matrix|
                if matrix._rows.first == other._rows.first
                  other._rows.shift
                  matrix._rows.prepend other._rows.shift until other._rows.empty?
                  done = true

                elsif matrix._rows.first == other._rows.last
                  other._rows.pop
                  matrix._rows.prepend other._rows.pop until other._rows.empty?
                  done = true

                elsif matrix._rows.last == other._rows.first
                  other._rows.shift
                  matrix._rows.append other._rows.shift until other._rows.empty?
                  done = true

                elsif matrix._rows.last == other._rows.last
                  other._rows.pop
                  matrix._rows.append other._rows.pop until other._rows.empty?
                  done = true
                end

                break if done
              end
              condensed << other unless done
            end
          end

          condensed
        end
      end

      refine ::Matrix do
        # Converts a matrix to one or more P (point sequence) representations.
        #
        # This method decomposes the matrix into directional segments based on the
        # time dimension, then converts each segment into a P sequence format suitable
        # for representing musical gestures in Musa DSL.
        #
        # A P sequence is an array extended with the P module, containing alternating
        # value arrays (extended with V module) and numeric time deltas:
        # [value1, delta1, value2, delta2, ..., valueN].extend(P)
        # where each value is an array extended with V module.
        #
        # The decomposition process identifies monotonic segments in the time dimension,
        # handling cases where the temporal ordering might have reversals or
        # non-linearities.
        #
        # @param time_dimension [Integer] index of the dimension representing time (typically 0).
        # @param keep_time [Boolean, nil] if true, the time dimension is preserved in each point;
        #   if false/nil, it's removed and used only for computing deltas.
        #
        # @return [Array<Musa::Datasets::P>] array of P sequences, one per directional segment.
        #
        # @example Basic conversion
        #   matrix = Matrix[[0, 60], [1, 62], [2, 64]]
        #   result = matrix.to_p(time_dimension: 0)
        #   # => Array with one P object:
        #   #    [[60], 1, [62], 1, [64]].extend(P)
        #   # Each value like [60] is extended with V module
        #
        # @example Keeping time dimension
        #   matrix = Matrix[[0, 60, 100], [1, 62, 110], [2, 64, 120]]
        #   result = matrix.to_p(time_dimension: 0, keep_time: true)
        #   # => Array with one P object:
        #   #    [[0, 60, 100], 1, [1, 62, 110], 1, [2, 64, 120]].extend(P)
        #   # Time dimension kept in each value array
        #
        # @see Musa::Datasets::P
        # @see Musa::Datasets::V
        # @see #decompose
        def to_p(time_dimension:, keep_time: nil)
          decompose(self.to_a, time_dimension).collect do |points|
            line = []

            start_point = points[0]
            start_time = start_point[time_dimension]

            line << start_point.clone.tap { |_| _.delete_at(time_dimension) unless keep_time; _ }.extend(Musa::Datasets::V)

            (1..points.size-1).each do |i|
              end_point = points[i]

              end_time = end_point[time_dimension]

              line << end_time - start_time
              line << end_point.clone.tap { |_| _.delete_at(time_dimension) unless keep_time; _ }.extend(Musa::Datasets::V)

              start_time = end_time
            end

            line.extend(Musa::Datasets::P)
          end
        end

        # Provides direct access to the internal rows array of the matrix.
        #
        # This is a utility method used primarily by {Array#condensed_matrices}
        # to manipulate matrix rows when merging matrices with shared boundaries.
        #
        # @return [Array<Array>] the internal @rows instance variable.
        #
        # @api private
        # @note This method accesses Ruby's Matrix internals and should be used with caution.
        def _rows
          @rows
        end

        # Decomposes an array of points into directional segments based on a time dimension.
        #
        # This private method analyzes the array to find monotonic (non-decreasing)
        # sequences in the specified time dimension. It scans bidirectionally from
        # each point to discover maximal segments where time progresses consistently.
        #
        # The algorithm:
        # 1. Groups points by their time values
        # 2. Iterates through time values in sorted order
        # 3. For each unprocessed index, scans backward and forward
        # 4. Collects points while time is non-decreasing
        # 5. Returns segments with 2+ points
        #
        # @param array [Array<Array>] array of point arrays (each point is an array of coordinates).
        # @param time_dimension [Integer] index of the dimension representing time.
        #
        # @return [Array<Array<Array>>] array of directional segments, each segment
        #   being an array of points.
        #
        # @api private
        #
        # @example
        #   # Points with time in dimension 0
        #   points = [[0, 10], [1, 20], [0.5, 15], [2, 30]]
        #   decompose(points, 0)
        #   # => [[[1, 20], [0.5, 15], [0, 10]], [[0, 10], [0.5, 15], [1, 20], [2, 30]]]
        #   # Two segments: one going backward in time, one forward
        private def decompose(array, time_dimension)
          x_dim = array.collect { |v| v[time_dimension] }
          x_dim_values_indexes = x_dim.indexes_of_values

          used_indexes = Set[]

          directional_segments = []

          x_dim_values_indexes.keys.sort.each do |value|
            x_dim_values_indexes[value].each do |index|
              # Scan in both directions from this point to find monotonic segments
              unless used_indexes.include?(index)
                # Scan backward (decreasing indices) while time is non-decreasing
                i = index
                xx = array[i][time_dimension]

                a = []

                while i >= 0 && array[i][time_dimension] >= xx
                  used_indexes << i
                  a << array[i]

                  xx = array[i][time_dimension]
                  i -= 1
                end

                directional_segments << a if a.size > 1

                # Scan forward (increasing indices) while time is non-decreasing
                i = index
                xx = array[i][time_dimension]

                b = []

                while i < array.size && array[i][time_dimension] >= xx
                  used_indexes << i
                  b << array[i]

                  xx = array[i][time_dimension]
                  i += 1
                end

                directional_segments << b if b.size > 1
              end
            end
          end

          return directional_segments
        end
      end
    end
  end
end