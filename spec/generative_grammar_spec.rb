require 'spec_helper'

require 'musa-dsl'

include Musa::GenerativeGrammar

RSpec.describe Musa do
  context 'Generative grammar' do
    it 'Node repetition with min and max limit' do
      a = N("a") + N("b")

      ar = a.next(a.next(a.repeat(max: 2))).options(raw: true)

      br = a.repeat(min: 2, max: 4).options(raw: true)

      expect(ar).to eq br
    end

    it 'Simple grammar, using | and + operators, repeat and condition limit' do
      a = N("a", length: 1/8r + 1/8r)
      b = N("b", length: 1/4r + 1/4r + 1/8r)
      c = N("c", length: 1/8r + 1/8r + 1/4r)

      m = a | b

      a = m.repeat + c

      options = a.options(raw: true) { |o| o.collect { |e| e.attributes[:length] }.sum <= 2.0 }
                    .select { |o| o.collect { |e| e.attributes[:length] }.sum == 2.0 }
                    .collect { |o| [o.collect { |e| e.content }, o.collect { |e| e.attributes[:length] }.sum] }

      expect(options).to eq [[["a", "a", "a", "a", "a", "a", "c"], 2],
                             [["a", "b", "b", "c"], 2],
                             [["b", "a", "b", "c"], 2],
                             [["b", "b", "a", "c"], 2]]
    end

    it 'Simple grammar with BlockNodes and fixed repetition' do
      a = N(color: :blue) { |parent| 'hola'}
      b = N(color: :red) { |parent, attributes| OptionElement.new('adios', final: true, **attributes) }
      c = N(color: :yellow) { |parent| 'cosa' }

      d = (a | b | c).repeat(4)

      dd = d.options

      expect(dd.length).to eq 3 * 3 * 3 * 3

      expect(dd[0]).to eq ["hola", "hola", "hola", "hola"]
      expect(dd[1]).to eq ["hola", "hola", "hola", "adios"]
      expect(dd[2]).to eq ["hola", "hola", "hola", "cosa"]
      expect(dd[3]).to eq ["hola", "hola", "adios", "hola"]
      expect(dd[4]).to eq ["hola", "hola", "adios", "adios"]

      expect(dd.last).to eq ["cosa", "cosa", "cosa", "cosa"]
    end

    it 'Simple grammar with limit on a node' do
      a = N('a', size: 1)
      b = N('b', size: 1)

      c = (a | b).repeat.limit { |o| o.collect { |_| _.attributes[:size] }.sum == 3 }

      cc = c.options(content: :join) { |o| o.collect { |e| e.attributes[:size] }.sum <= 4 }

      expect(cc).to eq ["aaa", "aab", "aba", "abb", "baa", "bab", "bba", "bbb"]
    end

    it 'Simple grammar, using simplified methods for filtering and retrieving' do
      a = N('a', size: 1)
      b = N('b', size: 1)

      c = (a | b).repeat.limit(:size, :sum, :==, 3)

      cc = c.options(:size, :sum, :<=, 4, content: :join)

      expect(cc).to eq ["aaa", "aab", "aba", "abb", "baa", "bab", "bba", "bbb"]
    end

    it 'Simple recursive grammar' do
      a = N('a', size: 1)
      b = N('b', size: 1)
      c = N('c', size: 1)

      d = (c + (dp = PN()) | (a | b)).repeat.limit(:size, :sum, :==, 3)
      dp.node = d

      dd = d.options(:size, :sum, :<=, 4, content: :join)

      expect(dd).to eq ["cca", "ccb", "caa", "cab", "cba", "cbb", "aca", "acb", "aaa", "aab", "aba", "abb", "bca", "bcb", "baa", "bab", "bba", "bbb"]
    end

    it 'Simple repeating' do
      a = N('a')
      b = N('b')
      c = N('c')

      d = (a | b).repeat(3) + c

      dd = d.options(content: :join)

      expect(dd).to eq ["aaac", "aabc", "abac", "abbc", "baac", "babc", "bbac", "bbbc"]
    end
  end

end
