require 'spec_helper'

require 'musa-dsl'

include Musa::Extension::SmartProcBinder

RSpec.describe SmartProcBinder do
  context 'SmartProcBinder' do

    it 'block with value and key params, apply with value and key params (less values, not all keys)' do
      b = Proc.new do |a, b, c, d:, e:, f:|
      end

      bb = SmartProcBinder.new(b)

      v, k = bb.apply(1, e: 5)

      expect(v).to eq([1, nil, nil])
      expect(k).to eq(d: nil, e: 5, f: nil)
    end

    it 'block with value and key params, apply with value and key params (more values, more keys)' do
      b = Proc.new do |a, b, c, d:, e:, f:|
      end

      bb = SmartProcBinder.new(b)

      v, k = bb.apply(1, 2, 3, 4, 5,d: 4, e: 5,f: 6, g: 7, h: 8)

      expect(v).to eq([1, 2, 3])
      expect(k).to eq(d: 4, e: 5, f: 6)
    end

    it 'block with value and key params, apply without params' do
      b = Proc.new do |a, b, c, d:, e:, f:|
      end

      bb = SmartProcBinder.new(b)

      v, k = bb.apply()

      expect(v).to eq([nil, nil, nil])
      expect(k).to eq(d: nil, e: nil, f: nil)
    end

    it 'block without params, apply with value and key params' do
      b = Proc.new do
      end

      bb = SmartProcBinder.new(b)

      v, k = bb.apply(1, e: 5)

      expect(v).to eq([])
      expect(k).to eq({})
    end

    it 'block without params, apply without params' do
      b = Proc.new do
      end

      bb = SmartProcBinder.new(b)

      v, k = bb.apply()

      expect(v).to eq([])
      expect(k).to eq({})
    end
  end
end
