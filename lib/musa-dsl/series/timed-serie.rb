require_relative '../datasets/e'

require_relative 'base-series'

module Musa
  module Series::Constructors
    # Merges multiple timed series by synchronizing events at each time point.
    #
    # TIMED_UNION combines series with `:time` attributes, emitting events at each
    # unique time where at least one source has a value. Sources without values at
    # a given time emit `nil`. Operates in two distinct modes based on input format.
    #
    # ## Timed Series Format
    #
    # Each event is a hash with `:time` and `:value` keys, extended with AbsTimed:
    #
    # ```ruby
    # { time: 0r, value: 60, duration: 1r }.extend(Musa::Datasets::AbsTimed)
    # ```
    #
    # Additional attributes (`:duration`, `:velocity`, etc.) are preserved and
    # synchronized alongside values.
    #
    # ## Operating Modes
    #
    # **Array Mode**: `TIMED_UNION(s1, s2, s3)`
    # - Anonymous positional sources
    # - Output: `{ time: t, value: [val1, val2, val3] }`
    # - Use for: Ordered tracks without specific names
    #
    # **Hash Mode**: `TIMED_UNION(melody: s1, bass: s2)`
    # - Named sources with keys
    # - Output: `{ time: t, value: { melody: val1, bass: val2 } }`
    # - Use for: Identified voices/tracks for routing
    #
    # ## Value Types and Combination
    #
    # **Direct values** (integers, strings, etc.):
    # ```ruby
    # s1 = S({ time: 0, value: 60 })
    # s2 = S({ time: 0, value: 64 })
    # TIMED_UNION(s1, s2)  # => { time: 0, value: [60, 64] }
    # ```
    #
    # **Hash values** (polyphonic events):
    # ```ruby
    # s1 = S({ time: 0, value: { a: 1, b: 2 } })
    # s2 = S({ time: 0, value: { c: 10 } })
    # TIMED_UNION(s1, s2)  # => { time: 0, value: { a: 1, b: 2, c: 10 } }
    # ```
    #
    # **Array values** (multi-element events):
    # ```ruby
    # s1 = S({ time: 0, value: [1, 2] })
    # s2 = S({ time: 0, value: [10, 20] })
    # TIMED_UNION(s1, s2)  # => { time: 0, value: [1, 2, 10, 20] }
    # ```
    #
    # **Mixed Hash + Direct** (advanced):
    # ```ruby
    # s1 = S({ time: 0, value: { a: 1, b: 2 } })
    # s2 = S({ time: 0, value: 100 })
    # TIMED_UNION(s1, s2)  # => { time: 0, value: { a: 1, b: 2, 0 => 100 } }
    # ```
    #
    # ## Synchronization Behavior
    #
    # Events are emitted at each unique time point across all sources:
    #
    # ```ruby
    # s1 = S({ time: 0r, value: 1 }, { time: 2r, value: 3 })
    # s2 = S({ time: 1r, value: 10 })
    # TIMED_UNION(s1, s2).i.to_a
    # # => [{ time: 0r, value: [1, nil] },
    # #     { time: 1r, value: [nil, 10] },
    # #     { time: 2r, value: [3, nil] }]
    # ```
    #
    # ## Extra Attributes
    #
    # Non-standard attributes (beyond `:time`, `:value`) are synchronized:
    #
    # ```ruby
    # s1 = S({ time: 0, value: 1, velocity: 80 })
    # s2 = S({ time: 0, value: 10, duration: 1r })
    # TIMED_UNION(s1, s2)
    # # => { time: 0, value: [1, 10], velocity: [80, nil], duration: [nil, 1r] }
    # ```
    #
    # @param array_of_timed_series [Array<Serie>] timed series (array mode)
    # @param hash_of_timed_series [Hash{Symbol => Serie}] named timed series (hash mode)
    #
    # @return [TimedUnionOfArrayOfTimedSeries, TimedUnionOfHashOfTimedSeries] merged serie
    #
    # @raise [ArgumentError] if mixing array and hash modes
    # @raise [RuntimeError] if hash values have duplicate keys across sources
    # @raise [RuntimeError] if mixing incompatible value types (Hash with Array)
    #
    # @example Array mode with direct values
    #   s1 = S({ time: 0r, value: 1 }, { time: 1r, value: 2 })
    #   s2 = S({ time: 0r, value: 10 }, { time: 2r, value: 20 })
    #
    #   union = TIMED_UNION(s1, s2).i
    #   union.to_a
    #   # => [{ time: 0r, value: [1, 10] },
    #   #     { time: 1r, value: [2, nil] },
    #   #     { time: 2r, value: [nil, 20] }]
    #
    # @example Hash mode with named sources
    #   melody = S({ time: 0r, value: 60 }, { time: 1r, value: 64 })
    #   bass = S({ time: 0r, value: 36 }, { time: 2r, value: 40 })
    #
    #   union = TIMED_UNION(melody: melody, bass: bass).i
    #   union.to_a
    #   # => [{ time: 0r, value: { melody: 60, bass: 36 } },
    #   #     { time: 1r, value: { melody: 64, bass: nil } },
    #   #     { time: 2r, value: { melody: nil, bass: 40 } }]
    #
    # @example Hash values with polyphonic events
    #   s1 = S({ time: 0r, value: { a: 1, b: 2 } })
    #   s2 = S({ time: 0r, value: { c: 10, d: 20 } })
    #
    #   union = TIMED_UNION(s1, s2).i
    #   union.next_value  # => { time: 0r, value: { a: 1, b: 2, c: 10, d: 20 } }
    #
    # @example Extra attributes synchronization
    #   s1 = S({ time: 0r, value: 1, velocity: 80, duration: 1r })
    #   s2 = S({ time: 0r, value: 10, velocity: 90 })
    #
    #   union = TIMED_UNION(s1, s2).i
    #   union.next_value
    #   # => { time: 0r,
    #   #      value: [1, 10],
    #   #      velocity: [80, 90],
    #   #      duration: [1r, nil] }
    #
    # @example Key conflict detection
    #   s1 = S({ time: 0r, value: { a: 1, b: 2 } })
    #   s2 = S({ time: 0r, value: { a: 10 } })  # 'a' already used!
    #
    #   union = TIMED_UNION(s1, s2).i
    #   union.next_value  # RuntimeError: Value: key a already used
    #
    # @see flatten_timed Splits compound values into individual timed events
    # @see compact_timed Removes events with all-nil values
    # @see union_timed Instance method for union
    #
    # @api public
    def TIMED_UNION(*array_of_timed_series, **hash_of_timed_series)
      raise ArgumentError, 'Can\'t union an array of series with a hash of series' if array_of_timed_series.any? && hash_of_timed_series.any?

      if array_of_timed_series.any?
        TimedUnionOfArrayOfTimedSeries.new(array_of_timed_series)
      elsif hash_of_timed_series.any?
        TimedUnionOfHashOfTimedSeries.new(hash_of_timed_series)
      else
        raise ArgumentError, 'Missing argument series'
      end
    end

    # Array-mode timed union implementation.
    #
    # Combines anonymous positional timed series, emitting events synchronized by time.
    # Values are combined into arrays or hashes depending on source value types.
    #
    # ## Value Combination Logic
    #
    # - **Direct values**: `[val1, val2, val3]`
    # - **Hash values**: `{ key1: val1, key2: val2 }` (merged from all sources)
    # - **Array values**: `[elem1, elem2, elem3, elem4]` (concatenated)
    # - **Mixed Hash + Direct**: `{ hash_keys..., 0 => direct_val }` (advanced)
    #
    # ## Component Mapping
    #
    # On first value, infers structure via `infer_components` which creates extraction
    # map: `{ attribute => { target_key => [source_i, attr, source_key] } }`
    #
    # This map guides extraction from sources and placement in result for all future values.
    #
    # @api private
    class TimedUnionOfArrayOfTimedSeries
      include Series::Serie::Base
      include Series::Serie::WithSources

      # Creates array-mode union from series array.
      #
      # @param series [Array<Serie>] source timed series
      # @api private
      def initialize(series)
        self.sources = series
        init
      end

      # Initializes buffering and component inference state.
      # @api private
      private def _init
        @sources_next_values = Array.new(@sources.size)
        @components = nil
      end

      # Restarts all source series.
      # @api private
      private def _restart
        @sources.each(&:restart)
      end

      # Generates next synchronized timed event.
      #
      # Algorithm:
      # 1. Buffer next value from each source
      # 2. Infer component structure (first call only)
      # 3. Find minimum time across all sources
      # 4. Extract values at that time
      # 5. Build result using component map
      # 6. Clear consumed values from buffer
      #
      # @return [Hash, nil] timed event or nil when exhausted
      # @api private
      private def _next_value
        sources_values = @sources_next_values.each_index.collect do |i|
          @sources_next_values[i] || (@sources_next_values[i] = @sources[i].next_value)
        end

        @components, @hash_mode, @array_mode = infer_components(sources_values) unless @components

        time = sources_values.collect { |_| _&.[](:time) }.compact.min

        if time
          selected_values = sources_values.collect { |_| _ if _&.[](:time) == time }

          @sources_next_values.each_index do |i|
            if @sources_next_values[i]&.[](:time) == time
              @sources_next_values[i] = nil
            end
          end

          result = { time: time }

          @components.each do |attribute_name, components|
            result[attribute_name] = if @hash_mode
                                       {}
                                     elsif @array_mode
                                       []
                                     else # value mode
                                       []
                                     end

            components.each do |target_key_or_index, source_placement|
              result[attribute_name][target_key_or_index] = selected_values.dig(*source_placement)
            end
          end

          result.extend(Musa::Datasets::AbsTimed)
        else
          nil
        end
      end

      # Checks if any source is infinite.
      # @return [Boolean] true if any source infinite
      # @api private
      def infinite?
        !!@sources.find(&:infinite?)
      end

      # Infers component extraction and placement map from first values.
      #
      # Analyzes source value types to create extraction map for all future values.
      # Map structure: `{ attribute => { target_key => [source_i, attr, source_key] } }`
      #
      # **Hash values**: Keys map directly to target keys
      # **Array/Direct values**: `target_index` (0, 1, 2...) assigns positions
      #
      # Also detects and validates:
      # - Duplicate keys across sources (raises RuntimeError)
      # - Incompatible type mixing (Hash with Array, raises RuntimeError)
      #
      # @param sources_values [Array<Hash>] first value from each source
      # @return [Array(Hash, Boolean, Boolean)] components map, hash_mode flag, array_mode flag
      # @raise [RuntimeError] if duplicate keys found
      # @raise [RuntimeError] if incompatible types (Hash + Array)
      # @api private
      private def infer_components(sources_values)
        other_attributes = Set[]

        sources_values.each do |source_value|
          (source_value.keys - [:time, :value]).each { |_| other_attributes << _ }
        end

        components = {}
        components[:value] = {}

        hash_mode = array_mode = nil

        other_attributes.each do |attribute_name|
          components[attribute_name] = {}
        end

        target_index = 0

        sources_values.each_with_index do |source_value, i|
          case source_value[:value]
          when Hash
            hash_mode = true

            source_value[:value].each_key do |key|
              raise "Value: key #{key} already used" unless components[:value][key].nil?

              components[:value][key] = [i, :value, key]

              other_attributes.each do |attribute_name|
                raise "Attribute #{attribute_name}: key #{key} already used" unless components[attribute_name][key].nil?

                components[attribute_name][key] = [i, attribute_name, key]
              end
            end
          when Array
            array_mode = true

            (0..source_value[:value].size - 1).each do |index|
              components[:value][target_index] = [i, :value, index]

              other_attributes.each do |attribute_name|
                components[attribute_name][target_index] = [i, attribute_name, index]
              end

              target_index += 1
            end
          else
            components[:value][target_index] = [i, :value]

            other_attributes.each do |attribute_name|
              components[attribute_name][target_index] = [i, attribute_name]
            end

            target_index += 1
          end
        end

        raise "source series values are of incompatible type (can't combine Hash and Array values)" if array_mode && hash_mode

        [components, hash_mode, array_mode]
      end
    end

    private_constant :TimedUnionOfArrayOfTimedSeries

    # Hash-mode timed union implementation.
    #
    # Combines named timed series with explicit keys, emitting synchronized events
    # with hash-structured values preserving source names.
    #
    # Output structure: `{ time: t, value: { key1: val1, key2: val2 } }`
    #
    # Simpler than array mode since component names are predetermined by source keys.
    # No inference needed - directly uses hash keys from initialization.
    #
    # @api private
    class TimedUnionOfHashOfTimedSeries
      include Series::Serie::Base
      include Series::Serie::WithSources

      # Creates hash-mode union from named series hash.
      #
      # @param series [Hash{Symbol => Serie}] named source series
      # @api private
      def initialize(series)
        self.sources = series
        init
      end

      # Stores sources and captures component keys.
      # @param series [Hash{Symbol => Serie}] named sources
      # @api private
      def sources=(series)
        super
        @components = series.keys
      end

      # Initializes buffering for named sources.
      # @api private
      private def _init
        @sources_next_values = @components.collect { |k| [k, nil] }.to_h
        @other_attributes = nil
      end

      # Restarts all source series.
      # @api private
      private def _restart
        @sources.each_value(&:restart)
      end

      # Generates next synchronized timed event with named values.
      #
      # Similar to array mode but uses predetermined component keys instead of
      # inferring structure from values.
      #
      # @return [Hash, nil] timed event with named values
      # @api private
      private def _next_value
        sources_values = {}

        @components.each do |key|
          sources_values[key] = @sources_next_values[key] || (@sources_next_values[key] = @sources[key].next_value)
        end

        @other_attributes ||= infer_other_attributes(sources_values)

        time = sources_values.values.collect { |_| _&.[](:time) }.compact.min

        if time
          selected_values = sources_values.transform_values { |_| _ if _&.[](:time) == time }

          @sources_next_values.each_key do |key|
            if @sources_next_values[key]&.[](:time) == time
              @sources_next_values[key] = nil
            end
          end

          result = { time: time, value: {} }

          @other_attributes.each do |attribute_name|
            result[attribute_name] = {}
          end

          @components.each do |component|
            result[:value][component] = selected_values[component]&.[](:value)

            @other_attributes.each do |attribute_name|
              result[attribute_name][component] = selected_values[component]&.[](attribute_name)
            end
          end

          result.extend(Musa::Datasets::AbsTimed)
        else
          nil
        end
      end

      # Checks if any source is infinite.
      # @return [Boolean] true if any source infinite
      # @api private
      def infinite?
        !!@sources.values.find(&:infinite?)
      end

      # Discovers extra attributes from first source values.
      #
      # Collects all attribute names beyond `:time` and `:value` for synchronization.
      #
      # @param sources_values [Hash{Symbol => Hash}] first values by source key
      # @return [Set<Symbol>] extra attribute names
      # @api private
      private def infer_other_attributes(sources_values)
        other_attributes = Set[]

        sources_values.each_value do |source_value|
          (source_value.keys - [:time, :value]).each do |attribute_name|
            other_attributes << attribute_name
          end
        end

        other_attributes
      end
    end

    private_constant :TimedUnionOfHashOfTimedSeries
  end

  module Series::Operations
    # Splits compound timed values into individual timed events.
    #
    # Converts events with Hash or Array values into separate timed events per element,
    # preserving time and extra attributes. Direct values pass through unchanged.
    #
    # **Hash values** → Hash of timed events (keyed by original keys):
    # ```ruby
    # { time: 0, value: { a: 1, b: 2 }, velocity: { a: 80, b: 90 } }
    # # becomes:
    # { a: { time: 0, value: 1, velocity: 80 },
    #   b: { time: 0, value: 2, velocity: 90 } }
    # ```
    #
    # **Array values** → Array of timed events (indexed):
    # ```ruby
    # { time: 0, value: [1, 2], velocity: [80, 90] }
    # # becomes:
    # [{ time: 0, value: 1, velocity: 80 },
    #  { time: 0, value: 2, velocity: 90 }]
    # ```
    #
    # **Direct values** → Pass through unchanged (already flat)
    #
    # ## Use Cases
    #
    # - Separate polyphonic events into individual voices
    # - Split multi-track sequences for independent processing
    # - Prepare for voice-specific routing via `split`
    # - Enable per-voice filtering with `compact_timed`
    #
    # @return [TimedFlattener] flattened timed serie
    #
    # @example Hash values to individual voices
    #   s = S({ time: 0r, value: { a: 60, b: 64 }, velocity: { a: 80, b: 90 } })
    #
    #   flat = s.flatten_timed.i
    #   flat.next_value
    #   # => { a: { time: 0r, value: 60, velocity: 80 },
    #   #      b: { time: 0r, value: 64, velocity: 90 } }
    #
    # @example Array values to indexed events
    #   s = S({ time: 0r, value: [60, 64], velocity: [80, 90] })
    #
    #   flat = s.flatten_timed.i
    #   flat.next_value
    #   # => [{ time: 0r, value: 60, velocity: 80 },
    #   #     { time: 0r, value: 64, velocity: 90 }]
    #
    # @example Direct values pass through
    #   s = S({ time: 0r, value: 60, velocity: 80 })
    #
    #   flat = s.flatten_timed.i
    #   flat.next_value  # => { time: 0r, value: 60, velocity: 80 }
    #
    # @see compact_timed Remove nil-only events
    # @see TIMED_UNION Combine multiple timed series
    #
    # @api public
    def flatten_timed
      TimedFlattener.new(self)
    end

    # Removes timed events where all values are nil.
    #
    # Filters out temporal "gaps" where no sources have active values. Useful after
    # union operations that create nil placeholders, or for cleaning sparse sequences.
    #
    # **Removal logic**:
    # - **Direct nil**: `{ time: t, value: nil }` → removed
    # - **All-nil Hash**: `{ time: t, value: { a: nil, b: nil } }` → removed
    # - **Partial Hash**: `{ time: t, value: { a: 1, b: nil } }` → kept (has non-nil)
    # - **All-nil Array**: `{ time: t, value: [nil, nil] }` → removed
    # - **Partial Array**: `{ time: t, value: [1, nil] }` → kept (has non-nil)
    #
    # @return [TimedCompacter] compacted serie
    #
    # @example Remove direct nil events
    #   s = S({ time: 0r, value: 1 },
    #         { time: 1r, value: nil },
    #         { time: 2r, value: 3 })
    #
    #   s.compact_timed.i.to_a
    #   # => [{ time: 0r, value: 1 },
    #   #     { time: 2r, value: 3 }]
    #
    # @example Remove all-nil hash events
    #   s = S({ time: 0r, value: { a: 1, b: 2 } },
    #         { time: 1r, value: { a: nil, b: nil } },
    #         { time: 2r, value: { a: 3, b: nil } })
    #
    #   s.compact_timed.i.to_a
    #   # => [{ time: 0r, value: { a: 1, b: 2 } },
    #   #     { time: 2r, value: { a: 3, b: nil } }]  # Kept: has non-nil 'a'
    #
    # @example Clean sparse union results
    #   s1 = S({ time: 0r, value: 1 }, { time: 2r, value: 3 })
    #   s2 = S({ time: 1r, value: 10 })
    #
    #   union = TIMED_UNION(melody: s1, bass: s2).i.to_a
    #   # => [{ time: 0r, value: { melody: 1, bass: nil } },
    #   #     { time: 1r, value: { melody: nil, bass: 10 } },
    #   #     { time: 2r, value: { melody: 3, bass: nil } }]
    #
    #   # All events have at least one non-nil, so none removed
    #
    # @see flatten_timed Split compound values
    # @see TIMED_UNION Combine series (may introduce nils)
    #
    # @api public
    def compact_timed
      TimedCompacter.new(self)
    end

    # Combines this timed serie with others via TIMED_UNION.
    #
    # Convenience method for unioning series, supporting both array and hash modes.
    # Calls {TIMED_UNION} constructor with appropriate parameters.
    #
    # **Array mode**: `s1.union_timed(s2, s3)`
    # **Hash mode**: `s1.union_timed(key: :melody, bass: s2, drums: s3)`
    #
    # @param other_timed_series [Array<Serie>] additional series (array mode)
    # @param key [Symbol, nil] key name for this serie (hash mode)
    # @param other_key_timed_series [Hash{Symbol => Serie}] named series (hash mode)
    #
    # @return [TimedUnionOfArrayOfTimedSeries, TimedUnionOfHashOfTimedSeries] union
    #
    # @raise [ArgumentError] if mixing array and hash modes
    #
    # @example Array mode
    #   melody = S({ time: 0r, value: 60 })
    #   bass = S({ time: 0r, value: 36 })
    #
    #   melody.union_timed(bass).i.next_value
    #   # => { time: 0r, value: [60, 36] }
    #
    # @example Hash mode
    #   melody = S({ time: 0r, value: 60 })
    #   bass = S({ time: 0r, value: 36 })
    #   drums = S({ time: 0r, value: 38 })
    #
    #   melody.union_timed(key: :melody, bass: bass, drums: drums).i.next_value
    #   # => { time: 0r, value: { melody: 60, bass: 36, drums: 38 } }
    #
    # @see TIMED_UNION Constructor version
    #
    # @api public
    def union_timed(*other_timed_series, key: nil, **other_key_timed_series)
      if key && other_key_timed_series.any?
        Series::Constructors.TIMED_UNION(key => self, **other_key_timed_series)

      elsif other_timed_series.any? && other_key_timed_series.empty?
        Series::Constructors.TIMED_UNION(self, *other_timed_series)

      else
        raise ArgumentError, 'Can\'t union an array of series with a hash of series'
      end
    end

    # Internal implementation for flattening timed values.
    #
    # Transforms compound timed events into collections of individual timed events,
    # distributing extra attributes to corresponding elements.
    #
    # @api private
    class TimedFlattener
      include Series::Serie::Base
      include Series::Serie::WithSource

      # Creates flattener wrapping source serie.
      #
      # @param serie [Serie] source timed serie
      # @api private
      def initialize(serie)
        self.source = serie
        init
      end

      # Restarts source serie.
      # @api private
      private def _restart
        @source.restart
      end

      # Generates next flattened value from source.
      #
      # Algorithm:
      # 1. Get next timed event from source
      # 2. Extract time and extra attributes
      # 3. Based on value type:
      #    - **Hash**: Create hash of timed events (key → timed event)
      #    - **Array**: Create array of timed events (index → timed event)
      #    - **Direct**: Clone and pass through unchanged
      # 4. Distribute extra attributes to corresponding elements
      #
      # @return [Hash, Array, Hash, nil] flattened structure or nil
      # @api private
      private def _next_value
        source_value = @source.next_value

        if !source_value.nil?
          time = source_value[:time]
          source_value_value = source_value[:value]

          # Extract all attributes beyond :time and :value
          source_value_extra = (source_value.keys - [:time, :value]).collect do |attribute_name|
            [attribute_name, source_value[attribute_name]]
          end.to_h

          case source_value_value
          when Hash
            # Hash values: { key => timed_event }
            result = {}
            source_value_value.each_pair do |key, value|
              result[key] = { time: time, value: value }.extend(Musa::Datasets::AbsTimed)

              # Distribute extra attributes by key
              source_value_extra.each do |attribute_name, attribute_value|
                result[key][attribute_name] = attribute_value[key]
              end
            end

          when Array
            # Array values: [timed_event, timed_event, ...]
            result = []
            source_value_value.each_index do |index|
              result[index] = { time: time, value: source_value_value[index] }.extend(Musa::Datasets::AbsTimed)

              # Distribute extra attributes by index
              source_value_extra.each do |attribute_name, attribute_value|
                result[index][attribute_name] = attribute_value[index]
              end
            end
          else
            # Direct values: pass through unchanged
            result = source_value.clone.extend(Musa::Datasets::AbsTimed)
          end

          result.extend(Musa::Datasets::AbsTimed)
        else
          nil
        end
      end

      # Checks if source is infinite.
      # @return [Boolean] true if source infinite
      # @api private
      def infinite?
        @source.infinite?
      end
    end

    private_constant :TimedFlattener

    # Internal implementation for compacting timed series.
    #
    # Filters out events where all values are nil, removing temporal gaps.
    # Checks value structure to determine if entire event should be skipped.
    #
    # @api private
    class TimedCompacter
      include Series::Serie::Base
      include Series::Serie::WithSource

      # Creates compacter wrapping source serie.
      #
      # @param serie [Serie] source timed serie
      # @api private
      def initialize(serie)
        self.source = serie
        init
      end

      # Restarts source serie.
      # @api private
      private def _restart
        @source.restart
      end

      # Generates next non-nil value from source.
      #
      # Skips source values while they contain only nil values (direct nil,
      # all-nil hash, or all-nil array). Returns first event with any non-nil.
      #
      # @return [Hash, nil] timed event with non-nil values, or nil when exhausted
      # @api private
      private def _next_value
        while (source_value = @source.next_value) && skip_value?(source_value[:value]); end
        source_value
      end

      # Checks if source is infinite.
      # @return [Boolean] true if source infinite
      # @api private
      def infinite?
        @source.infinite?
      end

      # Determines if value should be skipped (all-nil check).
      #
      # **Hash**: All values nil → skip
      # **Array**: All elements nil → skip
      # **Direct**: Value is nil → skip
      #
      # @param timed_value [Hash, Array, Object] value to check
      # @return [Boolean] true if should skip
      # @api private
      private def skip_value?(timed_value)
        case timed_value
        when Hash
          timed_value.all? { |_, v| v.nil? }
        when Array
          timed_value.all?(&:nil?)
        else
          timed_value.nil?
        end
      end
    end

    private_constant :TimedCompacter
  end
end

