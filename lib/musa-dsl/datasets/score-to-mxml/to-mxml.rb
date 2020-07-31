require_relative '../../musicxml'

require_relative 'process-time'
require_relative 'process-pdv'
require_relative 'process-ps'

module Musa::Datasets::Score::ToMXML

  include Musa::MusicXML::Builder
  include Musa::Datasets

  def to_mxml(beats_per_bar, ticks_per_beat,
              bpm: nil,
              title: nil,
              creators: nil,
              encoding_date: nil,
              parts:)

    bpm ||= 90
    title ||= 'Untitled'
    creators ||= { composer: 'Unknown' }

    mxml = ScorePartwise.new do |_|
      _.work_title title
      _.creators creators
      _.encoding_date encoding_date if encoding_date

      parts.each_pair do |id, part_info|
        _.part id,
               name: part_info&.[](:name) ,
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

    parts.each_key do |part_id|
      fill_part mxml.parts[part_id], beats_per_bar * ticks_per_beat, (parts.size > 1 ? part_id : nil)
    end

    mxml
  end

  private

  def fill_part(part, divisions_per_bar, instrument = nil)
    measure = nil
    dynamics_context = nil

    (1..finish || 0).each do |bar|
      measure = part.add_measure if measure
      measure ||= part.measures.last

      pointer = 0r

      instrument_score = subset { |dataset| dataset[:instrument] == instrument }

      bar_elements = \
        (instrument_score.changes_between(bar, bar + 1).select { |p| p[:dataset].is_a?(PS) } +
          (pdvs = instrument_score.between(bar, bar + 1).select { |p| p[:dataset].is_a?(PDV) }))
        .sort_by { |element| element[:time_in_interval] || element[:start_in_interval] }


      bar_elements.each do |element|
        case element[:dataset]
        when PDV
          pointer = process_pdv(measure, bar, divisions_per_bar, element, pointer)

        when PS
          dynamics_context = process_ps(measure, element, dynamics_context)
        else
          # ignored
        end
      end

      if pdvs.empty?
        process_pdv(measure, bar, divisions_per_bar,
                    { start: bar,
                      finish: bar + 1,
                      dataset: { pitch: :silence, duration: 1 }.extend(PDV) },
                    pointer)

      end
    end
  end
end
