require_relative '../../../musicxml'

require_relative 'process-time'
require_relative 'process-pdv'
require_relative 'process-ps'

module Musa::Datasets; class Score
  module ToMXML
    include Musa::MusicXML::Builder
    include Musa::Datasets

    def to_mxml(beats_per_bar, ticks_per_beat,
                bpm: nil,
                title: nil,
                creators: nil,
                encoding_date: nil,
                parts:,
                do_log: nil)

      bpm ||= 90
      title ||= 'Untitled'
      creators ||= { composer: 'Unknown' }
      do_log ||= nil

      mxml = ScorePartwise.new do |_|
        _.work_title title
        _.creators **creators
        _.encoding_date encoding_date if encoding_date

        parts.each_pair do |id, part_info|
          _.part id,
                 name: part_info&.[](:name),
                 abbreviation: part_info&.[](:abbreviation) do |_|

            _.measure do |_|
              _.attributes do |_|
                _.divisions ticks_per_beat

                i = 0
                (part_info&.[](:clefs) || { g: 2 }).each_pair do |clef, line|
                  i += 1
                  _.clef i, sign: clef.upcase, line: line
                  _.time i, beats: beats_per_bar, beat_type: 4
                end
              end

              _.metronome placement: 'above', beat_unit: 'quarter', per_minute: bpm
            end
          end
        end
      end

      if do_log
        warn "\nscore.to_mxl log:"
        warn   "-----------------"
      end

      parts.each_key do |part_id|
        fill_part mxml.parts[part_id], beats_per_bar * ticks_per_beat, (parts.size > 1 ? part_id : nil), do_log
      end

      mxml
    end

    private

    def fill_part(part, divisions_per_bar, instrument, do_log)
      measure = nil
      dynamics_context = nil

      (1..finish || 0).each do |bar|
        if do_log
          warn ""
          warn msg = "filling part #{part.name} (#{instrument}): processing bar #{bar}"
          warn "-" * msg.size
        end

        measure = part.add_measure if measure
        measure ||= part.measures.last

        pointer = 0r

        instrument_score = subset { |dataset| dataset[:instrument] == instrument }

        bar_elements = \
        (instrument_score.changes_between(bar, bar + 1).select { |p| p[:dataset].is_a?(PS) } +
            (pdvs = instrument_score.between(bar, bar + 1).select { |p| p[:dataset].is_a?(PDV) }))
                                   .sort_by { |e| [ e[:time_in_interval] || e[:start_in_interval],
                                                    e[:dataset].is_a?(PS) ? 0 : 1 ] }

        if pdvs.empty?
          warn "\nadded full bar silence" if do_log

          process_pdv(measure, bar, divisions_per_bar,
                      { start: bar,
                        finish: bar + 1,
                        dataset: { pitch: :silence, duration: 1 }.extend(PDV) },
                      pointer,
                      do_log)
        else
          first = bar_elements.first

          warn "\nfirst element #{first}" if do_log

          # TODO habrá que arreglar el cálculo de pointer cuando haya avances y retrocesos para que
          # TODO no añada silencios incorrectos al principio o al final

          if (first[:time_in_interval] || first[:start_in_interval]) > bar

            silence_duration = first[:start_in_interval] - bar

            warn "\nadded initial silence for duration #{silence_duration}" if do_log

            pointer = process_pdv(measure, bar, divisions_per_bar,
                                  { start: bar,
                                    finish: first[:start_in_interval],
                                    dataset: { pitch: :silence, duration: silence_duration }.extend(PDV) },
                                  pointer,
                                  do_log)
          end

          bar_elements.each do |element|
            case element[:dataset]
            when PDV
              pointer = process_pdv(measure, bar, divisions_per_bar, element, pointer, do_log)

            when PS
              dynamics_context = process_ps(measure, element, dynamics_context, do_log)

            else
              # ignored
            end
          end

          if pointer < 1r
            silence_duration = 1r - pointer

            warn "\nadded ending silence for duration #{silence_duration}" if do_log

            process_pdv(measure, bar, divisions_per_bar,
                        { start: bar + pointer,
                          finish: bar + 1 - Rational(1, divisions_per_bar),
                          dataset: { pitch: :silence, duration: silence_duration }.extend(PDV) },
                        pointer,
                        do_log)

          end
        end
      end
    end
  end
end; end
