require 'spec_helper'

require 'musa-dsl'

include Musa::Sequencer
include Musa::Datasets

using Musa::Extension::InspectNice

RSpec.describe Musa::Sequencer do
  context 'Move2 testing' do
    it '' do
      s = BaseSequencer.new do_log: true, do_error_log: true

      p = [{ a: 0r, b: 1r }.extend(PackedV), 3, { a: 4r, b: 5.75r }.extend(PackedV), 2, { a: 1.5r, b: 2 + 1/3r }.extend(PackedV) ].extend(P)

      s.at 1 do
        s._move2 p.to_ps_serie(base_duration: 1).i, step: 1, reference: 0 do |values, duration:, quantized_duration:, started_ago:|
          s.debug "values = #{values.inspect} duration #{duration} q_duration #{quantized_duration} started_ago #{started_ago}"
        end
      end

      puts
      s.run
      puts

    end
  end

  context 'Move2 quantizing detection' do

    it 'empty line' do
      cc = BaseSequencer::Quantizer.new(0r, 1r)

      expect(cc.pop).to be_nil

    end

    it 'empty line with only 1 point' do
      cc = BaseSequencer::Quantizer.new(0r, 1r)

      cc.push time: 0r, value: 0r

      expect(cc.pop).to be_nil
    end

    it 'allow time only to go forward' do
      cc = BaseSequencer::Quantizer.new(0r, 1r)

      cc.push time: 0r, value: 0r

      expect { cc.push time: 0r, value: 0r }.to raise_exception(ArgumentError)
      expect { cc.push time: -1r, value: 0r }.to raise_exception(ArgumentError)
    end

    it "don't allow pushes after last value received" do
      cc = BaseSequencer::Quantizer.new(0r, 1r)

      cc.push time: 0r, value: 0r
      cc.push time: 1r, value: 1r, last: true

      expect { cc.push time: 2r, value: 2r }.to raise_exception(ArgumentError)
    end


    it 'line with 2 points with one boundary crossing' do
      cc = BaseSequencer::Quantizer.new(0r, 1r)

      cc.push time: 0r, value: 0r
      cc.push time: 1r, value: 1r, last: true

      expect(cc.pop).to eq({ time: 0r, value: 0r, first: true, last: false, duration: 0.5r })
      expect(cc.pop).to eq({ time: 0.5r, value: 1r, first: false, last: true, duration: 0.5r })
      expect(cc.pop).to be_nil
    end

    it 'line with 2 points with 2 boundary crossings' do
      cc = BaseSequencer::Quantizer.new(0r, 1r)

      cc.push time: 0r, value: 0r
      cc.push time: 2r, value: 2r, last: true

      expect(cc.pop).to eq({ time: 0r, value: 0r, first: true, last: false, duration: 0.5r })
      expect(cc.pop).to eq({ time: 0.5r, value: 1r, first: false, last: false, duration: 1r })
      expect(cc.pop).to eq({ time: 1.5r, value: 2r, first: false, last: true, duration: 0.5r })
      expect(cc.pop).to be_nil
    end

    it 'line with no crossing boundaries' do
      cc = BaseSequencer::Quantizer.new(0r, 1r)

      cc.push time: 0r, value: 0.65r
      cc.push time: 2r, value: 0.70r
      cc.push time: 5r, value: 0.75r, last: true

      expect(cc.pop).to eq({ time: 0r, value: 1r, first: true, last: true, duration: 5r })
    end

    it 'line with no crossing boundaries (negative values)' do
      cc = BaseSequencer::Quantizer.new(0r, 1r)

      cc.push time: 0r, value: -0.65r
      cc.push time: 2r, value: -0.70r
      cc.push time: 5r, value: -0.75r, last: true

      expect(cc.pop).to eq({ time: 0r, value: -1r, first: true, last: true, duration: 5r })
    end

    it 'line goes up and after goes down' do
      cc = BaseSequencer::Quantizer.new(0r, 1r)

      cc.push time: 0, value: 0r
      cc.push time: 3, value: 3r


      expect(cc.pop).to eq({ time: 0r, value: 0r, first: true, last: false, duration: 0.5r })
      expect(cc.pop).to eq({ time: 0.5r, value: 1r, first: false, last: false, duration: 1r })
      expect(cc.pop).to eq({ time: 1.5r, value: 2r, first: false, last: false, duration: 1r })

      expect(cc.pop).to be_nil

      cc.push time: 5, value: 1r, last: true

      expect(cc.pop).to eq({ time: 2.5r, value: 3r, first: false, last: false, duration: 1r })
      expect(cc.pop).to eq({ time: 3.5r, value: 2r, first: false, last: false, duration: 1r })
      expect(cc.pop).to eq({ time: 4.5r, value: 1r, first: false, last: true, duration: 0.5r })

      expect(cc.pop).to be_nil

    end

    it 'line from 0 to 5 quantized to (0, 1)' do
      cc = BaseSequencer::Quantizer.new(0r, 1r)

      cc.push time: 0r, value: 0r
      cc.push time: 3r, value: 3r

      expect(cc.pop).to eq({ time: 0r, value: 0r, first: true, last: false, duration: 0.5r })
      expect(cc.pop).to eq({ time: 0.5r, value: 1r, first: false, last: false, duration: 1r })
      expect(cc.pop).to eq({ time: 1.5r, value: 2r, first: false, last: false, duration: 1r })

      expect(cc.pop).to be_nil

      cc.push time: 5r, value: 5r, last: true

      expect(cc.pop).to eq({ time: 2.5r, value: 3r, first: false, last: false, duration: 1r })
      expect(cc.pop).to eq({ time: 3.5r, value: 4r, first: false, last: false, duration: 1r })
      expect(cc.pop).to eq({ time: 4.5r, value: 5r, first: false, last: true, duration: 0.5r })

      expect(cc.pop).to be_nil
    end

    it 'line from 0 to 5 quantized to (0.5, 1)' do
      cc = BaseSequencer::Quantizer.new(0.5r, 1r)

      cc.push time: 0r, value: 0r
      cc.push time: 3r, value: 3r

      expect(cc.pop).to eq({ time: 0r, value: 0.5r, first: true, last: false, duration: 1r })
      expect(cc.pop).to eq({ time: 1r, value: 1.5r, first: false, last: false, duration: 1r })
      expect(cc.pop).to eq({ time: 2r, value: 2.5r, first: false, last: false, duration: 1r })

      expect(cc.pop).to be_nil

      cc.push time: 5r, value: 5r, last: true

      expect(cc.pop).to eq({ time: 3r, value: 3.5r, first: false, last: false, duration: 1r })
      expect(cc.pop).to eq({ time: 4r, value: 4.5r, first: false, last: true, duration: 1r })

      expect(cc.pop).to be_nil

    end

    it 'line from 2 to -3 quantized to (0.5, 1) (descending line, crossing 0, negative values)' do
      cc = BaseSequencer::Quantizer.new(0.5r, 1r)

      cc.push time: 0r, value: 2r
      cc.push time: 3r, value: -1r

      expect(cc.pop).to eq({ time: 0r, value: 1.5r, first: true, last: false, duration: 1r})
      expect(cc.pop).to eq({ time: 1r, value: 0.5r, first: false, last: false, duration: 1r })
      expect(cc.pop).to eq({ time: 2r, value: -0.5r, first: false, last: false, duration: 1r })

      expect(cc.pop).to be_nil

      cc.push time: 5r, value: -3r, last: true

      expect(cc.pop).to eq({ time: 3r, value: -1.5r, first: false, last: false, duration: 1r })
      expect(cc.pop).to eq({ time: 4r, value: -2.5r, first: false, last: true, duration: 1r })

      expect(cc.pop).to be_nil
    end

    it 'pushing several values and poping all together is the same as pushing and poping alternatively' do
      cc1 = BaseSequencer::Quantizer.new(0r, 1r)

      l1 = []

      cc1.push time: 0r, value: 0r

      while v = cc1.pop
        l1 << v
      end

      cc1.push time: 3r, value: 3r

      while v = cc1.pop
        l1 << v
      end

      cc1.push time: 5r, value: 5r

      while v = cc1.pop
        l1 << v
      end

      cc1.push time: 8r, value: -5r, last: true

      while v = cc1.pop
        l1 << v
      end

      cc2 = BaseSequencer::Quantizer.new(0r, 1r)
      l2 = []

      cc2.push time: 0r, value: 0r
      cc2.push time: 3r, value: 3r
      cc2.push time: 5r, value: 5r
      cc2.push time: 8r, value: -5r, last: true

      while v = cc2.pop
        l2 << v
      end

      expect(l1).to eq(l2)
    end

  end
end
