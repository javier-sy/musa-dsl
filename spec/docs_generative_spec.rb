require 'docs_helper'

using Musa::Extension::Neumas
using Musa::Extension::Matrix

RSpec.describe 'Generative Documentation Examples' do

  context 'Generative - Algorithmic Composition' do
    it 'creates Markov chain for probabilistic sequence generation' do
      markov = Musa::Markov::Markov.new(
        start: 0,
        finish: :end,
        transitions: {
          0 => { 2 => 0.5, 4 => 0.3, 7 => 0.2 },
          2 => { 0 => 0.3, 4 => 0.5, 5 => 0.2 },
          4 => { 2 => 0.4, 5 => 0.4, 7 => 0.2 },
          5 => { 0 => 0.5, :end => 0.5 },
          7 => { 0 => 0.6, :end => 0.4 }
        }
      ).i

      # Generate melody pitches (Markov is a Serie, so we can use .to_a)
      melody_pitches = markov.to_a

      expect(melody_pitches).to be_an(Array)
      expect(melody_pitches.size).to be > 0
      expect([0, 2, 4, 5, 7]).to include(melody_pitches[0])
    end

    it 'uses Variatio for Cartesian product of parameter variations' do
      # Variatio - Cartesian product of parameter variations
      # Generates ALL combinations of field values
      variatio = Musa::Variatio::Variatio.new :chord do
        field :root, [60, 64, 67]     # C, E, G
        field :type, [:major, :minor]

        constructor do |root:, type:|
          { root: root, type: type }
        end
      end

      all_chords = variatio.run

      # 3 roots × 2 types = 6 variations
      expect(all_chords).to be_an(Array)
      expect(all_chords.size).to eq(6)

      expect(all_chords).to include({ root: 60, type: :major })
      expect(all_chords).to include({ root: 60, type: :minor })
      expect(all_chords).to include({ root: 64, type: :major })
      expect(all_chords).to include({ root: 64, type: :minor })
      expect(all_chords).to include({ root: 67, type: :major })
      expect(all_chords).to include({ root: 67, type: :minor })

      # Override field values at runtime
      limited_chords = variatio.on(root: [60, 64])
      # 2 roots × 2 types = 4 variations
      expect(limited_chords.size).to eq(4)
      expect(limited_chords).to include({ root: 60, type: :major })
      expect(limited_chords).to include({ root: 60, type: :minor })
      expect(limited_chords).to include({ root: 64, type: :major })
      expect(limited_chords).to include({ root: 64, type: :minor })
    end

    it 'generates chord voicings using Rules production system' do
      # Build chord voicings by adding notes sequentially
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

        # Pruning rule: avoid wide intervals
        cut 'no wide spacing' do |chord|
          if chord.size >= 2
            prune if (chord[-1] - chord[-2]) > 12  # Max octave between adjacent notes
          end
        end

        # End after three notes
        ended_when do |chord|
          chord.size == 3
        end
      end

      tree = rules.apply(0)  # seed value (triggers generation)
      combinations = tree.combinations

      expect(combinations).to be_an(Array)
      expect(combinations.size).to eq(6)  # 3 roots × 2 thirds × 1 fifth = 6 voicings

      # Extract voicings from combinations (last element of each path)
      voicings = combinations.map { |path| path.last }

      # All voicings should have 3 notes
      expect(voicings.all? { |v| v.size == 3 }).to be true

      # Should include specific voicings
      expect(voicings).to include([60, 64, 67])  # C major
      expect(voicings).to include([60, 63, 67])  # C minor

      # With parameters
      tree_with_params = rules.apply(0, max_interval: 7)
      expect(tree_with_params).to respond_to(:combinations)
      expect(tree_with_params.combinations).to be_an(Array)
    end

    it 'generates combinations using Generative Grammar with operators' do
      # Use GenerativeGrammar module methods directly
      a = Musa::GenerativeGrammar.N('a', size: 1)
      b = Musa::GenerativeGrammar.N('b', size: 1)
      c = Musa::GenerativeGrammar.N('c', size: 1)
      d = b | c  # d can be either b or c

      # Grammar: (a or d) repeated 3 times, then c
      grammar = (a | d).repeat(3) + c

      # Generate all possibilities
      result = grammar.options(content: :join)

      expect(result).to be_an(Array)
      expect(result.size).to eq(27)  # 3^3 × 1 = 27 combinations

      # Should include specific combinations
      expect(result).to include("aaac")
      expect(result).to include("abac")
      expect(result).to include("acac")
      expect(result).to include("cccc")

      # With constraints - filter by attribute
      grammar_with_limit = (a | d).repeat(min: 1, max: 4).limit { |o|
        o.collect { |e| e.attributes[:size] }.sum <= 3
      }

      result_limited = grammar_with_limit.options(content: :join)
      expect(result_limited).to be_an(Array)
      expect(result_limited.size).to eq(36)  # All valid combinations with size <= 3

      # Should include pairs (size = 2)
      expect(result_limited).to include("aa")
      expect(result_limited).to include("ab")
      expect(result_limited).to include("bc")

      # Should include triples (size = 3)
      expect(result_limited).to include("aaa")
      expect(result_limited).to include("abc")
      expect(result_limited).to include("ccc")

      # Should NOT include quadruples (size > 3)
      expect(result_limited).not_to include("aaaa")
      expect(result_limited).not_to include("abcd")
    end

    it 'selects and ranks population using Darwin fitness evaluation' do
      # Generate population using Variatio
      variatio = Musa::Variatio::Variatio.new :melody do
        field :interval, 1..7
        field :contour, [:up, :down, :repeat]
        field :duration, [1/4r, 1/2r, 1r]

        constructor do |interval:, contour:, duration:|
          { interval: interval, contour: contour, duration: duration }
        end
      end

      candidates = variatio.run
      expect(candidates.size).to eq(63)  # 7 × 3 × 3

      # Select and rank using Darwin
      darwin = Musa::Darwin::Darwin.new do
        measures do |melody|
          die if melody[:interval] > 5  # No large leaps

          feature :stepwise if melody[:interval] <= 2
          feature :has_quarter_notes if melody[:duration] == 1/4r

          dimension :interval_size, -melody[:interval].to_f
          dimension :duration_value, melody[:duration].to_f
        end

        weight interval_size: 2.0,
               stepwise: 1.5,
               has_quarter_notes: 1.0,
               duration_value: -0.5
      end

      ranked = darwin.select(candidates)

      # Verify large intervals are excluded
      expect(ranked.none? { |m| m[:interval] > 5 }).to be true

      # Verify we have results
      expect(ranked.size).to be > 0
      expect(ranked.size).to be < 63  # Some candidates excluded

      # Best candidate should have good characteristics
      best_melody = ranked.first
      expect(best_melody[:interval]).to be <= 5
      expect([1, 2, 3, 4, 5]).to include(best_melody[:interval])
    end
  end


end
