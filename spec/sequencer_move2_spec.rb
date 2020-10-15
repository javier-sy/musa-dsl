require 'spec_helper'

require 'musa-dsl'

include Musa::Sequencer
include Musa::Datasets

using Musa::Extension::InspectNice

RSpec.describe Musa::Sequencer do
  # context 'Move2 testing' do
  #   it '' do
  #     s = BaseSequencer.new do_log: true, do_error_log: true
  #
  #     p = [{ a: 0r, b: 1r }.extend(PackedV), 3, { a: 4r, b: 5.75r }.extend(PackedV), 2, { a: 1.5r, b: 2.33r }.extend(PackedV) ].extend(P)
  #
  #     s.at 1 do
  #       s._move2 p.to_ps_serie(base_duration: 1).i, step: 1, reference: 0 do |values|
  #         s.debug "values = #{values.inspect}"
  #       end
  #     end
  #
  #     puts
  #     s.run
  #     puts
  #
  #   end
  # end

  context 'Move2 quantizing detection' do
    it 'empty line' do
      cc = BaseSequencer::Quantizer.new(0r, 1r)

      r = cc.crossing

      expect(r).to be_nil
    end

    it 'empty line with only 1 point' do
      cc = BaseSequencer::Quantizer.new(0r, 1r)

      cc.push time: 0r, value: 0r
      r = cc.crossing

      expect(r).to be_nil
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

    it 'line with no crossing points' do
      cc = BaseSequencer::Quantizer.new(0r, 1r)

      cc.push time: 0r, value: 0.5r
      cc.push time: 5r, value: 0.75r

      r = cc.crossing

      expect(r).to eq []
    end

    it 'line with no crossing points (negative values)' do
      cc = BaseSequencer::Quantizer.new(0r, 1r)

      cc.push time: 0r, value: -0.75r
      cc.push time: 5r, value: -0.5r

      r = cc.crossing

      expect(r).to eq []
    end

    it 'line with no crossing points (descending line)' do
      cc = BaseSequencer::Quantizer.new(0r, 1r)

      cc.push time: 0r, value: 0.75r
      cc.push time: 5r, value: 0.5r

      r = cc.crossing

      expect(r).to eq []
    end

    it 'line with no crossing points (descending line and negative)' do
      cc = BaseSequencer::Quantizer.new(0r, 1r)

      cc.push time: 0r, value: -0.5r
      cc.push time: 5r, value: -0.75r

      r = cc.crossing

      expect(r).to eq []
    end

    it 'long line with no crossing points' do
      cc = BaseSequencer::Quantizer.new(0r, 1r)

      cc.push time: 0r, value: 0.5r
      cc.push time: 5r, value: 0.75r

      r = cc.crossing

      expect(r).to eq []

      cc.push time: 6r, value: 0.5r

      r = cc.crossing

      expect(r).to eq []

      cc.push time: 7r, value: 0.5r

      r = cc.crossing

      expect(r).to eq []

      cc.push time: 8r, value: 0.75r

      r = cc.crossing

      expect(r).to eq []
    end

    it 'line goes up and after goes down' do
      cc = BaseSequencer::Quantizer.new(0r, 1r)

      cc.push time: 0, value: 0r
      cc.push time: 3, value: 3r

      r = cc.crossing

      expect(r).to eq [{ time: 0r, value: 0r, crossing: false, first: true, last: false, sign: 1 },
                       { time: 1r, value: 1r, crossing: true, first: false, last: false, sign: 1 },
                       { time: 2r, value: 2r, crossing: true, first: false, last: false, sign: 1 },
                       { time: 3r, value: 3r, crossing: false, first: false, last: false, sign: nil  } ]

      cc.push time: 5, value: 1r, last: true

      r = cc.crossing

      expect(r).to eq [{ time: 3r, value: 3r, crossing: true, first: false, last: false, sign: -1 },
                       { time: 4r, value: 2r, crossing: true, first: false, last: false, sign: -1 },
                       { time: 5r, value: 1r, crossing: false, first: false, last: true, sign: nil } ]

    end

    it 'line from 0 to 5 quantized to (0, 1): expected first 0, last 5 and crossing from 1 to 4' do
      cc = BaseSequencer::Quantizer.new(0r, 1r)

      cc.push time: 0r, value: 0r
      cc.push time: 3r, value: 3r

      r = cc.crossing

      expect(r).to eq [{ time: 0r, value: 0r, crossing: false, first: true, last: false, sign: 1 },
                       { time: 1r, value: 1r, crossing: true, first: false, last: false, sign: 1 },
                       { time: 2r, value: 2r, crossing: true, first: false, last: false, sign: 1 },
                       { time: 3r, value: 3r, crossing: false, first: false, last: false, sign: nil  } ]

      cc.push time: 5r, value: 5r, last: true

      r = cc.crossing

      expect(r).to eq [{ time: 3r, value: 3r, crossing: true, first: false, last: false, sign: 1 },
                       { time: 4r, value: 4r, crossing: true, first: false, last: false, sign: 1 },
                       { time: 5r, value: 5r, crossing: false, first: false, last: true, sign: nil } ]
    end

    it 'line from 0 to 5 quantized to (0.5, 1): expected crossing from 0.5 to 4.5, no first or last' do
      cc = BaseSequencer::Quantizer.new(0.5r, 1r)

      cc.push time: 0r, value: 0r
      cc.push time: 3r, value: 3r

      r = cc.crossing

      expect(r).to eq [{ time: 0.5r, value: 0.5r, crossing: true, first: false, last: false, sign: 1 },
                       { time: 1.5r, value: 1.5r, crossing: true, first: false, last: false, sign: 1 },
                       { time: 2.5r, value: 2.5r, crossing: true, first: false, last: false, sign: 1 } ]

      cc.push time: 5r, value: 5r, last: true

      r = cc.crossing

      expect(r).to eq [{ time: 3.5r, value: 3.5r, crossing: true, first: false, last: false, sign: 1 },
                       { time: 4.5r, value: 4.5r, crossing: true, first: false, last: false, sign: 1 }]
    end

    it 'line from 2 to -3 quantized to (0.5, 1) (descending line, crossing 0, negative values): expected crossing from 2.5 to -2.5, no first or last' do
      cc = BaseSequencer::Quantizer.new(0.5r, 1r)

      cc.push time: 0r, value: 2r
      cc.push time: 3r, value: -1r

      r = cc.crossing

      expect(r).to eq [{ time: 0.5r, value: 1.5r, crossing: true, first: false, last: false, sign: -1 },
                       { time: 1.5r, value: 0.5r, crossing: true, first: false, last: false, sign: -1 },
                       { time: 2.5r, value: -0.5r, crossing: true, first: false, last: false, sign: -1 } ]

      cc.push time: 5r, value: -3r, last: true

      r = cc.crossing

      expect(r).to eq [{ time: 3.5r, value: -1.5r, crossing: true, first: false, last: false, sign: -1 },
                       { time: 4.5r, value: -2.5r, crossing: true, first: false, last: false, sign: -1 } ]
    end


  end
end
