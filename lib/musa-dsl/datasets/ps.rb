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

    def to_score(score: nil, position: nil)

      score ||= Musa::Datasets::Score.new
      position ||= 1r



      score
    end
  end
end
