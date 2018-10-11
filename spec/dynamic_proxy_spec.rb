require 'spec_helper'

require 'musa-dsl'

RSpec.describe DynamicProxy do
  context 'Dynamic Proxy forwarding' do
    proxy1_1000 = DynamicProxy.new(1000)
    proxy2_1000 = DynamicProxy.new(1000)
    proxy3_2000 = DynamicProxy.new(2000)

    it 'proxy(1000) == 1000' do
      expect(proxy1_1000).to eq 1000
    end

    it 'proxy(2000) > 1000' do
      expect(proxy3_2000).to be > 1000
    end

    it 'proxy(2000) > proxy(1000)' do
      expect(proxy3_2000).to be > proxy2_1000
    end

    it 'proxy(1000) == proxy(1000)' do
      expect(proxy1_1000).to eq proxy2_1000
    end

    it 'proxy(1000).is_a? Integer' do
      expect(proxy1_1000.is_a?(Integer)).to be true
    end

    it 'proxy(1000).is_a? Numeric' do
      expect(proxy1_1000.is_a?(Numeric)).to be true
    end

    it 'proxy(1000).is_a? DynamicProxy' do
      expect(proxy1_1000.is_a?(DynamicProxy)).to be true
    end

    it 'proxy(1000).kind_of? Integer' do
      expect(proxy1_1000.is_a?(Integer)).to be true
    end

    it 'proxy(1000).kind_of? Numeric' do
      expect(proxy1_1000.is_a?(Numeric)).to be true
    end

    it 'proxy(1000).kind_of? DynamicProxy' do
      expect(proxy1_1000.is_a?(DynamicProxy)).to be true
    end
  end

  context 'Dynamic Proxy receiver change' do
    proxy = DynamicProxy.new(1000)

    it 'proxy = (1000); proxy == 1000' do
      expect(proxy).to eq 1000
    end

    it 'proxy = (2000); proxy == 2000' do
      proxy.receiver = 2000
      expect(proxy).to eq 2000
    end
  end
end
