require_relative '../datasets/e'

module Musa
  module Series

    module SerieOperations
      def flatten_timed
        TimedFlattener.new(self)
      end

      class TimedFlattener
        include Serie

        attr_reader :source

        def initialize(serie)
          @source = serie
          mark_regarding! @source
        end

        def _restart
          @source.restart
        end

        def _next_value
          source_value = @source.next_value

          if !source_value.nil?
            result = {}
            time = source_value[:time]

            source_value[:value].each_pair do |key, value|
              result[key] = { time: time, value: value }.extend(AbsTimed)
            end

            result
          else
            nil
          end
        end

        def infinite?
          @source.infinite?
        end
      end

      private_constant :TimedFlattener
    end
  end
end
