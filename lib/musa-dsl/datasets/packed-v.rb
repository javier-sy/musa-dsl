require_relative 'e'
require_relative 'v'

module Musa::Datasets
  module PackedV
    include AbsI

    def to_V(mapper)
      case mapper
      when Hash
        mapper.collect { |key, default| self[key] || default }.extend(V)
      when Array
        mapper.collect { |key| self[key] }.extend(V)
      else
        raise ArgumentError, "Expected Hash or Array as mapper but got a #{mapper.class.name}"
      end
    end
  end
end
