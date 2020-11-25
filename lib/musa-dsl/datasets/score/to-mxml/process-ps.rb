module Musa::Datasets::Score::ToMXML
  using Musa::Extension::InspectNice

  DynamicsContext = Struct.new(:last_dynamics)
  private_constant :DynamicsContext

  private def process_ps(measure, element, context, logger, do_log)
    context ||= DynamicsContext.new

    logger.debug ''
    logger.debug('process_ps') { "processing #{element.inspect}" } if do_log

    case element[:dataset][:type]
    when :crescendo, :diminuendo
      if element[:change] == :start
        dynamics = dynamics_to_string(element[:dataset][:from])

        if dynamics != context.last_dynamics
          if dynamics
            if element[:dataset][:from] < 0
              logger.warn { "dynamics #{element[:dataset][:from]} not renderizable" } if do_log
            elsif element[:dataset][:from] > 0
              measure.add_dynamics dynamics, placement: 'below'
            end
          end

          context.last_dynamics = dynamics
        end

        measure.add_wedge element[:dataset][:type],
                          niente: element[:dataset][:type] == :crescendo && element[:dataset][:from] == 0,
                          placement: 'below'
      else
        measure.add_wedge 'stop',
                          niente: element[:dataset][:type] == :diminuendo && element[:dataset][:to] == 0,
                          placement: 'below'

        dynamics = dynamics_to_string(element[:dataset][:to])

        if dynamics != context.last_dynamics
          if dynamics
            if element[:dataset][:to] < 0
              logger.warn { "dynamics #{element[:dataset][:to]} not renderizable" } if do_log
            elsif element[:dataset][:to] > 0
              measure.add_dynamics dynamics, placement: 'below'
            end
          end
        end

        context.last_dynamics = dynamics
      end

    when :dynamics
      dynamics = dynamics_to_string(element[:dataset][:from])

      if dynamics != context.last_dynamics


        if dynamics
          if element[:dataset][:from] < 0
            logger.warn { "dynamics #{element[:dataset][:to]} not renderizable" } if do_log
          elsif element[:dataset][:from] > 0
            measure.add_dynamics dynamics, placement: 'below'
          end
        end

        context.last_dynamics = dynamics
      end

    else
      # ignored
    end

    context
  end

end
