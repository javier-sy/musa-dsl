require_relative 'dataset'

module Musa::Datasets
  module E
    include Dataset

    NaturalKeys = [].freeze
  end

  module Abs
    include E
  end

  module Delta
    include E
  end

  module AbsI
    include Abs
  end

  module DeltaI
    include Delta
  end
end