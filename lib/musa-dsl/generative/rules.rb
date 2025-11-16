require_relative '../core-ext/smart-proc-binder'
require_relative '../core-ext/with'

# Rule-based production system with growth and pruning.
#
# Rules implements a production system that generates tree structures
# by applying growth rules to produce branches and pruning rules to
# eliminate invalid paths. Similar to L-systems and production systems
# in formal grammars, but with validation and constraint satisfaction.
#
# ## Core Concepts
#
# - **Grow Rules**: Transform objects into new possibilities (branches)
# - **Cut Rules**: Prune branches that violate constraints
# - **End Condition**: Mark branches as complete
# - **Tree**: Hierarchical structure of all valid possibilities
# - **History**: Path from root to current node
# - **Combinations**: All valid complete paths through tree
#
# ## Generation Process
#
# 1. **Seed**: Start with initial object(s)
# 2. **Grow**: Apply grow rules sequentially to create branches
# 3. **Validate**: Apply cut rules to prune invalid branches
# 4. **Check End**: Mark branches meeting end condition
# 5. **Recurse**: Continue growing non-ended branches
# 6. **Collect**: Gather all valid complete paths
#
# ## Rule Application
#
# Rules are applied in definition order. Each grow rule can produce
# multiple branches via `branch`. Cut rules can prune with `prune`.
# The system tracks history (path to current node) for context-aware
# rule application.
#
# ## Musical Applications
#
# - Generate harmonic progressions with voice leading rules
# - Create melodic variations with contour constraints
# - Produce rhythmic patterns following metric rules
# - Build counterpoint with species rules
# - Generate chord voicings with spacing constraints
#
# @example Basic chord progression rules
#   rules = Musa::Rules::Rules.new do
#     # Generate possible next chords
#     grow 'next chord' do |chord, history|
#       case chord
#       when :I   then branch(:ii); branch(:IV); branch(:V)
#       when :ii  then branch(:V); branch(:vii)
#       when :IV  then branch(:I); branch(:V)
#       when :V   then branch(:I); branch(:vi)
#       when :vi  then branch(:ii); branch(:IV)
#       when :vii then branch(:I)
#       end
#     end
#
#     # Avoid parallel fifths
#     cut 'parallel fifths' do |chord, history|
#       prune if has_parallel_fifths?(history + [chord])
#     end
#
#     # End after 4 chords
#     ended_when do |chord, history|
#       history.size == 4
#     end
#   end
#
#   tree = rules.apply([:I])
#   progressions = tree.combinations
#   # => [[:I, :ii, :V, :I], [:I, :IV, :V, :I], ...]
#
# @example Melodic contour rules with parameters
#   rules = Musa::Rules::Rules.new do
#     grow 'next note' do |pitch, history, max_interval:|
#       # Try intervals within max_interval
#       (-max_interval..max_interval).each do |interval|
#         branch pitch + interval unless interval.zero?
#       end
#     end
#
#     cut 'range limit' do |pitch, history|
#       prune if pitch < 60 || pitch > 84  # C4 to C6
#     end
#
#     cut 'no large leaps' do |pitch, history|
#       prune if history.last && (pitch - history.last).abs > 7
#     end
#
#     ended_when do |pitch, history|
#       history.size == 8  # 8-note melody
#     end
#   end
#
#   tree = rules.apply([60], max_interval: 3)
#   melodies = tree.combinations
#
# @example Rhythm pattern generation
#   rules = Musa::Rules::Rules.new do
#     grow 'add duration' do |pattern, history, remaining:|
#       [1/4r, 1/8r, 1/16r].each do |dur|
#         if dur <= remaining
#           branch pattern + [dur]
#         end
#       end
#     end
#
#     cut 'too many sixteenths' do |pattern, history|
#       sixteenths = pattern.count { |d| d == 1/16r }
#       prune if sixteenths > 4
#     end
#
#     ended_when do |pattern, history, remaining:|
#       pattern.sum >= remaining
#     end
#   end
#
#   tree = rules.apply([], remaining: 1r)  # One bar
#   rhythms = tree.combinations
#
# @see https://en.wikipedia.org/wiki/Production_system_(computer_science) Production systems (Wikipedia)
# @see https://en.wikipedia.org/wiki/L-system L-systems (Wikipedia)
# @see https://en.wikipedia.org/wiki/Expert_system Expert systems (Wikipedia)
#
# # TODO: hacer que pueda funcionar en tiempo real? le vas suministrando seeds y le vas diciendo qué opción has elegido (p.ej. para hacer un armonizador en tiempo real)
# TODO: esto mismo sería aplicable en otros generadores? variatio/darwin? generative-grammar? markov?
# TODO: optimizar la llamada a .with que internamente genera cada vez un SmartProcBinder; podría generarse sólo una vez por cada &block

module Musa
  # Rule-based production system with growth and pruning.
  #
  # Contains the {Rules} class for generating tree structures through
  # sequential application of grow rules (expansion) and cut rules (pruning).
  # Produces all valid combination paths satisfying defined constraints.
  #
  # @see Rules Main rule-based generator class
  module Rules
    using Musa::Extension::Arrayfy

    # Rule-based generator with growth and pruning.
    #
    # Applies grow/cut rules to generate tree of valid possibilities.
    class Rules
      include Musa::Extension::With

      # Creates rule system with defined rules.
      #
      # @yield rule definition DSL block
      # @yieldreturn [void]
      #
      # @example
      #   rules = Rules.new do
      #     grow 'generate' { |obj| branch new_obj }
      #     cut 'validate' { |obj| prune if invalid?(obj) }
      #     ended_when { |obj| complete?(obj) }
      #   end
      def initialize(&block)
        @dsl = RulesEvalContext.new(&block)
      end

      # Generates possibility tree from object.
      #
      # Recursively applies grow rules to create branches, cut rules to
      # prune invalid paths, and end conditions to mark complete branches.
      #
      # @param object [Object] object to expand
      # @param confirmed_node [Node, nil] confirmed parent node (for history)
      # @param node [Node, nil] current node being built
      # @param grow_rules [Array<GrowRule>, nil] rules to apply
      # @param parameters [Hash] additional parameters for rules
      #
      # @return [Node] root node of possibility tree
      #
      # @api private
      def generate_possibilities(object, confirmed_node = nil, node = nil, grow_rules = nil, **parameters)
        node ||= Node.new
        grow_rules ||= @dsl._grow_rules

        history = confirmed_node.history if confirmed_node
        history ||= []

        grow_rules = grow_rules.clone
        grow_rule = grow_rules.shift

        if grow_rule
          grow_rule.generate_possibilities(object, history, **parameters).each do |new_object|
            new_node = Node.new new_object, node
            if @dsl._has_ending? && @dsl._ended?(new_object, history, **parameters) ||
              !@dsl._has_ending? && grow_rules.empty?

              new_node.mark_as_ended!
            end

            rejection = @dsl._cut_rules.find { |cut_rule| cut_rule.rejects?(new_object, history, **parameters) }
            # TODO: include rejection secondary reasons in rejection message

            new_node.reject! rejection if rejection

            node.children << new_node
          end
        end

        unless grow_rules.empty?
          node.children.each do |node|
            generate_possibilities node.object, confirmed_node, node, grow_rules, **parameters unless node.rejected || node.ended?
          end
        end

        node
      end

      # Applies rules to seed objects sequentially.
      #
      # Processes list of seed objects in sequence, generating possibilities
      # from each confirmed endpoint of previous seed. Returns tree of all
      # valid combination paths.
      #
      # @param object_or_list [Object, Array] seed object(s) to process
      # @param node [Node, nil] root node (creates if nil)
      # @param parameters [Hash] additional parameters for rules
      #
      # @return [Node] root node with all combination paths
      #
      # @example Single seed
      #   tree = rules.apply(:I)
      #   tree.combinations  # => [[:I, :ii, :V, :I], ...]
      #
      # @example Multiple seeds
      #   tree = rules.apply([:I, :ii, :V])
      #   tree.combinations  # => combinations starting from each seed
      def apply(object_or_list, node = nil, **parameters)
        list = object_or_list.arrayfy.clone

        node ||= Node.new

        seed = list.shift

        if seed
          result = generate_possibilities seed, node, **parameters

          fished = result.fish

          node.reject! 'All children are rejected' if fished.empty?

          fished.each do |object|
            subnode = node.add(object).mark_as_ended!
            apply list, subnode, **parameters
          end
        end

        node
      end

      # DSL context for rule definitions.
      #
      # @api private
      class RulesEvalContext
        include Musa::Extension::With

        # @return [Array<GrowRule>] grow rules
        # @return [Proc, nil] end condition
        # @return [Array<CutRule>] cut rules
        attr_reader :_grow_rules, :_ended_when, :_cut_rules

        # @api private
        def initialize(&block)
          @_grow_rules = []
          @_cut_rules = []
          with &block
        end

        # Defines grow rule.
        #
        # @param name [String] rule name for debugging
        # @yield [object, history, **params] rule block
        # @return [self]
        # @api private
        def grow(name, &block)
          @_grow_rules << GrowRule.new(name, &block)
          self
        end

        # Defines end condition.
        #
        # @yield [object, history, **params] condition block
        # @return [self]
        # @api private
        def ended_when(&block)
          @_ended_when = block
          self
        end

        # Defines cut/pruning rule.
        #
        # @param reason [String] rejection reason
        # @yield [object, history, **params] pruning block
        # @return [self]
        # @api private
        def cut(reason, &block)
          @_cut_rules << CutRule.new(reason, &block)
          self
        end

        def _has_ending?
          !@_ended_when.nil?
        end

        def _ended?(object, history, **parameters)
          if @_ended_when
            with object, history, **parameters, &@_ended_when
          else
            false
          end
        end

        class GrowRule
          attr_reader :name

          def initialize(name, &block)
            @name = name
            @block = block
          end

          def generate_possibilities(object, history, **parameters)
            # TODO: optimize context using only one instance for all genereate_possibilities calls
            context = GrowRuleEvalContext.new
            context.with object, history, **parameters, &@block

            context._branches
          end

          class GrowRuleEvalContext
            include Musa::Extension::With

            attr_reader :_branches

            def initialize
              @_branches = []
            end

            def branch(object)
              @_branches << object
              self
            end
          end

          private_constant :GrowRuleEvalContext
        end

        private_constant :GrowRule

        class CutRule
          attr_reader :reason

          def initialize(reason, &block)
            @reason = reason
            @block = block
          end

          def rejects?(object, history, **parameters)
            # TODO: optimize context using only one instance for all rejects? checks
            context = CutRuleEvalContext.new
            context.with object, history, **parameters, &@block

            reasons = context._secondary_reasons.collect { |_| ("#{@reason} (#{_})" if _) || @reason }

            reasons.empty? ? nil : reasons
          end

          class CutRuleEvalContext
            include Musa::Extension::With

            attr_reader :_secondary_reasons

            def initialize
              @_secondary_reasons = []
            end

            def prune(secondary_reason = nil)
              @_secondary_reasons << secondary_reason
              self
            end
          end

          private_constant :CutRuleEvalContext
        end

        private_constant :CutRule
      end

      private_constant :RulesEvalContext

      # Tree node representing possibility in generation.
      #
      # Nodes form tree structure of generation possibilities.
      # Each node has object, parent, children, rejection status, and end flag.
      #
      # @attr_reader parent [Node, nil] parent node
      # @attr_reader children [Array<Node>] child nodes
      # @attr_reader object [Object, nil] node object
      # @attr_reader rejected [String, Array<String>, nil] rejection reason(s)
      #
      # @api private
      class Node
        attr_reader :parent, :children, :object, :rejected

        # @api private
        def initialize(object = nil, parent = nil)
          @parent = parent
          @children = []
          @object = object

          @ended = false
          @rejected = nil
        end

        # Adds child node.
        #
        # @param object [Object] child object
        # @return [Node] created child node
        # @api private
        def add(object)
          Node.new(object, self).tap { |n| @children << n }
        end

        # Marks node as rejected.
        #
        # @param rejection [String, Array<String>] rejection reason(s)
        # @return [self]
        # @api private
        def reject!(rejection)
          @rejected = rejection
          self
        end

        # Marks node as ended/complete.
        #
        # Propagates rejection if all children rejected.
        #
        # @return [self]
        # @api private
        def mark_as_ended!
          @children.each(&:update_rejection_by_children!)

          if !@children.empty? && !@children.find { |n| !n.rejected }
            reject! 'Node rejected because all children are rejected'
          end

          @ended = true

          self
        end

        # Checks if node is ended.
        #
        # @return [Boolean]
        # @api private
        def ended?
          @ended
        end

        # Returns path from root to this node.
        #
        # @return [Array<Object>] history of objects
        # @api private
        def history
          objects = []
          n = self
          while n && n.object
            objects << n.object
            n = n.parent
          end

          objects.reverse
        end

        # Collects objects from ended leaf nodes.
        #
        # Recursively gathers objects from all valid ended branches,
        # excluding rejected paths.
        #
        # @return [Array<Object>] objects from valid endpoints
        # @api private
        def fish
          fished = []

          @children.each do |node|
            unless node.rejected
              if node.ended?
                fished << node.object
              else
                fished += node.fish
              end
            end
          end

          fished
        end

        # Returns all valid combination paths.
        #
        # Recursively builds complete paths from root to all valid
        # leaf nodes, excluding rejected branches.
        #
        # @param parent_combination [Array, nil] parent path
        #
        # @return [Array<Array<Object>>] all valid complete paths
        #
        # @example
        #   tree.combinations
        #   # => [
        #   #   [:I, :ii, :V, :I],
        #   #   [:I, :IV, :V, :I],
        #   #   ...
        #   # ]
        # @api private
        def combinations(parent_combination = nil)
          parent_combination ||= []

          combinations = []

          unless rejected
            if @children.empty?
              combinations << parent_combination
            else
              @children.each do |node|
                node.combinations(parent_combination + [node.object]).each do |object|
                  combinations << object
                end
              end
            end
          end

          combinations
        end
      end

      private_constant :Node
    end
  end
end
