require_relative '../core-ext/key-parameters-procedure-binder'
require_relative '../core-ext/with'


# incluir With
# eliminar method_missing
# crear rama tb debe recibir la serie de la history
# crear rama puede repetirse (hasta terminar según ended_when)
#
# hacer que pueda funcionar en tiempo real? le vas suministrando seeds y le vas diciendo qué opción has elegido (p.ej. para hacer un armonizador en tiempo real)
# esto mismo sería aplicable en otros generadores? variatio/darwin? generative-grammar? markov?

module Musa
  module Backboner
    class Backboner
      include With

      def initialize(&block)
        @context = RulesEvalContext.new &block
      end

      def generate_possibilities(object, confirmed_node = nil, node = nil, grow_rules = nil)
        node ||= Node.new
        grow_rules ||= @context._grow_rules

        history = confirmed_node.history if confirmed_node
        history ||= []

        grow_rules = grow_rules.clone
        grow_rule = grow_rules.shift

        if grow_rule
          grow_rule.generate_possibilities(object, history).each do |new_object|
            new_node = Node.new new_object, node
            new_node.mark_as_ended! if @context._ended? new_object

            rejection = @context._cut_rules.find { |cut_rule| cut_rule.rejects?(new_object, history) }
            # TODO: include rejection secondary reasons in rejection message

            new_node.reject! rejection if rejection

            node.children << new_node
          end
        end

        unless grow_rules.empty?
          node.children.each do |node|
            generate_possibilities node.object, confirmed_node, node, grow_rules unless node.rejected || node.ended?
          end
        end

        node
      end

      def apply(object_or_list, node = nil)
        list = object_or_list.arrayfy.clone

        node ||= Node.new

        seed = list.shift

        if seed
          result = generate_possibilities seed, node

          fished = result.fish

          node.reject! 'All children are rejected' if fished.empty?

          fished.each do |object|
            subnode = node.add(object).mark_as_ended!
            apply list, subnode
          end
        end

        node
      end

      class RulesEvalContext
        include With

        attr_reader :_grow_rules, :_ended_when, :_cut_rules

        def initialize(&block)
          with &block
        end

        def grow(name, repeat: nil, &block)
          repeat ||= nil

          @_grow_rules ||= []
          @_grow_rules << GrowRule.new(name, self, repeat, block)
          self
        end

        def ended_when(&block)
          @_ended_when = block
          self
        end

        def cut(reason, &block)
          @_cut_rules ||= []
          @_cut_rules << CutRule.new(reason, self, block)
          self
        end

        def _ended?(object)
          instance_exec object, &@_ended_when
        end

        class GrowRule
          attr_reader :name

          def initialize(name, context, repeat, block)
            @name = name
            @repeat = repeat
            @context = context
            @block = block
          end

          def generate_possibilities(object, history)
            # TODO: optimize context using only one instance for all genereate_possibilities calls
            context = GrowRuleEvalContext.new @context
            context.instance_exec object, history, &@block

            context._branches
          end

          class GrowRuleEvalContext
            attr_reader :_branches

            def initialize(parent_context)
              @_parent_context = parent_context
              @_branches = []
            end

            def branch(object)
              @_branches << object
              self
            end

            private

            def method_missing(method_name, *args, **key_args, &block)
              if @_parent_context.respond_to? method_name
                @_parent_context.send method_name, *args, **key_args, &block
              else
                super
              end
            end

            def respond_to_missing?(method_name, include_private)
              @_parent_context.respond_to?(method_name, include_private) || super
            end
          end

          private_constant :GrowRuleEvalContext
        end

        private_constant :GrowRule

        class CutRule
          attr_reader :reason

          def initialize(reason, context = nil, block = nil)
            @reason = reason
            @context = context
            @block = block
          end

          def rejects?(object, history)
            # TODO: optimize context using only one instance for all rejects? checks
            context = CutRuleEvalContext.new @context
            context.instance_exec object, history, &@block

            reasons = context._secondary_reasons.collect { |_| ("#{@reason} (#{_})" if _) || @reason }

            reasons.empty? ? nil : reasons
          end

          class CutRuleEvalContext
            attr_reader :_secondary_reasons

            def initialize(parent_context)
              @_parent_context = parent_context
              @_secondary_reasons = []
            end

            def prune(secondary_reason = nil)
              @_secondary_reasons << secondary_reason
              self
            end

            private

            def method_missing(method_name, *args, **key_args, &block)
              if @_parent_context.respond_to? method_name
                @_parent_context.send method_name, *args, **key_args, &block
              else
                super
              end
            end

            def respond_to_missing?(method_name, include_private)
              @_parent_context.respond_to?(method_name, include_private) || super
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
            reject! CutRule::AllChildrenRejected
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
