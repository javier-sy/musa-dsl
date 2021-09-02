module Musa
  module Series
    module Operations
      def autorestart
        Autorestart.new self
      end

      def repeat(times = nil, condition: nil, &condition_block)
        condition ||= condition_block

        if times || condition
          Repeater.new self, times, &condition
        else
          InfiniteRepeater.new self
        end
      end

      def max_size(length)
        LengthLimiter.new self, length
      end

      def skip(length)
        Skipper.new self, length
      end

      def flatten
        Flattener.new self
      end

      def process_with(**parameters, &processor)
        Processor.new self, parameters, &processor
      end

      # TODO: test case
      def hashify(*keys)
        HashFromSeriesArray.new self, keys
      end

      # TODO: test case
      def shift(shift)
        Shifter.new self, shift
      end

      # TODO: test case
      def lock
        Locker.new self
      end

      # TODO: test case
      def reverse
        Reverser.new self
      end

      # TODO: test case
      def randomize(random: nil)
        random ||= Random.new
        Randomizer.new self, random
      end

      def remove(block = nil, &yield_block)
        # TODO make history an optional block parameter (via keyparametersprocedurebinder)
        block ||= yield_block
        Remover.new self, &block
      end

      def select(block = nil, &yield_block)
        # TODO add optional history (via keyparametersprocedurebinder)
        block ||= yield_block
        Selector.new self, &block
      end

      # TODO: test case
      def switch(*indexed_series, **hash_series)
        Switcher.new self, indexed_series, hash_series
      end

      def multiplex(*indexed_series, **hash_series)
        MultiplexSelector.new self, indexed_series, hash_series
      end

      # TODO: test case
      def switch_serie(*indexed_series, **hash_series)
        SwitchFullSerie.new self, indexed_series, hash_series
      end

      def after(*series)
        Musa::Series::Constructors.MERGE self, *series
      end

      def +(other)
        Musa::Series::Constructors.MERGE self, other
      end

      def cut(length)
        Cutter.new self, length
      end

      def merge
        MergeSerieOfSeries.new self
      end

      # TODO on with and map methods implement parameter passing with cloning on restart as on E()
      #
      def with(block = nil, on_restart: nil, **with_series, &yield_block)
        block ||= yield_block
        ProcessWith.new self, with_series, on_restart, &block
      end

      alias_method :eval, :with

      def map(&block)
        ProcessWith.new self, &block
      end

      def anticipate(&block)
        Anticipate.new self, &block
      end

      def lazy(&block)
        LazySerieEval.new self, &block
      end

      ###
      ### Implementation
      ###

      class ProcessWith
        include Serie.with(source: true,
                           sources: true, sources_as: :with_sources, mandatory_sources: false,
                           smart_block: true)

        def initialize(serie, with_series = nil, on_restart = nil, &block)
          self.source = serie
          self.with_sources = with_series || {}
          self.on_restart = on_restart
          self.proc = block if block

          init
        end

        def on_restart(&block)
          if block
            @on_restart = block
          else
            @on_restart
          end
        end

        def on_restart=(block)
          @on_restart = block
        end

        private def _restart
          @source.restart
          @sources.values.each(&:restart)
          @on_restart.call if @on_restart
        end

        private def _next_value
          main = @source.next_value
          others = @sources.transform_values { |v| v.next_value }

          value = nil

          if main && !others.values.include?(nil)
            if @block
              value = @block._call([main], others)
            else
              value = [main, others]
            end
          end

          value
        end

        def infinite?
          @source.infinite? && !@sources.values.find { |s| !s.infinite? }
        end
      end

      private_constant :ProcessWith

      class Anticipate
        include Serie.with(source: true, block: true)

        def initialize(serie, &block)
          self.source = serie
          self.proc = block

          init
        end

        private def _restart
          @source.restart
        end

        private def _next_value
          previous_value = @source.current_value
          value = @source.next_value
          peek_next_value = @source.peek_next_value

          if value.nil?
            nil
          else
            @block.call(previous_value, value, peek_next_value)
          end
        end

        def infinite?
          @source.infinite?
        end
      end

      private_constant :Anticipate

      class Switcher
        include Serie.with(source: true, sources: true, sources_as: :options)

        def initialize(selector, indexed_series, hash_series)
          self.source = selector
          self.options = indexed_series || hash_series

          init
        end

        private def _restart
          @source.restart
          if @sources.is_a? Array
            @sources.each(&:restart)
          elsif @sources.is_a? Hash
            @sources.each { |_key, serie| serie.restart }
          end
        end

        private def _next_value
          value = nil

          index_or_key = @source.next_value

          value = @sources[index_or_key].next_value unless index_or_key.nil?

          value
        end

        def infinite?
          @source.infinite? && @sources.any? { |serie| serie.infinite? }
        end
      end

      private_constant :Switcher

      class MultiplexSelector
        include Serie.with(source: true, sources: true, sources_as: :options)

        def initialize(selector, indexed_series, hash_series)
          self.source = selector
          self.options = indexed_series || hash_series

          init
        end

        private def _init
          @current_value = nil
          @first = true
        end

        private def _restart
          @source.restart

          if @sources.is_a? Array
            @sources.each(&:restart)
          elsif @sources.is_a? Hash
            @sources.values.each(&:restart)
          end
        end

        private def _next_value
          @current_value =
              if @first || !@current_value.nil?
                @first = false
                index_or_key = @source.next_value
                unless index_or_key.nil?
                  @sources.each(&:next_value)
                  @sources[index_or_key].current_value
                end
              end
        end

        def infinite?
          @source.infinite? && @sources.any? { |serie| serie.infinite? }
        end
      end

      private_constant :MultiplexSelector

      class SwitchFullSerie
        include Serie.with(source: true, sources: true, sources_as: :options)

        def initialize(selector, indexed_series, hash_series)
          self.source = selector
          self.options = indexed_series || hash_series

          init
        end

        private def _restart
          @source.restart
          @sources.each(&:restart)
        end

        private def _next_value
          value = nil

          value = @sources[@index_or_key].next_value unless @index_or_key.nil?

          if value.nil?
            @index_or_key = @source.next_value

            value = next_value unless @index_or_key.nil?
          end

          value
        end

        def infinite?
          !!(@source.infinite? || @sources.find(&:infinite?))
        end
      end

      private_constant :SwitchFullSerie

      class InfiniteRepeater
        include Serie.with(source: true)

        def initialize(serie)
          self.source = serie
          init
        end

        private def _restart
          @source.restart
        end

        private def _next_value
          value = @source.next_value

          if value.nil?
            @source.restart
            value = @source.next_value
          end

          value
        end

        def infinite?
          true
        end
      end

      private_constant :InfiniteRepeater

      class Repeater
        include Serie.with(source: true)

        def initialize(serie, times = nil, &condition)
          self.source = serie
          self.times = times
          self.condition = condition

          init
        end

        attr_reader :times

        def times=(value)
          @times = value
          calculate_condition
        end

        def condition(&block)
          if block
            @external_condition = block
            calculate_condition
          else
            @external_condition
          end
        end

        def condition=(block)
          @external_condition = block
          calculate_condition
        end

        private def _init
          @count = 0
          calculate_condition
        end

        private def _restart
          @source.restart
        end

        private def _next_value
          value = @source.next_value

          if value.nil?
            @count += 1

            if @condition.call
              @source.restart
              value = @source.next_value
            end
          end

          value
        end

        def infinite?
          @source.infinite?
        end

        private def calculate_condition
          @condition = if @external_condition
                         @external_condition
                       elsif @times
                         proc { @count < @times }
                       else
                         proc { false }
                       end
        end
      end

      private_constant :Repeater

      class LengthLimiter
        include Serie.with(source: true)

        def initialize(serie, length)
          self.source = serie
          self.length = length

          init
        end

        attr_accessor :length

        private def _init
          @position = 0
        end

        private def _restart
          @source.restart
        end

        private def _next_value
          if @position < @length
            @position += 1
            @source.next_value
          end
        end

        def infinite?
          false
        end
      end

      private_constant :LengthLimiter

      class Skipper
        include Serie.with(source: true)

        def initialize(serie, length)
          self.source = serie
          self.length = length

          init
        end

        attr_accessor :length

        private def _init
          @first = true
        end

        private def _restart
          @source.restart
        end

        private def _next_value
          @length.times { @source.next_value } if @first
          @first = nil

          @source.next_value
        end

        def infinite?
          @source.infinite?
        end
      end

      private_constant :Skipper

      class Flattener
        include Serie.base

        def initialize(serie)
          @source = serie
          mark_regarding! @source
          init
        end

        private def _init
          @stack = [@source]
          @restart_each_serie = false
        end

        private def _restart
          @source.restart
          @restart_each_serie = true
        end

        private def _next_value
          if @stack.last
            value = @stack.last.next_value

            case value
            when Serie
              value = value.instance
              value.restart if @restart_each_serie
              @stack.push(value)
              _next_value
            when nil
              @stack.pop
              _next_value
            else
              value
            end
          end
        end

        def infinite?
          @source.infinite? # TODO revisar porque las series hijas sí que pueden ser infinitas
        end
      end

      private_constant :Flattener

      class MergeSerieOfSeries
        include Serie.with(source: true)

        def initialize(serie)
          self.source = serie
          init
        end

        private def _init
          @current_serie = nil
          @restart_each_serie = false
        end

        private def _restart
          @source.restart
          @restart_each_serie = true
        end

        private def _next_value
          value = nil

          restart_current_serie_if_needed = false

          if @current_serie.nil?
            @current_serie = @source.next_value
            @current_serie = @current_serie.instance if @current_serie

            if @restart_each_serie
              @current_serie.restart if @current_serie
            else
              restart_current_serie_if_needed = true
            end
          end

          if @current_serie
            value = @current_serie.next_value

            if value.nil?
              if restart_current_serie_if_needed
                @current_serie.restart
              else
                @current_serie = nil
              end

              value = _next_value
            end
          end

          value
        end
      end

      private_constant :MergeSerieOfSeries

      class Processor
        include Serie.with(source: true, smart_block: true)

        def initialize(serie, parameters, &processor)
          self.source = serie

          self.parameters = parameters
          self.proc = processor if processor

          init
        end

        attr_accessor :parameters

        private def _init
          @pending_values = []
        end

        private def _restart
          @source.restart
        end

        private def _next_value
          if @pending_values.empty?

            v = @source.next_value

            if v.nil?
              nil
            else
              value = @block.call(v, **@parameters)

              if value.is_a?(Array)
                @pending_values = value
                value = _next_value
              end

              value
            end
          else
            value = @pending_values.shift

            if value.nil?
              value = _next_value
            end

            value
          end
        end

        def infinite?
          @source.infinite?
        end
      end

      class Autorestart
        include Serie.with(source: true)

        def initialize(serie)
          self.source = serie
          init
        end

        private def _init
          @restart_on_next = false
        end

        private def _restart
          @source.restart
        end

        private def _next_value
          if @restart_on_next
            @source.restart
            @restart_on_next = false
          end

          value = @source.next_value

          @restart_on_next = value.nil?

          value
        end
      end

      private_constant :Autorestart

      class Cutter
        include Serie.with(source: true)

        def initialize(serie, length)
          self.source = serie
          self.length = length
          init
        end

        def source=(serie)
          super
          @previous&.source = serie
        end

        attr_reader :length

        def length=(value)
          @length = value
          @previous&.length = value
        end

        private def _restart
          @source.restart
        end

        private def _next_value
          @previous&.materialize
          @previous = CutSerie.new @source, @length if @source.peek_next_value
        end

        class CutSerie
          include Serie.with(source: true)

          def initialize(serie, length)
            self.source = serie.instance
            self.length = length

            @values = []
            init
          end

          attr_accessor :length

          def _prototype!
            # TODO review why cannot get prototype of a cut serie
            raise PrototypingError, 'Cannot get prototype of a cut serie'
          end

          private def _init
            @count = 0
          end

          private def _next_value
            value = @values[@count]
            value ||= @values[@count] = @source.next_value if @count < @length

            @count += 1

            value
          end

          def materialize
            (@values.size..@length - 1).each { |i| @values[i] = @source.next_value }
          end
        end

        private_constant :CutSerie
      end

      private_constant :Cutter

      class Locker
        include Serie.with(source: true)

        def initialize(serie)
          self.source = serie

          @values = []
          @first_round = true

          init
        end

        private def _init
          @index = 0
        end

        private def _next_value
          if @first_round
            value = @source.next_value

            @first_round = false if value.nil?
            @values << value unless value.nil?
          else
            if @index < @values.size
              value = @values[@index]
              @index += 1
            else
              value = nil
            end
          end

          value
        end
      end

      private_constant :Locker

      class Reverser
        include Serie.with(source: true)

        def initialize(serie)
          self.source = serie
          init
        end

        private def _init
          @reversed = nil
        end

        private def _restart
          @source.restart
        end

        private def _next_value
          raise ArgumentError, "A serie to reverse can't be infinite" if @source.infinite?

          @reversed ||= Constructors.S(*next_values_array_of(@source).reverse).instance
          @reversed.next_value
        end

        private def next_values_array_of(serie)
          array = []

          until (value = serie.next_value).nil?
            array << value
          end

          array
        end
      end

      private_constant :Reverser

      class Randomizer
        include Serie.with(source: true)

        def initialize(serie, random)
          self.source = serie
          self.random = random

          init
        end

        attr_accessor :random

        private def _init
          @values = @source.to_a(duplicate: false, restart: false)
        end

        private def _restart
          @source.restart
          @values = @source.to_a(duplicate: false, restart: false)
        end

        private def _next_value
          if !@values.empty?
            position = @random.rand(0...@values.size)
            value = @values[position]

            @values.delete_at position
          else
            value = nil
          end

          value
        end
      end

      private_constant :Randomizer

      class Shifter
        include Serie.with(source: true)

        def initialize(serie, shift)
          self.source = serie
          self.shift = shift

          init
        end

        def source=(serie)
          raise ArgumentError, "cannot shift to right an infinite serie" if @shift > 0 && serie.infinite?
          super
          # should _restart(false) ??? if so, we lost the shifted values of the previous serie; if not we don't shift the new serie values
          # I think it's better to not _restart unless it's explicitly called by the caller
        end

        attr_reader :shift

        def shift=(value)
          raise ArgumentError, "cannot shift to right an infinite serie" if value > 0 && @source&.infinite?
          raise NotImplementedError, 'cannot shift to right: function not yet implemented' if value > 0

          @shift = value
        end

        private def _init
          @shifted = []
          @first = true
        end

        private def _restart
          @source.restart
        end

        private def _next_value
          if @first
            @shift.abs.times { @shifted << @source.next_value } if @shift < 0
            @first = false
          end

          value = @source.next_value
          return value unless value.nil?

          @shifted.shift
        end
      end

      private_constant :Shifter

      class Remover
        include Serie.with(source: true, block: true)

        def initialize(serie, &block)
          self.source = serie
          self.proc = block

          @history = []

          init
        end

        private def _init
          @history.clear
        end

        private def _restart
          @source.restart
        end

        private def _next_value
          if value = @source.next_value
            while value && @block.call(value, @history)
              @history << value
              value = @source.next_value
            end
            @history << value
          end
          value
        end
      end

      private_constant :Remover

      class Selector
        include Serie.with(source: true, block: true)

        def initialize(serie, &block)
          self.source = serie
          self.proc = block

          init
        end

        private def _restart
          @source.restart
        end

        private def _next_value
          value = @source.next_value
          until value.nil? || @block.call(value)
            value = @source.next_value
          end
          value
        end
      end

      private_constant :Selector

      class HashFromSeriesArray
        include Serie.with(source: true)

        def initialize(serie, keys)
          self.source = serie
          self.keys = keys

          init
        end

        attr_accessor :keys

        private def _restart
          @source.restart
        end

        private def _next_value
          array = @source.next_value

          return nil unless array

          value = array.length.times.collect { |i| [@keys[i], array[i]] }.to_h

          if value.find { |_key, value| value.nil? }
            nil
          else
            value
          end
        end
      end

      private_constant :HashFromSeriesArray

      class LazySerieEval
        include Serie.with(source: true, block: true)

        def initialize(serie, &block)
          self.source = serie
          self.proc = block

          init
        end

        def source=(serie)
          super
          @processed = nil
        end

        def proc(&block)
          super
          @processed = nil if block
        end

        def proc=(block)
          super
          @processed = nil if block
        end

        private def _restart
          @processed = nil
          @source.restart
        end

        private def _next_value
          @processed ||= @block.call(@source)
          @processed.next_value
        end
      end

      private_constant :LazySerieEval
    end

  end
end
