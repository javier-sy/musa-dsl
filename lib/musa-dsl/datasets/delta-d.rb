require_relative 'e'

module Musa::Datasets
  module DeltaD
    include Delta

    NaturalKeys = [:abs_duration, # absolute duration
                   :delta_duration, # incremental duration
                   :factor_duration # multiplicative factor duration
    ].freeze
  end
end