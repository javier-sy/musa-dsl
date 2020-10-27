require 'spec_helper'

require 'musa-dsl'

include Musa::Series
include Musa::Datasets

using Musa::Extension::InspectNice

RSpec.describe Musa::Series do
  context 'Move2 testing' do
    # it '' do
    #   s = BaseSequencer.new do_log: true, do_error_log: true
    #
    #   p = [{ a: 0r, b: 1r }.extend(PackedV), 3, { a: 4r, b: 5.75r }.extend(PackedV), 2, { a: 1.5r, b: 2 + 1/3r }.extend(PackedV) ].extend(P)
    #
    #   s.at 1 do
    #     s._move2 p.to_ps_serie(base_duration: 1).i, step: 1, reference: 0 do |values, duration:, quantized_duration:, started_ago:|
    #       s.debug "values = #{values.inspect} duration #{duration} q_duration #{quantized_duration} started_ago #{started_ago}"
    #     end
    #   end
    #
    #   puts
    #   s.run
    #   puts
    #
    # end
  end

  context 'Move2 quantizing detection' do

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

      expect(cc.next_value).to eq({ time: 0r, value: 0r, first: true, last: false, duration: 0.5r })
      expect(cc.next_value).to eq({ time: 0.5r, value: 1r, first: false, last: true, duration: 0.5r })

      expect(cc.next_value).to be_nil
    end

    it 'line with 2 points with 2 boundary crossings' do
      c = S([0r, 0r], [2r, 2r])

      cc = QUANTIZE(c, reference: 0r, step: 1r).i

      expect(cc.next_value).to eq({ time: 0r, value: 0r, first: true, last: false, duration: 0.5r })
      expect(cc.next_value).to eq({ time: 0.5r, value: 1r, first: false, last: false, duration: 1r })
      expect(cc.next_value).to eq({ time: 1.5r, value: 2r, first: false, last: true, duration: 0.5r })

      expect(cc.next_value).to be_nil
    end


    it 'line with no crossing boundaries' do
      c = S([0r, 0.65r], [2r, 0.70r], [5r, 0.75r])

      cc = QUANTIZE(c, reference: 0r, step: 1r).i

      expect(cc.next_value).to eq({ time: 0r, value: 1r, first: true, last: true, duration: 5r })

      expect(cc.next_value).to be_nil
    end


    it 'line with no crossing boundaries (negative values)' do
      c = S([0r, -0.65r], [2r, -0.70r], [5r, -0.75r])

      cc = QUANTIZE(c, reference: 0r, step: 1r).i


      expect(cc.next_value).to eq({ time: 0r, value: -1r, first: true, last: true, duration: 5r })

      expect(cc.next_value).to be_nil
    end

    it 'line goes up and after goes down' do
      c = S([0r, 0r], [3r, 3r], [5r, 1r])

      cc = QUANTIZE(c, reference: 0r, step: 1r).i

      expect(cc.next_value).to eq({ time: 0r, value: 0r, first: true, last: false, duration: 0.5r })
      expect(cc.next_value).to eq({ time: 0.5r, value: 1r, first: false, last: false, duration: 1r })
      expect(cc.next_value).to eq({ time: 1.5r, value: 2r, first: false, last: false, duration: 1r })


      expect(cc.next_value).to eq({ time: 2.5r, value: 3r, first: false, last: false, duration: 1r })
      expect(cc.next_value).to eq({ time: 3.5r, value: 2r, first: false, last: false, duration: 1r })
      expect(cc.next_value).to eq({ time: 4.5r, value: 1r, first: false, last: true, duration: 0.5r })

      expect(cc.next_value).to be_nil

    end

    it 'line from 0 to 5 quantized to (0, 1)' do
      c = S([0r, 0r], [3r, 3r], [5r, 5r])

      cc = QUANTIZE(c, reference: 0r, step: 1r).i

      expect(cc.next_value).to eq({ time: 0r, value: 0r, first: true, last: false, duration: 0.5r })
      expect(cc.next_value).to eq({ time: 0.5r, value: 1r, first: false, last: false, duration: 1r })
      expect(cc.next_value).to eq({ time: 1.5r, value: 2r, first: false, last: false, duration: 1r })

      expect(cc.next_value).to eq({ time: 2.5r, value: 3r, first: false, last: false, duration: 1r })
      expect(cc.next_value).to eq({ time: 3.5r, value: 4r, first: false, last: false, duration: 1r })
      expect(cc.next_value).to eq({ time: 4.5r, value: 5r, first: false, last: true, duration: 0.5r })

      expect(cc.next_value).to be_nil
    end

    it 'line from 0 to 5 quantized to (0.5, 1)' do
      c = S([0r, 0r], [3r, 3r], [5r, 5r])

      cc = QUANTIZE(c, reference: 0.5r, step: 1r).i


      expect(cc.next_value).to eq({ time: 0r, value: 0.5r, first: true, last: false, duration: 1r })
      expect(cc.next_value).to eq({ time: 1r, value: 1.5r, first: false, last: false, duration: 1r })
      expect(cc.next_value).to eq({ time: 2r, value: 2.5r, first: false, last: false, duration: 1r })

      expect(cc.next_value).to eq({ time: 3r, value: 3.5r, first: false, last: false, duration: 1r })
      expect(cc.next_value).to eq({ time: 4r, value: 4.5r, first: false, last: true, duration: 1r })

      expect(cc.next_value).to be_nil
    end



    it 'line from 2 to -3 quantized to (0.5, 1) (descending line, crossing 0, negative values)' do
      c = S([0r, 2r], [3r, -1r], [5r, -3r])

      cc = QUANTIZE(c, reference: 0.5r, step: 1r).i

      expect(cc.next_value).to eq({ time: 0r, value: 1.5r, first: true, last: false, duration: 1r})
      expect(cc.next_value).to eq({ time: 1r, value: 0.5r, first: false, last: false, duration: 1r })
      expect(cc.next_value).to eq({ time: 2r, value: -0.5r, first: false, last: false, duration: 1r })

      expect(cc.next_value).to eq({ time: 3r, value: -1.5r, first: false, last: false, duration: 1r })
      expect(cc.next_value).to eq({ time: 4r, value: -2.5r, first: false, last: true, duration: 1r })

      expect(cc.next_value).to be_nil
    end
  end
end
