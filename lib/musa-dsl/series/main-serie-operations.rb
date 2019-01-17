module Musa
  module SerieOperations
    def autorestart(skip_nil: nil, **options)
      skip_nil ||= false
      BasicSerieAutorestart.new self, skip_nil
    end

    alias_method :ar, :autorestart

    def repeat(times = nil, condition: nil, **options, &condition_block)
      condition ||= condition_block

      if times || condition
        Repeater.new self, times, &condition
      else
        InfiniteRepeater.new self
      end
    end

    def max_size(length, **options)
      LengthLimiter.new self, length
    end

    def skip(length, **options)
      Skipper.new self, length
    end

    def flatten(serie_of_series: nil, **options)
      serie_of_series ||= false

      if serie_of_series
        FlattenFromSerieOfSeries.new self
      else
        Flattener.new self
      end
    end

    def process_with(**parameters, &processor)
      Processor.new self, parameters, &processor
    end

    # TODO: test case
    def hashify(*keys, **options)
      HashFromSeriesArray.new self, keys
    end

    # TODO: test case
    def shift(shift, **options)
      Shifter.new self, shift
    end

    # TODO: test case
    def remove(positions, **options)
      Remover.new self, positions
    end

    # TODO: test case
    def lock(**options)
      Locker.new self
    end

    # TODO: test case
    def reverse(**options)
      Reverser.new self
    end

    # TODO: test case
    def randomize(random: nil, **options)
      random ||= Random.new
      Randomizer.new self, random
    end

    # TODO: test case
    def eval(block = nil, with: nil, on_restart: nil, **options, &yield_block)
      block ||= yield_block
      FromEvalBlockOnSerie.new self, with: with, on_restart: on_restart, &block
    end

    # TODO: test case
    def select(*indexed_series, **hash_series)
      Selector.new self, indexed_series, hash_series
    end

    def multiplex(*indexed_series, **hash_series)
      MultiplexSelector.new self, indexed_series, hash_series
    end

    # TODO: test case
    def select_serie(*indexed_series, **hash_series)
      SelectorFullSerie.new self, indexed_series, hash_series
    end

    def after(*series, **options)
      Sequence.new [self, *series]
    end

    def +(other)
      Sequence.new [self, other]
    end

    def cut(length, **options)
      Cutter.new self, length
    end

    def merge(**options)
      MergeSerieOfSeries.new self
    end

    # TODO: test case
    def slave
      slave_serie = Slave.new self

      @_slaves ||= []
      @_slaves << slave_serie

      slave_serie
    end

    ###
    ### Implementation
    ###

    class Sequence
      include Serie

      attr_reader :sources

      def initialize(series)
        @sources = series.collect(&:instance)
        _restart false
      end

      def sources=(series)
        @sources = series
        _restart false
      end

      def _restart(restart_sources = true)
        @index = 0
        @sources[@index].restart if restart_sources
      end

      def _next_value
        value = nil

        if @index < @sources.size
          value = @sources[@index].next_value

          if value.nil?
            @index += 1
            if @index < @sources.size
              @sources[@index].restart
              value = next_value
            end
          end
        end

        value
      end

      def infinite?
        !!@sources.find(&:infinite?)
      end
    end

    private_constant :Sequence

    class Selector
      include Serie

      attr_accessor :selector, :sources

      def initialize(selector, indexed_series, hash_series)
        @selector = selector.instance

        if indexed_series && !indexed_series.empty?
          @sources = indexed_series.collect(&:instance)
        elsif hash_series && !hash_series.empty?
          @sources = hash_series.transform_values(&:instance)
        end
      end

      def _restart
        @selector.restart
        @sources.each(&:restart) if @sources.is_a? Array
        @sources.each { |_key, serie| serie.restart } if @sources.is_a? Hash
      end

      def _next_value
        value = nil

        index_or_key = @selector.next_value

        value = @sources[index_or_key].next_value unless index_or_key.nil?

        value
      end

      def infinite?
        @selector.infinite? && @sources.any? { |serie| serie.infinite? }
      end
    end

    private_constant :Selector

    class MultiplexSelector
      include Serie

      attr_accessor :selector, :sources

      def initialize(selector, indexed_series, hash_series)
        @selector = selector.instance

        if indexed_series && !indexed_series.empty?
          @sources = indexed_series.collect(&:instance)
        elsif hash_series && !hash_series.empty?
          @sources = hash_series.transform_values(&:instance)
        end

        _restart false
      end

      def _restart(restart_sources = true)
        @current_value = nil

        if restart_sources
          @selector.restart
          @sources.each(&:restart) if @sources.is_a? Array
          @sources.each { |_key, serie| serie.restart } if @sources.is_a? Hash
        end

        @first = true
      end

      def _next_value
        @current_value =
          if @first || !@current_value.nil?
            @first = false
            index_or_key = @selector.next_value
            unless index_or_key.nil?
              @sources.each(&:next_value)
              @sources[index_or_key].current_value
            end
          end
      end

      def infinite?
        @selector.infinite? && @sources.any? { |serie| serie.infinite? }
      end
    end

    private_constant :MultiplexSelector

    class SelectorFullSerie
      include Serie

      attr_accessor :selector, :sources

      def initialize(selector, indexed_series, hash_series)
        @selector = selector.instance

        if indexed_series && !indexed_series.empty?
          @sources = indexed_series.collect(&:instance)
        elsif hash_series && !hash_series.empty?
          @sources = hash_series.transform_values(&:instance)
        end
      end

      def _restart(restart_sources = true)
        @selector.restart
        @sources.each(&:restart)
      end

      def _next_value
        value = nil

        value = @sources[@index_or_key].next_value unless @index_or_key.nil?

        if value.nil?
          @index_or_key = @selector.next_value

          value = next_value unless @index_or_key.nil?
        end

        value
      end

      def infinite?
        !!(@selector.infinite? || @sources.find(&:infinite?))
      end
    end

    private_constant :SelectorFullSerie

    class InfiniteRepeater
      include Serie

      attr_accessor :source

      def initialize(serie)
        @source = serie.instance
      end

      def _restart
        @source.restart
      end

      def _next_value
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
      include Serie

      attr_reader :source, :times, :condition

      def initialize(serie, times = nil, &condition_block)
        @source = serie.instance

        @times = times
        @condition = condition_block

        update_condition
        _restart false
      end

      def source=(serie)
        @source = serie
        _restart false
      end

      def times=(times)
        @times = times
        update_condition
      end

      def condition=(condition)
        @condition = condition
        @times = nil if @condition
        update_condition
      end

      def _restart(restart_sources = true)
        @count = 0
        @source.restart if restart_sources
      end

      def _next_value
        value = @source.next_value

        if value.nil?
          @count += 1

          if instance_eval &@condition
            @source.restart
            value = @source.next_value
          end
        end

        value
      end

      def infinite?
        @source.infinite?
      end

      private

      def update_condition
        @condition = proc { @count < @times } if @times && !@condition
        @condition ||= proc { false }
      end
    end

    private_constant :Repeater

    class LengthLimiter
      include Serie

      attr_reader :source
      attr_accessor :length

      def initialize(serie, length)
        @source = serie.instance
        @length = length

        _restart false
      end

      def source=(serie)
        @source = serie
        _restart false
      end

      def _restart(restart_sources = true)
        @position = 0
        @source.restart if restart_sources
      end

      def _next_value
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
      include Serie

      attr_accessor :source, :length

      def initialize(serie, length)
        @source = serie.instance
        @length = length

        _restart false
      end

      def _restart(restart_sources = true)
        @source.restart if restart_sources
        @length.times { @source.next_value }
      end

      def _next_value
        @source.next_value
      end

      def infinite?
        @source.infinite?
      end
    end

    private_constant :Skipper

    class Flattener
      include Serie

      attr_accessor :source, :length

      def initialize(serie)
        @source = serie.instance

        _restart false
      end

      def _restart(restart_sources = true)
        if restart_sources
          @source.restart
          @restart_each_serie = true
        else
          @restart_each_serie = false
        end

        @stack = [@source]
      end

      def _next_value
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

    class FlattenFromSerieOfSeries
      include Serie

      attr_accessor :source

      def initialize(serie)
        @source = serie.instance
        _restart false
      end

      def _restart(restart_sources = true)
        if restart_sources
          @source.restart
          @restart_each_serie = true
        end
        @current_serie = nil
      end

      def _next_value
        value = nil

        restart_current_serie_if_needed = false

        if @current_serie.nil?
          @current_serie = @source.next_value

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

    private_constant :FlattenFromSerieOfSeries

    class Processor
      include Serie

      attr_reader :source

      def initialize(serie, parameters, &processor)
        @source = serie.instance
        @parameters = parameters
        @processor = KeyParametersProcedureBinder.new(processor)

        _restart false
      end

      def source=(serie)
        @source = serie
        _restart false
      end

      def _restart(restart_source = true)
        @source.restart if restart_source
        @pending_values = []
      end

      def _next_value
        if @pending_values.empty?

          v = @source.next_value

          if v.nil?
            nil
          else
            value = @processor.call(v, **@parameters)

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

    class BasicSerieAutorestart
      include Serie

      attr_accessor :source
      attr_accessor :skip_nil

      def initialize(serie, skip_nil)
        @source = serie.instance
        @skip_nil = skip_nil

        @restart_on_next = false
      end

      def _restart
        @source.restart
      end

      def _next_value
        if @restart_on_next
          @source.restart
          @restart_on_next = false
        end

        value = @source.next_value

        if value.nil?
          if @skip_nil
            @source.restart
            value = @source.next_value
          else
            @restart_on_next = true
          end
        end

        value
      end
    end

    private_constant :BasicSerieAutorestart

    class Cutter
      include Serie

      def initialize(serie, length)
        @source = serie.instance
        @length = length
      end

      def _restart
        @source.restart
      end

      def _next_value
        @previous.materialize if @previous

        @previous = CutSerie.new @source, @length if @source.peek_next_value
      end

      private

      class CutSerie
        include Serie

        def initialize(serie, length)
          @source = serie.instance
          @length = length

          @values = []
          _restart
        end

        def _restart
          @count = 0
        end

        def _next_value
          value ||= @values[@count]
          value ||= @values[@count] = @source.next_value if @count < @length

          @count += 1

          value
        end

        def materialize
          (@values.size..@length - 1).each { |i| @values[i] = @source.next_value }
        end
      end
    end

    private_constant :Cutter

    class MergeSerieOfSeries
      include Serie

      attr_reader :source

      def initialize(serie)
        @source = serie.instance
        _restart false
      end

      def source=(serie)
        @source = serie
        _restart false
      end

      def _restart(restart_sources = true)
        @source.restart if restart_sources
        @current = nil
      end

      def _next_value
        value = nil

        @current ||= @source.next_value

        if @current
          value = @current.next_value

          if value.nil?
            @current = nil
            value = next_value
          end
        else
          value = nil
        end

        value
      end
    end

    private_constant :MergeSerieOfSeries

    class Locker
      include Serie

      attr_reader :source

      def initialize(serie)
        @source = serie.instance
        @values = []
        @first_round = true

        _restart
      end

      def source=(serie)
        @source = serie
        @values = []
        @first_round = true

        _restart
      end

      def _restart
        @index = 0
      end

      def _next_value
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
      include Serie

      attr_reader :source

      def initialize(serie)
        @source = serie.instance
        _restart false
      end

      def source=(serie)
        raise ArgumentError, "cannot reverse an infinite serie #{serie}" if serie.infinite?

        @source = serie
        _restart false
      end

      def _restart(restart_sources = true)
        @source.restart if restart_sources
        @reversed = FromArray.new next_values_array_of(@source).reverse
      end

      def _next_value
        @reversed.next_value
      end

      private

      def next_values_array_of(serie)
        array = []

        until (value = serie.next_value).nil?
          array << value
        end

        array
      end
    end

    private_constant :Reverser

    class Randomizer
      include Serie

      attr_reader :source, :random

      def initialize(serie, random)
        @source = serie.instance
        @random = random

        _restart false
      end

      def source=(serie)
        raise ArgumentError, "cannot randomize an infinite serie #{serie}" if serie.infinite?

        @source = serie
      end

      def random=(random)
        @random = random
      end

      def _restart(restart_sources = true)
        @source.restart if restart_sources
        @values = @source.to_a
      end

      def _next_value
        _restart(false) if @needs_restart

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
      include Serie

      attr_reader :source, :shift

      def initialize(serie, shift)
        raise ArgumentError, "cannot shift to right an infinite serie #{serie}" if shift > 0 && serie.infinite?
        raise ArgumentError, 'cannot shift to right: function not yet implemented' if shift > 0

        @source = serie.instance
        @shift = shift

        _restart false
      end

      def source=(serie)
        @source = serie
      end

      def shift=(shift)
        @shift = shift
      end

      def _restart(restart_sources = true)
        @source.restart if restart_sources

        @shifted = []
        @shift.abs.times { @shifted << @source.next_value } if @shift < 0
      end

      def _next_value
        value = @source.next_value
        return value unless value.nil?

        @shifted.shift
      end
    end

    private_constant :Shifter

    class Remover
      include Serie

      attr_reader :source, :remove

      def initialize(serie, remove)
        @source = serie.instance
        @remove = remove

        _restart false
      end

      def source=(serie)
        @source = serie
      end

      def remove=(remove)
        @remove = remove
      end

      def _restart(restart_sources = true)
        @source.restart if restart_sources
        @remove.times { @source.next_value }
      end

      def _next_value
        @source.next_value
      end
    end

    private_constant :Shifter

    class FromEvalBlockOnSerie
      include Serie

      attr_accessor :source, :with
      attr_accessor :on_restart, :block

      def initialize(serie, with: nil, on_restart: nil, &block)
        @source = serie.instance
        @with = with.instance if with

        @block = block
        @on_restart = on_restart

        _restart false
      end

      def _restart(restart_sources = true)
        if restart_sources
          @source.restart
          @with.restart if @with
          @on_restart.call if @on_restart
        end
      end

      def _next_value
        next_value = @source.next_value

        if @block && !next_value.nil?
          next_with = @with.next_value if @with

          if next_with
            @block.call next_value, next_with
          else
            @block.call next_value
          end
        else
          next_value
        end
      end
    end

    private_constant :FromEvalBlockOnSerie

    class HashFromSeriesArray
      include Serie

      attr_accessor :source
      attr_accessor :keys

      def initialize(serie, keys)
        @source = serie.instance
        @keys = keys
        _restart false
      end

      def _restart(restart_sources = true)
        @source.restart if restart_sources
      end

      def _next_value
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
  end
end
