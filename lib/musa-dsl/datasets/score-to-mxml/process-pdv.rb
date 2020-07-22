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

    until effective_duration_decomposition.empty?
      duration = effective_duration_decomposition.shift

      type, dots, tuplet_ratio = type_and_dots_and_tuplet_ratio(duration)

      raise NotImplementedError,
            "Found irregular time (tuplet ratio #{tuplet_ratio}) on element #{element}. " \
            "Don't know how to handle on this version. " \
        unless tuplet_ratio == 1

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
        measure.add_rest type: type,
                         dots: dots,
                         duration: (duration * divisions_per_bar).to_i,
                         voice: element[:dataset][:voice]
      else
        measure.add_pitch pitch, octave: octave, alter: sharps,
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

  def midi_velocity_to_dynamics(midi_velocity)
    return nil unless midi_velocity

    # ppp = 16 ... fff = 127
    # TODO create a customizable MIDI velocity to score dynamics bidirectional conversor
    dynamics_number = [0..0, 1..1, 2..8, 9..16, 17..33, 34..49, 49..64, 65..80, 81..96, 97..112, 113..127]
                          .index { |r| r.cover? midi_velocity }

    ['pppppp', 'ppppp', 'pppp', 'ppp', 'pp', 'p', 'mp', 'mf', 'f', 'ff', 'fff'][dynamics_number]
  end
end
