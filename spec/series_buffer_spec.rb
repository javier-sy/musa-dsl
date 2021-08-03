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
      buffer = S(1, 2, 3, 4, 5, 6, 7).buffered.instance

      i1 = buffer.buffer.instance

      expect(i1.next_value).to eq 1
      expect(i1.next_value).to eq 2
      expect(i1.next_value).to eq 3

      i2 = buffer.buffer.instance

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
      buffer = S(1, 2, 3, 4, 5, 6, 7).buffered.instance

      i1 = buffer.buffer.instance

      expect(i1.next_value).to eq 1
      expect(i1.next_value).to eq 2
      expect(i1.next_value).to eq 3

      i2 = buffer.buffer.instance

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

    it 'bugfix: restarting a joined buffer generates a stack overflow' do
      buffered = S(1, 2, 3).buffered

      i1 = buffered.buffer
      i2 = buffered.buffer

      h = H(a: i1, b: i2)
      s = h.instance

      s.restart

      expect(s.next_value).to eq({ a: 1, b: 1 })
      expect(s.next_value).to eq({ a: 2, b: 2 })
      expect(s.next_value).to eq({ a: 3, b: 3 })

      expect(s.next_value).to be_nil
      expect(s.next_value).to be_nil
    end

    it 'bugfix: restarting a buffered joined series of a split serie generates a stack overflow' do
      s = S([1, 10], [2, 20], [3, 30])
      ss = s.split.instance

      s2 = A(*ss).buffered
      s2i = s2.buffer.instance

      s2i.restart

      expect(s2i.next_value).to eq [1, 10]
      expect(s2i.next_value).to eq [2, 20]
      expect(s2i.next_value).to eq [3, 30]

      expect(s2i.next_value).to be_nil
    end

    it 'A NIL() prototype buffered series returns nil' do
      s = NIL().buffered
      ss = s.buffer.instance

      expect(ss.next_value).to be_nil
    end

    it 'A NIL() instance buffered series returns nil' do
      s = NIL().instance.buffered
      ss = s.buffer

      expect(ss.next_value).to be_nil
    end

    it 'buffered sourced to undefined proxy handles .instance when the proxy source is assigned to a prototype serie' do
      p = PROXY()
      b = p.buffered
      bb = b.buffer

      p.proxy_source = S(1, 2, 3)

      i = bb.instance

      expect(i.next_value).to eq 1
      expect(i.next_value).to eq 2
      expect(i.next_value).to eq 3
      expect(i.next_value).to be_nil
    end

    it 'buffered sourced to undefined proxy resolves to instance when the proxy source is assigned to an instance serie' do
      p = PROXY()
      s = p.buffered.buffer

      p.proxy_source = S(1, 2, 3).instance

      expect(s.prototype?).to be false
      expect(s.instance?).to be true
      expect(s.undefined?).to be false

      expect(s.next_value).to eq 1
      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3
      expect(s.next_value).to be_nil
    end

    it 'buffered sourced to undefined proxy handles .instance when the proxy source is assigned to an instance serie' do
      p = PROXY()
      s = p.buffered.buffer

      expect(s.prototype?).to be_falsey
      expect(s.instance?).to be_falsey
      expect(s.undefined?).to be_truthy
    end

  end
end
