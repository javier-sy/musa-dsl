require 'spec_helper'

require 'musa-dsl'

include Musa::Series

RSpec.describe Musa::Serie do
  context 'Series prototype and instance:' do
    it 'basic prototype and instance definition' do
      p = S(1, 2, 3)
      expect(p.prototype?).to be false

      pp = p.p

      expect(pp).to be p
      expect(p.prototype?).to be true

      a = p.i
      b = p.i

      expect(a.prototype?).to be false
      expect(b.prototype?).to be false

      expect(a).to_not be b
    end

    it 'basic prototype and instance validation' do
      p = S(1, 2, 3)

      expect(p.restart).to be p

      pp = p.p

      expect { pp.restart }.to raise_error(Musa::Serie::PrototypeSerieError)
      expect { pp.next_value }.to raise_error(Musa::Serie::PrototypeSerieError)
      expect { pp.peek_next_value }.to raise_error(Musa::Serie::PrototypeSerieError)
      expect { pp.current_value }.to raise_error(Musa::Serie::PrototypeSerieError)

      expect { pp.infinite? }.to_not raise_error

      i = pp.i

      expect { i.restart }.to_not raise_error
      expect { i.next_value }.to_not raise_error
      expect { i.peek_next_value }.to_not raise_error
      expect { i.current_value }.to_not raise_error
    end
  end
end
