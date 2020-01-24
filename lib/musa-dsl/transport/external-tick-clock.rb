require 'musa-dsl/transport/clock'

module Musa
  module Clock
    class ExternalTickClock < Clock
      def initialize(do_log: nil)
        do_log ||= false

        super()

        @do_log = do_log
      end

      def run(&block)
        @on_start.each(&:call)
        @run = true
        @block = block
      end

      def tick
        if @run
          @block.call if @block
        end
      end

      def terminate
        @on_stop.each(&:call)
        @run = false
      end
    end
  end
end
