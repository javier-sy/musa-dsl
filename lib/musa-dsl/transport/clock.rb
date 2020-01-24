module Musa
  module Clock
    class Clock
      def initialize
        @run = nil
        @on_start = []
        @on_stop = []
        @on_change_position = []
      end

      def running?
        @run
      end

      def on_start(&block)
        @on_start << block
      end

      def on_stop(&block)
        @on_stop << block
      end

      def on_change_position(&block)
        @on_change_position << block
      end

      def run
        raise NotImplementedError
      end

      def terminate
        raise NotImplementedError
      end
    end
  end
end
