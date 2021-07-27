require 'spec_helper'

require 'musa-dsl'

include Musa::Series::Composer
include Musa::Series::Constructors

RSpec.describe Musa::Series::Composer do
  context 'Series composer' do

    it 'No input, ultra-simple 1 step output (1 symbol operation), explicit output access' do
      composer = Composer.new(inputs: nil) do
        input ({ S: [1, 2, 3, 4, 5] })

        step1 reverse

        route input, to: step1
        route step1, to: output
      end

      s = composer.output(:output).i

      expect(s.to_a).to eq [5, 4, 3, 2, 1]
    end

    it 'No input, ultra-simple 1 step output (3 symbol operations)' do
      composer = Composer.new(inputs: nil) do
        input ({ S: [1, 2, 3, 4, 5] })

        step1 reverse, reverse, reverse

        route input, to: step1
        route step1, to: output
      end

      s = composer.output.i

      expect(s.to_a).to eq [5, 4, 3, 2, 1]
    end

    it 'No input, simple 1 step output (1 hash operation)' do
      composer = Composer.new(inputs: nil) do
        input ({ S: [1, 2, 3, 4, 5] })

        step1 ({ skip: 2 })

        route input, to: step1
        route step1, to: output
      end

      s = composer.output.i

      expect(s.to_a).to eq [3, 4, 5]
    end

    it 'No input, simple 1 step output (2 hash operation)' do
      composer = Composer.new(inputs: nil) do
        input ({ S: [1, 2, 3, 4, 5] })

        step1 ({ skip: 2 }), { skip: 2 }

        route input, to: step1
        route step1, to: output
      end

      s = composer.output.i

      expect(s.to_a).to eq [5]
    end

    it 'No input, simple 1 step output' do
      composer = Composer.new(inputs: nil) do
        input ({ S: [1, 2, 3, 4, 5] })

        step1 ({ skip: 2 }), { repeat: 2 }, reverse, { repeat: 2 }, reverse

        route input, to: step1
        route step1, to: output
      end

      s = composer.output.i

      expect(s.to_a).to eq [3, 4, 5, 3, 4, 5, 3, 4, 5, 3, 4, 5]
    end

    it 'No input, simple 2 step output, with proc' do
      composer = Composer.new(inputs: nil) do
        input ({ S: [1, 2, 3, 4, 5] })

        step1 ({ skip: 2 }), reverse, { repeat: 2 }, reverse
        step2 ({ eval: lambda { |v| v + 100 } })

        route input,to: step1
        route step1, to: step2
        route step2, to: output
      end

      s = composer.output.i

      expect(s.to_a).to eq [103, 104, 105, 103, 104, 105]
    end

    it 'simple external input and pipeline with only one symbol step, explicit access to input and output' do
      composer = Composer.new do
        step1 reverse

        route input, to: step1
        route step1, to: output
      end

      composer.input(:input).proxy_source = S(1, 2, 3, 4, 5)

      s = composer.output(:output).i

      expect(s.to_a(dr: false)).to eq [5, 4, 3, 2, 1]
    end

    it 'with external input' do
      composer = Composer.new do
        step1 ({ skip: 2 }), reverse, { repeat: 2 }, reverse
        step2 ({ eval: lambda { |v| v + 100 } })

        route input, to: step1
        route step1, to: step2

        route step2, to: output
      end

      composer.input.proxy_source = S(1, 2, 3, 4, 5)

      s = composer.output.i

      expect(s.to_a(dr: false)).to eq [103, 104, 105, 103, 104, 105]
    end

    it 'with two inputs merged' do
      composer = Composer.new(inputs: [:input1, :input2]) do
        step1 ({ skip: 1 }), reverse
        step2 ({ eval: lambda { |v| v + 100 } })

        fusion ({ H: {} })

        route input1, to: step1
        route input2, to: step2

        route step1, to: fusion, as: :a
        route step2, to: fusion, as: :b

        route fusion, to: output
      end

      composer.input(:input1).proxy_source = S(1, 2, 3, 4, 5, 6)
      composer.input(:input2).proxy_source = S(1, 2, 3, 4, 5)

      s = composer.output.i

      expect(s.to_a(dr: false)).to eq [{ a: 6, b: 101 }, { a: 5, b: 102 }, { a: 4, b: 103 }, { a: 3, b: 104 }, { a: 2, b: 105 }]
    end


    it 'routing a new output to a used input raises error' do
      expect {
        Composer.new do
          step1 reverse
          step2 reverse
          step3 reverse

          route input, to: step1
          route step1, to: step3
          route step2, to: step3
        end
      }.to raise_error(ArgumentError)
    end

    it 'routing again an output to a the same input raises error' do
      expect {
        Composer.new do
          step1 (reverse)
          step2 (reverse)
          step3 (reverse)

          route input, to: step1
          route step1, to: step3
          route step1, to: step3
        end
      }.to raise_error(ArgumentError)
    end

    it 'add pipelines and routing from composer object' do
      composer = Composer.new(auto_commit: false)

      composer.pipeline :step1, { skip: 2 }, :reverse, { repeat: 2 }, :reverse
      composer.pipeline :step2, { eval: lambda { |v| v + 100 } }

      composer.route :input, to: :step1
      composer.route :step1, to: :step2
      composer.route :step2, to: :output

      composer.input.proxy_source = S(1, 2, 3, 4, 5)

      composer.commit!

      s = composer.output.i

      expect(s.to_a).to eq [103, 104, 105, 103, 104, 105]
    end

    it 'add pipelines and routing with composer update' do
      composer = Composer.new(auto_commit: false)

      composer.update do
        step1 ({ skip: 2 }), reverse, { repeat: 2 }, reverse
        step2 ({ eval: lambda { |v| v + 100 } })

        route input, to: step1
        route step1, to: step2
        route step2, to: output
      end

      composer.input.proxy_source = S(1, 2, 3, 4, 5)

      composer.commit!

      s = composer.output.i

      expect(s.to_a).to eq [103, 104, 105, 103, 104, 105]
    end

    it 'with buffered routing sending input to 2 pipelines and merging the results' do
      composer = Composer.new(auto_commit: false) do
        step1 ({ skip: 2 }), reverse, { repeat: 2 }, reverse
        step2 ({ eval: lambda { |v| v + 100 } })

        integrate ({ H: {} })

        route input, to: step1
        route input, to: step2

        route step1, to: integrate, as: :a
        route step2, to: integrate, on: :sources, as: :b

        route integrate, to: output
      end

      composer.input.proxy_source = S(1, 2, 3, 4, 5)

      composer.commit!

      s = composer.output.i

      s.restart

      expect(s.to_a(duplicate: false, restart: false)).to eq [{ a: 3, b: 101 },
                                                              { a: 4, b: 102 },
                                                              { a: 5, b: 103 },
                                                              { a: 3, b: 104 },
                                                              { a: 4, b: 105 }]
    end

    it 'lambda is interpreted as { eval: lambda ... }' do
      composer = Composer.new do
        step lambda { |v| v + 100 }

        route input, to: step
        route step, to: output
      end

      composer.input.proxy_source = S(1, 2, 3, 4, 5)

      s = composer.output.i

      s.restart

      expect(s.to_a(duplicate: false, restart: false)).to eq [101, 102, 103, 104, 105]
    end

    it '{ |x| ... } is interpreted as { eval: lambda ... }' do
      composer = Composer.new do
        step { |v| v + 100 }

        route input, to: step
        route step, to: output
      end

      composer.input.proxy_source = S(1, 2, 3, 4, 5)

      s = composer.output.i

      s.restart

      expect(s.to_a(duplicate: false, restart: false)).to eq [101, 102, 103, 104, 105]
    end

    it 'normal functions (and constructors) can be used inside a pipeline within a lazy operation' do
      composer = Composer.new do
        step reverse,
             { lazy: [split, instance,
                      to_a,
                      { collect: proc { |_| _.with { |_| _ + 1000 } } },
                      { A: nil }] },
             { map: proc { |i| [i[0] + 1_000_000, i[1]] } },
             reverse

        route input, to: step
        route step, to: output
      end

      composer.input.proxy_source = S([1, 10], [2, 20], [3, 30])

      s = composer.output.i

      expect(s.to_a(duplicate: false, restart: false)).to eq [[1_001_001, 1010], [1_001_002, 1020], [1_001_003, 1030]]

      s.restart
      expect(s.to_a(duplicate: false, restart: false)).to eq [[1_001_001, 1010], [1_001_002, 1020], [1_001_003, 1030]]
    end

    it 'normal functions (and constructors) can be used inside a pipeline within a lazy operation (delayed commit)' do
      composer = Composer.new(auto_commit: false) do
        step reverse,
             { lazy: [split, instance,
                      to_a,
                      { collect: proc { |_| _.with { |_| _ + 1000 } } },
                      :A] },
             { map: proc { |i| [i[0] + 1_000_000, i[1]] } },
             reverse

        route input, to: step
        route step, to: output
      end

      composer.input.proxy_source = S([1, 10], [2, 20], [3, 30])

      composer.commit!

      s = composer.output.i

      expect(s.to_a(duplicate: false, restart: false)).to eq [[1_001_001, 1010], [1_001_002, 1020], [1_001_003, 1030]]

      s.restart
      expect(s.to_a(duplicate: false, restart: false)).to eq [[1_001_001, 1010], [1_001_002, 1020], [1_001_003, 1030]]
    end

    it 'normal functions (and constructors) can be used inside a pipeline (delayed commit)' do
      composer = Composer.new(auto_commit: false) do
        step split, instance,
             to_a,
             { collect: proc { |_| _.with { |_| _ + 1000 } } },
             :A

        route input, to: step
        route step, to: output
      end

      composer.input.proxy_source = S([1, 10], [2, 20], [3, 30])

      composer.commit!

      s = composer.output.i

      s.restart

      expect(s.to_a(duplicate: false, restart: false)).to eq [[1001, 1010], [1002, 1020], [1003, 1030]]
    end


    it 'normal functions (and constructors) can be used inside a pipeline (immediate resolution)' do
      composer = Composer.new(inputs: nil) do
        step ({ S: [[1, 10], [2, 20], [3, 30]] }),
             split, instance,
             to_a,
             { collect: lambda { |_| _.with { |_| _ + 1000 } } },
             :A

        route step, to: output
      end

      s = composer.output.i

      s.restart

      expect(s.to_a(duplicate: false, restart: false)).to eq [[1001, 1010], [1002, 1020], [1003, 1030]]
    end

    it 'normal functions (and constructors) can be used inside a pipeline (immediate resolution) with lambda simplified syntax' do
      composer = Composer.new(inputs: nil) do
        step ({ S: [[1, 10], [2, 20], [3, 30]] }),
             split, instance,
             to_a,
             { collect: { with: lambda { |_| _ + 1000 } } },
             :A

        route step, to: output
      end

      s = composer.output.i

      s.restart

      expect(s.to_a(duplicate: false, restart: false)).to eq [[1001, 1010], [1002, 1020], [1003, 1030]]
    end

  end
end
