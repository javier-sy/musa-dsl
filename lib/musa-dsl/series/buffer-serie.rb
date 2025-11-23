module Musa
  module Series::Operations
    # Creates buffered serie allowing multiple independent iterations over same source.
    #
    # Provides buffering mechanism enabling multiple "readers" to independently
    # iterate over the same serie source without interfering with each other.
    #
    # ## Buffering Modes
    #
    # - **Async (default)**: Buffers fill independently, each progresses at own pace
    # - **Sync**: All buffers synchronized, restart affects all
    #
    # ## Use Cases
    #
    # - Multiple voices reading same melodic sequence at different speeds
    # - Polyphonic playback from single source
    # - Canonic structures (rounds, fugues)
    # - Independent transformations of same base material
    #
    # ## Memory Management
    #
    # History is automatically cleaned when all buffers have progressed past
    # old values, preventing unbounded memory growth.
    #
    # @param sync [Boolean] synchronized mode (default: false)
    #
    # @return [BufferSerie, SyncBufferSerie] buffered serie
    #
    # @example Create buffered serie
    #   buffered = S(1, 2, 3, 4).buffered
    #   reader1 = buffered.buffer.i
    #   reader2 = buffered.buffer.i
    #
    # @example Multiple independent readers
    #   source = S(1, 2, 3, 4).buffered
    #   reader1 = source.buffer.i
    #   reader2 = source.buffer.i
    #
    #   reader1.next_value  # => 1
    #   reader2.next_value  # => 1 (independent)
    #   reader1.next_value  # => 2
    #   reader2.next_value  # => 2
    #
    # @example Canon structure
    #   melody = S(60, 64, 67, 72).buffered
    #   voice1 = melody.buffer
    #   voice2 = melody.buffer
    #   # Play voice2 delayed by N beats
    #
    # @api public
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
        @buffers = Set[]

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
        @buffer ||= Buffer.new(@history)
        @buffer.send(state).tap { |_| @buffers << _ }
      end

      private def clear_old_history
        min_last_nil_index = @buffers.collect(&:last_nil_index).min

        if min_last_nil_index && min_last_nil_index >=0
          @history = @history.drop(min_last_nil_index)

          @buffers.each do |b|
            b._reindex(@history, min_last_nil_index)
          end
        end
      end

      class Buffer
        include Series::Serie.base

        def initialize(history)
          @history = history
          @last_nil_index = -1
          mark_as_prototype!
          init
        end

        attr_reader :last_nil_index

        def _reindex(history, offset)
          @history = history

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

          @history[@index]
        end
      end

      private_constant :Buffer
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
        @buffers = Set[]

        @buffer = nil

        init
      end

      def buffer
        Buffer.new(self)
      end

      def _sources_resolved
        (prototype || self).singleton = self if instance?
      end

      protected def singleton=(the_instance)
        @singleton ||= the_instance
      end

      def singleton
        if instance?
          prototype.nil? ? @singleton : prototype.singleton
        elsif prototype?
          @singleton
        else
          raise "ES UNDEFINED!"
        end
      end

      private def _restart(buffer)
        raise ArgumentError, "Can't restart a BufferSerie directly. Should use a buffer instance instead." unless buffer
        return if @source_just_restarted

        next_nil = @nils.find { |_| _ > buffer.index }

        if next_nil && buffer.index < next_nil
          buffer.last_nil_index = buffer.index = next_nil

        else
          until _next_value.nil?; end
          buffer.last_nil_index = buffer.index = @nils.last
        end

        clear_old_history

        @source.restart
        @source_just_restarted = true
      end

      private def _next_value
        @source_just_restarted = false
        value = @source.next_value

        if value.nil?
          unless @history.last.nil?
            @history << nil
            @nils << @history.size - 1
          end
        else
          @history << value
        end

        value
      end

      def _register(buffer)
        @buffers << buffer

        buffer.history = @history
        buffer.last_nil_index = 0
      end

      private def clear_old_history
        min_last_nil_index = @buffers.collect(&:last_nil_index).min

        if min_last_nil_index && min_last_nil_index >= 0
          @history = @history.drop(min_last_nil_index)

          @nils.collect! { |_| _ - min_last_nil_index }
          @nils.delete_if(&:negative?)

          @buffers.each do |b|
            b._reindex(@history, min_last_nil_index)
          end
        end
      end

      class Buffer
        include Series::Serie.with(source: true, private_source: true)

        def initialize(base)
          self.source = base
          init
        end

        attr_accessor :history
        attr_accessor :last_nil_index
        attr_accessor :index

        def _reindex(history, offset)
          @history = history
          @last_nil_index -= offset
          @index -= offset
        end

        private def _sources_resolved
          @source.singleton._register(self) if instance?
          @index = @last_nil_index
        end

        private def _restart
          @source.singleton.restart(self)
          @needs_restart = false
        end

        private def _next_value
          value = nil

          unless @needs_restart
            if @index + 1 < @history.size
              @index += 1
              value = @history[@index]
            else
              value = _next_value unless @source.singleton.next_value.nil?
            end

            if value.nil?
              @needs_restart = true
            end
          end

          value
        end
      end

      private_constant :Buffer
    end

    private_constant :BufferSerie
  end
end
