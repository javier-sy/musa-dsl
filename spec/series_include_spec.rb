require 'spec_helper'
require 'musa-dsl'

RSpec.describe Musa::Series do
  context 'include Musa::Series failures:' do
    it 'include Musa::Series inside class definition' do
      class IncludeTest
        include Musa::Series

        def test
          s1 = Musa::Series::Constructors::S({ time: 0, value: 1, extra1: 10 },
                                             { time: 1, value: 2, extra1: 20 },
                                             { time: 2, value: 3, extra1: 30 } )

          u = Musa::Series::Constructors::TIMED_UNION(s1).i
          v = u.next_value

        end
      end

      expect { IncludeTest.new.test }.to_not raise_exception
    end
  end
end
