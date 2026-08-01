require_relative '../series'

module Musa
  
  
  # Markov chain generator for stochastic sequence generation.
  #
  # Implements Markov chains that generate sequences of states based on
  # probabilistic transition rules. Each state transitions to the next
  # based on defined probabilities, creating pseudo-random but structured
  # sequences.
  #
  # ## Theory
  #
  # A Markov chain is a stochastic model describing a sequence of possible
  # events where the probability of each event depends only on the state
  # attained in the previous event (memoryless property).
  #
  # ## Transition Types
  #
  # - **Array**: Equal probability between all options
  #   - `{ a: [:b, :c] }` → 50% chance of :b, 50% chance of :c
  #
  # - **Hash**: Weighted probabilities
  #   - `{ a: { b: 0.2, c: 0.8 } }` → 20% :b, 80% :c
  #   - Probabilities are normalized (don't need to sum to 1.0)
  #
  # - **Proc**: Algorithmic transitions based on history
  #   - `{ a: proc { |history| history.size.even? ? :b : :c } }`
  #   - Proc receives full history and returns next state
  #
  # ## Musical Applications
  #
  # - Generate melodic sequences with style-based transitions
  # - Create rhythmic patterns with probabilistic variation
  # - Produce chord progressions with weighted likelihood
  # - Build dynamic musical structures with emergent behavior
  #
  # @example Equal probability transitions
  #   markov = Musa::Markov::Markov.new(
  #     start: :a,
  #     finish: :x,
  #     transitions: {
  #       a: [:b, :c],      # 50/50 chance
  #       b: [:a, :c],
  #       c: [:a, :b, :x]
  #     },
  #     random: 7  # an explicit seed makes the sequence the same sequence
  #   ).i
  #
  #   markov.to_a  # => [:a, :c, :a, :c, :x]
  #
  # @example Weighted probability transitions
  #   markov = Musa::Markov::Markov.new(
  #     start: :a,
  #     finish: :x,
  #     transitions: {
  #       a: { b: 0.2, c: 0.8 },  # 20% b, 80% c
  #       b: { a: 0.3, c: 0.7 },  # 30% a, 70% c
  #       c: [:a, :b, :x]         # Equal probability
  #     }
  #   ).i
  #
  # @example Algorithmic transitions with history
  #   markov = Musa::Markov::Markov.new(
  #     start: :a,
  #     finish: :x,
  #     transitions: {
  #       a: { b: 0.2, c: 0.8 },
  #       # Transition based on history length
  #       b: proc { |history| history.size.even? ? :a : :c },
  #       c: [:a, :b, :x]
  #     }
  #   ).i
  #
  # @example Musical pitch transitions
  #   # Create melodic sequence with style-based transitions
  #   melody = Musa::Markov::Markov.new(
  #     start: 60,  # Middle C
  #     finish: nil,  # Infinite
  #     # Every reachable state needs its own row: landing on one that has no
  #     # transitions raises "No transition defined for ...".
  #     transitions: {
  #       60 => { 62 => 0.4, 64 => 0.3, 59 => 0.3 },  # C → D/E/B
  #       62 => { 60 => 0.3, 64 => 0.4, 67 => 0.3 },  # D → C/E/G
  #       64 => [60, 62, 65, 67],                     # E → C/D/F/G
  #       65 => [64, 67],                             # F → E/G
  #       67 => [64, 65, 60],                         # G → E/F/C
  #       59 => [60, 62]                              # B → C/D
  #     },
  #     random: 3
  #   ).i.max_size(16).to_a
  #
  #   melody.first(6)  # => [60, 64, 62, 67, 64, 60]
  #
  # @see Musa::Series::Serie Series interface for chaining operations
  # @see Musa::Extension::SmartProcBinder Smart procedure binding for history-based transitions
  # @see https://en.wikipedia.org/wiki/Markov_chain Markov chain (Wikipedia)
  # @see https://en.wikipedia.org/wiki/Stochastic_process Stochastic process (Wikipedia)
  # @see https://en.wikipedia.org/wiki/Markov_chain#Music Markov chains in music (Wikipedia)
  module Markov
    # Markov chain serie generator.
    #
    # Generates sequences of states following probabilistic transition rules.
    # Implements {Musa::Series::Serie} interface for integration with series operations.
    class Markov
      # TODO: adapt to series prototyping
      include Musa::Series::Serie::Base

      # Creates Markov chain generator.
      #
      # @param transitions [Hash] state transition rules
      #   Keys are states, values are next state definitions (Array, Hash, or Proc)
      # @param start [Object] initial state
      # @param finish [Object, nil] terminal state (nil for infinite)
      # @param random [Random, Integer, nil] a generator, or a seed to build one
      #   with, or nothing for an unseeded one. A seed and a `Random` built from
      #   that same seed give the same chain.
      #
      # @example
      #   markov = Markov.new(
      #     transitions: { a: [:b, :c], b: [:a, :c], c: [:a, :b, :x] },
      #     start: :a,
      #     finish: :x
      #   )
      #
      # @example A seed and a generator built from it are the same thing
      #   transitions = { a: [:b, :c], b: [:a, :c], c: [:a, :b, :x] }
      #
      #   from_seed = Markov.new(start: :a, finish: :x, transitions: transitions, random: 7)
      #   from_generator = Markov.new(start: :a, finish: :x, transitions: transitions,
      #                               random: Random.new(7))
      #
      #   from_seed.i.to_a == from_generator.i.to_a  # => true
      #
      # @note A generator passed in is used, not copied, so several series
      #   sharing one draw from the same stream -- `next_value` advances it.
      #   `to_a` does not, because it consumes a deep copy of the serie.
      #
      # @return [void]
      def initialize(transitions:, start:, finish: nil, random: nil)
        @transitions = transitions.clone.freeze

        @start = start
        @finish = finish

        # A seed is turned into a generator; a generator is kept as it is. The
        # second line used to overwrite the ivar the first had not set, so a
        # `Random` passed in was replaced by an unseeded one and the chain came
        # out different on every run while the caller believed it was pinned
        # (issue #79).
        @random = random.is_a?(Integer) ? Random.new(random) : random
        @random ||= Random.new

        @procedure_binders = {}

        mark_as_prototype!
        init
      end

      # @return [Object] starting state
      attr_accessor :start

      # @return [Object, nil] finishing state (nil for infinite)
      attr_accessor :finish

      # @return [Random] random number generator
      attr_accessor :random

      # @return [Hash] transition rules (frozen)
      attr_accessor :transitions

      # Initializes serie instance state.
      #
      # @api private
      private def _init
        @current = nil
        @finished = false
        @history = []
      end

      # Generates next value in Markov chain.
      #
      # Selects next state based on current state's transition rules.
      # Handles Array (equal probability), Hash (weighted), and Proc (algorithmic)
      # transitions.
      #
      # @return [Object, nil] next state, or nil if finished
      #
      # @raise [RuntimeError] if no transition defined for current state
      # @raise [ArgumentError] if transition type is not Array, Hash, or Proc
      #
      # @api private
      private def _next_value
        if @finished
          @current = nil
        else
          if @current.nil?
            @current = @start
          else
            if @transitions.has_key?(@current)
              options = @transitions[@current]

              case options
              when Array
                @current = options[@random.rand(0...options.size)]

              when Hash
                total = accumulated = 0.0
                options.each_value { |probability| total += probability.abs }
                r = @random.rand total

                @current = options.find { |key, probability|
                  accumulated += probability;
                  r >= accumulated - probability && r < accumulated }[0]

              when Proc
                procedure_binder = @procedure_binders[options] ||= Musa::Extension::SmartProcBinder::SmartProcBinder.new(options)
                @current = procedure_binder.call @history
              else
                raise ArgumentError, "Option #{option} is not allowed. Only Array, Hash or Proc are allowed."
              end
            else
              raise RuntimeError, "No transition defined for #{@current}"
            end
          end

          @history << @current
          @finished = true if !@finish.nil? && (@current == @finish)
        end

        @current
      end

      # Checks if Markov chain is infinite.
      #
      # @return [Boolean] true if no finish state defined
      def infinite?
        @finish.nil?
      end
    end
  end
end

