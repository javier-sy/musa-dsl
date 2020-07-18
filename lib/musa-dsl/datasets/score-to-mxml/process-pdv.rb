require 'prime'

module Musa::Datasets::Score::ToMXML
  private

  def process_pdv(measure, divisions_per_bar, bar, element, pointer)
    pitch, octave, sharps = pitch_and_octave_and_sharps(element[:dataset])

    continue_from_previous_bar = element[:start] < bar
    continue_to_next_bar = element[:finish] >= bar + 1r

    effective_start = continue_from_previous_bar ? 0r : element[:start] - bar

    effective_duration = continue_to_next_bar ?
                             (1r - effective_start) :
                             (element[:start] + element[:dataset][:duration] - (bar + effective_start))

    effective_duration_decomposition = \
        integrate_as_dotteable_durations(
        decompose_as_sum_of_simple_durations(effective_duration))

    if pointer > effective_start
      duration_to_go_back = (pointer - effective_start)

      measure.add_backup(duration_to_go_back * divisions_per_bar)
      pointer -= duration_to_go_back
    end

    # TODO generalize articulations and other musicxml elements

    staccato = element[:dataset][:st] == 1 || element[:dataset][:st] == true
    staccatissimo = element[:dataset][:st].is_a?(Numeric) && element[:dataset][:st] > 1

    trill = !element[:dataset][:tr].nil?

    mordent = [:down, :low].include?(element[:dataset][:mor])
    inverted_mordent = [:up, true].include?(element[:dataset][:mor])

    turn = [:up, true].include?(element[:dataset][:turn])
    inverted_turn = [:down, :low].include?(element[:dataset][:turn])

    internal_tie = false

    last_duration = nil
    last_note = nil

    until effective_duration_decomposition.empty?
      duration = effective_duration_decomposition.shift

      type, dots, tuplet_ratio = type_and_dots_and_tuplet_ratio(duration)

      tied = if continue_from_previous_bar && continue_to_next_bar
               'start'
             elsif continue_to_next_bar
               'start'
             elsif continue_from_previous_bar
               'stop'
             elsif !effective_duration_decomposition.empty?
               internal_tie = true
               'start'
             elsif internal_tie
               'stop'
             else
               nil
             end

      slur = if element[:dataset][:grace]
               { type: 'start', number: 2 }
             elsif element[:dataset][:graced]
               { type: 'stop', number: 2 }
             end

      if pitch == :silence
        last_note = measure.add_rest type: type,
                         dots: dots,
                         duration: (duration * divisions_per_bar).to_i,
                         voice: element[:dataset][:voice]
      else
        last_note = measure.add_pitch pitch, octave: octave, alter: sharps,
                          type: type,
                          dots: dots,
                          duration: (duration * divisions_per_bar).to_i,
                          grace: element[:dataset][:grace],
                          tied: tied,
                          slur: slur,
                          tie_start: continue_to_next_bar,
                          tie_stop: continue_from_previous_bar,
                          staccato: staccato,
                          staccatissimo: staccatissimo,
                          trill_mark: trill,
                          mordent: mordent,
                          inverted_mordent: inverted_mordent,
                          turn: turn,
                          inverted_turn: inverted_turn,
                          voice: element[:dataset][:voice]
      end

      pointer += duration unless element[:dataset][:grace]
      last_duration = duration
    end
  end

  def pitch_and_octave_and_sharps(pdv)
    if pdv[:pitch] == :silence
      [:silence, nil, nil]
    else
      p, s = [['C', 0], ['C', 1],
              ['D', 0], ['D', 1],
              ['E', 0],
              ['F', 0], ['F', 1],
              ['G', 0], ['G', 1],
              ['A', 0], ['A', 1],
              ['B', 0]][(pdv[:pitch] - 60) % 12]

      o = 4 + ((pdv[:pitch] - 60).rationalize / 12r).floor

      [p, o, s]
    end
  end

  def decompose_as_sum_of_simple_durations(duration)
    return [] if duration.zero?

    #pd = Prime.prime_division(duration.to_r.denominator).collect(&:first)
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

    all_combinations
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
     '64th', '32th', '16th', 'eighth',
     'quarter', 'half', 'whole', 'breve',
     'long', 'maxima'][duration_log2i + 10]
  end

  def midi_velocity_to_dynamics(midi_velocity)
    return nil unless midi_velocity

    # ppp = 16 ... fff = 127
    # TODO create a customizable MIDI velocity to score dynamics bidirectional conversor
    dynamics_number = [0..0, 1..1, 2..8, 9..16, 17..33, 34..49, 49..64, 65..80, 81..96, 97..112, 113..127]
                          .index { |r| r.cover? midi_velocity }

    ['pppppp', 'ppppp', 'pppp', 'ppp', 'pp', 'p', 'mp', 'mf', 'f', 'ff', 'fff'][dynamics_number]
  end
end
