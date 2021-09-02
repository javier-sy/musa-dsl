require_relative '../../sequencer'
require_relative '../../series'

module Musa
  module Datasets
    class Score
      module Render
        def render(on:, &block)
          @score.keys.each do |score_at|
            effective_wait = score_at - 1r

            @score[score_at].each do |element|
              case element
              when Score
                on.wait effective_wait do
                  element.render(on: on, &block)
                end

              when Abs
                on.wait effective_wait do
                  block.call(element)
                end

              else
                raise ArgumentError, "Can't sequence #{element} because it's not an Abs dataset"
              end
            end
          end

          nil
        end
      end
    end
  end
end