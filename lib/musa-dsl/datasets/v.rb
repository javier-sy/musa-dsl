require_relative 'dataset'
require_relative 'packed-v'

module Musa::Datasets
  module V
    include AbsI

    def to_packed_V(mapper)
      case mapper
      when Hash
        pv = {}.extend(PackedV)
        each_index { |i| pv[mapper.keys[i]] = self[i] unless self[i] == mapper.values[i] }
        pv
      when Array
        pv = {}.extend(PackedV)
        each_index { |i| pv[mapper[i]] = self[i] if mapper[i] && self[i] }
        pv
      else
        raise ArgumentError, "Expected Hash or Array as mapper but got a #{mapper.class.name}"
      end
    end
  end
end
