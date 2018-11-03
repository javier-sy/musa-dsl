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
        if @serie.nil?
          @serie = serie
        else
          @new_serie = serie
        end
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

      def current_value
        @serie.current_value if @serie
      end

      def next_value
        @serie.next_value if @serie
      end

      def peek_next_value
        @serie.peek_next_value if @serie
      end

      def infinite?
        @serie.infinite? if @serie
      end

      def deterministic?
        @serie.deterministic? if @serie
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
