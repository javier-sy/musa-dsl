module Musa

	module Series
		def HLD(serie = nil)
			HolderSerie.new serie
		end

    class HolderSerie < Serie
      def initialize serie
        @serie = serie
        @new_serie = nil
      end

      def hold_next= serie
        @new_serie = serie
      end

      def hold_next
        @new_serie
      end

      def hold= serie
        @serie = serie
      end

      def hold
        @serie
      end

      def restart
        if @new_serie
          @serie = @new_serie
          @new_serie = nil
        else
          @serie.restart
        end

        self
      end

      def next_value
        @serie.next_value
      end

      def peek_next_value
        @serie.peek_next_value
      end

      def infinite?
        @serie.infinite?
      end
    end
  end

  module SerieOperations
    def hold
			Series::HolderSerie.new self
		end
  end
end
