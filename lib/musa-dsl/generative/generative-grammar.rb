module Musa
  module GenerativeGrammar

    def N(content = nil, **attributes, &block)
      if block_given? && content.nil?
        BlockNode.new(attributes, &block)
      else
        FinalNode.new(content, attributes)
      end
    end

    class OptionElement
      attr_reader :content, :attributes

      def initialize(content, attributes = nil)
        @content = content
        @attributes = attributes || {}
      end
    end

    class Node
      def or(other)
        OrNode.new(self, other)
      end

      alias | or

      def repeat(exactly = nil, min: nil, max: nil)
        raise ArgumentError, 'Only exactly value or min/max values are allowed' if exactly && (min || max)

        min = max = exactly if exactly

        if min && min > 0
          pre = self

          (min - 1).times do
            pre += self
          end
        end

        if pre && max == min
          pre
        elsif pre && max > min
          pre + RepeatNode.new(self, max - min)
        else
          RepeatNode.new(self, max)
        end
      end

      def limit(&block)
        ConditionNode.new(self, &block)
      end

      def next(other)
        NextNode.new(self, other)
      end

      alias + next

      def options(parent: nil, &condition)
        raise NotImplementedError
      end
    end

    private_constant :Node

    class FinalNode < Node
      attr_reader :content
      attr_reader :attributes

      def initialize(content, attributes)
        super()
        @element = OptionElement.new(content, attributes)
      end

      def options(parent: nil, &condition)
        parent ||= []

        if block_given?
          if yield(parent + [@element])
            [[@element]]
          else
            []
          end
        else
          [[@element]]
        end
      end

    end

    private_constant :FinalNode

    class BlockNode < Node
      def initialize(attributes, &block)
        @attributes = attributes
        @block = block
      end

      def options(parent: nil, &condition)
        parent ||= []

        element = @block.call(parent, @attributes)
        element = OptionElement.new(element, @attributes) unless element.is_a?(OptionElement)

        if block_given?
          if yield(parent + [element], @attributes)
            [[element]]
          else
            []
          end
        else
          [[element]]
        end
      end
    end

    private_constant :BlockNode

    class ConditionNode < Node
      def initialize(node, &block)
        @node = node
        @block = block
      end

      def options(parent: nil, &condition)
        parent ||= []

        r = []

        @node.options(parent: parent, &condition).each do |node_option|
          r << node_option if (!block_given? || yield(parent + node_option)) && @block.call(parent + node_option)
        end

        r
      end
    end

    private_constant :ConditionNode

    class OrNode < Node
      def initialize(node1, node2)
        @node1 = node1
        @node2 = node2
        super()
      end

      def options(parent: nil, &condition)
        parent ||= []

        r = []

        @node1.options(parent: parent, &condition).each do |node_option|
          r << node_option if !block_given? || yield(parent + node_option)
        end

        @node2.options(parent: parent, &condition).each do |node_option|
          r << node_option if !block_given? || yield(parent + node_option)
        end

        r
      end
    end

    private_constant :OrNode

    class NextNode < Node
      def initialize(node, after)
        @node = node
        @after = after
        super()
      end

      def options(parent: nil, &condition)
        parent ||= []

        r = []
        @node.options(parent: parent, &condition).each do |node_option|
          @after.options(parent: parent + node_option, &condition).each do |after_option|
            r << node_option + after_option unless after_option.empty?
          end
        end
        r
      end
    end

    private_constant :NextNode

    class RepeatNode < Node
      def initialize(node, max = nil)
        @node = node
        @max = max

        super()
      end

      def options(parent: nil, depth: nil, &condition)
        parent ||= []
        depth ||= 0

        r = []

        if @max.nil? || depth < @max
          node_options = @node.options(parent: parent, &condition)

          node_options.each do |node_option|
            r << node_option

            node_suboptions = options(parent: parent + node_option, depth: depth + 1, &condition)

            node_suboptions.each do |node_suboption|
              r << node_option + node_suboption
            end
          end
        end

        r
      end
    end

    private_constant :RepeatNode
  end
end
