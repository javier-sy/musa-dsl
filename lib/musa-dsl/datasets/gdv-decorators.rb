module Musa::Datasets::GDV

  # Process: appogiatura (neuma)neuma
  class AppogiaturaDecorator < TwoNeumasDecorator
    def process(gdv, base_duration:, tick_duration:)
      if gdv_appogiatura = gdv[:appogiatura]
        gdv.delete :appogiatura

        # TODO process with Decorators the gdv_appogiatura
        # TODO implement also posterior appogiatura neuma(neuma)
        # TODO implement also multiple appogiatura with several notes (neuma neuma)neuma or neuma(neuma neuma)

        gdv[:duration] = gdv[:duration] - gdv_appogiatura[:duration]

        [ gdv_appogiatura, gdv ]
      else
        gdv
      end
    end
  end

  # Process: .mord
  class MordentDecorator < Decorator
    def initialize(duration_factor: nil)
      @duration_factor = duration_factor || 1/4r
    end

    def process(gdv, base_duration:, tick_duration:)
      mor = gdv.delete :mor

      if mor
        direction = :up

        check(mor) do |mor|
          case mor
          when :true, :up
            direction = :up
          when :down, :low
            direction = :down
          end
        end

        short_duration = [base_duration * @duration_factor, tick_duration].max

        gdvs = []

        gdvs << gdv.clone.tap { |gdv| gdv[:duration] = short_duration }

        case direction
        when true, :up
          gdvs << gdv.clone.tap { |gdv| gdv[:grade] += 1; gdv[:duration] = short_duration }
        when :down, :low
          gdvs << gdv.clone.tap { |gdv| gdv[:grade] -= 1; gdv[:duration] = short_duration }
        end

        gdvs << gdv.clone.tap { |gdv| gdv[:duration] -= 2 * short_duration }

        gdvs
      else
        gdv
      end
    end
  end

  # Process: .tr
  class TrillDecorator < Decorator
    # TODO include lower note at the end, confirm if the last note is the base or the lower one
    # TODO refine timing when repetitions is not divisible by 2
    #
    def initialize(duration_factor: nil)
      @duration_factor = duration_factor || 1/4r
    end

    def process(gdv, base_duration:, tick_duration:)
      if gdv[:tr]
        tr = gdv.delete :tr

        note_duration = base_duration * @duration_factor

        check(tr) do |tr|
          case tr
          when Numeric # duration factor
            note_duration *= base_duration * tr
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

          when :same # start with the same note
            gdvs << gdv.clone.tap { |gdv| gdv[:grade] += (last = 0); gdv[:duration] = note_duration }
            used_duration += note_duration
          end
        end

        while used_duration + 2 * note_duration <= gdv[:duration]
          gdvs << gdv.clone.tap { |gdv| gdv[:grade] += (last = 1); gdv[:duration] = note_duration }
          gdvs << gdv.clone.tap { |gdv| gdv[:grade] += (last = 0); gdv[:duration] = note_duration }

          used_duration += 2 * note_duration
        end

        duration_diff = gdv[:duration] - used_duration
        if duration_diff >= note_duration
          # ???
        elsif duration_diff > 0
          gdvs.last[:duration] += duration_diff
        end

        gdvs
      else
        gdv
      end
    end
  end

  # Process: .st .st(1) .st(2) .st(3): staccato level 1 2 3
  class StaccatoDecorator < Decorator
    def initialize(min_duration_factor: nil)
      @min_duration_factor = min_duration_factor || 1/8r
    end

    def process(gdv, base_duration:, tick_duration:)
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

        gdv[:effective_duration] = [calculated, base_duration * @min_duration_factor].max
      end

      gdv
    end
  end
end