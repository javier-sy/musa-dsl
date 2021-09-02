require 'spec_helper'

require 'musa-dsl'

include Musa::Series

RSpec.describe Musa::Series do
  context 'Series proxy' do
    include Musa::Series
    include Musa::Datasets

    it 'Basic PROXY series substitution' do
      s = PROXY(S(1, 2, 3)).i

      expect(s.next_value).to eq 1
      expect(s.current_value).to eq 1

      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil

      s.restart

      expect(s.next_value).to eq 1
      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
    end

    it 'Basic PROXY changing source' do
      s = PROXY(S(1, 2, 3)).i

      expect(s.next_value).to eq 1
      expect(s.current_value).to eq 1

      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil

      s.restart

      expect(s.next_value).to eq 1

      s.proxy_source = S(4, 5, 6).i

      expect(s.next_value).to eq 4
      expect(s.next_value).to eq 5
      expect(s.next_value).to eq 6

      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil

      s.restart

      expect(s.next_value).to eq 4
      expect(s.next_value).to eq 5
      expect(s.next_value).to eq 6
    end

    it 'Getting a PROXY instance without source raises error' do
      expect { PROXY().i }.to raise_error(Serie::Prototyping::PrototypingError)
    end

    it 'Basic PROXY delegation' do
      s = PROXY(S(1, 2, 3)).i

      expect(s.next_value).to eq 1
      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3

      expect(s.values).to eq [1, 2, 3]
    end

    it 'PROXY without source is not a prototype nor an instance' do
      s = PROXY()

      expect(s.undefined?).to be true

      expect(s.defined?).to be false

      expect(s.prototype?).to be false
      expect(s.instance?).to be false

      expect { s.restart }.to raise_error(Serie::Prototyping::PrototypingError)
      expect { s.next_value }.to raise_error(Serie::Prototyping::PrototypingError)
      expect { s.infinite? }.to raise_error(Serie::Prototyping::PrototypingError)
    end

    it 'PROXY without source allows to assign a prototype source' do
      s = PROXY()
      s.proxy_source = S(1, 2, 3)

      expect(s.instance?).to be(false)
      expect(s.prototype?).to be(true)
    end

    it 'PROXY without source allows to assign an instance source' do
      s = PROXY()

      s.proxy_source = S(1, 2, 3).instance

      expect(s.instance?).to be(true)
      expect(s.prototype?).to be(false)
    end

    it 'Prototype PROXY allows changing the source to a Prototype serie' do
      s = PROXY(S(1, 2, 3))

      expect {
        s.proxy_source = S(3, 4, 5)
      }.to_not raise_error
    end

    it 'Instance PROXY don\'t allow changing the source to Instance serie' do
      s = PROXY(S(1, 2, 3)).i

      expect {
        s.proxy_source = S(3, 4, 5)
      }.to raise_error(ArgumentError)
    end

    it 'Prototype PROXY allows to set a prototype source and get the instance correctly' do
      p = PROXY()

      p.proxy_source = S(1, 2, 3)

      s = p.instance

      expect(s.next_value).to eq 1
      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3

      expect(s.next_value).to be_nil

      s.restart

      expect(s.next_value).to eq 1
      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3

      expect(s.next_value).to be_nil
    end
  end
end
