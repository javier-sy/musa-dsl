module Musa
  module Series
    def HOLDER(serie = nil)
      Holder.new(serie)
    end

    class Holder
      include Serie

      attr_accessor :hold
      attr_reader :next

      def initialize(serie)
        @hold = serie
        @next = []
      end

      def <<(serie)
        if @hold.nil?
          @hold = serie
        else
          @next << serie
        end

        self
      end

      def restart
        if @next.empty? && @hold
          @hold.restart
        else
          @hold = @next.shift
        end

        self
      end

      def current_value
        @hold.current_value if @hold
      end

      def next_value
        @hold.next_value if @hold
      end

      def peek_next_value
        @hold.peek_next_value if @hold
      end

      def infinite?
        @hold.infinite? if @hold
      end

      private

      def method_missing(method_name, *args, **key_args, &block)
        if @hold && @hold.respond_to?(method_name)
          @hold.send_nice method_name, *args, **key_args, &block
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private)
        @hold && @hold.respond_to?(method_name, include_private) || super
      end
    end
  end

  module SerieOperations
    # TODO add test case
    def hold
      Series::Holder.new self
     end
  end
end
