require_relative 'dataset'
require_relative 'ps'

require_relative '../sequencer'

module Musa::Datasets
  module P
    include Dataset

    def to_ps_serie(base_duration = nil)
      base_duration ||= 1/4r

      p = clone

      Musa::Series::E() do
        (p.size >= 3) ?
          { from: p.shift,
            duration: p.shift * base_duration,
            to: p.first,
            right_open: (p.length > 1) }.extend(PS).tap { |_| _.base_duration = base_duration } : nil
      end
    end

    def to_score(score: nil,
                 mapper: nil,
                 position: nil,
                 sequencer: nil,
                 beats_per_bar: nil, ticks_per_beat: nil,
                 right_open: nil,
                 do_log: nil,
                 &block)

      raise ArgumentError,
            "'beats_per_bar' and 'ticks_per_beat' parameters should be both nil or both have values" \
              unless beats_per_bar && ticks_per_beat || beats_per_bar.nil? && ticks_per_beat.nil?

      raise ArgumentError,
            "'sequencer' parameter should not be used when 'beats_per_bar' and 'ticks_per_beat' parameters are used" \
            if sequencer && beats_per_bar

      run_sequencer = sequencer.nil?

      score ||= Musa::Datasets::Score.new

      sequencer ||= Sequencer.new(beats_per_bar, ticks_per_beat, do_log: do_log)

      sequencer.at(position || 1r) do |_|

          _.play to_ps_serie do |_, line|

            line.to_score(sequencer: _,
                          score: score,
                          mapper: mapper,
                          position: _.position,
                          right_open: right_open,
                          &block)
        end
      end

      if run_sequencer
        sequencer.run
        score
      else
        nil
      end
    end
  end
end