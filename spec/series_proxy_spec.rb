require 'spec_helper'

require 'musa-dsl'

include Musa::Series

RSpec.describe Musa::Series do
  context 'Series proxy' do
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

      s.source = S(4, 5, 6).i

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

    it 'Basic PROXY without source' do
      s = PROXY().i

      expect(s.current_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.current_value).to eq nil
    end

    it 'Basic PROXY delegation' do
      s = PROXY(S(1, 2, 3)).i

      expect(s.next_value).to eq 1
      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3

      expect(s.values).to eq [1, 2, 3]
    end

    it 'Prototype PROXY allows changing the source to a Prototype serie' do
      s = PROXY(S(1, 2, 3))

      expect {
        s.source = S(3, 4, 5)
      }.to_not raise_error(ArgumentError)
    end

    it 'Instance PROXY don\'t allow changing the source to Instance serie' do
      s = PROXY(S(1, 2, 3)).i

      expect {
        s.source = S(3, 4, 5)
      }.to raise_error(ArgumentError)
    end

    it 'Prototype PROXY allows to set a prototype source and get the instance correctly' do
      p = PROXY()

      p.source = S(1, 2, 3)

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
