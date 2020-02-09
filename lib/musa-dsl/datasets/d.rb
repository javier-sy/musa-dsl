require_relative 'dataset'

module Musa::Datasets
  module D
    include Dataset

    NaturalKeys = [:duration].freeze
  end
end