require 'prime'

# Time and duration processing for MusicXML export.
#
# This module provides helper methods for converting musical durations
# to MusicXML note types, dots, and tuplet ratios. Handles the complex
# mathematics of decomposing arbitrary rational durations into standard
# notation elements.
#
# ## Duration Representation
#
# Durations are Rational numbers where 1 = one beat (typically quarter note).
# - 1r = quarter note
# - 1/2r = eighth note
# - 3/2r = dotted quarter
# - 1/3r = eighth note triplet
#
# ## Decomposition Process
#
# 1. **Decompose**: Break duration into sum of simple durations (powers of 2)
# 2. **Integrate**: Combine consecutive halves into dotted notes
# 3. **Type & Dots**: Determine note type and dot count
# 4. **Tuplet Ratio**: Calculate tuplet modification if needed
#
# @api private
module Musa::Datasets::Score::ToMXML
  private

  # Decomposes duration into dotted note representation.
  #
  # Internal class representing the breakdown of an element's duration
  # within a measure. Handles ties across bar lines and duration decomposition.
  #
  # @api private
  class ElementDurationDecomposition
    # Creates duration decomposition for element.
    #
    # @param element [Hash] event with :start, :finish, :dataset keys
    # @param bar [Integer] bar number (1-based)
    # @param bar_size [Rational] bar duration (default: 1r)
    #
    # @api private
    def initialize(element, bar, bar_size = 1r) # TODO remove (unused because of bad strategy to time groups)
      @continue_from_previous_bar = element[:start] < bar
      @continue_to_next_bar = element[:finish] >= bar + bar_size

      @start = continue_from_previous_bar ? 0r : element[:start] - bar

      @duration = continue_to_next_bar ?
                      (1r - @start) :
                      (element[:start] + element[:dataset][:duration] - (bar + start))

      @duration_decomposition = integrate_as_dotteable_durations(decompose_as_sum_of_simple_durations(@duration))
    end

    # Whether note continues from previous bar (tied).
    # @return [Boolean]
    attr_reader :continue_from_previous_bar

    # Whether note continues to next bar (tied).
    # @return [Boolean]
    attr_reader :continue_to_next_bar

    # Start time within bar.
    # @return [Rational]
    attr_reader :start

    # Total duration.
    # @return [Rational]
    attr_reader :duration

    # Duration broken into dotteable components.
    # @return [Array<Rational>]
    attr_reader :duration_decomposition

    def to_s
      "ElementDurationDecomposition(#{@duration}) = [#{@duration_decomposition}]"
    end

    alias inspect to_s
  end

  private_constant :ElementDurationDecomposition

  # Optimizes time and tuplet representation (experimental).
  #
  # Attempts to find optimal tuplet grouping for elements in a bar.
  # Currently unused due to incomplete implementation.
  #
  # @param elements [Array] PDV events
  # @param bar [Integer] bar number
  # @param bar_size [Rational] bar duration
  #
  # @return [nil] incomplete implementation
  #
  # @api private
  # @todo Complete or remove this experimental method
  def time_and_tuplet_optimize(elements, bar, bar_size = 1r) # TODO remove (unused because of bad strategy to time groups)
    decompositions = elements.collect { |pdv| ElementDurationDecomposition.new(pdv, bar, bar_size) }

    denominators = decompositions.collect { |g| g.duration_decomposition.collect { |d| d.to_r.denominator } }.flatten.uniq

    lcm_denominators = denominators.reduce(:lcm)

    primes = Prime.prime_division(lcm_denominators)

    factors = primes.collect { |base, exp| [base] * exp }.flatten

    refactors = all_combinations(factors).collect { |a| a.reduce(&:*) }

    # Y no se puede seguir con la descomposición

    nil
  end

  # Decomposes duration into sum of simple durations.
  #
  # Breaks a rational duration into sum of fractions with power-of-2 denominators.
  # This is the first step in converting arbitrary durations to standard notation.
  #
  # Uses greedy algorithm: repeatedly subtracts largest possible simple duration.
  #
  # @param duration [Rational] duration to decompose
  #
  # @return [Array<Rational>] simple durations that sum to input
  #
  # @raise [ArgumentError] if duration cannot be decomposed
  #
  # @example Quarter note
  #   decompose_as_sum_of_simple_durations(1r)
  #   # => [1r]
  #
  # @example Dotted quarter
  #   decompose_as_sum_of_simple_durations(3/2r)
  #   # => [1r, 1/2r]
  #
  # @example Complex duration
  #   decompose_as_sum_of_simple_durations(5/8r)
  #   # => [1/2r, 1/8r]
  #
  # @api private
  def decompose_as_sum_of_simple_durations(duration)
    return [] if duration.zero?

    # TODO mejorar esta descomposición para que tenga menos factores redundantes
    pd = Prime.prime_division(duration.to_r.denominator).collect { |base, exp| (1..exp).collect { |i| base ** i } }.flatten

    divisors = ([[1]] + all_combinations(pd)).collect { |combination| combination.inject(:*) }

    summands = []

    while divisor = divisors.shift
      c = Rational(1, divisor)
      f = (duration / c).floor
      n = f * c
      summands << n unless n.zero?
      duration -= n
    end

    raise ArgumentError, "#{duration} cannot be further decomposed" unless duration.zero?

    summands
  end

  # Generates all combinations of array elements.
  #
  # @param numbers [Array] elements to combine
  #
  # @return [Array<Array>] all unique combinations (excluding empty)
  #
  # @example
  #   all_combinations([2, 3])
  #   # => [[2], [3], [2, 3]]
  #
  # @api private
  def all_combinations(numbers)
    all_combinations = []
    i = 1
    until (combinations = numbers.combination(i).to_a).empty?
      all_combinations += combinations
      i += 1
    end

    all_combinations.uniq
  end

  # Integrates consecutive halves into dotted durations.
  #
  # Combines simple durations where each is half the previous into
  # single dotted duration. Example: [1r, 1/2r] → [3/2r] (dotted quarter).
  #
  # @param simple_durations [Array<Rational>] simple durations from decomposition
  #
  # @return [Array<Rational>] integrated dotted durations
  #
  # @example Dotted quarter
  #   integrate_as_dotteable_durations([1r, 1/2r])
  #   # => [3/2r]
  #
  # @example Double-dotted half
  #   integrate_as_dotteable_durations([1/2r, 1/4r, 1/8r])
  #   # => [7/8r]
  #
  # @example Non-dotteable
  #   integrate_as_dotteable_durations([1r, 1/4r])
  #   # => [1r, 1/4r]  (no integration possible)
  #
  # @api private
  def integrate_as_dotteable_durations(simple_durations)
    integrated_durations = []
    last = nil
    simple_durations.each do |duration|
      if last && duration == last / 2
        integrated_durations[integrated_durations.size-1] += duration
      else
        integrated_durations << duration
      end
      last = duration
    end
    integrated_durations
  end

  # Calculates note type, dots, and tuplet ratio.
  #
  # Converts a dotteable duration into MusicXML note representation:
  # - **type**: Base note type (quarter, eighth, etc.)
  # - **dots**: Number of dots (0-3 typically)
  # - **tuplet_ratio**: Tuplet modification (3:2 for triplets, etc.)
  #
  # @param noteable_duration [Rational] duration to convert
  #
  # @return [Array(String, Integer, Rational)] [type, dots, tuplet_ratio]
  #
  # @raise [ArgumentError] if duration cannot be represented with dots
  #
  # @example Quarter note
  #   type_and_dots_and_tuplet_ratio(1r)
  #   # => ["quarter", 0, 1r]
  #
  # @example Dotted quarter
  #   type_and_dots_and_tuplet_ratio(3/2r)
  #   # => ["quarter", 1, 1r]
  #
  # @example Eighth triplet
  #   type_and_dots_and_tuplet_ratio(1/3r)
  #   # => ["eighth", 0, 3/2r]
  #
  # @api private
  def type_and_dots_and_tuplet_ratio(noteable_duration)
    r = decompose_as_sum_of_simple_durations(noteable_duration)
    n = r.shift

    tuplet_ratio = Rational(n.denominator, nearest_lower_power_of_2(n.denominator))

    type = type_of(nearest_upper_power_of_2(n))
    dots = 0

    while nn = r.shift
      if nn == n / 2
        dots += 1
        n = nn
      else
        break
      end
    end

    raise ArgumentError, "#{noteable_duration} cannot be decomposed as a duration with dots" unless r.empty?

    return type, dots, tuplet_ratio
  end

  # Finds nearest power of 2 greater than or equal to number.
  #
  # @param number [Numeric] number to round up
  #
  # @return [Integer] nearest upper power of 2
  #
  # @example
  #   nearest_upper_power_of_2(5)  # => 8
  #   nearest_upper_power_of_2(8)  # => 8
  #   nearest_upper_power_of_2(9)  # => 16
  #
  # @api private
  def nearest_upper_power_of_2(number)
    return 0 if number.zero?

    exp = Math.log2(number)
    exp_floor = exp.floor
    plus = exp > exp_floor ? 1 : 0

    2 ** (exp_floor + plus)
  end

  # Finds nearest power of 2 less than or equal to number.
  #
  # @param number [Numeric] number to round down
  #
  # @return [Integer] nearest lower power of 2
  #
  # @example
  #   nearest_lower_power_of_2(5)  # => 4
  #   nearest_lower_power_of_2(8)  # => 8
  #   nearest_lower_power_of_2(15) # => 8
  #
  # @api private
  def nearest_lower_power_of_2(number)
    return 0 if number.zero?

    exp_floor = Math.log2(number).floor

    2 ** exp_floor
  end

  # Converts duration to MusicXML note type name.
  #
  # Maps inverse powers of 2 to standard note type names.
  # Duration must be power of 2 between 1/1024 and maxima (8 whole notes).
  #
  # @param base_type_duration [Numeric] duration as power of 2
  #
  # @return [String] MusicXML note type name
  #
  # @raise [ArgumentError] if duration is not power of 2 or out of range
  #
  # @example Standard durations
  #   type_of(1r)    # => "quarter"
  #   type_of(1/2r)  # => "eighth"
  #   type_of(1/4r)  # => "16th"
  #   type_of(2r)    # => "half"
  #   type_of(4r)    # => "whole"
  #
  # @api private
  def type_of(base_type_duration)
    duration_log2i = Math.log2(base_type_duration)

    raise ArgumentError, "#{base_type_duration} is not a inverse power of 2 (i.e. 2, 1, 1/2, 1/4, 1/8, 1/64, etc)" \
      unless base_type_duration == 2 ** duration_log2i

    raise ArgumentError, "#{base_type_duration} is not between 1024th and maxima accepted durations" \
      unless duration_log2i >= -10 && duration_log2i <= 3

    ['1024th', '512th', '256th', '128th',
     '64th', '32nd', '16th', 'eighth',
     'quarter', 'half', 'whole', 'breve',
     'long', 'maxima'][duration_log2i + 10]
  end
end

