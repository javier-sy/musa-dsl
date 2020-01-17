require 'spec_helper'

require 'musa-dsl'

include Musa::Series

RSpec.describe Musa::Series do
  context 'Series proxy' do
    it 'Basic PROXY series substitution' do
      s = PROXY(S(1, 2, 3))

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
      s = PROXY(S(1, 2, 3))

      expect(s.next_value).to eq 1
      expect(s.current_value).to eq 1

      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil

      s.restart

      expect(s.next_value).to eq 1

      s.target = S(4, 5, 6)

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
      s = PROXY()

      expect(s.current_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.current_value).to eq nil
    end

    it 'Basic PROXY delegation' do
      s = PROXY(S(1, 2, 3))

      expect(s.next_value).to eq 1
      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3

      expect(s.values).to eq [1, 2, 3]
    end
  end
end
