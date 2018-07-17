require 'musa-dsl'

require 'spec_helper'


class Chord
  attr_accessor :fundamental, :third, :fifth, :duplicated, :duplicate_on

  def initialize fundamental = nil
    @fundamental = fundamental
    @third = nil
    @fifth = nil
    @duplicated = nil
    @duplicate_on = nil
  end

  def soprano
    notes[3]
  end

  def alto
    notes[2]
  end

  def tenor
    notes[1]
  end

  def bass
    notes[0]
  end

  def ordered
    [bass, tenor, alto, soprano]
  end

  def to_s
    "Chord<#{@fundamental}, #{@third}, #{@fifth}, dup #{@duplicated} on #{duplicated_note}>"
  end

  alias :inspect :to_s

  private

  def notes
    [@fundamental, @third, @fifth, duplicated_note].compact.sort
  end

  def duplicated_note
    @duplicate_on + send(@duplicated) if @duplicated
  end
end

class Musa::Rules
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
        generate_possibilities node.object, confirmed_node, node, rules.clone unless node.rejected || node.ended?
      end
    end

    return node
  end

  def apply list, node = nil
    list = list.clone

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
    end

    def ended_when &block
      if block_given?
        @_ended_when = block
      else
        @_ended_when
      end
    end

    def rejection reason, &block
      @_rejections ||= []
      @_rejections << Rejection.new(reason, self, block)
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

        reasons = context._secondary_reasons.collect { |_| @reason || ("#{@reason} (#{_})" if _) }

        return reasons.empty? ? nil : reasons
      end

      class RejectionEvalContext
        attr_reader :_secondary_reasons

        def initialize parent_context
          @_parent_context = parent_context
          @_secondary_reasons = []
        end

        def reject secondary_reason = nil
          secondary_reason ||= ""
          @_secondary_reasons << secondary_reason
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

ChordProgression = Musa::Rules.new do

  rule "3º" do |chord|
    if chord.fundamental && !chord.third
      #possibility chord.duplicate.tap { |_| _.third = chord.fundamental + 4 - 12 }
      possibility chord.duplicate.tap { |_| _.third = chord.fundamental + 4 }
      possibility chord.duplicate.tap { |_| _.third = chord.fundamental + 4 + 12 }
      possibility chord.duplicate.tap { |_| _.third = chord.fundamental + 4 + 24 }
    end
  end

  rule "5º" do |chord|
    if chord.fundamental && !chord.fifth
      #possibility chord.duplicate.tap { |_| _.fifth = chord.fundamental + 7 - 12 }
      possibility chord.duplicate.tap { |_| _.fifth = chord.fundamental + 7 }
      possibility chord.duplicate.tap { |_| _.fifth = chord.fundamental + 7 + 12 }
      possibility chord.duplicate.tap { |_| _.fifth = chord.fundamental + 7 + 24 }
    end
  end

  rule "duplication" do |chord|
    if chord.fundamental && !chord.duplicated
      possibility chord.duplicate.tap { |_| _.duplicated = :fundamental; _.duplicate_on = -12 }
      possibility chord.duplicate.tap { |_| _.duplicated = :fundamental; _.duplicate_on = +12 }
      possibility chord.duplicate.tap { |_| _.duplicated = :third; _.duplicate_on = +12 }
      possibility chord.duplicate.tap { |_| _.duplicated = :third; _.duplicate_on = +24 }
      possibility chord.duplicate.tap { |_| _.duplicated = :fifth; _.duplicate_on = +12 }
      possibility chord.duplicate.tap { |_| _.duplicated = :fifth; _.duplicate_on = +24 }
    end
  end

  ended_when do |chord|
    chord.soprano && chord.alto && chord.tenor && chord.bass
  end

  rejection "more than octave apart" do |chord|
    if chord.tenor && chord.bass
      reject "bass-tenor" if chord.tenor - chord.bass > 12
    end

    if chord.alto && chord.tenor
      reject "alto-tenor" if chord.alto - chord.tenor > 12
    end

    if chord.soprano && chord.alto
      reject "soprano-alto" if chord.soprano - chord.alto > 12
    end
  end

  rejection "parallel fifth" do |chord, history|
    if !history.empty? && chord.soprano && chord.alto && chord.tenor && chord.bass

      (0..3).find do |voice|
        (0..3).to_a.tap { |vv| vv.delete voice }.find do |voice2|
          # 5ª entre 2 voces del acorde
          # 5ª en el acorde anterior con las mismas voces
          reject if (chord.ordered[voice] - chord.ordered[voice2]) % 12 == 7 &&
                    (history.last.ordered[voice] - history.last.ordered[voice2]) % 12 == 7
        end
      end
    end
  end

  rejection "parallel octave" do |chord, history|
    if !history.empty? && chord.soprano && chord.alto && chord.tenor && chord.bass
      (0..3).find do |voice|
        (0..3).to_a.tap { |vv| vv.delete voice }.find do |voice2|
          # 8ª entre 2 voces del acorde
          # 8ª en el acorde anterior con las mismas voces
          reject if (chord.ordered[voice] - chord.ordered[voice2]) % 12 == 0 &&
                    (history.last.ordered[voice] - history.last.ordered[voice2]) % 12 == 0
        end
      end
    end
  end
end

RSpec.describe "Rules" do # Musa::Rules

	context "Prototype" do
		it "Basic definition" do
      n = ChordProgression.apply [Chord.new(60), Chord.new(65), Chord.new(67)]

      #pp n.fish
      pp n.combinations

      expect(result).to eq nil
    end
  end
end
