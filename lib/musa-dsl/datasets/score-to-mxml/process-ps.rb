module Musa::Datasets::Score::ToMXML
  private

  def process_ps(measure, divisions_per_bar, element)
    case element[:dataset][:type]
    when :crescendo, :diminuendo
      if element[:change] == :start
        measure.add_dynamics midi_velocity_to_dynamics(element[:dataset][:from]) \
                unless element[:dataset][:from].nil? || element[:dataset][:from] == 0

        measure.add_wedge element[:dataset][:type],
                          niente: element[:dataset][:type] == :crescendo && element[:dataset][:from] == 0 ||
                              element[:dataset][:type] == :diminuendo && element[:dataset][:to] == 0
      else
        measure.add_wedge 'stop', offset: -divisions_per_bar / 4

        measure.add_dynamics midi_velocity_to_dynamics(element[:dataset][:to]) \
                unless element[:dataset][:to].nil? || element[:dataset][:to] == 0
      end

      # TODO añadir dinámicas a nivel de nota
    else
      # ignored
    end
  end
end
