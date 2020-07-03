require 'musa-dsl'

# TODO Este ScoreBuilder no es en realidad un Translator (de Score/Dataset a MusicXML)???? Lo que hay ya hecho en el módulo MusicXML son Builder's. Deberían estar en un submódulo

module MusicXML # TODO Cambiar a otro paquete, ya dentro de MusaDSL

  class ScoresToMusicXML # sabe traducir un conjunto de Scores con algunos Datasets existentes (PDV + DynamicPS + ...?)
    include Musa::Datasets
    include Musa::MusicXML

    def initialize(score, scale, filename)
      @score = score
      @scale = scale
      @filename = filename
      @divisions_per_bar = 96
      @divisions_per_quarter = 24
      @bpm = 90
    end

    def render
      mxml = ScorePartwise.new do |_|
        _.work_title "Prueba de integración entre GDV y MusicXML"
        _.creators composer: "Javier Sánchez"

        _.part :piano, name: "Piano", abbreviation: "pno" do |_|
          _.measure do |_|
            _.attributes do |_|
              _.divisions @divisions_per_quarter

              _.clef 1, sign: 'G', line: 2
              _.time 1, beats: 4, beat_type: 4

              _.clef 2, sign: 'F', line: 4
              _.time 2, beats: 4, beat_type: 4
            end

            _.metronome beat_unit: 'quarter', per_minute: @bpm
          end
        end
      end

      fill mxml.parts[:piano]

      File.open(@filename, 'w') { |f| f.write(mxml.to_xml.string) }
    end

    private

    def fill(part)
      puts "Renderer.fill @score.finish = #{@score.finish}"

      measure = nil

      (1..@score.finish || 0).each do |bar|
        measure = part.add_measure if measure
        measure ||= part.measures.last

        puts "Rendering bar #{bar}..."

        pointer = 0r

        @score.between(bar, bar + 1).each do |i|

          if i[:dataset].is_a?(GDV)
            pitch, octave, sharps = pitch_and_octave_and_sharps(i[:dataset], @scale)

            puts "pointer = #{pointer}"
            puts "pitch = #{pitch} octave = #{octave} sharps = #{sharps}"

            continue_from_previous_bar = i[:start] < bar
            continue_to_next_bar = i[:finish] >= bar + 1r

            effective_start = continue_from_previous_bar ? 0r : i[:start] - bar
            effective_duration = continue_to_next_bar ? (1r - effective_start) : (i[:start] + i[:dataset][:duration] - (bar + effective_start))

            effective_duration_decomposition = decompose(effective_duration)

            puts "continue_from_previous_bar = #{continue_from_previous_bar} continue_to_next_bar = #{continue_to_next_bar} effective_start = #{effective_start} effective_duration = #{effective_duration} decomposition = #{effective_duration_decomposition}"

            if pointer > effective_start
              duration_to_go_back = (pointer - effective_start)
              puts "going back #{duration_to_go_back}"

              measure.add_backup(duration_to_go_back * @divisions_per_bar)
              pointer -= duration_to_go_back
            end

            staccato = i[:dataset][:st] == 1 || i[:dataset][:st] == true
            staccatissimo = i[:dataset][:st].is_a?(Numeric) && i[:dataset][:st] > 1

            trill = !i[:dataset][:tr].nil?

            mordent = [:down, :low].include?(i[:dataset][:mor])
            inverted_mordent = [:up, true].include?(i[:dataset][:mor])

            turn = [:up, true].include?(i[:dataset][:turn])
            inverted_turn = [:down, :low].include?(i[:dataset][:turn])

            until effective_duration_decomposition.empty?
              type, dots, consumed_duration, remaining = type_and_dots_and_remaining(effective_duration_decomposition)

              duration = consumed_duration.collect { |i| (2**i).rationalize }.sum

              tied = if continue_from_previous_bar && continue_to_next_bar
                       'start'
                     elsif continue_to_next_bar
                       'start'
                     elsif continue_from_previous_bar
                       'stop'
                     else
                       nil
                     end

              slur = if i[:dataset][:grace]
                       { type: 'start', number: 2 }
                     elsif i[:dataset][:graced]
                       { type: 'stop', number: 2 }
                     end

              if pitch == :silence
                measure.add_rest type: type,
                                 dots: dots,
                                 duration: duration * @divisions_per_bar,
                                 voice: i[:dataset][:voice]
              else
                measure.add_pitch pitch, octave: octave, alter: sharps,
                                  type: type,
                                  dots: dots,
                                  grace: i[:dataset][:grace],
                                  tied: tied,
                                  slur: slur,
                                  tie_start: continue_to_next_bar,
                                  tie_stop: continue_from_previous_bar,
                                  duration: duration * @divisions_per_bar,
                                  staccato: staccato,
                                  staccatissimo: staccatissimo,
                                  trill_mark: trill,
                                  mordent: mordent,
                                  inverted_mordent: inverted_mordent,
                                  turn: turn,
                                  inverted_turn: inverted_turn,
                                  voice: i[:dataset][:voice]
              end

              pointer += duration unless i[:dataset][:grace]

              effective_duration_decomposition = remaining
            end
          else
            puts "ignored #{i}"
          end
        end
      end
    end

    def type_and_dots_and_remaining(duration_or_decomposition)
      r = duration_or_decomposition.is_a?(Array) ?
              duration_or_decomposition :
              decompose(duration_or_decomposition)

      n = r.shift
      d = [n]

      type = type_of(n)

      nn = nil
      dots = 0

      while nn = r.shift
        if nn == n - 1
          dots += 1
          n = nn
          d << n
        else
          break
        end
      end

      r.unshift nn if nn && nn != n

      [type, dots, d, r]
    end

    def decompose(duration)
      log2 = Math.log2(duration)
      i = log2.floor
      r = duration - (2 ** i)

      r == 0 ? [i] : [i] + decompose(r)
    end

    def type_of(duration_log2i)
      raise ArgumentError, "#{duration_log2i} is not between -10 and 3 accepted values" unless duration_log2i >= -10 && duration_log2i <= 3

      ['1024th', '512th', '256th', '128th',
       '64th', '32th', '16th', 'eighth',
       'quarter', 'half', 'whole', 'breve',
       'long', 'maxima'][duration_log2i + 10]
    end

    def pitch_and_octave_and_sharps(gdv, scale)
      pdv = gdv.to_pdv(scale)

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
  end
end
