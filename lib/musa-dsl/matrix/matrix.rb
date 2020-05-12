require 'matrix'

require_relative '../datasets/p'

module Musa
  module Matrix
    ## ??????
  end

  module Extension
    module Matrix
      refine Array do
        def indexes_of_values
          indexes = {}

          size.times do |i|
            indexes[self[i]] ||= []
            indexes[self[i]] << i
          end

          indexes
        end

        def to_p(time_dimension)
          condensed_matrices.collect { |m| m.to_p(time_dimension) }
        end

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
        include Musa::Datasets

        def to_p(time_dimension)
          decompose(self.to_a, time_dimension).collect do |points|
            line = []

            start_point = points[0].extend(Datasets::V)
            start_time = start_point[time_dimension]

            line << start_point

            (1..points.size-1).each do |i|
              end_point = points[i].extend(Datasets::V)

              end_time = end_point[time_dimension]

              line << end_time - start_time
              line << end_point

              start_time = end_time
            end

            line.extend(Datasets::P)
          end
        end

        def _rows
          @rows
        end

        private def decompose(array, time_dimension)
          x_dim = array.collect { |v| v[time_dimension] }
          x_dim_values_indexes = x_dim.indexes_of_values

          used_indexes = Set[]

          directional_segments = []

          x_dim_values_indexes.keys.sort.each do |value|
            x_dim_values_indexes[value].each do |index|
              # hacia un lado

              unless used_indexes.include?(index)
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

                # y hacia el otro

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