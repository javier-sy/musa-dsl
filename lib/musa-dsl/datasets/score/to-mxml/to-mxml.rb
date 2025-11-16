require_relative '../../../logger'
require_relative '../../../musicxml'
require_relative '../../../core-ext/inspect-nice'

require_relative 'process-time'
require_relative 'process-pdv'
require_relative 'process-ps'

module Musa::Datasets
  class Score
    # MusicXML export for scores.
    #
    # ToMXML provides conversion of {Score} objects to MusicXML format,
    # suitable for import into notation software like MuseScore, Finale,
    # or Sibelius.
    #
    # ## Conversion Process
    #
    # 1. Creates MusicXML structure with metadata (title, creators, etc.)
    # 2. Defines parts (instruments) with clefs and time signatures
    # 3. Divides score into measures (bars)
    # 4. Processes events in each measure:
    #
    #    - {PDV} events → notes and rests
    #    - {PS} events → dynamics markings (crescendo, diminuendo)
    #
    # 5. Fills gaps with rests
    #
    # ## Event Types Supported
    #
    # - **{PDV}** (Pitch/Duration/Velocity): Converted to notes or rests
    # - **{PS}** (Pitch Series): Converted to dynamics markings
    #
    # ## Multi-part Scores
    #
    # Scores can contain multiple instruments, differentiated by the
    # :instrument attribute. Each part is rendered separately.
    #
    # ## Time Representation
    #
    # - Score times are 1-based (first beat is at position 1)
    # - Each measure represents one bar
    # - Duration is specified in beats (1.0 = quarter note if beat_type is 4)
    #
    # @example Basic single-part score
    #   score = Musa::Datasets::Score.new
    #   score.at(1r, add: { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))
    #   score.at(2r, add: { pitch: 64, duration: 1.0 }.extend(Musa::Datasets::PDV))
    #
    #   mxml = score.to_mxml(
    #     4, 24,  # 4 beats per bar, 24 ticks per beat
    #     bpm: 120,
    #     title: 'My Song',
    #     creators: { composer: 'John Doe' },
    #     parts: { piano: { name: 'Piano', clefs: { g: 2 } } }
    #   )
    #
    #   File.write('score.musicxml', mxml.to_xml.string)
    #
    # @example Multi-part score
    #   score = Musa::Datasets::Score.new
    #   score.at(1r, add: { instrument: :violin, pitch: 67, duration: 1.0 }.extend(Musa::Datasets::PDV))
    #   score.at(1r, add: { instrument: :cello, pitch: 48, duration: 1.0 }.extend(Musa::Datasets::PDV))
    #
    #   mxml = score.to_mxml(
    #     4, 24,
    #     parts: {
    #       violin: { name: 'Violin', clefs: { g: 2 } },
    #       cello: { name: 'Cello', clefs: { f: 4 } }
    #     }
    #   )
    #
    # @example With dynamics
    #   score = Musa::Datasets::Score.new
    #   score.at(1r, add: { pitch: 60, duration: 2.0 }.extend(Musa::Datasets::PDV))
    #   score.at(1r, add: { type: :crescendo, duration: 2.0 }.extend(Musa::Datasets::PS))
    #
    # @see Musa::MusicXML::Builder MusicXML builder
    # @see PDV MIDI-style events
    # @see PS Pitch series for dynamics
    module ToMXML
      using Musa::Extension::InspectNice

      # Converts score to MusicXML.
      #
      # Creates complete MusicXML document with metadata, parts, measures,
      # notes, rests, and dynamics markings.
      #
      # @param beats_per_bar [Integer] time signature numerator (e.g., 4 for 4/4)
      # @param ticks_per_beat [Integer] resolution per beat (typically 24)
      #
      # @param bpm [Integer] tempo in beats per minute (default: 90)
      # @param title [String] work title (default: 'Untitled')
      # @param creators [Hash{Symbol => String}] creator roles and names
      #   (default: { composer: 'Unknown' })
      # @param encoding_date [DateTime, nil] encoding date for metadata
      # @param parts [Hash{Symbol => Hash}] part definitions
      #   Each part: { name: String, abbreviation: String, clefs: Hash }
      #   Clefs: { clef_sign: line_number } (e.g., { g: 2, f: 4 } for piano)
      # @param logger [Musa::Logger::Logger, nil] logger for debugging
      # @param do_log [Boolean, nil] enable logging output
      #
      # @return [Musa::MusicXML::Builder::ScorePartwise] MusicXML document
      #
      # @example Simple piano score
      #   score = Musa::Datasets::Score.new
      #   score.at(1r, add: { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))
      #
      #   mxml = score.to_mxml(
      #     4, 24,
      #     bpm: 120,
      #     title: 'Invention',
      #     creators: { composer: 'J.S. Bach' },
      #     parts: { piano: { name: 'Piano', clefs: { g: 2, f: 4 } } }
      #   )
      #
      # @example String quartet
      #   score = Musa::Datasets::Score.new
      #   score.at(1r, add: { instrument: :vln1, pitch: 67, duration: 1.0 }.extend(Musa::Datasets::PDV))
      #   score.at(1r, add: { instrument: :vln2, pitch: 64, duration: 1.0 }.extend(Musa::Datasets::PDV))
      #   score.at(1r, add: { instrument: :vla, pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))
      #   score.at(1r, add: { instrument: :vc, pitch: 48, duration: 1.0 }.extend(Musa::Datasets::PDV))
      #
      #   mxml = score.to_mxml(
      #     4, 24,
      #     parts: {
      #       vln1: { name: 'Violin I', abbreviation: 'Vln. I', clefs: { g: 2 } },
      #       vln2: { name: 'Violin II', abbreviation: 'Vln. II', clefs: { g: 2 } },
      #       vla: { name: 'Viola', abbreviation: 'Vla.', clefs: { c: 3 } },
      #       vc: { name: 'Cello', abbreviation: 'Vc.', clefs: { f: 4 } }
      #     }
      #   )
      #
      # @example Export to file
      #   score = Musa::Datasets::Score.new
      #   score.at(1r, add: { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))
      #
      #   mxml = score.to_mxml(4, 24, parts: { piano: { name: 'Piano' } })
      #   File.write('output.musicxml', mxml.to_xml.string)
      def to_mxml(beats_per_bar, ticks_per_beat,
                  bpm: nil,
                  title: nil,
                  creators: nil,
                  encoding_date: nil,
                  parts:,
                  logger: nil,
                  do_log: nil)

        bpm ||= 90
        title ||= 'Untitled'
        creators ||= { composer: 'Unknown' }

        if logger.nil?
          logger = Musa::Logger::Logger.new
          logger.debug! if do_log
        end

        do_log ||= nil

        mxml = Musa::MusicXML::Builder::ScorePartwise.new do |_|
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
          logger.debug ""
          logger.debug"score.to_mxml log:"
          logger.debug"------------------"
        end

        parts.each_key do |part_id|
          fill_part mxml.parts[part_id],
                    beats_per_bar * ticks_per_beat,
                    (parts.size > 1 ? part_id : nil),
                    logger, do_log
        end

        mxml
      end

      private

      # Fills a MusicXML part with measures and events.
      #
      # Processes each bar (measure) in the score, converting events to
      # MusicXML notes, rests, and dynamics. Handles:
      #
      # - Initial silences (gaps before first event)
      # - Event processing (PDV → notes, PS → dynamics)
      # - Ending silences (filling remainder of measure)
      #
      # @param part [Musa::MusicXML::Builder::Part] MusicXML part to fill
      # @param divisions_per_bar [Integer] total divisions in one bar
      # @param instrument [Symbol, nil] instrument filter (nil for single-part scores)
      # @param logger [Musa::Logger::Logger] logger for debugging
      # @param do_log [Boolean] enable logging
      #
      # @return [void]
      #
      # @api private
      def fill_part(part, divisions_per_bar, instrument, logger, do_log)
        measure = nil
        dynamics_context = nil

        (1..finish || 0).each do |bar|
          if do_log
            logger.debug ""
            logger.debug msg = "filling part #{part.name} (#{instrument || 'nil'}): processing bar #{bar}"
            logger.debug "-" * msg.size
          end

          measure = part.add_measure if measure
          measure ||= part.measures.last

          pointer = 0r

          instrument_score = subset { |dataset| instrument.nil? || dataset[:instrument] == instrument }

          bar_elements = \
          (instrument_score.changes_between(bar, bar + 1).select { |p| p[:dataset].is_a?(Musa::Datasets::PS) } +
              (pdvs = instrument_score.between(bar, bar + 1).select { |p| p[:dataset].is_a?(Musa::Datasets::PDV) }))
                                     .sort_by { |e| [ e[:time_in_interval] || e[:start_in_interval],
                                                      e[:dataset].is_a?(Musa::Datasets::PS) ? 0 : 1 ] }

          if pdvs.empty?
            logger.debug "\nadding full bar silence..." if do_log

            process_pdv(measure, bar, divisions_per_bar,
                        { start: bar,
                          finish: bar + 1,
                          dataset: { pitch: :silence, duration: 1 }.extend(Musa::Datasets::PDV) },
                        pointer,
                        logger,
                        do_log)
          else
            first = bar_elements.first

            logger.debug "\nfirst element #{first.inspect}" if do_log

            # TODO habrá que arreglar el cálculo de pointer cuando haya avances y retrocesos para que
            # TODO no añada silencios incorrectos al principio o al final

            if (first[:time_in_interval] || first[:start_in_interval]) > bar

              silence_duration = first[:start_in_interval] - bar

              logger.debug "\nadding initial silence for duration #{silence_duration}..." if do_log

              pointer = process_pdv(measure, bar, divisions_per_bar,
                                    { start: bar,
                                      finish: first[:start_in_interval],
                                      dataset: { pitch: :silence, duration: silence_duration }.extend(Musa::Datasets::PDV) },
                                    pointer,
                                    logger,
                                    do_log)
            end

            logger.debug "\nadding PDV and PS elements..." if do_log

            bar_elements.each do |element|
              case element[:dataset]
              when Musa::Datasets::PDV
                pointer = process_pdv(measure, bar, divisions_per_bar, element, pointer, logger, do_log)

              when Musa::Datasets::PS
                dynamics_context = process_ps(measure, element, dynamics_context, logger, do_log)

              else
                # ignored
              end
            end

            if pointer < 1r
              silence_duration = 1r - pointer

              logger.debug "\nadded ending silence for duration #{silence_duration}..." if do_log

              process_pdv(measure, bar, divisions_per_bar,
                          { start: bar + pointer,
                            finish: bar + 1 - Rational(1, divisions_per_bar),
                            dataset: { pitch: :silence, duration: silence_duration }.extend(Musa::Datasets::PDV) },
                          pointer,
                          logger,
                          do_log)

            end
          end
        end
      end
    end
end; end
