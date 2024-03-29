require 'spec_helper'

require 'musa-dsl'

RSpec.describe Musa::Series do
  context 'Series prototype and instance:' do
    include Musa::Series
    include Musa::Datasets

    it 'An operation over an undefined serie is another undefined serie' do
      p = PROXY()
      s = p.reverse

      expect(s.prototype?).to be false
      expect(s.instance?).to be false
      expect(s.undefined?).to be true

      expect { s.next_value }.to raise_error(Musa::Series::Serie::Prototyping::PrototypingError)
    end

    it 'basic prototype and instance definition' do
      p = S(1, 2, 3)
      expect(p.prototype?).to be true
      expect(p.instance?).to be false

      pp = p.p

      expect(pp).to be p
      expect(pp.prototype?).to be true
      expect(pp.instance?).to be false

      a = p.i
      b = p.i

      expect(a.prototype?).to be false
      expect(a.instance?).to be true

      expect(b.prototype?).to be false
      expect(b.instance?).to be true

      expect(a).to_not be b
    end

    it 'basic prototype and instance validation' do
      pp = S(1, 2, 3)

      expect { pp.restart }.to raise_error(Musa::Series::Serie::Prototyping::PrototypingError)
      expect { pp.next_value }.to raise_error(Musa::Series::Serie::Prototyping::PrototypingError)
      expect { pp.peek_next_value }.to raise_error(Musa::Series::Serie::Prototyping::PrototypingError)
      expect { pp.current_value }.to raise_error(Musa::Series::Serie::Prototyping::PrototypingError)

      expect { pp.infinite? }.to_not raise_error

      p = pp.i

      expect(p.restart).to be p

      i = pp.i

      expect { i.restart }.to_not raise_error
      expect { i.next_value }.to_not raise_error
      expect { i.peek_next_value }.to_not raise_error
      expect { i.current_value }.to_not raise_error
    end
  end
end
