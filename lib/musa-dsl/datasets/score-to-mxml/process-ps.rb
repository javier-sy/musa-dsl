module Musa::Datasets::Score::ToMXML
  private


  DynamicsContext = Struct.new(:last_dynamics)
  private_constant :DynamicsContext

  def process_ps(measure, element, context = nil)
    context ||= DynamicsContext.new

    case element[:dataset][:type]
    when :crescendo, :diminuendo
      if element[:change] == :start
        dynamics = midi_velocity_to_dynamics(element[:dataset][:from])

        if dynamics != context.last_dynamics
          measure.add_dynamics dynamics, placement: 'below' if dynamics && element[:dataset][:from] > 0
          context.last_dynamics = dynamics
        end

        #if element[:dataset][:from] && element[:dataset][:to]
          measure.add_wedge element[:dataset][:type],
                            niente: element[:dataset][:type] == :crescendo && element[:dataset][:from] == 0,
                            placement: 'below'
        #end
      else
        #if element[:dataset][:from] && element[:dataset][:to]
          measure.add_wedge 'stop',
                            niente: element[:dataset][:type] == :diminuendo && element[:dataset][:to] == 0,
                            placement: 'below'
        #end

        dynamics = midi_velocity_to_dynamics(element[:dataset][:to])

        measure.add_dynamics dynamics, placement: 'below' if dynamics && element[:dataset][:to] > 0
        context.last_dynamics = dynamics
      end

    when :dynamics
      if dynamics != context.last_dynamics
        measure.add_dynamics midi_velocity_to_dynamics(element[:dataset][:from]), placement: 'below'
        context.last_dynamics = dynamics
      end

    else
      # ignored
    end

    context
  end

end
