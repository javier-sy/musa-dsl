require 'musa-dsl/mods/as-context-run'
require 'musa-dsl/mods/key-parameters-procedure-binder'

module Musa

  class Rules

    def initialize &block
      @context = RulesEvalContext.new.tap { |_| _._as_context_run block }
    end

    def generate_possibilities object, confirmed_node = nil, node = nil, rules = nil
      node ||= Node.new
      rules ||= @context._rules

      history = confirmed_node.history if confirmed_node
      history ||= []

      rules = rules.clone
      rule = rules.shift

      if rule
        rule.generate_possibilities(object, history).each do |new_object|
          new_node = Node.new new_object, node
          new_node.mark_as_ended! if @context._ended? new_object

          rejection = @context._rejections.find { |rejection| rejection.rejects?(new_object, history) }
          # TODO include rejection secondary reasons in rejection message

          new_node.reject! rejection if rejection

          node.children << new_node
        end
      end

      unless rules.empty?
        node.children.each do |node|
          generate_possibilities node.object, confirmed_node, node, rules unless node.rejected || node.ended?
        end
      end

      return node
    end

    def apply object_or_list, node = nil
      list = object_or_list.arrayfy.clone

      node ||= Node.new

      seed = list.shift

      if seed
        result = generate_possibilities seed, node

        fished = result.fish

        node.reject! "All children are rejected" if fished.empty?

        fished.each do |object|
          subnode = node.add(object).mark_as_ended!
          apply list, subnode
        end
      end

      return node
    end

    class RulesEvalContext
      attr_reader :_rules, :_ended_when, :_rejections

      def rule name, &block
        @_rules ||= []
        @_rules << Rule.new(name, self, block)
        self
      end

      def ended_when &block
        @_ended_when = block
        self
      end

      def rejection reason, &block
        @_rejections ||= []
        @_rejections << Rejection.new(reason, self, block)
        self
      end

      def _ended? object
        as_context_run @_ended_when, object
      end

      class Rule
        attr_reader :name

        def initialize name, context, block
          @name = name
          @context = context
          @block = block
        end

        def generate_possibilities object, history
          # TODO optimize context using only one instance for all genereate_possibilities calls
          context = RuleEvalContext.new @context
          context.as_context_run @block, object, history
          return context._possibilities
        end

        class RuleEvalContext
          attr_reader :_possibilities

          def initialize parent_context
            @_parent_context = parent_context
            @_possibilities = []
          end

          def possibility object
            @_possibilities << object
            self
          end

          private

        	def method_missing method_name, *args, **key_args, &block
        		if @_parent_context.respond_to? method_name
        			@_parent_context.send_nice method_name, *args, **key_args, &block
        		else
        			super
        		end
        	end

        	def respond_to_missing? method_name, include_private
        		@_parent_context.respond_to?(method_name, include_private) || super
        	end
        end

        private_constant :RuleEvalContext
      end

      private_constant :Rule

      class Rejection
        attr_reader :reason

        def initialize reason, context = nil, block = nil
          @reason = reason
          @context = context
          @block = block
        end

        def rejects? object, history
          # TODO optimize context using only one instance for all rejects? checks
          context = RejectionEvalContext.new @context
          context.as_context_run @block, object, history

          reasons = context._secondary_reasons.collect { |_| ("#{@reason} (#{_})" if _) || @reason }

          return reasons.empty? ? nil : reasons
        end

        class RejectionEvalContext
          attr_reader :_secondary_reasons

          def initialize parent_context
            @_parent_context = parent_context
            @_secondary_reasons = []
          end

          def reject secondary_reason = nil
            @_secondary_reasons << secondary_reason
            self
          end

          private

        	def method_missing method_name, *args, **key_args, &block
        		if @_parent_context.respond_to? method_name
        			@_parent_context.send_nice method_name, *args, **key_args, &block
        		else
        			super
        		end
        	end

        	def respond_to_missing? method_name, include_private
        		@_parent_context.respond_to?(method_name, include_private) || super
        	end
        end

        private_constant :RejectionEvalContext
      end

      private_constant :Rejection
    end

    private_constant :RulesEvalContext

    class Node
      attr_reader :parent, :children, :object, :rejected

      def initialize object = nil, parent = nil
        @parent = parent
        @children = []
        @object = object

        @ended = false
        @rejected = nil
      end

      def add object
        Node.new(object, self).tap { |n| @children << n }
      end

      def reject! rejection
        @rejected = rejection
        self
      end

      def mark_as_ended!
        @children.each { |n| n.update_rejection_by_children! }

        if !@children.empty? && !@children.find { |n| !n.rejected }
          reject! Rejection::AllChildrenRejected
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
        return objects.reverse
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

        return fished
      end

      def combinations parent_combination = nil
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

        return combinations
      end
    end

    private_constant :Node
  end
end
