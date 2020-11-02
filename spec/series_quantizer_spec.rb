require 'spec_helper'

require 'musa-dsl'

include Musa::Series
include Musa::Datasets

using Musa::Extension::InspectNice

RSpec.describe Musa::Series do
  context 'Quantizer series handles' do
=begin
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

    it 'line with 2 points with 2 boundary crossings (with AbsTimed serie)' do
      c = S({ time: 0r, value: 0r }.extend(AbsTimed), { time: 2r, value: 2r }.extend(AbsTimed))

      cc = QUANTIZE(c, reference: 0r, step: 1r).i

      expect(cc.next_value).to eq({ time: 0r, value: 0r, duration: 0.5r })
      expect(cc.next_value).to eq({ time: 0.5r, value: 1r, duration: 1r })
      expect(cc.next_value).to eq({ time: 1.5r, value: 2r, duration: 0.5r })

      expect(cc.next_value).to be_nil
    end

    it 'line with 2 points with 2 boundary crossings (with AbsTimed serie with value on not default attribute)' do
      c = S({ time: 0r, cosa: 0r }.extend(AbsTimed), { time: 2r, cosa: 2r }.extend(AbsTimed))

      cc = QUANTIZE(c, reference: 0r, step: 1r, value_attribute: :cosa).i

      expect(cc.next_value).to eq({ time: 0r, cosa: 0r, duration: 0.5r })
      expect(cc.next_value).to eq({ time: 0.5r, cosa: 1r, duration: 1r })
      expect(cc.next_value).to eq({ time: 1.5r, cosa: 2r, duration: 0.5r })

      expect(cc.next_value).to be_nil
    end

    it 'simple line with no crossing boundaries' do
      c = S([0r, 0.65r], [2r, 0.70r], [5r, 0.75r])

      cc = QUANTIZE(c, reference: 0r, step: 1r).i

      expect(cc.next_value).to eq({ time: 0r, value: 1r, duration: 5r })

      expect(cc.next_value).to be_nil
    end


    it 'simple line with no crossing boundaries (negative values)' do
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

    it 'bufix: quantizer was ignoring the intermediate points on a flat value line' do
      c = S([0, 60], [4, 60], [8, 60], [12, 60], [16, 64])

      cc = QUANTIZE(c).i

      expect(cc.next_value).to eq({ time: 0r, value: 60r, duration: 12+1/2r })
      expect(cc.next_value).to eq({ time: 12+1/2r, value: 61r, duration: 1r })
      expect(cc.next_value).to eq({ time: 13+1/2r, value: 62r, duration: 1r })
      expect(cc.next_value).to eq({ time: 14+1/2r, value: 63r, duration: 1r })
      expect(cc.next_value).to eq({ time: 15+1/2r, value: 64r, duration: 1/2r })

      expect(cc.next_value).to be_nil
    end
=end
    it 'bufix: quantizer was ignoring the intermediate points on a flat value line (longer)' do
      c = S([0, 60], [4, 60], [8, 60], [12, 60], [16, 64], [20, 64], [24, 64], [28, 68], [32, 72])

      cc = QUANTIZE(c, crossings_aware: true).i

      cc.to_a.each do |x|
        puts "#{x.inspect}"
      end

      # expect(cc.next_value).to eq({ time: 0r, value: 60r, duration: 12+1/2r })
      #
      # expect(cc.next_value).to eq({ time: 12+1/2r, value: 61r, duration: 1r })
      # expect(cc.next_value).to eq({ time: 13+1/2r, value: 62r, duration: 1r })
      # expect(cc.next_value).to eq({ time: 14+1/2r, value: 63r, duration: 1r })
      # expect(cc.next_value).to eq({ time: 15+1/2r, value: 64r, duration: 9r })
      #
      # expect(cc.next_value).to eq({ time: 24+1/2r, value: 65r, duration: 1r })
      # expect(cc.next_value).to eq({ time: 25+1/2r, value: 66r, duration: 1r })
      # expect(cc.next_value).to eq({ time: 26+1/2r, value: 67r, duration: 1r })
      # expect(cc.next_value).to eq({ time: 27+1/2r, value: 68r, duration: 1r })
      #
      # expect(cc.next_value).to eq({ time: 28+1/2r, value: 69r, duration: 1r })
      # expect(cc.next_value).to eq({ time: 29+1/2r, value: 70r, duration: 1r })
      # expect(cc.next_value).to eq({ time: 30+1/2r, value: 71r, duration: 1r })
      # expect(cc.next_value).to eq({ time: 31+1/2r, value: 72r, duration: 1/2r })
      #
      # expect(cc.next_value).to be_nil
    end

  end
end
