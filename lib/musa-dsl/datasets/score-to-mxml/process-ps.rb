module Musa::Datasets::Score::ToMXML
  private

  def process_ps(measure, divisions_per_bar, element)
    puts "process_ps: element = #{element}"
    case element[:dataset][:type]
    when :crescendo, :diminuendo
      if element[:change] == :start
        measure.add_dynamics midi_velocity_to_dynamics(element[:dataset][:from]),
                             placement: 'below' \
                unless element[:dataset][:from].nil? || element[:dataset][:from] == 0

        if element[:dataset][:from] && element[:dataset][:to] && element[:dataset][:from] != element[:dataset][:to]
          measure.add_wedge element[:dataset][:type],
                          niente: element[:dataset][:type] == :crescendo && element[:dataset][:from] == 0,
                          offset: divisions_per_bar / 4,
                          placement: 'below'
        end
      else
        if element[:dataset][:from] && element[:dataset][:to] && element[:dataset][:from] != element[:dataset][:to]
          measure.add_wedge 'stop',
                            niente: element[:dataset][:type] == :diminuendo && element[:dataset][:to] == 0,
                            offset: -divisions_per_bar / 4,
                            placement: 'below'
        end

        measure.add_dynamics midi_velocity_to_dynamics(element[:dataset][:to]),
                             placement: 'below' \
                unless element[:dataset][:to].nil? || element[:dataset][:to] == 0
      end

      # TODO añadir dinámicas a nivel de nota
    else
      # ignored
    end
  end
end
