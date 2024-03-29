require_relative 'clock'

module Musa
  module Clock
    class DummyClock < Clock
      def initialize(ticks = nil, do_log: nil, &block)
        do_log ||= false

        super()

        raise ArgumentError, 'Cannot initialize with ticks and block. You can only use one of the parameters.' if ticks && block

        @ticks = ticks
        @do_log = do_log
        @block = block
      end

      attr_accessor :block, :ticks

      def run
        @on_start.each(&:call)
        @run = true

        while @run && eval_condition
          yield if block_given?

          Thread.pass
        end

        @on_stop.each(&:call)
      end

      def terminate
        @run = false
      end

      private

      def eval_condition
        if @ticks
          @ticks -= 1
          @ticks.positive?
        else
          @block.call
        end
      end
    end
  end
end
