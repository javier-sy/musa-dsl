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

  context 'Cyclic PROXY series' do
    include Musa::Series

    def cycle_of(material)
      back = PROXY(cyclic: true)
      cycle = material.after(back)
      back.proxy_source = cycle
      cycle
    end

    it 'a proxy that closes a cycle has to be declared cyclic' do
      back = PROXY()

      expect { back.proxy_source = S(1, 2, 3).after(back) }.to raise_error ArgumentError
    end

    it 'a proxy can be declared cyclic and never close a cycle' do
      proxy = PROXY(cyclic: true)
      proxy.proxy_source = S(1, 2, 3)

      expect(proxy.closes_cycle?).to be false
      expect(proxy.infinite?).to be false
      expect(proxy.i.to_a).to eq [1, 2, 3]
    end

    it 'a cycle repeats its material' do
      i = cycle_of(S(1, 2, 3)).i

      expect(9.times.collect { i.next_value }).to eq [1, 2, 3, 1, 2, 3, 1, 2, 3]
    end

    it 'a cycle is infinite, and says so without walking round itself' do
      expect(cycle_of(S(1, 2, 3)).infinite?).to be true
    end

    it 'the state of a cycle is the state of what feeds it from outside' do
      cycle = cycle_of(S(1, 2, 3))

      expect(cycle.state).to eq :prototype
    end

    it 'a cycle whose turn comes back empty ends instead of spinning' do
      n = 0
      i = cycle_of(E(nil) { n += 1; n <= 3 ? n : nil }).i

      expect(6.times.collect { i.next_value }).to eq [1, 2, 3, nil, nil, nil]
    end

    it 'a cycle over an empty serie produces nothing' do
      i = cycle_of(S()).i

      expect(4.times.collect { i.next_value }).to eq [nil, nil, nil, nil]
    end

    it 'two materials can call each other' do
      to_b = PROXY(cyclic: true)
      to_a = PROXY(cyclic: true)

      a = S(1, 2).after(to_b)
      b = S(3, 4).after(to_a)

      to_b.proxy_source = b
      to_a.proxy_source = a

      i = a.i

      expect(8.times.collect { i.next_value }).to eq [1, 2, 3, 4, 1, 2, 3, 4]
    end

    it 'a proxy that only becomes cyclic through another assignment is detected too' do
      to_head = PROXY(cyclic: true)
      refrain = PROXY()

      head = S(:a).after(refrain)
      chorus = S(:r).after(to_head)

      refrain.proxy_source = chorus     # no cycle yet: to_head has no source
      to_head.proxy_source = head       # now there is one, and it runs through refrain

      expect { head.i.next_value }.to raise_error ArgumentError
    end

    it 'a material reached from two places returns to each of them' do
      to_head = PROXY(cyclic: true)
      refrain = PROXY(cyclic: true)

      head = S(:a).after(refrain)
      chorus = S(:r).after(to_head)

      refrain.proxy_source = chorus
      to_head.proxy_source = head

      i = head.i

      expect(6.times.collect { i.next_value }).to eq [:a, :r, :a, :r, :a, :r]
    end

    it 'material queued while the cycle is already sounding joins the next turn' do
      queue = QUEUE(S(1, 2).i)
      i = cycle_of(queue).i

      expect(5.times.collect { i.next_value }).to eq [1, 2, 1, 2, 1]

      queue << S(:more).i

      expect(6.times.collect { i.next_value }).to eq [2, :more, 1, 2, :more, 1]
    end

    it 'a generator reading external state sees it change between turns' do
      pool = [10, 20]
      n = 0
      material = E(nil) { n += 1; n <= 2 ? pool[n - 1] : (n = 0; nil) }

      i = cycle_of(material).i

      expect(4.times.collect { i.next_value }).to eq [10, 20, 10, 20]

      pool.replace([30, 40])

      expect(4.times.collect { i.next_value }).to eq [30, 40, 30, 40]
    end
  end
end
