require_relative '../../sequencer'
require_relative '../../series'

module Musa
  module Datasets
    class Score
      # Real-time rendering of scores on sequencers.
      #
      # Render provides the {#render} method for playing back scores on a
      # {Musa::Sequencer::Sequencer}. Events are scheduled at their score times
      # relative to the sequencer's current position.
      #
      # ## Time Calculation
      #
      # Score times are 1-based (first beat is 1), but sequencer waits are
      # 0-based. The conversion is:
      #
      #     effective_wait = score_time - 1
      #
      # So score time 1 becomes wait 0 (immediate), time 2 becomes wait 1, etc.
      #
      # ## Nested Scores
      #
      # Scores can contain other scores. When a nested score is encountered,
      # it's rendered recursively at the appropriate time.
      #
      # @example Basic rendering
      #   score = Musa::Datasets::Score.new
      #   score.at(1r, add: { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))
      #   score.at(2r, add: { pitch: 64, duration: 1.0 }.extend(Musa::Datasets::PDV))
      #
      #   seq = Musa::Sequencer::Sequencer.new(4, 24)
      #
      #   played = []
      #   score.render(on: seq) { |event| played << [seq.position, event[:pitch]] }
      #   seq.run
      #
      #   played  # => [[(95/96), 60], [(191/96), 64]]
      #
      #   # Score time 1 is the sequencer's starting position, one tick before
      #   # bar 1, because `render` schedules a wait of `score_time - 1` and a
      #   # wait of zero fires where the sequencer already is.
      #
      # @example Nested scores
      #   inner = Musa::Datasets::Score.new
      #   inner.at(1r, add: { pitch: 67 }.extend(Musa::Datasets::AbsD))
      #   inner.at(2r, add: { pitch: 69 }.extend(Musa::Datasets::AbsD))
      #
      #   outer = Musa::Datasets::Score.new
      #   outer.at(1r, add: { pitch: 60 }.extend(Musa::Datasets::AbsD))
      #   outer.at(2r, add: inner)  # Nested score
      #
      #   nested_seq = Musa::Sequencer::Sequencer.new(4, 24)
      #   nested = []
      #   outer.render(on: nested_seq) { |e| nested << [nested_seq.position, e[:pitch]] }
      #   nested_seq.run
      #
      #   nested  # => [[(95/96), 60], [(191/96), 67], [(287/96), 69]]
      #
      #   # The inner score's own time 1 lands at the outer's time 2, and its
      #   # time 2 at the outer's 3: a nested score's times are read from where
      #   # it was placed, not from bar 1.
      #
      # @see Musa::Sequencer::Sequencer Sequencer for playback
      # @see Score#at Adding events to scores
      module Render
        # Renders score on sequencer.
        #
        # Schedules all events in the score on the sequencer, calling the block
        # for each event at its scheduled time. Score times are converted to
        # sequencer wait times (score_time - 1).
        #
        # Supports nested scores recursively.
        #
        # @param on [Musa::Sequencer::Sequencer] sequencer to render on
        #
        # @yieldparam event [Abs] each event to process
        #   Block is called at the scheduled time with the event dataset
        #
        # @return [nil]
        #
        # @raise [ArgumentError] if element is not Abs or Score
        #
        # @example MIDI output
        #   require 'midi-communications'
        #
        #   score = Musa::Datasets::Score.new
        #   score.at(1r, add: { pitch: 60, duration: 1.0, velocity: 64 }.extend(Musa::Datasets::PDV))
        #
        #   midi_out = MIDICommunications::Output.gets
        #   sequencer = Musa::Sequencer::Sequencer.new(4, 24)
        #
        #   score.render(on: sequencer) do |event|
        #     if event[:pitch]
        #       midi_out.puts(0x90, event[:pitch], event[:velocity] || 64)
        #       sequencer.at event[:duration] do
        #         midi_out.puts(0x80, event[:pitch], event[:velocity] || 64)
        #       end
        #     end
        #   end
        #
        #   sequencer.run
        #
        # @example Console output
        #   score = Musa::Datasets::Score.new
        #   score.at(1r, add: { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))
        #
        #   seq = Musa::Sequencer::Sequencer.new(4, 24)
        #   score.render(on: seq) do |event|
        #     puts "Time #{seq.position}: #{event.inspect}"
        #   end
        #   seq.run
        #   # => "Time 95/96: {pitch: 60, duration: 1.0}"
        #
        # @example Nested score rendering
        #   inner = Musa::Datasets::Score.new
        #   inner.at(1r, add: { pitch: 67 }.extend(Musa::Datasets::PDV))
        #
        #   outer = Musa::Datasets::Score.new
        #   outer.at(1r, add: { pitch: 60 }.extend(Musa::Datasets::PDV))
        #   outer.at(2r, add: inner)
        #
        #   seq = Musa::Sequencer::Sequencer.new(4, 24)
        #   outer.render(on: seq) do |event|
        #     puts "Event: #{event[:pitch]}"
        #   end
        #   seq.run
        #   # Inner scores automatically rendered at their scheduled times
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
