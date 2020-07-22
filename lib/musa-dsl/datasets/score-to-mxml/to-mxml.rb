require_relative '../../musicxml'

require_relative 'process-time'
require_relative 'process-pdv'
require_relative 'process-ps'

module Musa::Datasets::Score::ToMXML

  include Musa::MusicXML::Builder

  def to_mxml(beats_per_bar, ticks_per_beat,
              bpm: nil,
              title: nil,
              creators: nil,
              parts:)

    bpm ||= 90
    title ||= 'Untitled'
    creators ||= { composer: 'Unknown' }

    mxml = ScorePartwise.new do |_|
      _.work_title title
      _.creators creators

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

    (1..finish || 0).each do |bar|
      measure = part.add_measure if measure
      measure ||= part.measures.last

      pointer = 0r

      instrument_score = subset { |dataset| dataset[:instrument] == instrument }

      bar_elements = \
        (instrument_score.changes_between(bar, bar + 1).select { |p| p[:dataset].is_a?(PS) } +
          instrument_score.between(bar, bar + 1).select { |p| p[:dataset].is_a?(PDV) })
        .sort_by { |element| element[:time] || element[:start] }

      bar_elements.each do |element|
        case element[:dataset]
        when PDV
          process_pdv(measure, divisions_per_bar, bar, element, pointer)

        when PS
          process_ps(measure, divisions_per_bar, element)
        else
          # ignored
        end
      end
    end
  end
end
