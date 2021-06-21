require 'spec_helper'

require 'musa-dsl'

include Musa::Series::Composer
include Musa::Series::Constructors

RSpec.describe Musa::Series::Composer do
  using Musa::Extension::DeepCopy
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

    it 'with external input' do
      composer = Composer.new do
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

    it 'add pipelines and routing from composer object' do
      composer = Composer.new

      composer.pipeline :step1, { skip: 2 }, :reverse, { repeat: 2 }, :reverse
      composer.pipeline :step2, { eval: lambda { |v| v + 100 }}

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


# VOY POR AQUI    distribución de las salidas en route to...


=begin
    it '' do
      x.update do

        route input, to: s, as: [:with_sources, 10]

      end
    end
=end
  end
end