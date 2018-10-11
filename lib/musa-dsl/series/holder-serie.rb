module Musa
  module Series
    #  TODO add test case
    def HLD(serie = nil)
      HolderSerie.new serie
    end

    class HolderSerie
      include Serie

      def initialize(serie)
        @serie = serie
        @new_serie = nil
      end

      def hold_next=(serie)
        @new_serie = serie
      end

      def hold_next
        @new_serie
      end

      def hold=(serie)
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

      def deterministic?
        @serie.deterministic?
      end
    end
  end

  module SerieOperations
    # TODO add test case
    def hold
      Series::HolderSerie.new self
     end
  end
end
