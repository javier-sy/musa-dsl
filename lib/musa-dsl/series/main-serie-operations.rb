module Musa
  module SerieOperations

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

    # TODO: test case
    def eval(block = nil, with: nil, on_restart: nil, &yield_block)
      block ||= yield_block
      FromEvalBlockOnSerie.new self, with: with, on_restart: on_restart, &block
    end

    alias_method :map, :eval

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
      Sequence.new [self, *series]
    end

    def +(other)
      Sequence.new [self, other]
    end

    def cut(length)
      Cutter.new self, length
    end

    def merge
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

    class Switcher
      include Serie

      attr_accessor :selector, :sources

      def initialize(selector, indexed_series, hash_series)

        @selector = selector
        get = @selector.prototype? ? :prototype : :instance

        if indexed_series && !indexed_series.empty?
          @sources = indexed_series.collect(&get)
        elsif hash_series && !hash_series.empty?
          @sources = hash_series.clone.transform_values(&get)
        end

        if get == :_prototype
          @sources.freeze
        end

        mark_regarding! @selector
      end

      def _prototype
        @selector = @selector.prototype
        @sources = @sources.collect(&:prototype).freeze if @sources.is_a? Array
        @sources.transform_values(&:prototype).freeze if @sources.is_a? Hash
      end

      def _instance
        @selector = @selector.instance
        @sources = @sources.collect(&:instance) if @sources.is_a? Array
        @sources.transform_values(&:_instance) if @sources.is_a? Hash
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

    private_constant :Switcher

    class MultiplexSelector
      include Serie

      attr_accessor :selector, :sources

      def initialize(selector, indexed_series, hash_series)
        @selector = selector
        get = @selector.prototype? ? :prototype : :instance

        if indexed_series && !indexed_series.empty?
          @sources = indexed_series.collect(&get)
        elsif hash_series && !hash_series.empty?
          @sources = hash_series.clone.transform_values(&get)
        end

        _restart false

        if get == :_prototype
          @sources.freeze
        end

        mark_regarding! @selector
      end

      def _prototype
        @selector = @selector.prototype
        @sources = @sources.collect(&:prototype).freeze if @sources.is_a? Array
        @sources.transform_values(&:prototype).freeze if @sources.is_a? Hash
      end

      def _instance
        @selector = @selector.instance
        @sources = @sources.collect(&:instance) if @sources.is_a? Array
        @sources.transform_values(&:_instance) if @sources.is_a? Hash
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

    class SwitchFullSerie
      include Serie

      attr_accessor :selector, :sources

      def initialize(selector, indexed_series, hash_series)
        @selector = selector
        get = @selector.prototype? ? :prototype : :instance

        if indexed_series && !indexed_series.empty?
          @sources = indexed_series.collect(&get)
        elsif hash_series && !hash_series.empty?
          @sources = hash_series.clone.transform_values(&get)
        end

        if get == :_prototype
          @sources.freeze
        end

        mark_regarding! @selector
      end

      def _prototype
        @selector = @selector.prototype
        @sources = @sources.collect(&:prototype).freeze if @sources.is_a? Array
        @sources.transform_values(&:prototype).freeze if @sources.is_a? Hash
      end

      def _instance
        @selector = @selector.instance
        @sources = @sources.collect(&:instance) if @sources.is_a? Array
        @sources.transform_values(&:_instance) if @sources.is_a? Hash
      end

      def _restart
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

    private_constant :SwitchFullSerie

    class InfiniteRepeater
      include Serie

      attr_reader :source

      def initialize(serie)
        @source = serie

        mark_regarding! @source
      end

      def _prototype
        @source = @source.prototype
      end

      def _instance
        @source = @source.instance
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
        @source = serie

        @times = times
        @condition = condition_block

        update_condition
        _restart false

        mark_regarding! @source
      end

      def _prototype
        @source = @source.prototype
      end

      def _instance
        @source = @source.instance
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

      attr_reader :source, :length

      def initialize(serie, length)
        @source = serie
        @length = length

        _restart false

        mark_regarding! @source
      end

      def _prototype
        @source = @source.prototype
      end

      def _instance
        @source = @source.instance
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

      attr_reader :source, :length

      def initialize(serie, length)
        @source = serie
        @length = length

        _restart false

        mark_regarding! @source
      end

      def _prototype
        @source = @source.prototype
      end

      def _instance
        @source = @source.instance
      end

      def _restart(restart_sources = true)
        @source.restart if restart_sources
        @first = true
      end

      def _next_value
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
      include Serie

      attr_reader :source

      def initialize(serie)
        @source = serie

        _restart false

        mark_regarding! @source
      end

      def _prototype
        @source = @source.prototype
        _restart false
      end

      def _instance
        @source = @source.instance
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

    class MergeSerieOfSeries
      include Serie

      attr_reader :source

      def initialize(serie)
        @source = serie
        _restart false

        mark_regarding! @source
      end

      def _prototype
        @source = @source.prototype
      end

      def _instance
        @source = @source.instance
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
      include Serie

      attr_reader :source

      def initialize(serie, parameters, &processor)
        @source = serie
        @parameters = parameters
        @processor = KeyParametersProcedureBinder.new(processor)

        _restart false

        mark_regarding! @source
      end

      def _prototype
        @source = @source.prototype
      end

      def _instance
        @source = @source.instance
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

    class Autorestart
      include Serie

      attr_reader :source

      def initialize(serie)
        @source = serie

        @restart_on_next = false

        mark_regarding! @source
      end

      def _prototype
        @source = @source.prototype
      end

      def _instance
        @source = @source.instance
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

        @restart_on_next = value.nil?

        value
      end
    end

    private_constant :Autorestart

    class Cutter
      include Serie

      attr_reader :source, :length

      def initialize(serie, length)
        @source = serie
        @length = length

        mark_regarding! @source
      end

      def _prototype
        @source = @source.prototype
      end

      def _instance
        @source = @source.instance
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
          @source = serie
          @length = length

          @values = []
          _restart

          mark_as_instance!
        end

        def _prototype
          raise PrototypingSerieError, 'Cannot get prototype of a cut serie'
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

    class Locker
      include Serie

      attr_reader :source

      def initialize(serie)
        @source = serie
        @values = []
        @first_round = true

        _restart

        mark_regarding! @source
      end

      def _prototype
        @source = @source.prototype
      end

      def _instance
        @source = @source.instance
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
        @source = serie
        _restart false, false

        mark_regarding! @source
      end

      def _prototype
        @source = @source.prototype
      end

      def _instance
        @source = @source.instance
        _restart false, true
      end

      def _restart(restart_sources = true, get_reversed = true)
        @source.restart if restart_sources
        @reversed = FromArray.new(next_values_array_of(@source).reverse).instance if get_reversed
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
        @source = serie
        @random = random

        _restart false

        mark_regarding! @source
      end

      def _prototype
        @source = @source.prototype
      end

      def _instance
        @source = @source.instance
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

        @source = serie
        @shift = shift

        _restart false

        mark_regarding! @source
      end

      def _prototype
        @source = @source.prototype
      end

      def _instance
        @source = @source.instance
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

      def initialize(serie, &block)
        @source = serie
        @block = block
        @history = []

        _restart false

        mark_regarding! @source
      end

      def _prototype
        @source = @source.prototype
      end

      def _instance
        @source = @source.instance
      end

      def _restart(restart_sources = true)
        @source.restart if restart_sources
        @history.clear
      end

      def _next_value
        if value = @source.next_value
          while @block.call(value, @history)
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
      include Serie

      attr_reader :source, :remove

      def initialize(serie, &block)
        @source = serie
        @block = block

        _restart false

        mark_regarding! @source
      end

      def _prototype
        @source = @source.prototype
      end

      def _instance
        @source = @source.instance
      end

      def _restart(restart_sources = true)
        @source.restart if restart_sources
      end

      def _next_value
        value = @source.next_value
        until value.nil? || @block.call(value)
          value = @source.next_value
        end
        value
      end
    end

    private_constant :Selector

    class FromEvalBlockOnSerie
      include Serie

      attr_reader :source, :with, :on_restart, :block

      def initialize(serie, with: nil, on_restart: nil, &block)
        @source = serie
        @with = with if with

        @block = block
        @on_restart = on_restart

        _restart false

        mark_regarding! @source
      end

      def _prototype
        @source = @source.prototype
        @with = @with.prototype if @with
      end

      def _instance
        @source = @source.instance
        @with = @with.instance if @with
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

      attr_reader :source, :keys

      def initialize(serie, keys)
        @source = serie
        @keys = keys
        _restart false

        mark_regarding! @source
      end

      def _prototype
        @source = @source.prototype
      end

      def _instance
        @source = @source.instance
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
