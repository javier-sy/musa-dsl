require_relative 'e'
require_relative 'score'

module Musa::Datasets
  module PS
    include AbsD

    include Helper

    NaturalKeys = (NaturalKeys + [:from, :to, :right_open]).freeze

    attr_accessor :base_duration

    def to_neuma
      # TODO ???????
    end

    def to_pdv
      # ??????
    end

    def to_gdv
      # ?????
    end

    def to_absI
      # ?????
    end

    def to_score(score: nil,
                 position: nil,
                 sequencer: nil,
                 beats_per_bar: nil, ticks_per_beat: nil,
                 right_open: nil,
                 &block)

      raise ArgumentError,
            "'beats_per_bar' and 'ticks_per_beat' parameters should be both nil or both have values" \
              unless beats_per_bar && ticks_per_beat || beats_per_bar.nil? && ticks_per_beat.nil?

      raise ArgumentError,
            "'sequencer' parameter should not be used when 'beats_per_bar' and 'ticks_per_beat' parameters are used" \
            if sequencer && beats_per_bar

      run_sequencer = sequencer.nil?

      binder = Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)

      score ||= Musa::Datasets::Score.new

      sequencer ||= Musa::Sequencer::Sequencer.new(beats_per_bar, ticks_per_beat)

      ticks_per_bar = sequencer.ticks_per_bar

      sequencer.at(position || 1r) do |_|
        _.move from: self[:from],
               to: self[:to],
               right_open: right_open,
               duration: _quantize(self[:duration], ticks_per_bar),
               step: 1 do
          | _,
            value, next_value,
            duration:,
            quantized_duration:,
            position_jitter:, duration_jitter:,
            started_ago:|

          # TODO remove s parameter; only for testing
          #
          binder.call value, next_value,
                      position: _.position,
                      duration: duration,
                      quantized_duration: quantized_duration,
                      position_jitter: position_jitter,
                      duration_jitter: duration_jitter,
                      started_ago: started_ago,
                      s: _
        end
      end

      if run_sequencer
        sequencer.run
        score
      else
        nil
      end
    end

    private

    def _quantize(duration, ticks_per_bar)
      if ticks_per_bar &.< Float::INFINITY
        ((duration.rationalize * ticks_per_bar).round / ticks_per_bar).to_r
      else
        duration.rationalize
      end
    end


  end
end
