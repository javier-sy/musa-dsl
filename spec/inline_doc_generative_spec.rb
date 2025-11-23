require 'spec_helper'
require 'musa-dsl'

RSpec.describe 'Generative Subsystem Inline Documentation' do
  context 'Markov' do
    it 'demonstrates equal probability transitions' do
      markov = Musa::Markov::Markov.new(
        start: :a,
        finish: :x,
        transitions: {
          a: [:b, :c],      # 50/50 chance
          b: [:a, :c],
          c: [:a, :b, :x]
        }
      ).i

      result = markov.to_a
      expect(result).to be_an(Array)
      expect(result.first).to eq(:a)
      expect(result.last).to eq(:x)
    end

    it 'demonstrates weighted probability transitions' do
      markov = Musa::Markov::Markov.new(
        start: :a,
        finish: :x,
        transitions: {
          a: { b: 0.2, c: 0.8 },  # 20% b, 80% c
          b: { a: 0.3, c: 0.7 },  # 30% a, 70% c
          c: [:a, :b, :x]         # Equal probability
        }
      ).i

      result = markov.to_a
      expect(result).to be_an(Array)
      expect(result.first).to eq(:a)
      expect(result.last).to eq(:x)
    end

    it 'demonstrates algorithmic transitions with history' do
      markov = Musa::Markov::Markov.new(
        start: :a,
        finish: :x,
        transitions: {
          a: { b: 0.2, c: 0.8 },
          # Transition based on history length
          b: proc { |history| history.size.even? ? :a : :c },
          c: [:a, :b, :x]
        }
      ).i

      result = markov.to_a
      expect(result).to be_an(Array)
      expect(result.first).to eq(:a)
      expect(result.last).to eq(:x)
    end

    it 'demonstrates musical pitch transitions' do
      # Create melodic sequence with style-based transitions
      melody = Musa::Markov::Markov.new(
        start: 60,  # Middle C
        finish: nil,  # Infinite
        transitions: {
          60 => { 62 => 0.4, 64 => 0.3, 59 => 0.3 },  # C → D/E/B
          62 => { 60 => 0.3, 64 => 0.4, 67 => 0.3 },  # D → C/E/G
          64 => [60, 62, 65, 67],                      # E → C/D/F/G
          59 => [60, 62],                              # B → C/D
          65 => [64, 67],                              # F → E/G
          67 => [64, 65, 60]                           # G → E/F/C
        }
      ).i.max_size(16).to_a

      expect(melody).to be_an(Array)
      expect(melody.size).to eq(16)
      expect(melody.first).to eq(60)
    end
  end

  context 'Darwin' do
    it 'demonstrates basic selection with features and dimensions' do
      darwin = Musa::Darwin::Darwin.new do
        measures do |object|
          # Kill objects with unwanted property
          die if object[:bad_property]

          # Binary features
          feature :has_alpha if object[:type] == :alpha
          feature :has_beta if object[:type] == :beta

          # Numeric dimension (negative to prefer lower values)
          dimension :complexity, -object[:complexity].to_f
        end

        # Weight contributions to fitness
        weight complexity: 2.0, has_alpha: 1.0, has_beta: -0.5
      end

      population = [
        { type: :alpha, complexity: 5 },
        { type: :beta, complexity: 3 },
        { type: :alpha, complexity: 2 },
        { type: :beta, complexity: 8, bad_property: true }
      ]

      selected = darwin.select(population)

      expect(selected).to be_an(Array)
      expect(selected.size).to eq(3)  # One excluded by die
      expect(selected.none? { |o| o[:bad_property] }).to be true
    end

    it 'demonstrates musical chord progression selection' do
      # Helper functions for progression analysis
      has_parallel_fifths = ->(progression) { false }  # Simplified for example
      # Create different values for different progressions
      total_voice_leading_distance = ->(progression) {
        case progression
        when [:I, :IV, :V, :I] then 8.0
        when [:I, :ii, :V, :I] then 6.0
        when [:I, :vi, :IV, :I] then 10.0
        else progression.size * 2.0
        end
      }
      ends_with_V_I = ->(progression) { progression.last == :I && progression[-2] == :V }
      ends_with_IV_I = ->(progression) { progression.last == :I && progression[-2] == :IV }
      count_chromatic_notes = ->(progression) { 0 }  # Simplified

      darwin = Musa::Darwin::Darwin.new do
        measures do |progression|
          # Eliminate progressions with parallel fifths
          die if has_parallel_fifths.call(progression)

          # Prefer smooth voice leading (use different values to create range)
          dimension :voice_leading, -total_voice_leading_distance.call(progression).to_f

          # Prefer certain cadences
          feature :authentic_cadence if ends_with_V_I.call(progression)
          feature :plagal_cadence if ends_with_IV_I.call(progression)

          # Add progression length dimension to create proper range
          dimension :length, progression.size.to_f
        end

        weight voice_leading: 3.0,
               authentic_cadence: 2.0,
               plagal_cadence: 1.0,
               length: 0.1
      end

      candidates = [
        [:I, :IV, :V, :I],
        [:I, :ii, :V, :I],
        [:I, :vi, :IV, :I]
      ]

      best = darwin.select(candidates)

      expect(best).to be_an(Array)
      expect(best.size).to eq(3)
    end
  end

  context 'Variatio' do
    it 'demonstrates basic field variations' do
      variatio = Musa::Variatio::Variatio.new :chord do
        field :root, [60, 64, 67]     # C, E, G
        field :type, [:major, :minor]

        constructor do |root:, type:|
          { root: root, type: type }
        end
      end

      variations = variatio.run

      expect(variations.size).to eq(6)  # 3 roots × 2 types
      expect(variations).to include({ root: 60, type: :major })
      expect(variations).to include({ root: 67, type: :minor })
    end

    it 'demonstrates override field options at runtime' do
      variatio = Musa::Variatio::Variatio.new :object do
        field :a, 1..10
        field :b, [:alfa, :beta, :gamma]

        constructor { |a:, b:| { a: a, b: b } }
      end

      # Override :a to limit variations
      limited = variatio.on(a: 1..3)

      expect(limited.size).to eq(9)  # 3 × 3 instead of 10 × 3 = 30
    end

    it 'demonstrates nested fieldsets with attributes' do
      variatio = Musa::Variatio::Variatio.new :synth do
        field :wave, [:saw, :square]
        field :cutoff, [500, 1000, 2000]

        constructor do |wave:, cutoff:|
          { wave: wave, cutoff: cutoff, lfo: {} }
        end

        # Nested fieldset for LFO parameters
        fieldset :lfo, [:vibrato, :tremolo] do
          field :rate, [4, 8]
          field :depth, [0.1, 0.5]

          with_attributes do |synth:, lfo:, rate:, depth:|
            synth[:lfo][lfo] = { rate: rate, depth: depth }
          end
        end
      end

      variations = variatio.run

      # 2 waves × 3 cutoffs × 2 lfo types × 2 rates × 2 depths = 96 variations
      # (each lfo type creates separate variation, not nested replacement)
      expect(variations.size).to eq(96)
      expect([:saw, :square]).to include(variations.first[:wave])
      expect(variations.first[:lfo]).to be_a(Hash)
    end

    it 'demonstrates with finalize block' do
      variatio = Musa::Variatio::Variatio.new :note do
        field :pitch, [60, 62, 64]
        field :velocity, [64, 96, 127]

        constructor { |pitch:, velocity:| { pitch: pitch, velocity: velocity } }

        finalize do |note:|
          note[:loudness] = note[:velocity] / 127.0
          note[:dynamics] = case note[:velocity]
            when 0..48 then :pp
            when 49..80 then :mf
            else :ff
          end
        end
      end

      variations = variatio.run

      expect(variations.size).to eq(9)  # 3 × 3
      variations.each do |note|
        expect(note[:loudness]).to be_a(Float)
        expect([:pp, :mf, :ff]).to include(note[:dynamics])
      end
    end
  end

  context 'Rules' do
    # Simplified to match the working docs example pattern
    it 'demonstrates chord voicing generation with Rules' do
      rules = Musa::Rules::Rules.new do
        # Step 1: Choose root note
        grow 'add root' do |seed|
          [60, 64, 67].each { |root| branch [root] }  # C, E, G
        end

        # Step 2: Add third (major or minor)
        grow 'add third' do |chord|
          branch chord + [chord[0] + 4]  # Major third
          branch chord + [chord[0] + 3]  # Minor third
        end

        # Step 3: Add fifth
        grow 'add fifth' do |chord|
          branch chord + [chord[0] + 7]
        end

        # End after three notes
        ended_when do |chord|
          chord.size == 3
        end
      end

      tree = rules.apply(0)  # seed value (triggers generation)
      voicings = tree.fish  # Extract final voicings

      expect(voicings).to be_an(Array)
      expect(voicings.size).to eq(6)  # 3 roots × 2 thirds × 1 fifth
      expect(voicings).to include([60, 64, 67])  # C major
      expect(voicings).to include([60, 63, 67])  # C minor
    end

    it 'demonstrates melodic generation with pruning rules' do
      rules = Musa::Rules::Rules.new do
        grow 'choose starting pitch' do |seed|
          branch([60])  # Start with C4
        end

        grow 'add second pitch' do |melody|
          [-2, 2].each do |interval|
            branch melody + [melody.last + interval]
          end
        end

        grow 'add third pitch' do |melody|
          [-2, 2].each do |interval|
            branch melody + [melody.last + interval]
          end
        end

        grow 'add fourth pitch' do |melody|
          [-2, 2].each do |interval|
            branch melody + [melody.last + interval]
          end
        end

        cut 'out of range' do |melody|
          prune if melody.last < 56 || melody.last > 68
        end

        ended_when do |melody|
          melody.size == 4
        end
      end

      tree = rules.apply(0)
      melodies = tree.fish

      expect(melodies).to be_an(Array)
      expect(melodies.size).to be > 0
      melodies.each do |melody|
        expect(melody.size).to eq(4)
        expect(melody.first).to eq(60)
        expect(melody.all? { |p| p >= 56 && p <= 68 }).to be true
      end
    end

    it 'demonstrates rhythm pattern generation with parameters' do
      rules = Musa::Rules::Rules.new do
        grow 'start pattern' do |seed|
          [1/2r, 1/4r].each { |dur| branch [dur] }
        end

        grow 'add duration' do |pattern, max_sum:|
          [1/2r, 1/4r].each do |dur|
            branch pattern + [dur] if pattern.sum + dur <= max_sum
          end
        end

        ended_when do |pattern, max_sum:|
          pattern.sum == max_sum
        end
      end

      tree = rules.apply(0, max_sum: 1r)
      patterns = tree.fish

      expect(patterns).to be_an(Array)
      expect(patterns.size).to be > 0
      patterns.each do |pattern|
        expect(pattern.sum).to eq(1r)
      end
    end
  end

  context 'GenerativeGrammar' do
    include Musa::GenerativeGrammar

    it 'demonstrates simple sequence with alternatives' do
      a = N('a', size: 1)
      b = N('b', size: 1)
      c = N('c', size: 1)

      # Grammar: (a or b) repeated 3 times, then c
      grammar = (a | b).repeat(3) + c

      # Generate all possibilities
      result = grammar.options(content: :join)

      expect(result).to be_an(Array)
      expect(result.size).to eq(8)  # 2^3 = 8
      expect(result).to include("aaac")
      expect(result).to include("bbbc")
    end

    it 'demonstrates grammar with constraints' do
      a = N('a', size: 1)
      b = N('b', size: 1)

      # Limit: total size must equal 3
      grammar = (a | b).repeat.limit { |o| o.collect { |_| _.attributes[:size] }.sum == 3 }

      # Filter options where size <= 4
      result = grammar.options(content: :join) { |o| o.collect { |e| e.attributes[:size] }.sum <= 4 }

      expect(result).to be_an(Array)
      expect(result.size).to eq(8)  # aaa, aab, aba, abb, baa, bab, bba, bbb
      expect(result).to include("aaa")
      expect(result).to include("bbb")
    end

    it 'demonstrates recursive grammar using proxy nodes' do
      a = N('a', size: 1)
      b = N('b', size: 1)
      c = N('c', size: 1)

      # Create proxy for recursion
      dp = PN()

      # Grammar: (c + dp) or (a or b), limit size to 3
      d = (c + dp | (a | b)).repeat.limit(:size, :sum, :==, 3)

      # Assign recursive reference
      dp.node = d

      result = d.options(:size, :sum, :<=, 4, content: :join)

      expect(result).to be_an(Array)
      expect(result.size).to be > 0
      expect(result).to include("cca")
      expect(result).to include("ccb")
    end

    it 'demonstrates block nodes for dynamic content' do
      a = N(color: :blue) { |parent| 'hola' }
      b = N(color: :red) { |parent, attributes|
        Musa::GenerativeGrammar::OptionElement.new('adios', attributes)
      }

      grammar = (a | b).repeat(2)
      result = grammar.options

      expect(result).to be_an(Array)
      expect(result.size).to eq(4)  # 2^2 = 4
      expect(result).to include(["hola", "hola"])
      expect(result).to include(["adios", "adios"])
    end
  end
end
