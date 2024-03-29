require_relative 'from-gdv'

module Musa::Transcriptors
  module FromGDV
    module ToMIDI
      def self.transcription_set(duration_factor: nil)
        [ Appogiatura.new,
          Mordent.new(duration_factor: duration_factor),
          Turn.new,
          Trill.new(duration_factor: duration_factor),
          Staccato.new,
          Base.new ]
      end

      # Process: appogiatura (neuma)neuma
      class Appogiatura < Musa::Transcription::FeatureTranscriptor
        def transcript(gdv, base_duration:, tick_duration:)
          gdv_appogiatura = gdv.delete :appogiatura

          if gdv_appogiatura
            # TODO process with Decorators the gdv_appogiatura
            # TODO implement also posterior appogiatura neuma(neuma)
            # TODO implement also multiple appogiatura with several notes (neuma ... neuma)neuma or neuma(neuma ... neuma)

            gdv[:duration] = gdv[:duration] - gdv_appogiatura[:duration]

            super [ gdv_appogiatura, gdv ], base_duration: base_duration, tick_duration: tick_duration
          else
            super
          end
        end
      end

      # Process: .mor
      class Mordent < Musa::Transcription::FeatureTranscriptor
        def initialize(duration_factor: nil)
          @duration_factor = duration_factor || 1/4r
        end

        def transcript(gdv, base_duration:, tick_duration:)
          mor = gdv.delete :mor

          if mor
            direction = :up

            check(mor) do |mor|
              case mor
              when true, :up
                direction = :up
              when :down, :low
                direction = :down
              end
            end

            short_duration = [base_duration * @duration_factor, tick_duration].max

            gdvs = []

            gdvs << gdv.clone.tap { |gdv| gdv[:duration] = short_duration }

            case direction
            when :up
              gdvs << gdv.clone.tap { |gdv| gdv[:grade] += 1; gdv[:duration] = short_duration }
            when :down
              gdvs << gdv.clone.tap { |gdv| gdv[:grade] -= 1; gdv[:duration] = short_duration }
            end

            gdvs << gdv.clone.tap { |gdv| gdv[:duration] -= 2 * short_duration }

            super gdvs, base_duration: base_duration, tick_duration: tick_duration
          else
            super
          end
        end
      end

      # Process: .turn
      class Turn < Musa::Transcription::FeatureTranscriptor
        def transcript(gdv, base_duration:, tick_duration:)
          turn = gdv.delete :turn

          if turn
            start = :up

            check(turn) do |turn|
              case turn
              when :true, :up
                start = :up
              when :down, :low
                start = :down
              end
            end

            duration = gdv[:duration] / 4r

            gdvs = []

            case start
            when :up
              gdvs << gdv.clone.tap { |gdv| gdv[:grade] += 1; gdv[:duration] = duration }
              gdvs << gdv.clone.tap { |gdv| gdv[:grade] += 0; gdv[:duration] = duration }
              gdvs << gdv.clone.tap { |gdv| gdv[:grade] += -1; gdv[:duration] = duration }
              gdvs << gdv.clone.tap { |gdv| gdv[:grade] += 0; gdv[:duration] = duration }
            when :down
              gdvs << gdv.clone.tap { |gdv| gdv[:grade] += -1; gdv[:duration] = duration }
              gdvs << gdv.clone.tap { |gdv| gdv[:grade] += 0; gdv[:duration] = duration }
              gdvs << gdv.clone.tap { |gdv| gdv[:grade] += 1; gdv[:duration] = duration }
              gdvs << gdv.clone.tap { |gdv| gdv[:grade] += 0; gdv[:duration] = duration }
            end

            super gdvs, base_duration: base_duration, tick_duration: tick_duration
          else
            super
          end
        end
      end

      # Process: .tr
      class Trill < Musa::Transcription::FeatureTranscriptor
        def initialize(duration_factor: nil)
          @duration_factor = duration_factor || 1/4r
        end

        def transcript(gdv, base_duration:, tick_duration:)
          tr = gdv.delete :tr

          if tr
            note_duration = base_duration * @duration_factor

            check(tr) do |tr|
              case tr
              when Numeric # duration factor
                note_duration *= base_duration * tr.to_r
              end
            end

            used_duration = 0r
            last = nil

            gdvs = []

            check(tr) do |tr|
              case tr
              when :low # start with lower note
                gdvs << gdv.clone.tap { |gdv| gdv[:grade] += (last = -1); gdv[:duration] = note_duration }
                gdvs << gdv.clone.tap { |gdv| gdv[:grade] += (last = 0); gdv[:duration] = note_duration }
                used_duration += 2 * note_duration

              when :low2 # start with upper note but go to lower note once
                gdvs << gdv.clone.tap { |gdv| gdv[:grade] += (last = 1); gdv[:duration] = note_duration }
                gdvs << gdv.clone.tap { |gdv| gdv[:grade] += (last = 0); gdv[:duration] = note_duration }
                gdvs << gdv.clone.tap { |gdv| gdv[:grade] += (last = -1); gdv[:duration] = note_duration }
                gdvs << gdv.clone.tap { |gdv| gdv[:grade] += (last = 0); gdv[:duration] = note_duration }
                used_duration += 4 * note_duration

              when :same # start with the same note
                gdvs << gdv.clone.tap { |gdv| gdv[:grade] += (last = 0); gdv[:duration] = note_duration }
                used_duration += note_duration
              end
            end

            2.times do
              if used_duration + 2 * note_duration <= gdv[:duration]
                gdvs << gdv.clone.tap { |gdv| gdv[:grade] += (last = 1); gdv[:duration] = note_duration }
                gdvs << gdv.clone.tap { |gdv| gdv[:grade] += (last = 0); gdv[:duration] = note_duration }

                used_duration += 2 * note_duration
              end
            end

            while used_duration + 2 * note_duration * 2/3r <= gdv[:duration]
              gdvs << gdv.clone.tap { |gdv| gdv[:grade] += (last = 1); gdv[:duration] = note_duration * 2/3r }
              gdvs << gdv.clone.tap { |gdv| gdv[:grade] += (last = 0); gdv[:duration] = note_duration * 2/3r }

              used_duration += 2 * note_duration * 2/3r
            end

            duration_diff = gdv[:duration] - used_duration
            if duration_diff >= note_duration
              gdvs << gdv.clone.tap { |gdv| gdv[:grade] += (last = 1); gdv[:duration] = duration_diff / 2 }
              gdvs << gdv.clone.tap { |gdv| gdv[:grade] += (last = 0); gdv[:duration] = duration_diff / 2 }

            elsif duration_diff > 0
              gdvs[-1][:duration] += duration_diff / 2
              gdvs[-2][:duration] += duration_diff / 2
            end

            super gdvs, base_duration: base_duration, tick_duration: tick_duration
          else
            super
          end
        end
      end

      # Process: .st .st(1) .st(2) .st(3): staccato level 1 2 3
      class Staccato < Musa::Transcription::FeatureTranscriptor
        def initialize(min_duration_factor: nil)
          @min_duration_factor = min_duration_factor || 1/8r
        end

        def transcript(gdv, base_duration:, tick_duration:)
          st = gdv.delete :st

          if st
            calculated = 0

            check(st) do |st|
              case st
              when true
                calculated = gdv[:duration] / 2r
              when Numeric
                calculated = gdv[:duration] / 2**st if st >= 1
              end
            end

            gdv[:note_duration] = [calculated, base_duration * @min_duration_factor].max
          end

          super
        end
      end

    end
  end
end
