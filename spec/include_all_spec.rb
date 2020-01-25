require 'spec_helper'

require 'musa-dsl'

include Musa::All

RSpec.describe Musa::All do
  context 'Modules' do
    it 'are included correctly' do
      s = S(1, 2, 3).i

      expect(s.next_value).to eq 1
    end
  end
end
