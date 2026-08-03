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

RSpec.describe 'Series Composer Inline Documentation Examples' do
  include Musa::All

  context 'Composer class - Pipeline Definition' do

  end

  context 'Composer class - Routing System' do

  end

  context 'Composer class - Basic Examples' do

  end

  context 'Method: input' do
    it '@example Set input source dynamically' do
      composer = Musa::Series::Composer::Composer.new(auto_commit: false) do
        step reverse
        route input, to: step
        route step, to: output
      end

      composer.input.proxy_source = S(1, 2, 3)
      composer.commit!

      # The example doesn't show expected output, but we can verify it works
      expect(composer.output.i.to_a).to eq([3, 2, 1])
    end
  end

  context 'Method: output' do

    it 'example - Several outputs' do
      composer = Musa::Series::Composer::Composer.new(input: Musa::Series::Constructors.S(1, 2, 3),
                                                      outputs: [:doubled, :tripled]) do
        step_d({ map: ->(x) { x * 2 } })
        step_t({ map: ->(x) { x * 3 } })

        route input, to: step_d
        route input, to: step_t
        route step_d, to: doubled
        route step_t, to: tripled
      end

      expect(composer.output(:doubled).i.to_a).to eq([2, 4, 6])
      expect(composer.output(:tripled).i.to_a).to eq([3, 6, 9])
    end
  end

  context 'Method: route' do

  end

  context 'Method: pipeline' do

  end

  context 'Method: update' do
  end

  context 'Method: commit!' do

    it 'verifies output is blocked before commit' do
      composer = Musa::Series::Composer::Composer.new(auto_commit: false) do
        step reverse
        route input, to: step
        route step, to: output
      end

      composer.input.proxy_source = S(1, 2, 3)

      # Should raise error before commit
      expect { composer.output }.to raise_error(RuntimeError, /uncommited/)

      # After commit, should work
      composer.commit!
      expect(composer.output.i.to_a).to eq([3, 2, 1])
    end
  end

  context 'DSL: method_missing' do
    it 'DSL syntax demonstration' do
      composer = Musa::Series::Composer::Composer.new(input: S(1, 2, 3)) do
        # `reverse` → returns :reverse (operation symbol)
        # `my_step reverse, { skip: 1 }` → creates pipeline named :my_step
        # `route input, to: step1` → uses :step1 symbol for routing

        my_step reverse, { skip: 1 }
        route input, to: my_step
        route my_step, to: output
      end

      expect(composer.output.i.to_a).to eq([2, 1])
    end
  end

  context 'Integration: Composer as operation' do
    it 'can be used as a serie operation via composer method' do
      # Test the ComposerAsOperationSerie wrapper
      serie = S(1, 2, 3).composer do
        step reverse
        route input, to: step
        route step, to: output
      end

      expect(serie.i.to_a).to eq([3, 2, 1])
    end

    it 'works in serie chains' do
      result = S(1, 2, 3, 4)
        .composer do
          step ({ skip: 1 })
          route input, to: step
          route step, to: output
        end
        .map { |v| v * 10 }
        .i.to_a

      expect(result).to eq([20, 30, 40])
    end
  end

  context 'Advanced routing scenarios' do
    it 'handles multiple sources into single pipeline' do
      composer = Musa::Series::Composer::Composer.new(inputs: [:a, :b, :c], auto_commit: false) do
        hash_merge ({ H: {} })

        route a, to: hash_merge, as: :x
        route b, to: hash_merge, as: :y
        route c, to: hash_merge, as: :z
        route hash_merge, to: output
      end

      composer.input(:a).proxy_source = S(1, 2)
      composer.input(:b).proxy_source = S(10, 20)
      composer.input(:c).proxy_source = S(100, 200)
      composer.commit!

      expect(composer.output.i.to_a).to eq([
        {x: 1, y: 10, z: 100},
        {x: 2, y: 20, z: 200}
      ])
    end

    it 'handles pipeline chains with transformations' do
      composer = Musa::Series::Composer::Composer.new(input: S(1, 2, 3, 4)) do
        step1 ({ skip: 1 })
        step2 reverse
        step3 ({ max_size: 2 })

        route input, to: step1
        route step1, to: step2
        route step2, to: step3
        route step3, to: output
      end

      # S(1,2,3,4) → skip(1) → [2,3,4] → reverse → [4,3,2] → max_size(2) → [4,3]
      expect(composer.output.i.to_a).to eq([4, 3])
    end

    it 'allows single input to fan out to multiple pipelines' do
      composer = Musa::Series::Composer::Composer.new(input: S(1, 2, 3), auto_commit: false) do
        doubled ({ eval: ->(v) { v * 2 } })
        tripled ({ eval: ->(v) { v * 3 } })
        hash_merge ({ H: {} })

        route input, to: doubled
        route input, to: tripled
        route doubled, to: hash_merge, as: :x
        route tripled, to: hash_merge, as: :y
        route hash_merge, to: output
      end

      composer.commit!
      expect(composer.output.i.to_a).to eq([
        {x: 2, y: 3},
        {x: 4, y: 6},
        {x: 6, y: 9}
      ])
    end
  end

  context 'Edge cases and error handling' do
    it 'raises error when accessing output before commit' do
      composer = Musa::Series::Composer::Composer.new(auto_commit: false) do
        step reverse
        route input, to: step
        route step, to: output
      end

      expect { composer.output }.to raise_error(RuntimeError, /uncommited/)
    end

    it 'raises error when committing twice' do
      composer = Musa::Series::Composer::Composer.new(auto_commit: false) do
        step reverse
        route input, to: step
        route step, to: output
      end

      composer.input.proxy_source = S(1, 2, 3)
      composer.commit!

      expect { composer.commit! }.to raise_error(RuntimeError, /Already commited/)
    end

    it 'raises error when routing from nonexistent pipeline' do
      expect {
        Musa::Series::Composer::Composer.new(input: S(1, 2, 3)) do
          step reverse
          route nonexistent, to: step  # nonexistent pipeline
          route step, to: output
        end
      }.to raise_error(ArgumentError, /not found/)
    end

    it 'raises error when routing to nonexistent pipeline' do
      expect {
        Musa::Series::Composer::Composer.new(input: S(1, 2, 3)) do
          step reverse
          route input, to: nonexistent  # nonexistent pipeline
          route step, to: output
        end
      }.to raise_error(ArgumentError, /not found/)
    end

    it 'raises error when creating duplicate routes' do
      expect {
        Musa::Series::Composer::Composer.new(inputs: [:a, :b], auto_commit: false) do
          step reverse
          hash_merge ({ H: {} })

          route a, to: hash_merge, as: :x
          route b, to: hash_merge, as: :x  # Duplicate key :x
          route hash_merge, to: output
        end
      }.to raise_error(ArgumentError, /already connected/)
    end
  end

  context 'Constructor handling' do
    it 'handles S constructor with array parameter' do
      composer = Musa::Series::Composer::Composer.new(inputs: nil) do
        my_serie ({ S: [10, 20, 30] })
        route my_serie, to: output
      end

      expect(composer.output.i.to_a).to eq([10, 20, 30])
    end

    it 'handles H constructor with hash parameter' do
      # Create series outside DSL context
      s1 = S(1, 2)
      s2 = S(10, 20)

      composer = Musa::Series::Composer::Composer.new(inputs: nil) do
        my_hash ({ H: { a: s1, b: s2 } })  # Reference series from outer scope
        route my_hash, to: output
      end

      expect(composer.output.i.to_a).to eq([{a: 1, b: 10}, {a: 2, b: 20}])
    end

    it 'combines constructor with operations' do
      composer = Musa::Series::Composer::Composer.new(inputs: nil) do
        my_serie ({ S: [1, 2, 3, 4] }), reverse, { skip: 1 }
        route my_serie, to: output
      end

      # S(1,2,3,4) → reverse → [4,3,2,1] → skip(1) → [3,2,1]
      expect(composer.output.i.to_a).to eq([3, 2, 1])
    end
  end
end
