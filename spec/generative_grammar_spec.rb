require 'spec_helper'

require 'musa-dsl'

module Musa
  module GenerativeGrammar
    class Node
      attr_reader :attributes

      def initialize(attributes = nil)
        @attributes = attributes || []
      end

      def or(other)
        OrNode.new(self, other)
      end

      alias | or

      def repeat(min: nil, max: nil)
        if min && min > 0
          pre = self
          first = nil

          min.times do
            pre = pre.next(pre)
            first ||= pre
          end
        end

        if first
          first.next(RepeatNode.new(self, max - min))
        else
          RepeatNode.new(self, max)
        end
      end

      def next(other)
        NextNode.new(self, other)
      end

      alias + next

      def options(parent: nil, &condition)
        raise NotImplementedError
      end
    end

    class FinalNode < Node
      attr_reader :content

      def initialize(content, **attributes)
        super(attributes)
        @content = content
      end

      def options(parent: nil, &condition)
        parent ||= []

        option = [{ content: @content, attributes: @attributes }]

        if block_given?
          if yield(parent + option)
            [option]
          else
            []
          end
        else
          [option]
        end
      end
    end

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
          r << node_option if yield(parent + node_option)
        end

        @node2.options(parent: parent, &condition).each do |node_option|
          r << node_option if yield(parent + node_option)
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

  end
end

include Musa::GenerativeGrammar


RSpec.describe Musa do
  context 'Generative grammar' do
    it 'Node repetition with min and max limit' do


      a = FinalNode.new("a").next(FinalNode.new("b"))

      ar = a.next(a.next(a.repeat(max: 2))).options

      br = a.repeat(min: 2, max: 4).options

      pp ar
      pp br

      #expect(ar[0]).to eq
    end


    it 'Simple grammar' do


      _a = FinalNode.new("a", length: 1/8r + 1/8r)
      _b = FinalNode.new("b", length: 1/4r + 1/4r + 1/8r)
      _c = FinalNode.new("c", length: 1/8r + 1/8r + 1/4r)

      m = _a.or _b

      a = m.repeat.next(_c)

      options = a.options { |option| option.collect { |element| element[:attributes][:length] }.sum <= 2.0 }

      options.each do |option|
        pp h = { length: option.collect { |element| element[:attributes][:length] }.sum, option: option }
      end
    end

    it 'Simple grammar with | and + operators' do


      _a = FinalNode.new("a", length: 1/8r + 1/8r)
      _b = FinalNode.new("b", length: 1/4r + 1/4r + 1/8r)
      _c = FinalNode.new("c", length: 1/8r + 1/8r + 1/4r)

      m = _a | _b

      a = m.repeat + _c

      options = a.options { |option| option.collect { |element| element[:attributes][:length] }.sum <= 2.0 }

      options.each do |option|
        pp h = { length: option.collect { |element| element[:attributes][:length] }.sum, option: option }
      end
    end
  end
end
