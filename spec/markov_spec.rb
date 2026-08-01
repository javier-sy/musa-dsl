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

  # A seed is what makes a generative result a work rather than a performance,
  # and `random:` documents two ways to give one. The Random instance was
  # silently dropped and replaced by an unseeded generator, so the chain came
  # out different on every run while the caller believed it was pinned
  # (issue #79).
  context 'Reproducibility' do
    let(:transitions) { { a: %i[b c], b: %i[a c], c: %i[a b x] } }

    def chain(random)
      Musa::Markov::Markov.new(start: :a, finish: :x, transitions: transitions, random: random).i.to_a
    end

    it 'repeats itself when given a seed' do
      expect(chain(7)).to eq(chain(7))
    end

    it 'repeats itself when given a Random, which used to be thrown away' do
      expect(chain(Random.new(7))).to eq(chain(Random.new(7)))
    end

    it 'gives the same chain for a seed and for a Random built from it' do
      expect(chain(Random.new(7))).to eq(chain(7))
    end

    it 'keeps the generator it was given rather than making its own' do
      generator = Random.new(7)
      markov = Musa::Markov::Markov.new(start: :a, finish: :x,
                                        transitions: transitions, random: generator)

      expect(markov.random).to be(generator)
    end

    it 'draws from the generator it was given, so several series can share one' do
      untouched = Random.new(7)
      shared = Random.new(7)

      instance = Musa::Markov::Markov.new(start: :a, finish: :x,
                                          transitions: transitions, random: shared).i
      instance.next_value while instance.next_value

      # Consuming the chain moved the shared generator on; the twin did not move.
      expect(shared.rand(1000)).not_to eq(untouched.rand(1000))
    end

    it 'gives a different chain for a different seed' do
      expect(chain(7)).not_to eq(chain(8))
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
