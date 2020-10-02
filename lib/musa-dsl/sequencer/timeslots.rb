require 'set'

module Musa
  module Sequencer
    class BaseSequencer
      class Timeslots < Hash

        def initialize(*several_variants)
          super
          @sorted_keys = SortedSet.new
        end

        def []=(key, value)
          super
          @sorted_keys << key
        end

        def delete(key)
          super
          @sorted_keys.delete key

        end

        def first_after(position)
          if position.nil?
            @sorted_keys.first
          else
            @sorted_keys.find { |k| k >= position }
          end
        end
      end
    end
  end
end
