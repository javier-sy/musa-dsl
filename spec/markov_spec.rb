require 'spec_helper'

require 'musa-dsl'

RSpec.describe Musa::Markov do
  context 'Markov series' do
    it 'Simple markov equal probability' do
      m = Musa::Markov::Markov.new(start: :a, finish: :x, random: Random.new,
                                   transitions:
                                     { a: %i[b c],
                                       b: %i[a c],
                                       c: %i[a b x] }).i

      20.times do
        m.restart
        make_expects m.to_a.join
      end
    end

    it 'Simple markov combined equal and unequal probability' do
      m = Musa::Markov::Markov.new(start: :a, finish: :x,
                                   transitions:
                                     { a: { b: 0.2, c: 0.8 },
                                       b: { a: 0.3, c: 0.7 },
                                       c: %i[a b x] }).i

      20.times do
        m.restart
        make_expects m.to_a.join
      end
    end

    it 'Coded markov combined equal, unequal and code based probability' do
      m = Musa::Markov::Markov.new(start: :a, finish: :x,
                                   transitions:
                                     { a: { b: 0.2, c: 0.8 },
                                       b: proc { |history| history.size.even? ? :a : :c },
                                       c: %i[a b x] }).i

      20.times do
        m.restart
        make_expects m.to_a.join
      end
    end
  end

  def make_expects(result)
    expect(result).to match /^a[bc]/

    expect(result).not_to match /aa/
    expect(result).not_to match /bb/
    expect(result).not_to match /cc/
    expect(result).not_to match /ax/
    expect(result).not_to match /bx/

    expect(result).to match /cx/
    expect(result).to match /x$/
  end
end
