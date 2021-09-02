require 'spec_helper'
require 'musa-dsl'

RSpec.describe Musa::All do
  context 'Modules' do
    it 'are included correctly' do
      class ToTest
        include Musa::All
        def test
          s = S(1, 2, 3).i
          s.next_value == 1
        end
      end

      expect(ToTest.new.test).to be true
    end
  end
end
