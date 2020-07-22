require 'prime'

module Musa::Datasets::Score::ToMXML
  private

  class ElementDurationDecomposition
    def initialize(element, bar, bar_size = 1r) # TODO remove (unused because of bad strategy to time groups)
      @continue_from_previous_bar = element[:start] < bar
      @continue_to_next_bar = element[:finish] >= bar + bar_size

      @start = continue_from_previous_bar ? 0r : element[:start] - bar

      @duration = continue_to_next_bar ?
                      (1r - @start) :
                      (element[:start] + element[:dataset][:duration] - (bar + start))

      @duration_decomposition = integrate_as_dotteable_durations(decompose_as_sum_of_simple_durations(@duration))
    end

    attr_reader :continue_from_previous_bar, :continue_to_next_bar, :start, :duration, :duration_decomposition

    def to_s
      "ElementDurationDecomposition(#{@duration}) = [#{@duration_decomposition}]"
    end

    alias inspect to_s
  end

  private_constant :ElementDurationDecomposition

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

  def all_combinations(numbers)
    all_combinations = []
    i = 1
    until (combinations = numbers.combination(i).to_a).empty?
      all_combinations += combinations
      i += 1
    end

    all_combinations.uniq
  end

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

  def nearest_upper_power_of_2(number)
    return 0 if number.zero?

    exp = Math.log2(number)
    exp_floor = exp.floor
    plus = exp > exp_floor ? 1 : 0

    2 ** (exp_floor + plus)
  end

  def nearest_lower_power_of_2(number)
    return 0 if number.zero?

    exp_floor = Math.log2(number).floor

    2 ** exp_floor
  end

  def type_of(base_type_duration)
    duration_log2i = Math.log2(base_type_duration)

    raise ArgumentError, "#{base_type_duration} is not a inverse power of 2 (i.e. 2, 1, 1/2, 1/4, 1/8, 1/64, etc)" \
      unless base_type_duration == 2 ** duration_log2i

    raise ArgumentError, "#{base_type_duration} is not between 1024th and maxima accepted durations" \
      unless duration_log2i >= -10 && duration_log2i <= 3

    ['1024th', '512th', '256th', '128th',
     '64nd', '32nd', '16th', 'eighth',
     'quarter', 'half', 'whole', 'breve',
     'long', 'maxima'][duration_log2i + 10]
  end
end

