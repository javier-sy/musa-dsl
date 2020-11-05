require 'spec_helper'

require 'musa-dsl'

include Musa::Series
include Musa::Datasets

using Musa::Extension::InspectNice

RSpec.describe Musa::Series do
  context 'Quantizer series handles' do

    it 'empty line (raw algorithm)' do
      cc = QUANTIZE(NIL(), reference: 0r, step: 1r).i

      expect(cc.next_value).to be_nil
    end

    it 'operation syntax' do
      cc = NIL().quantize.i

      expect(cc.next_value).to be_nil
    end

    it 'empty line (predictive algorithm)' do
      cc = QUANTIZE(NIL(), reference: 0r, step: 1r, predictive: true).i

      expect(cc.next_value).to be_nil
    end

    it 'empty line with only 1 point (raw)' do
      c = S([0r, 0r])

      cc = QUANTIZE(c, reference: 0r, step: 1r).i

      expect(cc.next_value).to be_nil
    end

    it 'empty line with only 1 point (predictive)' do
      c = S([0r, 0r])

      cc = QUANTIZE(c, reference: 0r, step: 1r, predictive: true).i

      expect(cc.next_value).to be_nil
    end

    it 'allow time only to go forward (raw)' do
      c = S([0r, 0r], [0r, 0r], [-1r, 0r])

      cc = QUANTIZE(c, reference: 0r, step: 1r).i

      expect { cc.next_value }.to raise_exception(RuntimeError)
    end

    it 'allow time only to go forward (predictive)' do
      c = S([0r, 0r], [0r, 0r], [-1r, 0r])

      cc = QUANTIZE(c, reference: 0r, step: 1r, predictive: true).i

      expect { cc.next_value }.to raise_exception(RuntimeError)
    end

    it 'quantized values are AbsTimed and AbsD (raw algorithm)' do
      c = S([0, 60], [4, 60], [8, 60], [12, 60], [16, 64])

      cc = QUANTIZE(c, reference: 0r, step: 1r).i

      while v = cc.next_value
        expect(v).to be_a(AbsTimed)
        expect(v).to be_a(AbsD)
      end
    end

    it 'quantized values are AbsTimed and AbsD (raw algorithm with stops)' do
      c = S([0, 60], [4, 60], [8, 60], [12, 60], [16, 64])

      cc = QUANTIZE(c, reference: 0r, step: 1r).i

      while v = cc.next_value
        expect(v).to be_a(AbsTimed)
        expect(v).to be_a(AbsD)
      end
    end

    it 'quantized values are AbsTimed and AbsD (predictive algorithm)' do
      c = S([0, 60], [4, 60], [8, 60], [12, 60], [16, 64])

      cc = QUANTIZE(c, reference: 0r, step: 1r, predictive: true).i

      while v = cc.next_value
        expect(v).to be_a(AbsTimed)
        expect(v).to be_a(AbsD)
      end
    end

    it 'quantized values are AbsTimed and AbsD (predictive algorithm with stops)' do
      c = S([0, 60], [4, 60], [8, 60], [12, 60], [16, 64])

      cc = QUANTIZE(c, reference: 0r, step: 1r, predictive: true, stops: true).i

      while v = cc.next_value
        expect(v).to be_a(AbsTimed)
        expect(v).to be_a(AbsD)
      end
    end

    it 'line with 2 points with one boundary crossing (raw)' do
      c = S([0r, 0r], [1r, 1r])

      cc = QUANTIZE(c, reference: 0r, step: 1r).i

      expect(cc.next_value).to eq({ time: 0r, value: 0r, duration: 1r })

      expect(cc.next_value).to be_nil
    end

    it 'line with 2 points with one boundary crossing (predictive)' do
      c = S([0r, 0r], [1r, 1r])

      cc = QUANTIZE(c, reference: 0r, step: 1r, predictive: true).i

      expect(cc.next_value).to eq({ time: 0r, value: 0r, duration: 0.5r })
      expect(cc.next_value).to eq({ time: 0.5r, value: 1r, duration: 0.5r })

      expect(cc.next_value).to be_nil
    end

    it 'line with 2 points with 2 boundary crossings (raw)' do
      c = S([0r, 0r], [2r, 2r])

      cc = QUANTIZE(c, reference: 0r, step: 1r).i

      expect(cc.next_value).to eq({ time: 0r, value: 0r, duration: 1r })
      expect(cc.next_value).to eq({ time: 1r, value: 1r, duration: 1r })

      expect(cc.next_value).to be_nil
    end

    it 'line with 2 points with 2 boundary crossings (predictive)' do
      c = S([0r, 0r], [2r, 2r])

      cc = QUANTIZE(c, reference: 0r, step: 1r, predictive: true).i

      expect(cc.next_value).to eq({ time: 0r, value: 0r, duration: 0.5r })
      expect(cc.next_value).to eq({ time: 0.5r, value: 1r, duration: 1r })
      expect(cc.next_value).to eq({ time: 1.5r, value: 2r, duration: 0.5r })

      expect(cc.next_value).to be_nil
    end

    it 'line with 2 points with 2 boundary crossings (with AbsTimed serie) (raw)' do
      c = S({ time: 0r, value: 0r }.extend(AbsTimed), { time: 2r, value: 2r }.extend(AbsTimed))

      cc = QUANTIZE(c, reference: 0r, step: 1r).i

      expect(cc.next_value).to eq({ time: 0r, value: 0r, duration: 1r })
      expect(cc.next_value).to eq({ time: 1r, value: 1r, duration: 1r })

      expect(cc.next_value).to be_nil
    end

    it 'line with 2 points with 2 boundary crossings (with AbsTimed serie) (predictive)' do
      c = S({ time: 0r, value: 0r }.extend(AbsTimed), { time: 2r, value: 2r }.extend(AbsTimed))

      cc = QUANTIZE(c, reference: 0r, step: 1r, predictive: true).i

      expect(cc.next_value).to eq({ time: 0r, value: 0r, duration: 0.5r })
      expect(cc.next_value).to eq({ time: 0.5r, value: 1r, duration: 1r })
      expect(cc.next_value).to eq({ time: 1.5r, value: 2r, duration: 0.5r })

      expect(cc.next_value).to be_nil
    end

    it 'line with 2 points with 2 boundary crossings (with AbsTimed serie with value on not default attribute) (raw)' do
      c = S({ time: 0r, cosa: 0r }.extend(AbsTimed), { time: 2r, cosa: 2r }.extend(AbsTimed))

      cc = QUANTIZE(c, reference: 0r, step: 1r, value_attribute: :cosa).i

      expect(cc.next_value).to eq({ time: 0r, cosa: 0r, duration: 1r })
      expect(cc.next_value).to eq({ time: 1r, cosa: 1r, duration: 1r })

      expect(cc.next_value).to be_nil
    end

    it 'line with 2 points with 2 boundary crossings (with AbsTimed serie with value on not default attribute) (predictive)' do
      c = S({ time: 0r, cosa: 0r }.extend(AbsTimed), { time: 2r, cosa: 2r }.extend(AbsTimed))

      cc = QUANTIZE(c, reference: 0r, step: 1r, value_attribute: :cosa, predictive: true).i

      expect(cc.next_value).to eq({ time: 0r, cosa: 0r, duration: 0.5r })
      expect(cc.next_value).to eq({ time: 0.5r, cosa: 1r, duration: 1r })
      expect(cc.next_value).to eq({ time: 1.5r, cosa: 2r, duration: 0.5r })

      expect(cc.next_value).to be_nil
    end

    it 'simple line with no crossing boundaries (raw)' do
      c = S([0r, 0.65r], [2r, 0.70r], [3r, 0.80r], [5r, 0.75r])

      cc = QUANTIZE(c, reference: 0r, step: 1r).i

      expect(cc.next_value).to eq({ time: 0r, value: 1r, duration: 5r })

      expect(cc.next_value).to be_nil
    end

    it 'simple line with no crossing boundaries (predictive)' do
      c = S([0r, 0.65r], [2r, 0.70r], [5r, 0.75r])

      cc = QUANTIZE(c, reference: 0r, step: 1r, predictive: true).i

      expect(cc.next_value).to eq({ time: 0r, value: 1r, duration: 5r })

      expect(cc.next_value).to be_nil
    end

    it 'simple line with no crossing boundaries (negative values) (raw)' do
      c = S([0r, -0.65r], [2r, -0.70r], [5r, -0.75r])

      cc = QUANTIZE(c, reference: 0r, step: 1r).i

      expect(cc.next_value).to eq({ time: 0r, value: -1r, duration: 5r })

      expect(cc.next_value).to be_nil
    end

    it 'simple line with no crossing boundaries (negative values) (predictive)' do
      c = S([0r, -0.65r], [2r, -0.70r], [5r, -0.75r])

      cc = QUANTIZE(c, reference: 0r, step: 1r, predictive: true).i

      expect(cc.next_value).to eq({ time: 0r, value: -1r, duration: 5r })

      expect(cc.next_value).to be_nil
    end

    it 'line goes up and after goes down (raw)' do
      c = S([0r, 0r], [3r, 3r], [5r, 1r])

      cc = QUANTIZE(c, reference: 0r, step: 1r).i

      expected =[ { time: 0r, value: 0r, duration: 1r },
                  { time: 1r, value: 1r, duration: 1r },
                  { time: 2r, value: 2r, duration: 1r },
                  { time: 3r, value: 3r, duration: 1r },
                  { time: 4r, value: 2r, duration: 1r } ]

      while e = expected.shift
        expect(cc.next_value).to eq(e)
      end

      expect(cc.next_value).to be_nil
    end

    it 'line goes up and after goes down (predictive)' do
      c = S([0r, 0r], [3r, 3r], [5r, 1r])

      cc = QUANTIZE(c, reference: 0r, step: 1r, predictive: true).i

      expect(cc.next_value).to eq({ time: 0r, value: 0r, duration: 0.5r })
      expect(cc.next_value).to eq({ time: 0.5r, value: 1r, duration: 1r })
      expect(cc.next_value).to eq({ time: 1.5r, value: 2r, duration: 1r })


      expect(cc.next_value).to eq({ time: 2.5r, value: 3r, duration: 1r })
      expect(cc.next_value).to eq({ time: 3.5r, value: 2r, duration: 1r })
      expect(cc.next_value).to eq({ time: 4.5r, value: 1r, duration: 0.5r })

      expect(cc.next_value).to be_nil
    end

    it 'line from 0 to 5 quantized to (0, 1) (raw)' do
      c = S([0r, 0r], [3r, 3r], [5r, 5r])

      cc = QUANTIZE(c, reference: 0r, step: 1r).i

      expected =[ { time: 0r, value: 0r, duration: 1r },
                  { time: 1r, value: 1r, duration: 1r },
                  { time: 2r, value: 2r, duration: 1r },
                  { time: 3r, value: 3r, duration: 1r },
                  { time: 4r, value: 4r, duration: 1r } ]

      while e = expected.shift
        expect(cc.next_value).to eq(e)
      end

      expect(cc.next_value).to be_nil
    end

    it 'line from 0 to 5 quantized to (0, 1) (predictive)' do
      c = S([0r, 0r], [3r, 3r], [5r, 5r])

      cc = QUANTIZE(c, reference: 0r, step: 1r, predictive: true).i

      expect(cc.next_value).to eq({ time: 0r, value: 0r, duration: 0.5r })
      expect(cc.next_value).to eq({ time: 0.5r, value: 1r, duration: 1r })
      expect(cc.next_value).to eq({ time: 1.5r, value: 2r, duration: 1r })

      expect(cc.next_value).to eq({ time: 2.5r, value: 3r, duration: 1r })
      expect(cc.next_value).to eq({ time: 3.5r, value: 4r, duration: 1r })
      expect(cc.next_value).to eq({ time: 4.5r, value: 5r, duration: 0.5r })

      expect(cc.next_value).to be_nil
    end

    it 'line from 0 to 5 quantized to (0.5, 1) (predictive)' do
      c = S([0r, 0r], [3r, 3r], [5r, 5r])

      cc = QUANTIZE(c, reference: 0.5r, step: 1r, predictive: true).i

      expect(cc.next_value).to eq({ time: 0r, value: 0.5r, duration: 1r })
      expect(cc.next_value).to eq({ time: 1r, value: 1.5r, duration: 1r })
      expect(cc.next_value).to eq({ time: 2r, value: 2.5r, duration: 1r })

      expect(cc.next_value).to eq({ time: 3r, value: 3.5r, duration: 1r })
      expect(cc.next_value).to eq({ time: 4r, value: 4.5r, duration: 1r })

      expect(cc.next_value).to be_nil
    end

    it 'line from 2 to -3 quantized to (0.5, 1) (descending line, crossing 0, negative values) (raw)' do
      c = S([0r, 2r], [3r, -1r], [5r, -3r])

      cc = QUANTIZE(c, reference: 0.5r, step: 1r).i

      expect(cc.next_value).to eq({ time: 0r, value: 1.5r, duration: 1r})
      expect(cc.next_value).to eq({ time: 1r, value: 0.5r, duration: 1r })
      expect(cc.next_value).to eq({ time: 2r, value: -0.5r, duration: 1r })

      expect(cc.next_value).to eq({ time: 3r, value: -1.5r, duration: 1r })
      expect(cc.next_value).to eq({ time: 4r, value: -2.5r, duration: 1r })

      expect(cc.next_value).to be_nil
    end

    it 'line from 2 to -3 quantized to (0.5, 1) (descending line, crossing 0, negative values) (predictive)' do
      c = S([0r, 2r], [3r, -1r], [5r, -3r])

      cc = QUANTIZE(c, reference: 0.5r, step: 1r, predictive: true).i

      expect(cc.next_value).to eq({ time: 0r, value: 1.5r, duration: 1r})
      expect(cc.next_value).to eq({ time: 1r, value: 0.5r, duration: 1r })
      expect(cc.next_value).to eq({ time: 2r, value: -0.5r, duration: 1r })

      expect(cc.next_value).to eq({ time: 3r, value: -1.5r, duration: 1r })
      expect(cc.next_value).to eq({ time: 4r, value: -2.5r, duration: 1r })

      expect(cc.next_value).to be_nil
    end

    it 'line with one flat segment (raw)' do
      c = S([0, 60], [4, 60], [8, 60], [12, 60], [16, 64])

      cc = QUANTIZE(c).i

      expect(cc.next_value).to eq({ time: 0r, value: 60r, duration: 13r })
      expect(cc.next_value).to eq({ time: 13r, value: 61r, duration: 1r })
      expect(cc.next_value).to eq({ time: 14r, value: 62r, duration: 1r })
      expect(cc.next_value).to eq({ time: 15r, value: 63r, duration: 1r })

      expect(cc.next_value).to be_nil
    end

    it 'line with one flat segment (predictive)' do
      c = S([0, 60], [4, 60], [8, 60], [12, 60], [16, 64])

      cc = QUANTIZE(c, predictive: true).i

      expect(cc.next_value).to eq({ time: 0r, value: 60r, duration: 12+1/2r })
      expect(cc.next_value).to eq({ time: 12+1/2r, value: 61r, duration: 1r })
      expect(cc.next_value).to eq({ time: 13+1/2r, value: 62r, duration: 1r })
      expect(cc.next_value).to eq({ time: 14+1/2r, value: 63r, duration: 1r })
      expect(cc.next_value).to eq({ time: 15+1/2r, value: 64r, duration: 1/2r })

      expect(cc.next_value).to be_nil
    end

    it 'line with two flat segments (raw)' do
      c = S([0, 60], [4, 60], [8, 60], [12, 64], [16, 64], [20, 64], [24, 68], [32, 72], [36, 76])

      cc = QUANTIZE(c).i

      expected =[ { time: 0r, value: 60r, duration: 9r },
                  { time: 9r, value: 61r, duration: 1r },
                  { time: 10r, value: 62r, duration: 1r },
                  { time: 11r, value: 63r, duration: 1r },
                  { time: 12r, value: 64r, duration: 9r },
                  { time: 21r, value: 65r, duration: 1r },
                  { time: 22r, value: 66r, duration: 1r },
                  { time: 23r, value: 67r, duration: 1r },
                  { time: 24r, value: 68r, duration: 2r },
                  { time: 26r, value: 69r, duration: 2r },
                  { time: 28r, value: 70r, duration: 2r },
                  { time: 30r, value: 71r, duration: 2r },
                  { time: 32r, value: 72r, duration: 1r },
                  { time: 33r, value: 73r, duration: 1r },
                  { time: 34r, value: 74r, duration: 1r },
                  { time: 35r, value: 75r, duration: 1r } ]

      while e = expected.shift
        expect(cc.next_value).to eq(e)
      end

      expect(cc.next_value).to be_nil
    end

    it 'line with two flat segments (predictive)' do
      c = S([0, 60], [4, 60], [8, 60], [12, 64], [16, 64], [20, 64], [24, 68], [32, 72], [36, 76])

      cc = QUANTIZE(c, predictive: true).i

      expect(cc.next_value).to eq({ time: 0r, value: 60r, duration: 8+1/2r })
      expect(cc.next_value).to eq({ time: 8+1/2r, value: 61r, duration: 1r })
      expect(cc.next_value).to eq({ time: 9+1/2r, value: 62r, duration: 1r })
      expect(cc.next_value).to eq({ time: 10+1/2r, value: 63r, duration: 1r })
      expect(cc.next_value).to eq({ time: 11+1/2r, value: 64r, duration: 9r })
      expect(cc.next_value).to eq({ time: 20+1/2r, value: 65r, duration: 1r })
      expect(cc.next_value).to eq({ time: 21+1/2r, value: 66r, duration: 1r })
      expect(cc.next_value).to eq({ time: 22+1/2r, value: 67r, duration: 1r })
      expect(cc.next_value).to eq({ time: 23+1/2r, value: 68r, duration: 1+1/2r })
      expect(cc.next_value).to eq({ time: 25r, value: 69r, duration: 2r })
      expect(cc.next_value).to eq({ time: 27r, value: 70r, duration: 2r })
      expect(cc.next_value).to eq({ time: 29r, value: 71r, duration: 2r })
      expect(cc.next_value).to eq({ time: 31r, value: 72r, duration: 1+1/2r })
      expect(cc.next_value).to eq({ time: 32+1/2r, value: 73r, duration: 1r })
      expect(cc.next_value).to eq({ time: 33+1/2r, value: 74r, duration: 1r })
      expect(cc.next_value).to eq({ time: 34+1/2r, value: 75r, duration: 1r })
      expect(cc.next_value).to eq({ time: 35+1/2r, value: 76r, duration: 1/2r })

      expect(cc.next_value).to be_nil
    end

    it 'line with one flat segment (raw with stops)' do
      c = S([0, 60], [4, 60], [8, 60], [12, 60], [16, 64])

      cc = QUANTIZE(c, stops: true).i

      expect(cc.next_value).to eq({ time: 0r, value: 60r, duration: 12r })
      expect(cc.next_value).to eq({ time: 12r, value: 60r, duration: 1r })
      expect(cc.next_value).to eq({ time: 13r, value: 61r, duration: 1r })
      expect(cc.next_value).to eq({ time: 14r, value: 62r, duration: 1r })
      expect(cc.next_value).to eq({ time: 15r, value: 63r, duration: 1r })

      expect(cc.next_value).to be_nil
    end

    it 'line with one flat segment (predictive with stops)' do
      c = S([0, 60], [4, 60], [8, 60], [12, 60], [16, 64])

      cc = QUANTIZE(c, predictive: true, stops: true).i

      expect(cc.next_value).to eq({ time: 0r, value: 60r, duration: 12r })
      expect(cc.next_value).to eq({ time: 12r, value: 60r, duration: 1/2r })
      expect(cc.next_value).to eq({ time: 12+1/2r, value: 61r, duration: 1r })
      expect(cc.next_value).to eq({ time: 13+1/2r, value: 62r, duration: 1r })
      expect(cc.next_value).to eq({ time: 14+1/2r, value: 63r, duration: 1r })
      expect(cc.next_value).to eq({ time: 15+1/2r, value: 64r, duration: 1/2r })

      expect(cc.next_value).to be_nil
    end

    it 'line with two flat segments (raw with stops)' do
      c = S([0, 60], [4, 60], [8, 60], [12, 64], [16, 64], [20, 64], [24, 68], [32, 72], [36, 76])

      cc = QUANTIZE(c, stops: true).i

      expect(cc.next_value).to eq({ time: 0r, value: 60r, duration: 8r })
      expect(cc.next_value).to eq({ time: 8r, value: 60r, duration: 1r })
      expect(cc.next_value).to eq({ time: 9r, value: 61r, duration: 1r })
      expect(cc.next_value).to eq({ time: 10r, value: 62r, duration: 1r })
      expect(cc.next_value).to eq({ time: 11r, value: 63r, duration: 1r })
      expect(cc.next_value).to eq({ time: 12r, value: 64r, duration: 8r })
      expect(cc.next_value).to eq({ time: 20r, value: 64r, duration: 1r })
      expect(cc.next_value).to eq({ time: 21r, value: 65r, duration: 1r })
      expect(cc.next_value).to eq({ time: 22r, value: 66r, duration: 1r })
      expect(cc.next_value).to eq({ time: 23r, value: 67r, duration: 1r })
      expect(cc.next_value).to eq({ time: 24r, value: 68r, duration: 2r })
      expect(cc.next_value).to eq({ time: 26r, value: 69r, duration: 2r })
      expect(cc.next_value).to eq({ time: 28r, value: 70r, duration: 2r })
      expect(cc.next_value).to eq({ time: 30r, value: 71r, duration: 2r })
      expect(cc.next_value).to eq({ time: 32r, value: 72r, duration: 1r })
      expect(cc.next_value).to eq({ time: 33r, value: 73r, duration: 1r })
      expect(cc.next_value).to eq({ time: 34r, value: 74r, duration: 1r })
      expect(cc.next_value).to eq({ time: 35r, value: 75r, duration: 1r })

      expect(cc.next_value).to be_nil
    end

    it 'line with two flat segments (predictive with stops)' do
      c = S([0, 60], [4, 60], [8, 60], [12, 64], [16, 64], [20, 64], [24, 68], [32, 72], [36, 76])

      cc = QUANTIZE(c, predictive: true, stops: true).i

      expect(cc.next_value).to eq({ time: 0r, value: 60r, duration: 8r })
      expect(cc.next_value).to eq({ time: 8r, value: 60r, duration: 1/2r })
      expect(cc.next_value).to eq({ time: 8+1/2r, value: 61r, duration: 1r })
      expect(cc.next_value).to eq({ time: 9+1/2r, value: 62r, duration: 1r })
      expect(cc.next_value).to eq({ time: 10+1/2r, value: 63r, duration: 1r })
      expect(cc.next_value).to eq({ time: 11+1/2r, value: 64r, duration: 8+1/2r })
      expect(cc.next_value).to eq({ time: 20r, value: 64r, duration: 1/2r })
      expect(cc.next_value).to eq({ time: 20+1/2r, value: 65r, duration: 1r })
      expect(cc.next_value).to eq({ time: 21+1/2r, value: 66r, duration: 1r })
      expect(cc.next_value).to eq({ time: 22+1/2r, value: 67r, duration: 1r })
      expect(cc.next_value).to eq({ time: 23+1/2r, value: 68r, duration: 1+1/2r })
      expect(cc.next_value).to eq({ time: 25r, value: 69r, duration: 2r })
      expect(cc.next_value).to eq({ time: 27r, value: 70r, duration: 2r })
      expect(cc.next_value).to eq({ time: 29r, value: 71r, duration: 2r })
      expect(cc.next_value).to eq({ time: 31r, value: 72r, duration: 1+1/2r })
      expect(cc.next_value).to eq({ time: 32+1/2r, value: 73r, duration: 1r })
      expect(cc.next_value).to eq({ time: 33+1/2r, value: 74r, duration: 1r })
      expect(cc.next_value).to eq({ time: 34+1/2r, value: 75r, duration: 1r })
      expect(cc.next_value).to eq({ time: 35+1/2r, value: 76r, duration: 1/2r })

      expect(cc.next_value).to be_nil
    end

  end
end
