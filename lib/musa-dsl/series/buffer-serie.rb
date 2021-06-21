module Musa
  module Series::Operations
    def buffered(sync: false)
      if sync
        SyncBufferSerie.new(self)
      else
        BufferSerie.new(self)
      end
    end

    class SyncBufferSerie
      include Series::Serie.with(source: true)

      def initialize(serie)
        self.source = serie
        @history = []
        @buffereds = Set[]

        init
      end

      private def _restart
        @source.restart
        clear_old_history
      end

      private def _next_value
        @source.next_value.tap { |value| @history << value unless value.nil? && !@history.empty? && @history.last.nil? }
      end

      def buffer
        @buffered ||= Buffered.new(@history)
        @buffered.send(@get).tap { |_| @buffereds << _ }
      end

      private def clear_old_history
        min_last_nil_index = @buffereds.collect(&:last_nil_index).min

        if min_last_nil_index && min_last_nil_index >=0
          min_last_nil_index.times { || @history.shift }

          @buffereds.each do |b|
            b.reindex(min_last_nil_index)
          end
        end
      end

      class Buffered
        include Series::Serie.base

        def initialize(history)
          @history = history
          @last_nil_index = -1
          init
        end

        attr_reader :last_nil_index

        def reindex(offset)
          @last_nil_index -= offset
          @index -= offset
        end

        private def _init
          @index = @last_nil_index
          @wait_restart = false
        end

        private def _next_value
          @index += 1 if @index + 1 < @history.size && !@wait_restart

          if @history[@index].nil? && @index < @history.size

            @wait_restart = true

            if @index + 1 < @history.size
              @last_nil_index = @index
            end
          end

          #puts "after : _next_value: @index = #{@index} @history[@index] = #{@history[@index] || 'nil'} @last_nil_index = #{@last_nil_index} @history.size = #{@history.size} wait_restart = #{@wait_restart} "

          @history[@index]
        end
      end

      private_constant :Buffered
    end

    private_constant :SyncBufferSerie

    class BufferSerie
      # modo fill_on_restart: cuando una serie hace restart, las demás no se ven afectadas porque siguen recibiendo
      # todos los elementos de la serie original

      include Series::Serie.with(source: true)

      def initialize(serie)
        self.source = serie

        @history = [nil]
        @nils = [0]
        @buffereds = Set[]

        init
      end

      def buffer
        @buffered ||= Buffered.new(self, @history)
        @buffered.send(@get)
      end

      def _init; end

      private def _restart(main)
        raise ArgumentError, "Can't restart a ParallelBuffer serie directly. Should use a buffered instance instead." unless main

        next_nil = @nils.find { |_| _ > main.index }

        if next_nil && main.index < next_nil
          main.last_nil_index = main.index = next_nil

        else
          while !_next_value.nil?; end
          main.last_nil_index = main.index = @nils.last
        end

        @source.restart
        clear_old_history
      end

      private def _next_value
        value = @source.next_value

        if value.nil?
          if !@history.last.nil?
            @history << nil
            @nils << @history.size - 1
          end
        else
          @history << value
        end

        value
      end

      def _register(buffered_instance)
        @buffereds << buffered_instance
      end

      private def clear_old_history
        # min_last_nil_index = @buffereds.collect(&:last_nil_index).min
        #
        # if min_last_nil_index && min_last_nil_index >=0
        #   min_last_nil_index.times { || @history.shift }
        #
        #   @buffereds.each do |b|
        #     b.reindex(min_last_nil_index)
        #   end
        # end
      end

      class Buffered
        include Series::Serie.base

        def initialize(base, history)
          @base = base
          @history = history

          @last_nil_index = 0

          mark_as_prototype!
          init
        end

        attr_accessor :id # todo remove

        attr_accessor :last_nil_index
        attr_accessor :index

        private def _init
          @base._register(self) if instance?
          @index = @last_nil_index
        end

        private def _restart
          @base.restart(self)
          @needs_restart = false
        end

        private def _next_value
          value = nil

          if !@needs_restart
            if @index + 1 < @history.size
              @index += 1
              value = @history[@index]
            else
              @base.next_value
              value = _next_value
            end

            if value.nil?
              @needs_restart = true
            end
          end

          value
        end
      end

      private_constant :Buffered

    end

    private_constant :BufferSerie

  end
end
