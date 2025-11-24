require 'spec_helper'
require 'musa-dsl'

RSpec.describe 'Series Composer Inline Documentation Examples' do
  include Musa::All

  context 'Composer class - Pipeline Definition' do
    it 'example from line 154 - Pipeline with constructor' do
      composer = Musa::Series::Composer::Composer.new(inputs: nil) do
        my_pipeline ({ S: [1, 2, 3] }), reverse, { skip: 1 }
        route my_pipeline, to: output
      end
      expect(composer.output.i.to_a).to eq([2, 1])
    end

    it 'example from line 162 - Pipeline with operations only' do
      composer = Musa::Series::Composer::Composer.new(input: S(1, 2, 3)) do
        my_pipeline reverse, { skip: 1 }
        route input, to: my_pipeline
        route my_pipeline, to: output
      end
      expect(composer.output.i.to_a).to eq([2, 1])
    end
  end

  context 'Composer class - Routing System' do
    it 'example from line 191 - Hash routing' do
      composer = Musa::Series::Composer::Composer.new(inputs: [:a, :b], auto_commit: false) do
        step1 reverse
        step2 reverse
        hash_merge ({ H: {} })

        route a, to: step1
        route b, to: step2
        route step1, to: hash_merge, as: :x
        route step2, to: hash_merge, as: :y
        route hash_merge, to: output
      end

      composer.input(:a).proxy_source = S(1, 2, 3)
      composer.input(:b).proxy_source = S(10, 20, 30)
      composer.commit!
      expect(composer.output.i.to_a).to eq([{x: 3, y: 30}, {x: 2, y: 20}, {x: 1, y: 10}])
    end

    it 'example from line 209 - Setter routing' do
      composer = Musa::Series::Composer::Composer.new(input: S(1, 2, 3)) do
        step1 reverse
        route input, to: step1
        route step1, to: output
      end

      expect(composer.output.i.to_a).to eq([3, 2, 1])
    end
  end

  context 'Composer class - Basic Examples' do
    it 'example from line 241 - Basic pipeline' do
      composer = Musa::Series::Composer::Composer.new(input: S(1, 2, 3)) do
        step1 reverse
        route input, to: step1
        route step1, to: output
      end
      expect(composer.output.i.to_a).to eq([3, 2, 1])
    end

    it 'example from line 248 - Multiple inputs merging' do
      composer = Musa::Series::Composer::Composer.new(inputs: { a: S(1, 2), b: S(10, 20) }) do
        hash_merge ({ H: {} })
        route a, to: hash_merge, as: :x
        route b, to: hash_merge, as: :y
        route hash_merge, to: output
      end
      expect(composer.output.i.to_a).to eq([{x: 1, y: 10}, {x: 2, y: 20}])
    end

    it 'example from line 257 - Multiple outputs' do
      composer = Musa::Series::Composer::Composer.new(input: S(1, 2, 3)) do
        doubled ({ eval: ->(v) { v * 2 } })
        tripled ({ eval: ->(v) { v * 3 } })

        route input, to: doubled
        route input, to: tripled
        route doubled, to: output
      end
      expect(composer.output.i.to_a).to eq([2, 4, 6])
    end

    it 'example from line 268 - Complex routing' do
      composer = Musa::Series::Composer::Composer.new(inputs: [:a, :b], auto_commit: false) do
        step1 reverse
        step2 ({ skip: 1 })
        hash_merge ({ H: {} })

        route a, to: step1
        route b, to: step2
        route step1, to: hash_merge, as: :x
        route step2, to: hash_merge, as: :y
        route hash_merge, to: output
      end

      composer.input(:a).proxy_source = S(1, 2, 3)
      composer.input(:b).proxy_source = S(10, 20, 30)
      composer.commit!

      expect(composer.output.i.to_a).to eq([{x: 3, y: 20}, {x: 2, y: 30}])
    end
  end

  context 'Method: input' do
    it 'example from line 345 - Set input source dynamically' do
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
    it 'example from line 373 - Access output' do
      composer = Musa::Series::Composer::Composer.new(input: S(1, 2, 3)) do
        step reverse
        route input, to: step
        route step, to: output
      end

      expect(composer.output.i.to_a).to eq([3, 2, 1])
    end

    it 'example from line 376 - Multiple outputs' do
      composer = Musa::Series::Composer::Composer.new(input: S(1, 2, 3)) do
        doubled ({ eval: ->(v) { v * 2 } })
        tripled ({ eval: ->(v) { v * 3 } })

        route input, to: doubled
        route input, to: tripled
        route doubled, to: output
      end

      expect(composer.output.i.to_a).to eq([2, 4, 6])
      # Note: The original example shows accessing :doubled and :tripled outputs
      # but this composer only has one output, so we only test the main output
    end
  end

  context 'Method: route' do
    it 'example from line 413 - Hash routing (inside DSL block)' do
      composer = Musa::Series::Composer::Composer.new(inputs: [:a, :b], auto_commit: false) do
        step1 reverse
        step2 reverse
        hash_merge ({ H: {} })

        route a, to: step1
        route b, to: step2
        route step1, to: hash_merge, as: :x
        route step2, to: hash_merge, as: :y
        route hash_merge, to: output
      end

      composer.input(:a).proxy_source = S(1, 2)
      composer.input(:b).proxy_source = S(10, 20)
      composer.commit!
      expect(composer.output.i.to_a).to eq([{x: 2, y: 20}, {x: 1, y: 10}])
    end

    it 'example from line 431 - Setter routing (inside DSL block)' do
      composer = Musa::Series::Composer::Composer.new(input: S(1, 2, 3)) do
        step reverse
        route input, to: step
        route step, to: output
      end

      expect(composer.output.i.to_a).to eq([3, 2, 1])
    end

    it 'example from line 440 - Custom on parameter (inside DSL block)' do
      composer = Musa::Series::Composer::Composer.new(input: S(1, 2, 3), auto_commit: false) do
        step reverse
        hash_merge ({ H: {} })
        route input, to: step
        route step, to: hash_merge, on: :sources, as: :x  # Fixed: on: :sources (not :source)
        route hash_merge, to: output
      end

      composer.commit!
      expect(composer.output.i.to_a).to eq([{x: 3}, {x: 2}, {x: 1}])
    end
  end

  context 'Method: pipeline' do
    it 'example from line 467 - Direct call (inside DSL block)' do
      composer = Musa::Series::Composer::Composer.new(inputs: nil) do
        pipeline(:my_step, [{ S: [1, 2, 3] }, :reverse])  # Fixed: elements as array
        route my_step, to: output
      end

      expect(composer.output.i.to_a).to eq([3, 2, 1])
    end

    it 'example from line 475 - DSL equivalent (method_missing)' do
      composer = Musa::Series::Composer::Composer.new(inputs: nil) do
        my_step ({ S: [1, 2, 3] }), reverse
        route my_step, to: output
      end

      expect(composer.output.i.to_a).to eq([3, 2, 1])
    end
  end

  context 'Method: update' do
    it 'example from line 498 - Add routes dynamically' do
      composer = Musa::Series::Composer::Composer.new(input: S(1, 2, 3), auto_commit: false) do
        step1 reverse
        step2 ({ skip: 1 })

        route input, to: step1
        route step1, to: step2
      end

      # Update with additional routing
      composer.update do
        route step2, to: output
      end

      composer.commit!
      expect(composer.output.i.to_a).to eq([2, 1])
    end
  end

  context 'Method: commit!' do
    it 'example from line 524 - Manual commit' do
      composer = Musa::Series::Composer::Composer.new(auto_commit: false) do
        step reverse
        route input, to: step
        route step, to: output
      end

      composer.input.proxy_source = S(1, 2, 3)
      composer.commit!
      result = composer.output.i.to_a

      expect(result).to eq([3, 2, 1])
    end

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
    it 'example from line 1021 - DSL syntax demonstration' do
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
