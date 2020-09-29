require 'matrix'

require_relative '../datasets/p'
require_relative '../sequencer'

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

        def to_p(time_dimension, keep_time: nil)
          condensed_matrices.collect { |m| m.to_p(time_dimension, keep_time: keep_time) }
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

        def to_p(time_dimension, keep_time: nil)

          decompose(self.to_a, time_dimension).collect do |points|
            line = []

            start_point = points[0]
            start_time = start_point[time_dimension]

            line << start_point.tap { |_| _.delete_at(time_dimension) unless keep_time; _ }.extend(Datasets::V)

            (1..points.size-1).each do |i|
              end_point = points[i]

              end_time = end_point[time_dimension]

              line << end_time - start_time
              line << end_point.tap { |_| _.delete_at(time_dimension) unless keep_time; _ }.extend(Datasets::V)

              start_time = end_time
            end

            line.extend(Datasets::P)
          end
        end

        def to_score(time_dimension, mapper: nil, score: nil, position: nil, sequencer: nil, beats_per_bar: nil, ticks_per_beat: nil, right_open: nil, &block)

          raise ArgumentError,
                "'beats_per_bar' and 'ticks_per_beat' parameters should be both nil or both have values" \
              unless beats_per_bar && ticks_per_beat ||
                     beats_per_bar.nil? && ticks_per_beat.nil?

          raise ArgumentError,
                "'sequencer' parameter should not be used when 'beats_per_bar' and 'ticks_per_beat' parameters are used" \
            if sequencer && beats_per_bar

          raise ArgumentError,
                "'time_dimension' parameter should be an index number if no 'mapping' is provided" \
            unless time_dimension.is_a?(Symbol) && mapper&.include?(time_dimension) ||
                   time_dimension.is_a?(Integer) && (0..self.column_size-1).include(time_dimension)

          time_dimension = mapper&.find_index(time_dimension) if time_dimension.is_a?(Symbol)

          mapper = mapper.clone.tap { |_| _.delete_at(time_dimension) } if mapper

          run_sequencer = sequencer.nil?

          score ||= Musa::Datasets::Score.new

          sequencer ||= Sequencer::Sequencer.new(beats_per_bar, ticks_per_beat, log_decimals: 1.3)

          right_open = right_open.clone.tap { |_| _.delete_at(time_dimension) } if right_open&.is_a?(Array)



          # SEGUIIIIR AQUI propagando el mapper y time_dimension que puede ser numeric o symbol hacia P y PS



          sequencer.at(position || 1r) do |_|
            to_p(time_dimension).each do |p|
              p.to_score(score: score,
                         sequencer: _,
                         position: _.position,
                         right_open: right_open,
                         &block)
            end
          end

          if run_sequencer
            sequencer.run
            score
          else
            nil
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