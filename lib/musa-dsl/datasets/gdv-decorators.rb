module Musa::Datasets::GDV

  # Process: appogiatura (neuma)neuma
  class AppogiaturaDecorator < TwoNeumasDecorator
    def process(gdv, tick_duration:)
      if gdv_appogiatura = gdv[:appogiatura]
        gdv.delete :appogiatura

        # TODO process with Decorators the gdv_appogiatura

        gdv[:duration] = gdv[:duration] - gdv_appogiatura[:duration]

        [ gdv_appogiatura, gdv ]
      else
        gdv
      end
    end
  end

  # Process: .mord
  class MordentDecorator < Decorator
    def initialize(note_duration: nil)
      @note_duration = note_duration
    end

    def process(gdv, tick_duration:)
      if gdv[:mor]

        direction = gdv.delete(:mor)

        short_duration = [(@noteduration || gdv[:duration] / 8r), tick_duration].max

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
    def initialize(note_duration: nil)
      @note_duration = note_duration || 4/96r
    end

    def process(gdv, tick_duration:)
      if gdv[:tr]
        gdv.delete :tr

        repetitions = (gdv[:duration] / @note_duration).to_i / 2

        gdvs = []
        repetitions.times do
          gdvs << gdv.clone.tap { |gdv| gdv[:duration] = @note_duration }
          gdvs << gdv.clone.tap { |gdv| gdv[:grade] += 1; gdv[:duration] = @note_duration }
        end

        gdvs
      else
        gdv
      end
    end
  end

  # Process: .st .st(1) .st(2) .st(3): staccato level 1 2 3
  class StaccatoDecorator < Decorator
    def initialize(min_duration: nil)
      @min_duration = min_duration
    end

    def process(gdv, tick_duration:)
      if gdv[:st]
        case gdv[:st]
        when true
          calculated = gdv[:duration] / 2r
        when Numeric
          calculated = gdv[:duration] / 2**gdv[:st] if gdv[:st] >= 1
        end
        gdv.delete :st

        gdv[:effective_duration] = [calculated, (@min_duration || tick_duration)].max
      end

      gdv
    end
  end
end
