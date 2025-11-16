require 'prime'

# PDV event processing for MusicXML export.
#
# Converts {PDV} (Pitch/Duration/Velocity) events to MusicXML notes and rests.
# Handles pitch mapping, duration decomposition, ties, articulations, and
# ornaments.
#
# ## Processing Steps
#
# 1. Extract pitch, octave, and accidentals from MIDI pitch
# 2. Calculate effective duration within measure (may span bars)
# 3. Decompose duration into MusicXML-compatible note values
# 4. Add backup/forward if needed for voice positioning
# 5. Create MusicXML note/rest elements with all attributes
#
# ## Articulations & Ornaments Supported
#
# - **:st** → staccato / staccatissimo (1 or > 1)
# - **:tr** → trill
# - **:mor** → mordent (:down/:low) or inverted mordent (:up/true)
# - **:turn** → turn (:up/true) or inverted turn (:down/:low)
# - **:grace** → grace note (with slur)
# - **:graced** → note receiving grace note (with slur)
# - **:voice** → voice number for polyphony
#
# ## Ties Across Measures
#
# Notes spanning bar lines are automatically tied. Duration is decomposed
# and tie start/stop/continue markers added appropriately.
#
# @api private
module Musa::Datasets::Score::ToMXML
  using Musa::Extension::InspectNice

  # Processes PDV event to MusicXML note or rest.
  #
  # Converts a single PDV event to one or more MusicXML note/rest elements.
  # Handles duration decomposition, ties, backup/forward for polyphony,
  # and all articulations/ornaments.
  #
  # @param measure [Musa::MusicXML::Builder::Measure] target measure
  # @param bar [Integer] bar number (1-based)
  # @param divisions_per_bar [Integer] total divisions in bar
  # @param element [Hash] event hash from score query
  #   Contains :start, :finish, :dataset keys
  # @param pointer [Rational] current position in bar (0-1)
  # @param logger [Musa::Logger::Logger] logger for debugging
  # @param do_log [Boolean] enable logging
  #
  # @return [Rational] updated pointer position
  #
  # @raise [NotImplementedError] if tuplet ratios found (not yet supported)
  #
  # @example Simple quarter note
  #   element = {
  #     start: 1r,
  #     finish: 2r,
  #     dataset: { pitch: 60, duration: 1r }.extend(Musa::Datasets::PDV)
  #   }
  #   pointer = process_pdv(measure, 1, 96, element, 0r, logger, false)
  #   # Adds C4 quarter note, returns 1r
  #
  # @example Rest
  #   element = {
  #     start: 1r,
  #     finish: 2r,
  #     dataset: { pitch: :silence, duration: 1r }.extend(Musa::Datasets::PDV)
  #   }
  #   pointer = process_pdv(measure, 1, 96, element, 0r, logger, false)
  #   # Adds quarter rest, returns 1r
  #
  # @example Note with articulation
  #   dataset = { pitch: 64, duration: 1/2r, st: true }.extend(Musa::Datasets::PDV)
  #   # Adds staccato eighth note
  #
  # @example Tied note across bar
  #   element = { start: 1r, finish: 3r, dataset: { pitch: 60, duration: 2r } }
  #   # Automatically tied: tie-start in bar 1, tie-stop in bar 2
  #
  # @api private
  private def process_pdv(measure, bar, divisions_per_bar, element, pointer, logger, do_log)

    pitch, octave, sharps = pitch_and_octave_and_sharps(element[:dataset])

    continue_from_previous_bar = element[:start] < bar
    continue_to_next_bar = element[:finish] > bar + 1r

    effective_start = continue_from_previous_bar ? 0r : element[:start] - bar

    effective_duration = continue_to_next_bar ?
                             (1r - effective_start) :
                             (element[:start] + element[:dataset][:duration] - (bar + effective_start))

    effective_duration_decomposition = \
      integrate_as_dotteable_durations(
        decompose_as_sum_of_simple_durations(effective_duration))

    if do_log
      logger.debug ''
      logger.debug('process_pdv') { "processing #{element.inspect}" }
      logger.debug { "" }
      logger.debug { "           pointer #{pointer.inspect} continue_from_previous #{continue_from_previous_bar} continue_to_next #{continue_to_next_bar}" }
      logger.debug { "           effective_start #{effective_start.inspect} effective_duration #{effective_duration.inspect}" }
      logger.debug { "           duration decomposition #{effective_duration_decomposition}" }
    end

    if pointer > effective_start
      duration_to_go_back = (pointer - effective_start)

      logger.debug ''
      logger.debug { "       ->  adding backup #{duration_to_go_back * divisions_per_bar}" } if do_log

      measure.add_backup(duration_to_go_back * divisions_per_bar)
      pointer -= duration_to_go_back


    elsif pointer < effective_start
      logger.warn { "       ->  adding start rest duration #{effective_start - pointer} start #{bar + pointer} finish #{bar + effective_start}" } if do_log

      pointer = process_pdv(measure, bar, divisions_per_bar,
                            { start: bar + pointer,
                              finish: bar + effective_start,
                              dataset: { pitch: :silence, duration: effective_start - pointer }.extend(PDV) },
                            pointer,
                            logger, do_log)
    end

    # TODO generalize articulations and other musicxml elements

    staccato = element[:dataset][:st] == 1 || element[:dataset][:st] == true
    staccatissimo = element[:dataset][:st].is_a?(Numeric) && element[:dataset][:st] > 1

    trill = !element[:dataset][:tr].nil?

    mordent = [:down, :low].include?(element[:dataset][:mor])
    inverted_mordent = [:up, true].include?(element[:dataset][:mor])

    turn = [:up, true].include?(element[:dataset][:turn])
    inverted_turn = [:down, :low].include?(element[:dataset][:turn])

    first = true

    until effective_duration_decomposition.empty?
      duration = effective_duration_decomposition.shift

      type, dots, tuplet_ratio = type_and_dots_and_tuplet_ratio(duration)

      raise NotImplementedError,
            "Found irregular time (tuplet ratio #{tuplet_ratio}) on element #{element}. " \
            "Don't know how to handle on this version. " \
        unless tuplet_ratio == 1

      tied = if continue_from_previous_bar && first && !effective_duration_decomposition.empty?
               'continue'
             elsif continue_to_next_bar && effective_duration_decomposition.empty?
               'continue'
             elsif !first && !effective_duration_decomposition.empty?
               'continue'
             elsif first && !effective_duration_decomposition.empty?
               'start'
             elsif !first && effective_duration_decomposition.empty?
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
                          slur: slur,
                          tied: tied,
                          tie_stop: tied == 'stop' || tied == 'continue',
                          tie_start: tied == 'start' || tied == 'continue',
                          staccato: staccato,
                          staccatissimo: staccatissimo,
                          trill_mark: trill,
                          mordent: mordent,
                          inverted_mordent: inverted_mordent,
                          turn: turn,
                          inverted_turn: inverted_turn,
                          voice: element[:dataset][:voice]
      end

      first = false
      pointer += duration unless element[:dataset][:grace]
    end

    pointer
  end

  # Converts MIDI pitch to note name, octave, and accidental.
  #
  # Maps MIDI pitch number (0-127) to MusicXML pitch representation.
  # Middle C (MIDI 60) = C4 in scientific pitch notation.
  #
  # @param pdv [Hash] PDV dataset with :pitch key
  #
  # @return [Array(String, Integer, Integer), Array(Symbol, nil, nil)]
  #   - For pitches: [note_name, octave, sharps]
  #   - For silence: [:silence, nil, nil]
  #
  # @example Middle C
  #   pitch_and_octave_and_sharps({ pitch: 60 })
  #   # => ["C", 4, 0]
  #
  # @example C#4
  #   pitch_and_octave_and_sharps({ pitch: 61 })
  #   # => ["C", 4, 1]
  #
  # @example A4 (440Hz)
  #   pitch_and_octave_and_sharps({ pitch: 69 })
  #   # => ["A", 4, 0]
  #
  # @example Rest
  #   pitch_and_octave_and_sharps({ pitch: :silence })
  #   # => [:silence, nil, nil]
  #
  # @api private
  private def pitch_and_octave_and_sharps(pdv)
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

  # Converts MIDI velocity to dynamics index.
  #
  # Maps MIDI velocity (0-127) to dynamics marking index (0-10).
  # Used for determining dynamics from velocity values.
  #
  # @param midi_velocity [Integer, nil] MIDI velocity value
  #
  # @return [Integer, nil] dynamics index (0-10), or nil if no velocity
  #
  # @example Pianissimo
  #   dynamics_index_of(16)  # => 3 (ppp)
  #
  # @example Mezzo-forte
  #   dynamics_index_of(64)  # => 6 (mf)
  #
  # @example Fortissimo
  #   dynamics_index_of(100) # => 9 (ff)
  #
  # @api private
  private def dynamics_index_of(midi_velocity)
    return nil unless midi_velocity

    # ppp = midi 16 ... fff = midi 127
    # mp = dynamics index 6; dynamics = 0..10
    # TODO create a customizable MIDI velocity to score dynamics bidirectional conversor
    [0..0, 1..1, 2..8, 9..16, 17..33, 34..48, 49..64, 65..80, 81..96, 97..112, 113..127]
       .index { |r| r.cover? midi_velocity.round.to_i }
  end

  # Converts dynamics index to MusicXML dynamics string.
  #
  # Maps dynamics index (0-10) to standard dynamics marking string.
  #
  # @param dynamics_index [Integer, nil] dynamics index
  #
  # @return [String, nil] dynamics marking string, or nil if no index
  #
  # @example
  #   dynamics_to_string(3)  # => "ppp"
  #   dynamics_to_string(6)  # => "mp"
  #   dynamics_to_string(9)  # => "ff"
  #
  # @api private
  private def dynamics_to_string(dynamics_index)
    return nil unless dynamics_index
    ['pppppp', 'ppppp', 'pppp', 'ppp', 'pp', 'p', 'mp', 'mf', 'f', 'ff', 'fff'][dynamics_index.round.to_i]
  end
end
