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

    it 'Prototype PROXY don\'t allow changing the source' do
      s = PROXY(S(1, 2, 3))

      expect {
        s.source = S(3, 4, 5)
      }.to raise_error(ArgumentError)
    end

    it 'Instance PROXY don\'t allow changing the source to Prototype serie' do
      s = PROXY(S(1, 2, 3)).i

      expect {
        s.source = S(3, 4, 5)
      }.to raise_error(ArgumentError)
    end
  end
end
