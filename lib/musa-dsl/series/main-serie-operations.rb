module Musa
  module SerieOperations
    def autorestart(skip_nil: nil)
      skip_nil ||= false
      BasicSerieAutorestart.new self, skip_nil
    end

    def repeat(times = nil, condition: nil, &condition_block)
      condition ||= condition_block

      if times || condition
        BasicSerieRepeater.new self, times, &condition
      else
        BasicSerieInfiniteRepeater.new self
      end
    end

    def max_size(length)
      BasicSerieLengthLimiter.new self, length
    end

    def skip(length)
      BasicSerieSkipper.new self, length
    end

    def flatten(serie_of_series: nil)
      serie_of_series ||= false

      if serie_of_series
        FlattenSerieFromSerieOfSeries.new self
      else
        SerieFlattener.new self
      end
    end

    # TODO: test case
    def hashify(*keys)
      BasicHashSerieFromArraySerie.new self, keys
    end

    # TODO: test case
    def shift(shift)
      BasicSerieShifter.new self, shift
    end

    # TODO: test case
    def remove(positions)
      BasicSerieRemover.new self, positions
    end

    # TODO: test case
    def lock
      BasicSerieLocker.new self
    end

    # TODO: test case
    def reverse
      BasicSerieReverser.new self
    end

    # TODO: test case
    def randomize(random: nil)
      random ||= Random.new
      BasicSerieRandomizer.new self, random
    end

    # TODO: test case
    def eval(block = nil, with: nil, on_restart: nil, &yield_block)
      block ||= yield_block
      BasicSerieFromEvalBlockOnSerie.new self, with: with, on_restart: on_restart, &block
    end

    # TODO: test case
    def select(*indexed_series, **hash_series)
      SelectorBasicSerie.new self, indexed_series, hash_series
    end

    def multiplex(*indexed_series, **hash_series)
      MultiplexSelectorBasicSerie.new self, indexed_series, hash_series
    end

    # TODO: test case
    def select_serie(*indexed_series, **hash_series)
      SelectorFullSerieBasicSerie.new self, indexed_series, hash_series
    end

    def after(*series)
      SequenceBasicSerie.new [self, *series]
    end

    def +(serie)
      SequenceBasicSerie.new [duplicate, serie.duplicate]
    end

    def cut(length)
      CutterSerie.new self, length
    end

    def merge
      MergeSerieOfSeries.new self
    end

    # TODO: test case
    def slave
      slave_serie = SlaveSerie.new self

      @_slaves ||= []
      @_slaves << slave_serie

      slave_serie
    end

    # TODO: test case
    def to_a(recursive: nil, duplicate: nil, restart: nil)
      def copy_included_modules(source, target)
        target.tap do
          source.singleton_class.included_modules.each do |m|
            target.extend m unless target.is_a? m
          end
        end
      end

      def process(value)
        case value
        when Serie
          value.to_a(recursive: true)
        when Array
          a = value.collect { |v| v.is_a?(Serie) ? v.to_a(recursive: true) : process(v) }
          copy_included_modules value, a
        when Hash
          h = value.collect { |k, v| [process(k), v.is_a?(Serie) ? v.to_a(recursive: true) : process(v)] }.to_h
          copy_included_modules value, h
        else
          value
        end
      end

      recursive ||= false
      duplicate ||= true
      restart ||= true

      throw 'Cannot convert to array an infinite serie' if infinite?

      array = []

      serie = self
      serie = serie.duplicate if duplicate
      serie = serie.restart if restart

      while value = serie.next_value
        array << if recursive
                   process(value)
                 else
                   value
                 end
      end

      array
    end

    ###
    ### Implementation
    ###

    class SequenceBasicSerie
      include Serie

      attr_reader :sources

      def initialize(series)
        @sources = series
        _restart false
      end

      def sources=(series)
        @sources = series
        restart
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

    def deterministic?
      !@sources.find() { |t| !t.deterministic? }
    end

    private_constant :SequenceBasicSerie

    class SelectorBasicSerie
      include Serie

      attr_reader :selector, :sources

      def initialize(selector, indexed_series, hash_series)
        @selector = selector

        if indexed_series && !indexed_series.empty?
          @sources = indexed_series
        elsif hash_series && !hash_series.empty?
          @sources = hash_series
        end

        _restart false
      end

      def selector=(serie)
        @selector = serie
        @needs_restart = true
      end

      def sources=(series)
        @sources = series
        @needs_restart = true
      end

      def _restart(restart_sources = true)
        if restart_sources
          @selector.restart
          @sources.each(&:restart) if @sources.is_a? Array
          @sources.each { |_key, serie| serie.restart } if @sources.is_a? Hash
        end
        @needs_restart = false
      end

      def _next_value
        _restart(false) if @needs_restart

        value = nil

        index_or_key = @selector.next_value

        value = @sources[index_or_key].next_value unless index_or_key.nil?

        value
      end

      def infinite?
        @selector.infinite? && @sources.any? { |serie| serie.infinite? }
      end

      def deterministic?
        @selector.deterministic? && @sources.all? { |serie| serie.deterministic? }
      end
    end

    private_constant :SelectorBasicSerie

    class MultiplexSelectorBasicSerie
      include Serie

      attr_reader :selector, :sources

      def initialize(selector, indexed_series, hash_series)
        @selector = selector

        if indexed_series && !indexed_series.empty?
          @sources = indexed_series
        elsif hash_series && !hash_series.empty?
          @sources = hash_series
        end

        _restart false
      end

      def selector=(serie)
        @selector = serie
        @needs_restart = true
      end

      def sources=(series)
        @sources = series
        @needs_restart = true
      end

      def _restart(restart_sources = true)
        @current_value = nil

        if restart_sources
          @selector.restart
          @sources.each(&:restart) if @sources.is_a? Array
          @sources.each { |_key, serie| serie.restart } if @sources.is_a? Hash
        end

        @needs_restart = false
        @first = true
      end

      def _next_value
        _restart(false) if @needs_restart

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

      def deterministic?
        @selector.deterministic? && @sources.all? { |serie| serie.deterministic? }
      end
    end

    private_constant :MultiplexSelectorBasicSerie

    class SelectorFullSerieBasicSerie
      include Serie

      attr_reader :selector, :sources

      def initialize(selector, indexed_series, hash_series)
        @selector = selector

        if indexed_series && !indexed_series.empty?
          @sources = indexed_series
        elsif hash_series && !hash_series.empty?
          @sources = hash_series
        end

        _restart false
      end

      def selector=(serie)
        @selector = serie
        @needs_restart = true
      end

      def sources=(series)
        @sources = series
        @needs_restart = true
      end

      def _restart(restart_sources = true)
        if restart_sources
          @selector.restart
          @sources.each(&:restart)
        end
      end

      def _next_value
        _restart(false) if @needs_restart

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

    private_constant :SelectorFullSerieBasicSerie

    class BasicSerieInfiniteRepeater
      include Serie

      attr_reader :source

      def initialize(serie)
        @source = serie
        _restart false
      end

      def source=(serie)
        @source = serie
        restart
      end

      def _restart(restart_sources = true)
        @source.restart if restart_sources
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

      def deterministic?
        @source.deterministic?
      end
    end

    private_constant :BasicSerieInfiniteRepeater

    class BasicSerieRepeater
      include Serie

      attr_reader :source, :times, :condition

      def initialize(serie, times = nil, &condition_block)
        @source = serie

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

      def deterministic?
        @source.deterministic?
      end

      private

      def update_condition
        @condition = proc { @count < @times } if @times && !@condition
        @condition ||= proc { false }
      end
    end

    private_constant :BasicSerieRepeater

    class BasicSerieLengthLimiter
      include Serie

      attr_reader :source
      attr_accessor :length

      def initialize(serie, length)
        @source = serie
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

      def deterministic?
        @source.deterministic?
      end
    end

    private_constant :BasicSerieLengthLimiter

    class BasicSerieSkipper
      include Serie

      attr_reader :source, :length

      def initialize(serie, length)
        @source = serie
        @length = length

        _restart false
      end

      def source=(serie)
        @source = serie
        @needs_restart = true
      end

      def length=(length)
        @length = length
        @needs_restart = true
      end

      def _restart(restart_sources = true)
        if restart_sources
          @source.restart
        end
        @length.times { @source.next_value }
        @needs_restart = false
      end

      def _next_value
        _restart(false) if @needs_restart
        @source.next_value
      end

      def infinite?
        @source.infinite?
      end

      def deterministic?
        @source.deterministic?
      end
    end

    private_constant :BasicSerieSkipper

    class SerieFlattener
      include Serie

      attr_reader :source

      def initialize(serie)
        @source = serie

        _restart false
      end

      def source=(serie)
        @source = serie
        @needs_restart = true
      end

      def length=(length)
        @length = length
        @needs_restart = true
      end

      def _restart(restart_sources = true)
        if restart_sources
          @source.restart
          @restart_each_serie = true
        else
          @restart_each_serie = false
        end

        @stack = [@source]
        @needs_restart = false
      end

      def _next_value
        _restart(false) if @needs_restart

        if @stack.last
          value = @stack.last.next_value

          case value
          when Serie
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

      def deterministic?
        false # TODO revisar porque no se puede saber sin evaluar las subseries
      end
    end

    private_constant :SerieFlattener

    class FlattenSerieFromSerieOfSeries
      include Serie

      attr_accessor :source

      def initialize(serie)
        @source = serie
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

    private_constant :FlattenSerieFromSerieOfSeries

    class BasicSerieAutorestart
      include Serie

      attr_reader :source
      attr_accessor :skip_nil

      def initialize(serie, skip_nil)
        @source = serie
        @skip_nil = skip_nil

        @restart_on_next = false
        _restart false
      end

      def source=(serie)
        @source = serie
        @restart_on_next = false
        _restart
      end

      def _restart(restart_sources = true)
        @source.restart if restart_sources
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

    class CutterSerie
      include Serie

      def initialize(serie, length)
        @source = serie
        @length = length

        _restart false
      end

      def _restart(restart_sources = true)
        @source.restart if restart_sources
      end

      def _next_value
        @previous.materialize if @previous

        @previous = CutSerie.new @source, @length if @source.peek_next_value
      end

      private

      class CutSerie
        include Serie

        def initialize(serie, length)
          @source = serie
          @length = length

          @values = []
          _restart false
        end

        def _restart(restart_sources = true)
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

    private_constant :CutterSerie

    class MergeSerieOfSeries
      include Serie

      attr_reader :source

      def initialize(serie)
        @source = serie
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

    class BasicSerieLocker
      include Serie

      attr_reader :source

      def initialize(serie)
        @source = serie
        @values = []
        @first_round = true

        _restart false
      end

      def source=(serie)
        @source = serie
        @values = []
        @first_round = true

        _restart false
      end

      def _restart(restart_sources = true)
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

    private_constant :BasicSerieLocker

    class BasicSerieReverser
      include Serie

      attr_reader :source

      def initialize(serie)
        @source = serie
        _restart false
      end

      def source=(serie)
        raise ArgumentError, "cannot reverse an infinite serie #{serie}" if serie.infinite?

        @source = serie
        _restart false
      end

      def _restart(restart_sources = true)
        @source.restart if restart_sources
        @reversed = BasicSerieFromArray.new next_values_array_of(@source).reverse
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

    private_constant :BasicSerieReverser

    class BasicSerieRandomizer
      include Serie

      attr_reader :source, :random

      def initialize(serie, random)
        @source = serie
        @random = random

        _restart false
      end

      def source=(serie)
        raise ArgumentError, "cannot randomize an infinite serie #{serie}" if serie.infinite?

        @source = serie
        @needs_restart = true
      end

      def random=(random)
        @random = random
        @needs_restart = true
      end

      def _restart(restart_sources = true)
        @source.restart if restart_sources
        @values = @source.to_a

        @needs_restart = false
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

      def deterministic?
        false
      end
    end

    private_constant :BasicSerieRandomizer

    class BasicSerieShifter
      include Serie

      attr_reader :source, :shift

      def initialize(serie, shift)
        raise ArgumentError, "cannot shift to right an infinite serie #{serie}" if shift > 0 && serie.infinite?
        raise ArgumentError, 'cannot shift to right: function not yet implemented' if shift > 0

        self.source = serie
        self.shift = shift

        _restart false
      end

      def source=(serie)
        @source = serie
        @needs_restart = true
      end

      def shift=(shift)
        @shift = shift
        @needs_restart = true
      end

      def _restart(restart_sources = true)
        @source.restart if restart_sources

        @shifted = []
        @shift.abs.times { @shifted << @source.next_value } if @shift < 0

        @needs_restart = false
      end

      def _next_value
        _restart(false) if @needs_restart

        value = @source.next_value
        return value unless value.nil?

        @shifted.shift
      end
    end

    private_constant :BasicSerieShifter

    class BasicSerieRemover
      include Serie

      attr_reader :source, :remove

      def initialize(serie, remove)
        @source = serie
        @remove = remove

        _restart false
      end

      def source=(serie)
        @source = serie
        @needs_restart = true
      end

      def remove=(remove)
        @remove = remove
        @needs_restart = true
      end

      def _restart(restart_sources = true)
        @source.restart if restart_sources
        @remove.times { @source.next_value }

        @needs_restart = false
      end

      def _next_value
        _restart(false) if @needs_restart
        @source.next_value
      end
    end

    private_constant :BasicSerieShifter

    class BasicSerieFromEvalBlockOnSerie
      include Serie

      attr_reader :source, :with
      attr_accessor :on_restart, :block

      def initialize(serie, with: nil, on_restart: nil, &block)
        @source = serie
        @with = with if with

        @block = block
        @on_restart = on_restart

        _restart false
      end

      def source=(serie_or_array)
        if serie_or_array.is_a? Array
          @source = BasicSerieFromArray.new(serie_or_array)
        elsif serie_or_array.is_a? Serie
          @source = serie_or_array
        else
          raise ArgumentError, "serie is not an Array nor a Serie: #{serie_or_array}"
        end
        @needs_restart = true
      end

      def with=(with)
        case with
        when nil
          @with = nil
        when Array
          @with = BasicSerieFromArray.new with
        when Serie
          @with = with
        else
          raise ArgumentError, "with is not an Array nor a Serie: #{with}"
        end
        @needs_restart = true
      end

      def _restart(restart_sources = true)
        if restart_sources
          @source.restart
          @with.restart if @with
          @on_restart.call if @on_restart
        end

        @needs_restart = false
      end

      def _next_value
        _restart(false) if @needs_restart

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

    private_constant :BasicSerieFromEvalBlockOnSerie

    class BasicHashSerieFromArraySerie
      include Serie

      attr_reader :source
      attr_accessor :keys

      def initialize(serie, keys)
        @source = serie
        @keys = keys
        _restart false
      end

      def source=(serie)
        @source = serie
        restart
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

    private_constant :BasicHashSerieFromArraySerie
  end
end
