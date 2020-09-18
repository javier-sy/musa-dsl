require_relative '../../sequencer'
require_relative '../../series'

module Musa::Datasets; class Score
  module Play
    def play(on: nil, beats_per_bar: nil, ticks_per_beat: nil, at: nil, relative: nil, &block)
      on ||= Musa::Sequencer::Sequencer.new beats_per_bar, ticks_per_beat

      relative ||= at.nil?

      at_values = case at
                  when nil
                    relative ? [0] : [1]
                  when Numeric
                    [at]
                  when Serie
                    at.to_a
                  end

      at_values.each do |at_value|
        effective_start_at = if relative
                               on.position + at_value
                             else
                               at_value
                             end

        @score.keys.each do |score_at|
          effective_at = effective_start_at + score_at - 1r

          @score[score_at].each do |element|
            case element
            when Score
              on.at effective_at do
                element.play(on: on, &block)
              end

            when Abs
              on.at effective_at do
                block.call(element)
              end

            else
              raise ArgumentError, "Can't sequence #{element} because it's not an Abs dataset"
            end
          end
        end
      end

      on
    end
  end
end; end