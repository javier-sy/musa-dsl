require_relative '../core-ext/smart-proc-binder'
require_relative '../core-ext/with'

# TODO: hacer que pueda funcionar en tiempo real? le vas suministrando seeds y le vas diciendo qué opción has elegido (p.ej. para hacer un armonizador en tiempo real)
# TODO: esto mismo sería aplicable en otros generadores? variatio/darwin? generative-grammar? markov?
# TODO: optimizar la llamada a .with que internamente genera cada vez un SmartProcBinder; podría generarse sólo una vez por cada &block

module Musa
  module Rules
    using Musa::Extension::Arrayfy

    class Rules
      include Musa::Extension::With

      def initialize(&block)
        @dsl = RulesEvalContext.new(&block)
      end

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

      class RulesEvalContext
        include Musa::Extension::With

        attr_reader :_grow_rules, :_ended_when, :_cut_rules

        def initialize(&block)
          @_grow_rules = []
          @_cut_rules = []
          with &block
        end

        def grow(name, &block)
          @_grow_rules << GrowRule.new(name, &block)
          self
        end

        def ended_when(&block)
          @_ended_when = block
          self
        end

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

      class Node
        attr_reader :parent, :children, :object, :rejected

        def initialize(object = nil, parent = nil)
          @parent = parent
          @children = []
          @object = object

          @ended = false
          @rejected = nil
        end

        def add(object)
          Node.new(object, self).tap { |n| @children << n }
        end

        def reject!(rejection)
          @rejected = rejection
          self
        end

        def mark_as_ended!
          @children.each(&:update_rejection_by_children!)

          if !@children.empty? && !@children.find { |n| !n.rejected }
            reject! 'Node rejected because all children are rejected'
          end

          @ended = true

          self
        end

        def ended?
          @ended
        end

        def history
          objects = []
          n = self
          while n && n.object
            objects << n.object
            n = n.parent
          end

          objects.reverse
        end

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
