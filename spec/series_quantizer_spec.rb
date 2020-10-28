require 'spec_helper'

require 'musa-dsl'

include Musa::Series
include Musa::Datasets

using Musa::Extension::InspectNice

RSpec.describe Musa::Series do
  context 'Quantizer series handles' do
    it 'empty line' do
      cc = QUANTIZE(NIL(), reference: 0r, step: 1r).i

      expect(cc.next_value).to be_nil
    end

    it 'empty line with only 1 point' do
      c = S([0r, 0r])

      cc = QUANTIZE(c, reference: 0r, step: 1r).i

      expect(cc.next_value).to be_nil
    end

    it 'allow time only to go forward' do
      c = S([0r, 0r], [0r, 0r], [-1r, 0r])

      cc = QUANTIZE(c, reference: 0r, step: 1r).i

      expect { cc.next_value }.to raise_exception(RuntimeError)
    end

    it 'line with 2 points with one boundary crossing' do
      c = S([0r, 0r], [1r, 1r])

      cc = QUANTIZE(c, reference: 0r, step: 1r).i

      expect(cc.next_value).to eq({ time: 0r, value: 0r, duration: 0.5r })
      expect(cc.next_value).to eq({ time: 0.5r, value: 1r, duration: 0.5r })

      expect(cc.next_value).to be_nil
    end

    it 'line with 2 points with 2 boundary crossings' do
      c = S([0r, 0r], [2r, 2r])

      cc = QUANTIZE(c, reference: 0r, step: 1r).i

      expect(cc.next_value).to eq({ time: 0r, value: 0r, duration: 0.5r })
      expect(cc.next_value).to eq({ time: 0.5r, value: 1r, duration: 1r })
      expect(cc.next_value).to eq({ time: 1.5r, value: 2r, duration: 0.5r })

      expect(cc.next_value).to be_nil
    end


    it 'line with no crossing boundaries' do
      c = S([0r, 0.65r], [2r, 0.70r], [5r, 0.75r])

      cc = QUANTIZE(c, reference: 0r, step: 1r).i

      expect(cc.next_value).to eq({ time: 0r, value: 1r, duration: 5r })

      expect(cc.next_value).to be_nil
    end


    it 'line with no crossing boundaries (negative values)' do
      c = S([0r, -0.65r], [2r, -0.70r], [5r, -0.75r])

      cc = QUANTIZE(c, reference: 0r, step: 1r).i

      expect(cc.next_value).to eq({ time: 0r, value: -1r, duration: 5r })

      expect(cc.next_value).to be_nil
    end

    it 'line goes up and after goes down' do
      c = S([0r, 0r], [3r, 3r], [5r, 1r])

      cc = QUANTIZE(c, reference: 0r, step: 1r).i

      expect(cc.next_value).to eq({ time: 0r, value: 0r, duration: 0.5r })
      expect(cc.next_value).to eq({ time: 0.5r, value: 1r, duration: 1r })
      expect(cc.next_value).to eq({ time: 1.5r, value: 2r, duration: 1r })


      expect(cc.next_value).to eq({ time: 2.5r, value: 3r, duration: 1r })
      expect(cc.next_value).to eq({ time: 3.5r, value: 2r, duration: 1r })
      expect(cc.next_value).to eq({ time: 4.5r, value: 1r, duration: 0.5r })

      expect(cc.next_value).to be_nil

    end

    it 'line from 0 to 5 quantized to (0, 1)' do
      c = S([0r, 0r], [3r, 3r], [5r, 5r])

      cc = QUANTIZE(c, reference: 0r, step: 1r).i

      expect(cc.next_value).to eq({ time: 0r, value: 0r, duration: 0.5r })
      expect(cc.next_value).to eq({ time: 0.5r, value: 1r, duration: 1r })
      expect(cc.next_value).to eq({ time: 1.5r, value: 2r, duration: 1r })

      expect(cc.next_value).to eq({ time: 2.5r, value: 3r, duration: 1r })
      expect(cc.next_value).to eq({ time: 3.5r, value: 4r, duration: 1r })
      expect(cc.next_value).to eq({ time: 4.5r, value: 5r, duration: 0.5r })

      expect(cc.next_value).to be_nil
    end

    it 'line from 0 to 5 quantized to (0.5, 1)' do
      c = S([0r, 0r], [3r, 3r], [5r, 5r])

      cc = QUANTIZE(c, reference: 0.5r, step: 1r).i

      expect(cc.next_value).to eq({ time: 0r, value: 0.5r, duration: 1r })
      expect(cc.next_value).to eq({ time: 1r, value: 1.5r, duration: 1r })
      expect(cc.next_value).to eq({ time: 2r, value: 2.5r, duration: 1r })

      expect(cc.next_value).to eq({ time: 3r, value: 3.5r, duration: 1r })
      expect(cc.next_value).to eq({ time: 4r, value: 4.5r, duration: 1r })

      expect(cc.next_value).to be_nil
    end

    it 'line from 2 to -3 quantized to (0.5, 1) (descending line, crossing 0, negative values)' do
      c = S([0r, 2r], [3r, -1r], [5r, -3r])

      cc = QUANTIZE(c, reference: 0.5r, step: 1r).i

      expect(cc.next_value).to eq({ time: 0r, value: 1.5r, duration: 1r})
      expect(cc.next_value).to eq({ time: 1r, value: 0.5r, duration: 1r })
      expect(cc.next_value).to eq({ time: 2r, value: -0.5r, duration: 1r })

      expect(cc.next_value).to eq({ time: 3r, value: -1.5r, duration: 1r })
      expect(cc.next_value).to eq({ time: 4r, value: -2.5r, duration: 1r })

      expect(cc.next_value).to be_nil
    end
  end
end
