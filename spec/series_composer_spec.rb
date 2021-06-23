require 'spec_helper'

require 'musa-dsl'

include Musa::Series::Composer
include Musa::Series::Constructors

RSpec.describe Musa::Series::Composer do

  context 'Series composer' do
    it 'No input, simple 1 step output' do
      composer = Composer.new(inputs: nil) do
        input ({ S: [1, 2, 3, 4, 5] })

        step1 ({ skip: 2 }), { repeat: 2 },  reverse, { repeat: 2 }, reverse

        route input,to: step1
        route step1, to: output
      end

      s = composer.outputs[:output].i

      expect(s.to_a).to eq [3, 4, 5, 3, 4, 5, 3, 4, 5, 3, 4, 5]
    end

    it 'No input, simple 2 step output, with proc' do
      composer = Composer.new(inputs: nil) do
        input ({ S: [1, 2, 3, 4, 5] })

        step1 ({ skip: 2 }), reverse, { repeat: 2 }, reverse
        step2 ({ eval: lambda { |v| v + 100 }})

        route input,to: step1
        route step1, to: step2
        route step2, to: output
      end

      s = composer.outputs[:output].i

      expect(s.to_a).to eq [103, 104, 105, 103, 104, 105]
    end

    it 'simple external input and pipeline with only one symbol step' do
      composer = Composer.new do
        step1 reverse

        route input, to: step1
        route step1, to: output
      end

      composer.inputs[:input].source = S(1, 2, 3, 4, 5)

      s = composer.outputs[:output].i

      expect(s.to_a(dr: false)).to eq [5, 4, 3, 2, 1]
    end

    it 'with external input' do
      composer = Composer.new do
        step1 ({ skip: 2 }), reverse, { repeat: 2 }, reverse
        step2 ({ eval: lambda { |v| v + 100 }})

        route input, to: step1
        route step1, to: step2

        route step2, to: output
      end

      composer.inputs[:input].source = S(1, 2, 3, 4, 5)

      s = composer.outputs[:output].i

      expect(s.to_a(dr: false)).to eq [103, 104, 105, 103, 104, 105]
    end

    it 'add pipelines and routing from composer object' do
      composer = Composer.new

      composer.pipeline :step1, { skip: 2 }, :reverse, { repeat: 2 }, :reverse
      composer.pipeline :step2, { eval: lambda { |v| v + 100 } }

      composer.route :input, to: :step1
      composer.route :step1, to: :step2
      composer.route :step2, to: :output

      composer.inputs[:input].source = S(1, 2, 3, 4, 5)

      s = composer.outputs[:output].i

      expect(s.to_a).to eq [103, 104, 105, 103, 104, 105]
    end

    it 'add pipelines and routing with composer update' do
      composer = Composer.new

      composer.update do
        step1 ({ skip: 2 }), reverse, { repeat: 2 }, reverse
        step2 ({ eval: lambda { |v| v + 100 }})

        route input,to: step1
        route step1, to: step2
        route step2, to: output
      end

      composer.inputs[:input].source = S(1, 2, 3, 4, 5)

      s = composer.outputs[:output].i

      expect(s.to_a).to eq [103, 104, 105, 103, 104, 105]
    end

    it 'with buffered routing sending input to 2 pipelines and merging the results' do

      composer = Composer.new do
        step1 ({ skip: 2 }), reverse, { repeat: 2 }, reverse
        step2 ({ eval: lambda { |v| v + 100 }})

        integrate ({ H: {} })

        route input, to: step1
        route input, to: step2

        route step1, to: integrate, as: :a
        route step2, to: integrate, on: :sources, as: :b

        route integrate, to: output
      end

      composer.inputs[:input].source = S(1, 2, 3, 4, 5)

      s = composer.outputs[:output].i

      s.restart

      expect(s.to_a(duplicate: false, restart: false)).to eq [{ a: 3, b: 101 },
                                                              { a: 4, b: 102 },
                                                              { a: 5, b: 103 },
                                                              { a: 3, b: 104 },
                                                              { a: 4, b: 105 }]
    end
  end
end
