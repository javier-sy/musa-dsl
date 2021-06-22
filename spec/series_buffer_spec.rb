require 'spec_helper'

require 'musa-dsl'

include Musa::Series

RSpec.describe Musa::Series do
  context 'Series synced buffer' do

    it 'buffered series get all source values waiting values of the main serie' do
      buffer = S(1, 2, 3, 4, 5, 6, 7).buffered(sync: true)

      i1 = buffer.instance

      expect(i1.next_value).to eq 1
      expect(i1.next_value).to eq 2
      expect(i1.next_value).to eq 3

      i2 = i1.buffer.instance

      expect(i2.next_value).to eq 1
      expect(i2.next_value).to eq 2
      expect(i2.next_value).to eq 3

      expect(i1.next_value).to eq 4

      i3 = i1.buffer.instance

      expect(i2.next_value).to eq 4
      expect(i2.next_value).to eq 4
      expect(i2.next_value).to eq 4

      expect(i3.next_value).to eq 1
      expect(i3.next_value).to eq 2
      expect(i3.next_value).to eq 3
      expect(i3.next_value).to eq 4
      expect(i3.next_value).to eq 4

      expect(i1.next_value).to eq 5
      expect(i1.next_value).to eq 6
      expect(i1.next_value).to eq 7

      expect(i2.next_value).to eq 5
      expect(i2.next_value).to eq 6
      expect(i2.next_value).to eq 7
      expect(i2.next_value).to eq 7

      expect(i3.next_value).to eq 5
      expect(i3.next_value).to eq 6
      expect(i3.next_value).to eq 7
      expect(i3.next_value).to eq 7

      expect(i1.next_value).to be_nil
      expect(i2.next_value).to be_nil
      expect(i3.next_value).to be_nil
    end

    it 'secondary serie waits for values on primary serie' do
      buffer = S(1, 2, 3, 4, 5, 6, 7).buffered(sync: true)

      i1 = buffer.instance
      i2 = i1.buffer.instance

      expect(i2.next_value).to be_nil
      expect(i2.next_value).to be_nil

      expect(i1.next_value).to eq 1

      expect(i2.next_value).to eq 1
      expect(i2.next_value).to eq 1
    end

    it 'restarting a buffered serie reruns the history of values' do
      buffer = S(1, 2, 3, 4, 5, 6, 7).buffered(sync: true)

      i1 = buffer.instance

      i2 = i1.buffer.instance

      while i1.next_value; end
      while i2.next_value; end

      i2.restart

      expect(i2.next_value).to eq 1
      expect(i2.next_value).to eq 2
      expect(i2.next_value).to eq 3
      expect(i2.next_value).to eq 4
      expect(i2.next_value).to eq 5
      expect(i2.next_value).to eq 6
      expect(i2.next_value).to eq 7

      expect(i2.next_value).to be_nil
      expect(i2.next_value).to be_nil
    end

    it 'restarting the main serie when is finished and restarting the buffered serie' do
      buffer = S(1, 2, 3, 4, 5, 6, 7).buffered(sync: true)

      i1 = buffer.instance

      i2 = i1.buffer.instance

      while i1.next_value; end
      while i2.next_value; end

      i1.restart

      expect(i1.next_value).to eq 1

      expect(i2.next_value).to be_nil

      i2.restart

      expect(i2.next_value).to eq 1
      expect(i2.next_value).to eq 1

      expect(i1.next_value).to eq 2
      expect(i1.next_value).to eq 3

      expect(i2.next_value).to eq 2
      expect(i2.next_value).to eq 3
      expect(i2.next_value).to eq 3

      while i1.next_value; end

      i1.restart

      expect(i2.next_value).to eq 4
      expect(i2.next_value).to eq 5
      expect(i2.next_value).to eq 6
      expect(i2.next_value).to eq 7

      expect(i2.next_value).to be_nil
      expect(i2.next_value).to be_nil
    end

    it 'restarting the main serie in the middle' do
      buffer = S(1, 2, 3, 4, 5, 6, 7).buffered(sync: true)

      i1 = buffer.instance

      i2 = i1.buffer.instance

      expect(i1.next_value).to eq 1
      expect(i1.next_value).to eq 2
      expect(i1.next_value).to eq 3

      expect(i2.next_value).to eq 1
      expect(i2.next_value).to eq 2

      i1.restart

      expect(i2.next_value).to eq 3
      expect(i2.next_value).to eq 3

      expect(i1.next_value).to eq 1

      expect(i2.next_value).to eq 1
      expect(i2.next_value).to eq 1

      expect(i1.next_value).to eq 2

      expect(i2.next_value).to eq 2
      expect(i2.next_value).to eq 2

      i2.restart

      expect(i2.next_value).to eq 1

      expect(i1.next_value).to eq 3

      expect(i2.next_value).to eq 2
      expect(i2.next_value).to eq 3

      expect(i2.next_value).to eq 1
      expect(i2.next_value).to eq 2

      expect(i2.next_value).to eq 3
      expect(i2.next_value).to eq 3

      while i1.next_value; end

      expect(i2.next_value).to eq 4
      expect(i2.next_value).to eq 5
      expect(i2.next_value).to eq 6
      expect(i2.next_value).to eq 7

      expect(i2.next_value).to be_nil
      expect(i2.next_value).to be_nil
    end

  end

  context 'Series parallel buffer' do

    it 'get next values from a original source' do
      buffer = S(1, 2, 3, 4, 5, 6, 7).buffered(sync: false).instance

      i1 = buffer.buffer #.instance

      expect(i1.next_value).to eq 1
      expect(i1.next_value).to eq 2
      expect(i1.next_value).to eq 3

      i2 = buffer.buffer #.instance

      expect(i2.next_value).to eq 1
      expect(i2.next_value).to eq 2
      expect(i2.next_value).to eq 3

      expect(i1.next_value).to eq 4

      expect(i2.next_value).to eq 4

      expect(i1.next_value).to eq 5
      expect(i1.next_value).to eq 6
      expect(i1.next_value).to eq 7

      expect(i2.next_value).to eq 5
      expect(i2.next_value).to eq 6
      expect(i2.next_value).to eq 7

      expect(i1.next_value).to be_nil
      expect(i2.next_value).to be_nil

      expect(i1.next_value).to be_nil
      expect(i1.next_value).to be_nil
    end

    it 'restarting one serie allows the other series to get the full source values' do
      buffer = S(1, 2, 3, 4, 5, 6, 7).buffered(sync: false).instance

      i1 = buffer.buffer #.instance

      expect(i1.next_value).to eq 1
      expect(i1.next_value).to eq 2
      expect(i1.next_value).to eq 3

      i2 = buffer.buffer #.instance

      expect(i2.next_value).to eq 1
      expect(i2.next_value).to eq 2
      expect(i2.next_value).to eq 3

      i2.restart

      expect(i2.next_value).to eq 1
      expect(i2.next_value).to eq 2
      expect(i2.next_value).to eq 3

      expect(i1.next_value).to eq 4

      expect(i2.next_value).to eq 4

      expect(i1.next_value).to eq 5
      expect(i1.next_value).to eq 6
      expect(i1.next_value).to eq 7

      expect(i2.next_value).to eq 5
      expect(i2.next_value).to eq 6
      expect(i2.next_value).to eq 7

      expect(i1.next_value).to be_nil
      expect(i2.next_value).to be_nil

      expect(i1.next_value).to be_nil
      expect(i1.next_value).to be_nil
    end

    it 'restarting one serie more than once' do
      buffer = S(1, 2, 3, 4, 5, 6, 7).buffered.instance

      i1 = buffer.buffer #.instance

      expect(i1.next_value).to eq 1
      expect(i1.next_value).to eq 2
      expect(i1.next_value).to eq 3

      i2 = buffer.buffer #.instance

      expect(i2.next_value).to eq 1
      expect(i2.next_value).to eq 2
      expect(i2.next_value).to eq 3

      i2.restart
      i2.restart
      i2.restart

      expect(i2.next_value).to eq 1
      expect(i2.next_value).to eq 2
      expect(i2.next_value).to eq 3

      expect(i1.next_value).to eq 4

      expect(i2.next_value).to eq 4

      expect(i1.next_value).to eq 5
      expect(i1.next_value).to eq 6
      expect(i1.next_value).to eq 7

      expect(i2.next_value).to eq 5
      expect(i2.next_value).to eq 6
      expect(i2.next_value).to eq 7

      expect(i1.next_value).to be_nil
      expect(i2.next_value).to be_nil

      expect(i1.next_value).to be_nil
      expect(i1.next_value).to be_nil
    end

  end
end
