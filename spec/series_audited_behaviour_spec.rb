# Behaviours of the series subsystem that the documentation does not claim.
#
# WHY THIS FILE EXISTS, AND WHY IT IS NOT CALLED inline_doc_*. It was: a
# hand-written transcription of the `@example` blocks in `lib/`, written to
# verify them. `tools/doc-examples.rb` now runs every one of those where it is
# written and checks every output it declares, so transcribing them here was
# duplicating a mechanism -- and a transcription drifts from its original in
# silence, which is how a spec came to carry a `.extend` the document lacked.
#
# What survived the audit is what the doctest cannot do:
#
#   * a claim the documentation does not make. If the example says nothing
#     about what it produces and this file knows, the fix is to promote it: the
#     `# =>` goes in the example, the doctest takes over, and the spec goes.
#     Eight did during the audit, and promoting them found `anticipate`
#     documented with two block parameters when it takes three -- an error no
#     doctest could see, because an example that declares nothing is never
#     compared with anything;
#
#   * an output that CANNOT be declared. `.randomize` has no value to write
#     down, so what is checkable is the invariant -- same elements, different
#     order -- and asserting a property is the only possible check. These stay
#     here for good;
#
#   * behaviour reached through the documentation but never stated in it.
#
# The rule, so this does not grow back: a spec file does not transcribe
# documentation. What a spec knows and the document does not say is a
# documentation gap, not a test asset.

require 'spec_helper'
require 'musa-dsl'

RSpec.describe 'Series Inline Documentation Examples' do
  include Musa::All

  context 'Constructors (main-serie-constructors.rb)' do

    it 'E can carry state across calls in caller.parameters' do
      fib = E { |last_value:, caller:|
        a, b = caller.parameters
        caller.parameters = [b, a + b]
        a
      }
      fib.parameters = [0, 1]
      result = []
      inst = fib.i
      10.times { result << inst.next_value }
      expect(result).to eq([0, 1, 1, 2, 3, 5, 8, 13, 21, 34])
    end

    it '@example Shuffling an array' do
      # A shuffle, not a die: every value comes out exactly once and then the
      # serie ends. Membership was all that was asserted here, and membership is
      # true of a die too -- it is the part that does not distinguish them.
      shuffled = RND(1, 2, 3, 4, 5, 6, random: 42)

      expect(shuffled.i.to_a).to eq([4, 6, 3, 5, 2, 1])
      expect(shuffled.infinite?).to be false

      instance = shuffled.i
      6.times { instance.next_value }
      expect(instance.next_value).to be_nil
    end

    it 'sampling with replacement is RND().repeat' do
      die = RND(1, 2, 3, random: 42).repeat

      expect(die.infinite?).to be true

      instance = die.i
      # Reshuffled on each pass, so values do repeat across passes.
      expect(9.times.collect { instance.next_value }).to eq([3, 2, 1, 1, 2, 3, 3, 2, 1])
    end

    it '@example Harmonic series' do
      harmonics = HARMO(error: 0.5)
      expect(harmonics.infinite?).to be true

      inst = harmonics.i
      expect(8.times.map { inst.next_value }).to eq [0, 12, 19, 24, 28, 31, 34, 36]
    end

    it 'HARMO: a tighter tolerance drops the harmonics that fall between semitones' do
      inst = HARMO(error: 0.1).i
      expect(8.times.map { inst.next_value }).to eq [0, 12, 19, 24, 31, 36, 38, 43]
    end

    it 'HARMO: extended yields the same pitches, carrying their error' do
      plain = HARMO(error: 0.5).i
      extended = HARMO(error: 0.5, extended: true).i

      plain_values = 8.times.map { plain.next_value }
      extended_values = 8.times.map { extended.next_value }

      expect(extended_values.map { |v| v[:pitch] }).to eq plain_values
      expect(extended_values[0]).to eq({ pitch: 0, error: 0.0 })
      expect(extended_values[4][:error]).to be_within(0.001).of(-0.1369)
    end
  end

  context 'Operations (main-serie-operations.rb)' do
    it 'Infinite loop' do
      pattern = S(1, 2, 3).autorestart
      inst = pattern.i
      result = []
      9.times do
        val = inst.next_value
        result << val unless val.nil?
      end
      expect(result.size).to be >= 6
      expect(result[0..2]).to eq([1, 2, 3])
    end

    it '@example Shuffle' do
      s = S(1, 2, 3, 4, 5).randomize
      result = s.i.to_a
      expect(result.size).to eq(5)
      expect(result.sort).to eq([1, 2, 3, 4, 5])
    end

  end

  context 'Base Series (base-series.rb)' do

  end

  context 'Array to Serie (array-to-serie.rb)' do

  end

  context 'Buffer Serie (buffer-serie.rb)' do

  end

  context 'Splitter (hash-or-array-serie-splitter.rb)' do

    it 'Split components' do
      splitter = S({a: 1, b: 2}, {a: 3, b: 4}).split.i
      expect(splitter[:a].to_a).to eq([1, 3])
      expect(splitter[:b].to_a).to eq([2, 4])
    end
  end

  context 'Proxy Serie (proxy-serie.rb)' do

    it 'Empty proxy' do
      proxy = PROXY()

      expect(proxy.undefined?).to be true
      expect(proxy.prototype?).to be false
      expect(proxy.instance?).to be false

      proxy.proxy_source = S(1, 2, 3)

      expect(proxy.prototype?).to be true
      expect(proxy.i.to_a).to eq([1, 2, 3])
    end

  end

  context 'Queue Serie (queue-serie.rb)' do

    it 'Create queue' do
      queue = QUEUE(S(1, 2), S(3, 4))
      expect(queue.i.to_a).to eq([1, 2, 3, 4])
    end
  end

  context 'Quantizer Serie (quantizer-serie.rb)' do

    it 'Quantize to integers' do
      serie = S({time: 0r, value: 1.3}, {time: 1r, value: 2.7})
        .map { |v| v.extend(Musa::Datasets::AbsTimed) }
      quantized = serie.quantize(step: 1)
      result = quantized.i.to_a

      # The values come out exact, as Rationals, and each step carries the
      # duration it holds -- it is a staircase, not a list of samples.
      expect(result).to eq [{ time: 0r, value: 1r, duration: 1/2r },
                            { time: 1/2r, value: 2r, duration: 1/2r }]
      expect(result.first[:value]).to be_a Rational
    end
  end

  context 'Integration tests' do
    it 'chains multiple operations correctly' do
      result = S(1, 2, 3, 4, 5, 6)
        .select { |n| n.even? }
        .map { |n| n * 10 }
        .repeat(2)
        .i.to_a

      expect(result).to eq([20, 40, 60, 20, 40, 60])
    end

    it 'handles nested series properly' do
      outer = S(S(1, 2), S(3, 4), S(5, 6))
      inst = outer.i

      chunk1 = inst.next_value
      expect(chunk1.i.to_a).to eq([1, 2])

      chunk2 = inst.next_value
      expect(chunk2.i.to_a).to eq([3, 4])

      chunk3 = inst.next_value
      expect(chunk3.i.to_a).to eq([5, 6])
    end

    it 'maintains independent instance state' do
      proto = S(1, 2, 3)
      inst1 = proto.i
      inst2 = proto.i

      expect(inst1.next_value).to eq(1)
      expect(inst1.next_value).to eq(2)

      expect(inst2.next_value).to eq(1)
      expect(inst2.next_value).to eq(2)
    end

    it 'handles infinite series with max_size' do
      infinite = FOR(from: 0, step: 1)
      limited = infinite.max_size(10)

      result = limited.i.to_a
      expect(result).to eq([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
    end

    it 'combines H and with operations' do
      pitches = S(60, 64, 67)
      durations = S(1r, 0.5r, 0.5r)
      velocities = S(96, 80, 64)

      notes = H(pitch: pitches, duration: durations, velocity: velocities)
      result = notes.i.to_a

      expect(result.size).to eq(3)
      expect(result[0]).to eq({pitch: 60, duration: 1r, velocity: 96})
      expect(result[1]).to eq({pitch: 64, duration: 0.5r, velocity: 80})
      expect(result[2]).to eq({pitch: 67, duration: 0.5r, velocity: 64})
    end
  end
end
