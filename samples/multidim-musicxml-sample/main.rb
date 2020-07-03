require_relative '../../lib/musa-dsl'
require_relative 'tools'
require_relative 'score-builder'

require 'matrix'

include Musa::Sequencer
include Musa::Datasets
include Musa::Score

using Musa::Extension::Matrix

include MusicXML # TODO Cambiar a otro paquete

# [bar, pitch, intensity, instrument]
line = Matrix[ [0 * 4, 60, 50, 0],
               [10 * 4, 60, 50, 3],
               [15 * 4, 65, 70, 0],
               [20 * 4, 65, 80, 3],
               [25 * 4, 60, 70, -2],
               [30 * 4, 60, 50, 0] ]

scores = { -2 => nil, -1 => nil, 0 => nil, 1 => nil, 2 => nil, 3 => nil }.transform_values! { Score.new(0.25) }

Packed = Struct.new(:time, :pitch, :intensity, :instrument)

sequencer = Sequencer.new(4, 24) do |_|
  _.at 1 do |_|
    line.to_p(0).each do |p|
      _.play p.to_ps_serie do |thing|

        from = Packed.new(*thing[:from])
        to = Packed.new(*thing[:to])
        duration = thing[:duration]

        instruments = nil
        base_pitch = nil
        intensity = nil

        _.move from: from.intensity, to: to.intensity, duration: duration do |intensity_, next_intensity, duration:|
          intensity = intensity_
        end

        _.move from: from.instrument, to: to.instrument, duration: duration do |instrument, next_instrument|
          instruments = decode_instrument(instrument)
          next_instruments = decode_instrument(next_instrument) if next_instrument
          next_instruments ||= []

          if instruments.size == 1 && next_instruments.size == 2
            scores[(next_instruments.keys - instruments.keys).first]
                .at _.position,
                    add: { type: :crescendo, from: nil, to: nil, duration: duration }.extend(PS)

          elsif instruments.size == 2 && next_instruments.size == 1
            scores[(instruments.keys - next_instruments.keys).first]
                .at _.position,
                    add: { type: :diminuendo, from: nil, to: nil, duration: duration }.extend(PS)
          else
            # ignore intermediate steps
          end
        end

        _.move from: from.pitch, to: to.pitch, duration: duration, step: 1 do |pitch, next_pitch, duration:|
          base_pitch = pitch

          instruments.each_key do |instrument|
            scores[instrument].at _.position, add: { pitch: pitch, duration: duration }.extend(PDV)
          end
        end

      end
    end
  end
end

sequencer.run

translator = ScoresToMusicXML.new(author: 'Javier', title: 'mmmm', parts: { vln: 'violin 1', vln2: 'violin 2' })



mxml = renderer.render(vln: scores[-2],
                       vln2: scores[-1],
                       clo: scores[0])

scores.each_value do |score|
  puts
  puts "score"
  puts "-----"

  (1..score.finish).each do |bar|
    puts "bar #{bar}"
    puts "----------"

    ( score.between(bar, bar + 1).select { |p| p[:dataset].is_a?(PDV) } +
        score.events_between(bar, bar + 1).select { |p| p[:dataset].is_a?(PS) } )
      .sort_by { |i| i[:time] || i[:start] }
      .each do |i|

      puts "#{i}"
    end
  end
end

