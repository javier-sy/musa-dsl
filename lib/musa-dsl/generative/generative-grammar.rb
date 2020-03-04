module Musa
  module GenerativeGrammar
    extend self

    def N(content = nil, **attributes, &block)
      if block_given? && content.nil?
        Implementation::BlockNode.new(attributes, &block)
      else
        Implementation::FinalNode.new(content, attributes)
      end
    end

    def PN
      Implementation::ProxyNode.new
    end

    class OptionElement
      attr_reader :content, :attributes

      def initialize(content, attributes = nil)
        @content = content
        @attributes = attributes || {}
      end
    end

    module Implementation
      class Node
        def or(other)
          OrNode.new(self, other)
        end

        alias_method :|, :or

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

        def limit(attribute = nil, after_collect_operation = nil, comparison_method = nil, comparison_value = nil, &block)
          raise ArgumentError, 'Cannot use simplified arguments and yield block at the same time' if (attribute || after_collect_operation || comparison_method || comparison_value) && @block

          block ||= generate_simple_condition_block(attribute, after_collect_operation, comparison_method, comparison_value)

          ConditionNode.new(self, &block)
        end

        def next(other)
          NextNode.new(self, other)
        end

        alias_method :+, :next

        def options(attribute = nil,
                    after_collect_operation = nil,
                    comparison_method = nil,
                    comparison_value = nil,
                    raw: nil,
                    content: nil,
                    &condition)

          raise ArgumentError, 'Cannot use simplified arguments and yield block at the same time' if (attribute || after_collect_operation || comparison_method || comparison_value) && @condition
          raise ArgumentError, 'Cannot use raw: true and content: option at the same time' if raw && content

          raw ||= false
          content ||= :itself

          condition ||= generate_simple_condition_block(attribute, after_collect_operation, comparison_method, comparison_value)

          if raw
            _options(&condition)
          else
            _options(&condition).collect { |o| o.collect(&:content).send(content) }
          end
        end

        def size
          options.size
        end

        alias_method :length, :size

        def [](index)
          options[index].to_serie.to_node
        end

        def to_serie(flatten: nil, &condition)
          flatten ||= true

          serie = _options(&condition).collect { |o| o.collect(&:content) }.to_serie(of_series: true).merge
          serie = serie.flatten if flatten

          serie.prototype
        end

        alias_method :s, :to_serie

        def _options(parent: nil, &condition)
          raise NotImplementedError
        end

        protected

        def generate_simple_condition_block(attribute = nil,
                                            after_collect_operation = nil,
                                            comparison_method = nil,
                                            comparison_value = nil)

          if attribute && after_collect_operation && comparison_method && comparison_value
            proc do |o|
              o.collect { |_| _.attributes[attribute] }
                  .send(after_collect_operation)
                  .send(comparison_method, comparison_value)
            end
          end
        end
      end

      class ProxyNode < Node
        attr_accessor :node

        def _options(parent: nil, &condition)
          @node._options parent: parent, &condition
        end
      end

      class FinalNode < Node
        attr_reader :content
        attr_reader :attributes

        def initialize(content, attributes)
          super()
          @element = OptionElement.new(content, attributes)
        end

        def _options(parent: nil, &condition)
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

      class BlockNode < Node
        def initialize(attributes, &block)
          @attributes = attributes
          @block = block
        end

        def _options(parent: nil, &condition)
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

      class ConditionNode < Node
        def initialize(node, &block)
          @node = node
          @block = block
        end

        def _options(parent: nil, &condition)
          parent ||= []

          r = []

          @node._options(parent: parent, &condition).each do |node_option|
            r << node_option if (!block_given? || yield(parent + node_option)) && @block.call(parent + node_option)
          end

          r
        end
      end

      class OrNode < Node
        def initialize(node1, node2)
          @node1 = node1
          @node2 = node2
          super()
        end

        def _options(parent: nil, &condition)
          parent ||= []

          r = []

          @node1._options(parent: parent, &condition).each do |node_option|
            r << node_option if !block_given? || yield(parent + node_option)
          end

          @node2._options(parent: parent, &condition).each do |node_option|
            r << node_option if !block_given? || yield(parent + node_option)
          end

          r
        end
      end

      class NextNode < Node
        def initialize(node, after)
          @node = node
          @after = after
          super()
        end

        def _options(parent: nil, &condition)
          parent ||= []

          r = []
          @node._options(parent: parent, &condition).each do |node_option|
            @after._options(parent: parent + node_option, &condition).each do |after_option|
              r << node_option + after_option unless after_option.empty?
            end
          end
          r
        end
      end

      class RepeatNode < Node
        def initialize(node, max = nil)
          @node = node
          @max = max

          super()
        end

        def _options(parent: nil, depth: nil, &condition)
          parent ||= []
          depth ||= 0

          r = []

          if @max.nil? || depth < @max
            node_options = @node._options(parent: parent, &condition)

            node_options.each do |node_option|
              r << node_option

              node_suboptions = _options(parent: parent + node_option, depth: depth + 1, &condition)

              node_suboptions.each do |node_suboption|
                r << node_option + node_suboption
              end
            end
          end

          r
        end
      end
    end

    private_constant :Implementation
  end
end
