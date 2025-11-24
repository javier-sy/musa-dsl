require_relative 'extension'

module Musa
  module Extension
    # Refinements that provide more readable inspect/to_s output for Hash and Rational.
    #
    # These refinements improve readability of log output and debugging, especially
    # important when working with musical data that heavily uses Rationals for timing
    # and Hashes for event parameters.
    #
    # ## Changes
    #
    # - **Hash**: Compact syntax with symbol keys shown as `key: value`
    # - **Rational**: Musical-friendly format like `3+1/4r` instead of `(13/4)`
    # - **Configurable**: Rational display can switch between simple and detailed modes
    #
    # ## Use Cases
    #
    # - Improving log readability in musical applications
    # - Debugging DSL expressions with cleaner output
    # - Displaying musical time values (bars, durations) naturally
    #
    # @example Hash formatting
    #   using Musa::Extension::InspectNice
    #
    #   { pitch: 60, velocity: 100 }.inspect
    #   # => "{ pitch: 60, velocity: 100 }"
    #   # Instead of: "{:pitch=>60, :velocity=>100}"
    #
    # @example Rational formatting (detailed mode)
    #   using Musa::Extension::InspectNice
    #
    #   (5/4r).inspect       # => "1+1/4r"
    #   (3/2r).inspect       # => "1+1/2r"
    #   (2/1r).inspect       # => "2r"
    #   (-3/4r).inspect      # => "-3/4r"
    #
    # @example Rational formatting (simple mode)
    #   using Musa::Extension::InspectNice
    #
    #   Rational.to_s_as_inspect = false
    #   (5/4r).to_s          # => "5/4"
    #   (2/1r).to_s          # => "2"
    #
    # @see Musa::Logger::Logger Uses these refinements for cleaner logs
    # @note These refinements must be activated with `using Musa::Extension::InspectNice`
    #
    # ## Methods Added
    #
    # ### Hash
    # - {Hash#inspect} - Compact, readable inspect output with symbol-key shorthand
    # - {Hash#to_s} - Aliases to_s to inspect for consistency
    #
    # ### Rational (singleton class)
    # - {Rational.to_s_as_inspect} - Controls whether Rational#to_s uses inspect format
    #
    # ### Rational
    # - {Rational#inspect} - Musical-friendly inspect output for Rational numbers
    # - {Rational#to_s} - String representation controlled by Rational.to_s_as_inspect
    module InspectNice
      # @!method inspect
      #   Provides compact, readable inspect output with symbol-key shorthand.
      #
      #   Symbol keys are displayed as `key: value` (Ruby 2.0+ syntax) instead of
      #   `:key => value`. String/other keys use the fat arrow syntax.
      #
      #   @note This method is added to Hash via refinement. Requires `using Musa::Extension::InspectNice`.
      #
      #   @return [String] compact hash representation.
      #
      #   @example Mixed keys
      #     using Musa::Extension::InspectNice
      #     { pitch: 60, 'name' => 'C4' }.inspect
      #     # => "{ pitch: 60, 'name' => 'C4' }"
      class ::Hash; end

      # @!method to_s
      #   Aliases to_s to inspect for consistency.
      #
      #   @note This method is added to Hash via refinement. Requires `using Musa::Extension::InspectNice`.
      #
      #   @return [String] compact hash representation.
      #
      #   @see Hash#inspect
      class ::Hash; end

      refine Hash do
        def inspect
          all = collect { |key, value| [', ', key.is_a?(Symbol) ? key.to_s + ': ' : key.inspect + ' => ', value.inspect] }.flatten
          all.shift
          '{ ' + all.join + ' }'
        end

        alias _to_s to_s
        alias to_s inspect
      end

      # Adds configuration attribute to Rational singleton class.
      #
      # This allows global control of Rational#to_s behavior.
      #
      # @!attribute [rw] to_s_as_inspect
      #   Controls whether Rational#to_s uses inspect format.
      #
      #   When true: to_s displays detailed format (e.g., "1+1/4r")
      #   When false/nil: to_s displays simple format (e.g., "5/4")
      #
      #   @note This attribute is added to Rational's singleton class via refinement. Requires `using Musa::Extension::InspectNice`.
      #
      #   @return [Boolean, nil] current mode
      #
      #   @example Switching modes
      #     using Musa::Extension::InspectNice
      #     Rational.to_s_as_inspect = true
      #     (5/4r).to_s  # => "1+1/4r"
      class ::Rational; end

      refine Rational.singleton_class do
        attr_accessor :to_s_as_inspect
      end

      # @!method inspect(simple: nil)
      #   Provides musical-friendly inspect output for Rational numbers.
      #
      #   Two modes:
      #   - **Simple**: Just numerator/denominator (e.g., "5/4", "2")
      #   - **Detailed**: Mixed number with 'r' suffix (e.g., "1+1/4r", "2r")
      #
      #   The detailed format is particularly useful for musical time values,
      #   making expressions like "3+1/2r" (3.5 bars) immediately readable.
      #
      #   @note This method is added to Rational via refinement. Requires `using Musa::Extension::InspectNice`.
      #
      #   @param simple [Boolean, nil] if true, uses simple format; if false/nil, uses detailed.
      #
      #   @return [String] formatted rational.
      #
      #   @example Detailed format (default for inspect)
      #     using Musa::Extension::InspectNice
      #     (5/4r).inspect            # => "1+1/4r"
      #     (7/4r).inspect            # => "1+3/4r"
      #     (-3/2r).inspect           # => "-1-1/2r"
      #     (8/4r).inspect            # => "2r"
      #     (3/4r).inspect            # => "3/4r"
      #
      #   @example Simple format
      #     using Musa::Extension::InspectNice
      #     (5/4r).inspect(simple: true)   # => "5/4"
      #     (8/4r).inspect(simple: true)   # => "2"
      class ::Rational; end

      # @!method to_s
      #   Provides string representation, format controlled by Rational.to_s_as_inspect.
      #
      #   Delegates to #inspect with the appropriate simple flag based on the
      #   global Rational.to_s_as_inspect setting.
      #
      #   @note This method is added to Rational via refinement. Requires `using Musa::Extension::InspectNice`.
      #
      #   @return [String] formatted rational.
      #
      #   @example When to_s_as_inspect is true
      #     using Musa::Extension::InspectNice
      #     Rational.to_s_as_inspect = true
      #     (5/4r).to_s  # => "1+1/4r"
      #
      #   @example When to_s_as_inspect is false/nil
      #     using Musa::Extension::InspectNice
      #     Rational.to_s_as_inspect = false
      #     (5/4r).to_s  # => "5/4"
      class ::Rational; end

      refine Rational do
        def inspect(simple: nil)
          value = self.abs
          sign = negative? ? '-' : ''

          if simple
            if value.denominator == 1
              "#{sign}#{value.numerator}"
            else
              "#{sign}#{value.numerator}/#{value.denominator}"
            end
          else
            sign2 = negative? ? '-' : '+'

            d = value - value.to_i

            if d == 0
              "#{sign}#{value.to_i.to_s}r"
            else
              i = "#{value.to_i}#{sign2}" if value.to_i != 0
              "#{sign}#{i}#{d.numerator}/#{d.denominator}r"
            end
          end
        end

        def to_s
          inspect simple: !Rational.to_s_as_inspect
        end
      end
    end
  end
end
