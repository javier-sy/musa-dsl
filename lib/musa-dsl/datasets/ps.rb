require_relative 'e'
require_relative 'score'

require_relative '../sequencer'

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
      # TODO ??????
    end

    def to_gdv
      # TODO ?????
    end

    def to_absI
      # TODO ?????
    end

    def valid?
      case self[:from]
      when Array
        self[:to].is_a?(Array) &&
            self[:from].size == self[:to].size
      when Hash
        self[:to].is_a?(Hash) &&
            self[:from].keys == self[:to].keys
      else
        false
      end && self[:duration].is_a?(Numeric) && self[:duration] > 0
    end
  end
end
