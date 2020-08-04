module Musa::Datasets::Score::ToMXML
  private


  DynamicsContext = Struct.new(:last_dynamics)
  private_constant :DynamicsContext

  def process_ps(measure, element, context = nil)
    context ||= DynamicsContext.new

    case element[:dataset][:type]
    when :crescendo, :diminuendo
      if element[:change] == :start
        dynamics = dynamics_to_string(element[:dataset][:from])

        if dynamics != context.last_dynamics
          measure.add_dynamics dynamics, placement: 'below' if dynamics && element[:dataset][:from] > 0
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

        measure.add_dynamics dynamics, placement: 'below' if dynamics && element[:dataset][:to] > 0
        context.last_dynamics = dynamics
      end

    when :dynamics
      dynamics = dynamics_to_string(element[:dataset][:from])

      if dynamics != context.last_dynamics
        measure.add_dynamics dynamics, placement: 'below'
        context.last_dynamics = dynamics
      end

    else
      # ignored
    end

    context
  end

end
