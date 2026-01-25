module Musa
  module Series
    # Series transformation operations for composing and modifying series.
    #
    # Provides methods for transforming, combining, and controlling series flow.
    # All operations return new series (functional/immutable style).
    #
    # ## Categories
    #
    # ### Mapping & Transformation
    #
    # - **map** - Transform values via block
    # - **with** - Combine multiple series for mapping
    # - **process_with** - Generic processor with parameters
    # - **hashify** - Convert array values to hash
    # - **shift** - Shift values by offset
    #
    # ### Filtering & Selection
    #
    # - **select** - Keep values matching condition
    # - **remove** - Remove values matching condition
    # - **skip** - Skip first N values
    # - **max_size** - Limit to N values
    # - **cut** - Cut into chunks
    #
    # ### Flow Control
    #
    # - **repeat** - Repeat series N times or conditionally
    # - **autorestart** - Auto-restart when exhausted
    # - **flatten** - Flatten nested series
    # - **merge** - Merge serie of series
    # - **after** / **+** - Append series sequentially
    #
    # ### Switching & Multiplexing
    #
    # - **switch** - Switch between series based on selector
    # - **multiplex** - Multiplex series based on selector
    # - **switch_serie** - Switch to different series entirely
    #
    # ### Structural Operations
    #
    # - **reverse** - Reverse values
    # - **randomize** - Shuffle values randomly
    # - **lock** - Lock serie (prevent changes)
    # - **flatten** - Flatten nested series
    #
    # ### Timing Operations
    #
    # - **anticipate** - Evaluate block one step ahead
    # - **lazy** - Delay evaluation to next step
    #
    # ## Usage Patterns
    #
    # ### Mapping
    #
    # ```ruby
    # notes = S(60, 64, 67).map { |n| n + 12 }  # Transpose octave
    # notes.i.to_a  # => [72, 76, 79]
    # ```
    #
    # ### Filtering
    #
    # ```ruby
    # evens = S(1, 2, 3, 4, 5, 6).select { |n| n.even? }
    # evens.i.to_a  # => [2, 4, 6]
    # ```
    #
    # ### Combining
    #
    # ```ruby
    # pitches = S(60, 64, 67)
    # velocities = S(96, 80, 64)
    # notes = pitches.with(velocities) { |p, v| {pitch: p, velocity: v} }
    # ```
    #
    # ### Repeating
    #
    # ```ruby
    # pattern = S(1, 2, 3).repeat(3)
    # pattern.i.to_a  # => [1, 2, 3, 1, 2, 3, 1, 2, 3]
    # ```
    #
    # ### Chaining Operations
    #
    # ```ruby
    # result = S(1, 2, 3, 4, 5)
    #   .select { |n| n.even? }
    #   .map { |n| n * 10 }
    #   .repeat(2)
    # result.i.to_a  # => [20, 40, 20, 40]
    # ```
    #
    # @see Musa::Series::Constructors Serie creation methods
    #
    # @api public
    module Operations
      # Auto-restarts serie when exhausted.
      #
      # Creates an infinite serie from an original serie that automatically restarts from beginning
      # when it reaches the end.
      #
      # @return [Autorestart] auto-restarting serie
      #
      # @example Infinite loop
      #   pattern = S(1, 2, 3).autorestart
      #   pattern.infinite?  # => true
      #   inst = pattern.i
      #   inst.max_size(7).to_a  # => [1, 2, 3, 1, 2, 3, 1]
      #
      # @api public
      def autorestart
        Autorestart.new self
      end

      # Repeats serie multiple times or conditionally.
      #
      # Three modes:
      # - **times**: Repeat exact number of times
      # - **condition**: Repeat while condition true
      # - **neither**: Infinite repetition
      #
      # @param times [Integer, nil] number of repetitions
      # @param condition [Proc, nil] condition block
      # @yield optional condition block
      #
      # @return [Repeater, InfiniteRepeater] repeating serie
      #
      # @example Fixed repetitions
      #   s = S(1, 2, 3).repeat(3)
      #   s.i.to_a  # => [1, 2, 3, 1, 2, 3, 1, 2, 3]
      #
      # @example Conditional repeat
      #   count = 0
      #   s = S(1, 2, 3).repeat { count += 1; count < 3 }
      #
      # @example Infinite repeat
      #   s = S(1, 2, 3).repeat
      #   s.infinite?  # => true
      #
      # @api public
      def repeat(times = nil, condition: nil, &condition_block)
        condition ||= condition_block

        if times || condition
          Repeater.new self, times, &condition
        else
          InfiniteRepeater.new self
        end
      end

      # Limits serie to maximum number of values.
      #
      # Stops after N values regardless of source length.
      #
      # @param length [Integer] maximum number of values
      #
      # @return [LengthLimiter] length-limited serie
      #
      # @example Limit to 5
      #   s = FOR(from: 0, step: 1).max_size(5)
      #   s.i.to_a  # => [0, 1, 2, 3, 4]
      #
      # @api public
      def max_size(length)
        LengthLimiter.new self, length
      end

      # Skips first N values.
      #
      # Discards first `length` values, returns rest.
      #
      # @param length [Integer] number of values to skip
      #
      # @return [Skipper] serie with skipped values
      #
      # @example Skip first 2
      #   s = S(1, 2, 3, 4, 5).skip(2)
      #   s.i.to_a  # => [3, 4, 5]
      #
      # @api public
      def skip(length)
        Skipper.new self, length
      end

      # Flattens nested series into single level.
      #
      # Recursively consumes series elements that are themselves series.
      #
      # @return [Flattener] flattened serie
      #
      # @example Flatten nested
      #   s = S(S(1, 2), S(3, 4), 5).flatten
      #   s.i.to_a  # => [1, 2, 3, 4, 5]
      #
      # @api public
      def flatten
        Flattener.new self
      end

      # Processes values with parameterized block.
      #
      # Generic processor passing values and parameters to block.
      #
      # @param parameters [Hash] parameters passed to processor block
      # @yield processor block
      # @yieldparam value [Object] current value
      # @yieldparam parameters [Hash] processor parameters
      #
      # @return [Processor] processed serie
      #
      # @api public
      def process_with(**parameters, &processor)
        Processor.new self, parameters, &processor
      end

      # Converts array values to hash with specified keys.
      #
      # Takes array-valued serie and converts to hash using provided keys.
      #
      # @param keys [Array] hash keys for array elements
      #
      # @return [HashFromSeriesArray] hashified serie
      #
      # @example Array to hash
      #   s = S([60, 96], [64, 80]).hashify(:pitch, :velocity)
      #   s.i.next_value  # => {pitch: 60, velocity: 96}
      #
      # @api public
      def hashify(*keys)
        HashFromSeriesArray.new self, keys
      end

      # Rotates serie elements circularly.
      #
      # Performs circular rotation of elements:
      # - Negative values rotate left (first elements move to end)
      # - Positive values rotate right (last elements move to beginning)
      # - Zero performs no rotation
      #
      # Note: Right rotation (positive values) requires finite series as the
      # entire serie must be loaded into memory for rotation.
      #
      # @param shift [Integer] rotation amount
      #   - Negative: rotate left by N positions
      #   - Positive: rotate right by N positions
      #   - Zero: no rotation
      #
      # @return [Shifter] rotated serie
      #
      # @example Rotate left (negative shift)
      #   s = S(60, 64, 67).shift(-1)  # First element moves to end
      #   s.i.to_a  # => [64, 67, 60]
      #
      # @example Rotate right (positive shift)
      #   s = S(1, 2, 3, 4, 5).shift(2)  # Last 2 elements move to beginning
      #   s.i.to_a  # => [4, 5, 1, 2, 3]
      #
      # @example No rotation
      #   s = S(1, 2, 3).shift(0)
      #   s.i.to_a  # => [1, 2, 3]
      #
      # @api public
      def shift(shift)
        Shifter.new self, shift
      end

      # Locks serie preventing further modifications.
      #
      # Returns locked copy that cannot be transformed further.
      #
      # @return [Locker] locked serie
      #
      # @api public
      def lock
        Locker.new self
      end

      # Reverses order of values.
      #
      # Consumes entire serie and returns values in reverse order.
      # Requires finite serie.
      #
      # @return [Reverser] reversed serie
      #
      # @example Retrograde
      #   s = S(1, 2, 3, 4).reverse
      #   s.i.to_a  # => [4, 3, 2, 1]
      #
      # @api public
      def reverse
        Reverser.new self
      end

      # Randomizes order of values.
      #
      # Shuffles values randomly. Requires finite serie.
      #
      # @param random [Random, nil] Random instance (default: new Random)
      #
      # @return [Randomizer] randomized serie
      #
      # @example Shuffle
      #   s = S(1, 2, 3, 4, 5).randomize
      #   s.i.to_a  # => random permutation
      #
      # @api public
      def randomize(random: nil)
        random ||= Random.new
        Randomizer.new self, random
      end

      # Removes values matching condition.
      #
      # Filters out values where block returns true.
      #
      # @param block [Proc, nil] filter block
      # @yield filter condition
      # @yieldparam value [Object] current value
      # @yieldreturn [Boolean] true to remove value
      #
      # @return [Remover] filtered serie
      #
      # @example Remove odds
      #   s = S(1, 2, 3, 4, 5).remove { |n| n.odd? }
      #   s.i.to_a  # => [2, 4]
      #
      # @api public
      def remove(block = nil, &yield_block)
        block ||= yield_block
        Remover.new self, &block
      end

      # Selects values matching condition.
      #
      # Keeps only values where block returns true.
      #
      # @param block [Proc, nil] filter block
      # @yield filter condition
      # @yieldparam value [Object] current value
      # @yieldreturn [Boolean] true to keep value
      #
      # @return [Selector] filtered serie
      #
      # @example Select evens
      #   s = S(1, 2, 3, 4, 5).select { |n| n.even? }
      #   s.i.to_a  # => [2, 4]
      #
      # @api public
      def select(block = nil, &yield_block)
        block ||= yield_block
        Selector.new self, &block
      end

      # Switches between multiple series based on selector values.
      #
      # Uses selector serie to choose which source serie to read from.
      # Selector values can be indices (Integer) or keys (Symbol).
      #
      # @param indexed_series [Array] series indexed by integer
      # @param hash_series [Hash] series indexed by symbol key
      #
      # @return [Switcher] switching serie
      #
      # @example Index switching
      #   s1 = S(1, 2, 3)
      #   s2 = S(10, 20, 30)
      #   selector = S(0, 1, 0, 1)
      #   result = selector.switch(s1, s2)
      #   result.i.to_a  # => [1, 10, 2, 20]
      #
      # @api public
      def switch(*indexed_series, **hash_series)
        Switcher.new self, indexed_series, hash_series
      end

      # Multiplexes values from multiple series based on selector.
      #
      # Like switch but returns composite values instead of switching.
      #
      # @param indexed_series [Array] series to multiplex
      # @param hash_series [Hash] series to multiplex by key
      #
      # @return [MultiplexSelector] multiplexed serie
      #
      # @api public
      def multiplex(*indexed_series, **hash_series)
        MultiplexSelector.new self, indexed_series, hash_series
      end

      # Switches to entirely different series based on selector.
      #
      # Changes which serie is being consumed entirely.
      #
      # @param indexed_series [Array] series to switch between
      # @param hash_series [Hash] series to switch between by key
      #
      # @return [SwitchFullSerie] serie switcher
      #
      # @api public
      def switch_serie(*indexed_series, **hash_series)
        SwitchFullSerie.new self, indexed_series, hash_series
      end

      # Appends series sequentially.
      #
      # Alias for MERGE - plays this serie, then others in sequence.
      #
      # @param series [Array<Serie>] series to append
      #
      # @return [Sequence] sequential combination
      #
      # @example Append
      #   s = S(1, 2).after(S(3, 4), S(5, 6))
      #   s.i.to_a  # => [1, 2, 3, 4, 5, 6]
      #
      # @api public
      def after(*series)
        Musa::Series::Constructors.MERGE self, *series
      end

      # Appends another serie (operator alias for after).
      #
      # @param other [Serie] serie to append
      #
      # @return [Sequence] sequential combination
      #
      # @example Concatenate
      #   s = S(1, 2) + S(3, 4)
      #   s.i.to_a  # => [1, 2, 3, 4]
      #
      # @api public
      def +(other)
        Musa::Series::Constructors.MERGE self, other
      end

      # Cuts serie into chunks of specified length.
      #
      # Returns serie of arrays, each containing `length` values.
      #
      # @param length [Integer] chunk size
      #
      # @return [Cutter] chunked serie
      #
      # @example Cut into pairs
      #   s = S(1, 2, 3, 4, 5, 6).cut(2)
      #   s.i.to_a  # => [[1, 2], [3, 4], [5, 6]]
      #
      # @api public
      def cut(length)
        Cutter.new self, length
      end

      # Merges serie of series into single serie.
      #
      # Flattens one level: consumes serie where each element is itself
      # a serie, merging them sequentially.
      #
      # @return [MergeSerieOfSeries] merged serie
      #
      # @example Merge phrases
      #   phrases = S(S(1, 2, 3), S(4, 5, 6))
      #   merged = phrases.merge
      #   merged.i.to_a  # => [1, 2, 3, 4, 5, 6]
      #
      # @api public
      def merge
        MergeSerieOfSeries.new self
      end

      # Combines multiple series for mapping.
      #
      # Synchronously iterates multiple series, passing all values to block.
      # Enables multi-voice transformations and combinations.
      #
      # ## Parameters
      #
      # - **with_series**: Positional series (passed as array to block)
      # - **with_key_series**: Named series (passed as keywords to block)
      # - **on_restart**: Block called on restart
      # - **isolate_values**: Clone values to prevent mutation
      #
      # ## Block Parameters
      #
      # Block receives:
      # - Main serie value (first argument)
      # - Positional with_series values (array)
      # - Keyword with_key_series values (keywords)
      #
      # @param with_series [Array<Serie>] positional series to combine
      # @param on_restart [Proc, nil] restart callback
      # @param isolate_values [Boolean, nil] clone values to prevent mutation
      # @param with_key_series [Hash] keyword series to combine
      # @yield combination block
      # @yieldparam main_value [Object] value from main serie
      # @yieldparam with_values [Array] values from positional series
      # @yieldparam with_key_values [Hash] values from keyword series
      # @yieldreturn [Object] combined value
      #
      # @return [With] combined serie
      #
      # @example Combine pitches and velocities
      #   pitches = S(60, 64, 67)
      #   velocities = S(96, 80, 64)
      #   notes = pitches.with(velocities) { |p, v| {pitch: p, velocity: v} }
      #   notes.i.to_a  # => [{pitch: 60, velocity: 96}, ...]
      #
      # @example Named series
      #   melody = S(60, 64, 67)
      #   rhythm = S(1r, 0.5r, 0.5r)
      #   combined = melody.with(duration: rhythm) { |pitch, duration:|
      #     {pitch: pitch, duration: duration}
      #   }
      #
      # @api public
      def with(*with_series, on_restart: nil, isolate_values: nil, **with_key_series, &block)
        if with_series.any? && with_key_series.any?
          raise ArgumentError, 'Can\'t use extra parameters series and key named parameters series'
        end

        extra_series = if with_series.any?
                         with_series
                       elsif with_key_series.any?
                         with_key_series
                       end

        isolate_values ||= isolate_values.nil? ? true : isolate_values

        ProcessWith.new self, extra_series, on_restart, isolate_values: isolate_values, &block
      end

      # Alias for {#with}.
      #
      # @api public
      alias_method :eval, :with

      # Maps values via transformation block.
      #
      # Simplest and most common transformation. Applies block to each value.
      # Shorthand for `with` without additional series.
      #
      # @param isolate_values [Boolean, nil] clone values to prevent mutation (default: false)
      # @yield transformation block
      # @yieldparam value [Object] current value
      # @yieldreturn [Object] transformed value
      #
      # @return [ProcessWith] mapped serie
      #
      # @example Transpose notes
      #   notes = S(60, 64, 67).map { |n| n + 12 }
      #   notes.i.to_a  # => [72, 76, 79]
      #
      # @example Transform to hash
      #   s = S(1, 2, 3).map { |n| {value: n, squared: n**2} }
      #
      # @api public
      def map(isolate_values: nil, &block)
        isolate_values ||= isolate_values.nil? ? false : isolate_values

        ProcessWith.new self, isolate_values: isolate_values, &block
      end

      # Evaluates block one step ahead (anticipate).
      #
      # Block receives current value and NEXT value (peeked).
      # Enables look-ahead transformations and transitions.
      #
      # @yield anticipation block
      # @yieldparam current [Object] current value
      # @yieldparam next_value [Object, nil] next value (nil if last)
      # @yieldreturn [Object] transformed value
      #
      # @return [Anticipate] anticipating serie
      #
      # @example Smooth transitions
      #   s = S(1, 5, 3, 8).anticipate { |current, next_val|
      #     next_val ? (current + next_val) / 2.0 : current
      #   }
      #
      # @example Add interval information
      #   notes = S(60, 64, 67, 72).anticipate { |pitch, next_pitch|
      #     interval = next_pitch ? next_pitch - pitch : nil
      #     {pitch: pitch, interval: interval}
      #   }
      #
      # @api public
      def anticipate(&block)
        Anticipate.new self, &block
      end

      # Delays evaluation to next step (lazy evaluation).
      #
      # Block receives previous value and evaluates for current step.
      # Enables state-dependent transformations.
      #
      # @yield lazy evaluation block
      # @yieldparam previous [Object, nil] previous value
      # @yieldreturn [Object] current value
      #
      # @return [LazySerieEval] lazy-evaluated serie
      #
      # @example Cumulative sum
      #   s = S(1, 2, 3, 4).lazy { |prev| (prev || 0) + value }
      #
      # @api public
      def lazy(&block)
        LazySerieEval.new self, &block
      end

      ###
      ### Implementation
      ###

      class ProcessWith
        # @!parse include Musa::Series::Serie::WithSource
        # @!parse include Musa::Series::Serie::WithSources
        # @!parse include Musa::Series::Serie::WithBlock
        include Serie.with(source: true,
                           sources: true, sources_as: :with_sources, mandatory_sources: false,
                           smart_block: true)

        using Musa::Extension::Arrayfy

        def initialize(serie, with_series = nil, on_restart = nil, isolate_values: nil, &block)
          self.source = serie
          self.with_sources = with_series || []
          self.on_restart = on_restart

          if block
            self.proc = block
          elsif !with_series
            proc { |_| _ }
          end

          @isolate_values = isolate_values

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

          case @sources
          when Array
            @sources.each(&:restart)
          when Hash
            @sources.each_value(&:restart)
          end

          @on_restart.call if @on_restart
        end

        private def _next_value
          main = @source.next_value

          others = case @sources
                   when Array
                     @sources.map(&:next_value)
                   when Hash
                     @sources.transform_values(&:next_value)
                  end

          value = nil


          if main
            case others
            when Array
              unless others.include?(nil)
                value = if @block
                          if @isolate_values
                            raise ArgumentError, "Received 'with_sources' as an Array and asked to 'isolate_values'. This can't be done. Please, set 'isolate_values' to false or make with_sources to be a Hash." if others.any?

                            @block._call([main])
                          else
                            @block._call(main.arrayfy + others)
                          end
                        else
                          if @isolate_values
                            [main, others]
                          else
                            main.arrayfy + others
                          end
                        end
              end

            when Hash
              unless others.values.include?(nil)
                value = if @block
                          @block._call(main, others)
                        else
                          [main, others]
                        end
              end
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
        # @!parse include Musa::Series::Serie::WithSource
        # @!parse include Musa::Series::Serie::WithBlock
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
        # @!parse include Musa::Series::Serie::WithSource
        # @!parse include Musa::Series::Serie::WithSources
        include Serie.with(source: true, sources: true, sources_as: :options)

        def initialize(selector, indexed_series, hash_series)
          self.source = selector
          self.options = indexed_series || hash_series

          init
        end

        private :_restart
        def _restart
          @source.restart
          if @sources.is_a? Array
            @sources.each(&:restart)
          elsif @sources.is_a? Hash
            @sources.each { |_key, serie| serie.restart }
          end
        end

        private :_next_value
        def _next_value
          value = nil

          index_or_key = @source.next_value

          value = @sources[index_or_key].next_value unless index_or_key.nil?

          value
        end

        def infinite?
          @source.infinite? && @sources.any?(&:infinite?)
        end
      end

      private_constant :Switcher

      class MultiplexSelector
        # @!parse include Musa::Series::Serie::WithSource
        # @!parse include Musa::Series::Serie::WithSources
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
          @source.infinite? && @sources.any?(&:infinite?)
        end
      end

      private_constant :MultiplexSelector

      class SwitchFullSerie
        # @!parse include Musa::Series::Serie::WithSource
        # @!parse include Musa::Series::Serie::WithSources
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
        # @!parse include Musa::Series::Serie::WithSource
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
        # @!parse include Musa::Series::Serie::WithSource
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
        # @!parse include Musa::Series::Serie::WithSource
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
        # @!parse include Musa::Series::Serie::WithSource
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
        # @!parse include Musa::Series::Serie::WithSource
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

      # Serie operation that processes/transforms values using a block.
      #
      # Applies transformation function to each value from source serie.
      # The block can return single values or arrays (which are flattened
      # into the output stream).
      #
      # Uses smart block binding for flexible parameter handling.
      #
      # @example Simple transformation
      #   serie = FromArray.new([1, 2, 3])
      #   processor = Processor.new(serie, {}) { |v| v * 2 }
      #   processor.next_value  # => 2
      #   processor.next_value  # => 4
      #
      # @example Transformation with parameters
      #   processor = Processor.new(serie, multiplier: 3) { |v, multiplier:| v * multiplier }
      #
      # @example Returning arrays (flattened)
      #   processor = Processor.new(serie, {}) { |v| [v, v + 1] }
      #   processor.next_value  # => 1
      #   processor.next_value  # => 2
      #
      # @api private
      class Processor
        # @!parse include Musa::Series::Serie::WithSource
        # @!parse include Musa::Series::Serie::WithBlock
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

            value = _next_value if value.nil?

            value
          end
        end

        def infinite?
          @source.infinite?
        end
      end

      class Autorestart
        # @!parse include Musa::Series::Serie::WithSource
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
        # @!parse include Musa::Series::Serie::WithSource
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
          # @!parse include Musa::Series::Serie::WithSource
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
        # @!parse include Musa::Series::Serie::WithSource
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
        # @!parse include Musa::Series::Serie::WithSource
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
        # @!parse include Musa::Series::Serie::WithSource
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
        # @!parse include Musa::Series::Serie::WithSource
        include Serie.with(source: true)

        def initialize(serie, shift)
          self.shift = shift
          self.source = serie

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

          @shift = value
        end

        private def _init
          @shifted = []
          @buffer = []
          @buffer_index = 0
          @first = true
        end

        private def _restart
          @source.restart
        end

        private def _next_value
          if @first
            if @shift < 0
              # Shift left: guardar primeros N elementos para moverlos al final
              @shift.abs.times { @shifted << @source.next_value }
            elsif @shift > 0
              # Shift right: leer toda la serie y rotarla
              while (value = @source.next_value)
                @buffer << value
              end

              # Rotar: tomar últimos N elementos y ponerlos al principio
              if @buffer.size >= @shift
                last_elements = @buffer.pop(@shift)
                @buffer = last_elements + @buffer
              end
            end

            @first = false
          end

          # Retornar valores según el tipo de shift
          if @shift > 0
            # Shift derecho: devolver del buffer pre-cargado
            return nil if @buffer_index >= @buffer.size
            value = @buffer[@buffer_index]
            @buffer_index += 1
            value
          else
            # Shift izquierdo o sin shift: lógica original
            value = @source.next_value
            return value unless value.nil?

            @shifted.shift
          end
        end
      end

      private_constant :Shifter

      class Remover
        # @!parse include Musa::Series::Serie::WithSource
        # @!parse include Musa::Series::Serie::WithBlock
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
        # @!parse include Musa::Series::Serie::WithSource
        # @!parse include Musa::Series::Serie::WithBlock
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
        # @!parse include Musa::Series::Serie::WithSource
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
        # @!parse include Musa::Series::Serie::WithSource
        # @!parse include Musa::Series::Serie::WithBlock
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
