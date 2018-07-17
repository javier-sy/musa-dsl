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
    rules ||= @context._rules.clone

    history = confirmed_node.history if confirmed_node
    history ||= []

    rule = rules.find { |r| r.applies_on? object, history }

    if rule
      rules.delete rule

      rule.generate_possibilities(object, history).each do |new_object|

        new_node = Node.new new_object, node
        new_node.mark_as_ended! if @context._ended? new_object

        rejection =
          @context._rejections.find { |rejection|
            rejection.applies_on?(new_object, history) &&
            rejection.rejects?(new_object, history) }

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

      node.reject! Rejection::AllChildrenRejected if fished.empty?

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
      @_rules << Rule.new(name, self).tap { |r| r._as_context_run block }
    end

    def ended_when &block
      if block_given?
        @_ended_when = block
      else
        @_ended_when
      end
    end

    def reject reason, &block
      @_rejections ||= []
      @_rejections << Rejection.new(reason, self).tap { |r| r._as_context_run block }
    end

    def _ended? object
      as_context_run @_ended_when, object
    end

    class Rule
      attr_reader :name

      def initialize name, context
        @name = name
        @context = context

        @apply_when = []
        @possibilities = []
      end

      def apply_when &block
        @apply_when << block
      end

      def possibility &block
        @possibilities << block
      end

      def applies_on? object, history
        @apply_when.each do |apply_when|
          return true if @context.as_context_run(apply_when, object, history)
        end
        return false
      end

      def generate_possibilities object, history
        @possibilities.collect do |possibility|
          object.duplicate.tap { |o| @context.as_context_run(possibility, o, history) }
        end
      end
    end

    private_constant :Rule

    class Rejection
      attr_reader :reason

      def initialize reason, context
        @reason = reason
        @context = context

        @apply_on = []
        @rejections_if = []
      end

      def apply_on &block
        @apply_on << block
      end

      def reject_if &block
        @rejections_if << block
      end

      def applies_on? object, previous_objects
        @apply_on.each do |apply_on|
          return true if @context.as_context_run(apply_on, object, previous_objects)
        end
        return false
      end

      def rejects? object, previous_objects
        @rejections_if.each do |rejection|
          return true if @context.as_context_run(rejection, object, previous_objects)
        end
        return false
      end

      AllChildrenRejected = Rejection.new "All children rejected", nil
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
  rule "3º" do
    apply_when { |chord| chord.fundamental && !chord.third }

    possibility { |chord| chord.third = chord.fundamental + 4 - 12 }
    possibility { |chord| chord.third = chord.fundamental + 4 }
    possibility { |chord| chord.third = chord.fundamental + 4 + 12 }
    possibility { |chord| chord.third = chord.fundamental + 4 + 24 }
  end

  rule "5º" do
    apply_when { |chord| chord.fundamental && !chord.fifth }

    possibility { |chord| chord.fifth = chord.fundamental + 7 - 12 }
    possibility { |chord| chord.fifth = chord.fundamental + 7 }
    possibility { |chord| chord.fifth = chord.fundamental + 7 + 12 }
    possibility { |chord| chord.fifth = chord.fundamental + 7 + 24 }
  end

  rule "duplication" do
    apply_when { |chord| chord.fundamental && !chord.duplicated }

    possibility { |chord| chord.duplicated = :fundamental; chord.duplicate_on = -12 }
    possibility { |chord| chord.duplicated = :fundamental; chord.duplicate_on = +12 }
    possibility { |chord| chord.duplicated = :third; chord.duplicate_on = +12 }
    possibility { |chord| chord.duplicated = :third; chord.duplicate_on = +24 }
    possibility { |chord| chord.duplicated = :fifth; chord.duplicate_on = +12 }
    possibility { |chord| chord.duplicated = :fifth; chord.duplicate_on = +24 }
  end

  ended_when do |chord|
    chord.soprano && chord.alto && chord.tenor && chord.bass
  end

  reject "more than octave apart bass - tenor" do
    apply_on { |chord| chord.tenor && chord.bass }
    reject_if { |chord| chord.tenor - chord.bass > 12 }
  end

  reject "more than octave apart tenor - alto" do
    apply_on { |chord| chord.alto && chord.tenor }
    reject_if { |chord| chord.alto - chord.tenor > 12 }
  end

  reject "more than octave apart alto - soprano" do
    apply_on { |chord| chord.soprano && chord.alto }
    reject_if { |chord| chord.soprano - chord.alto > 12 }
  end

  reject "parallel fifth" do
    apply_on { |chord, history| !history.empty? && chord.soprano && chord.alto && chord.tenor && chord.bass }

    reject_if do |chord, history|
      (0..3).find do |voice|
        (0..3).to_a.tap { |vv| vv.delete voice }.find do |voice2|
          # 5ª entre 2 voces del acorde
          # 5ª en el acorde anterior con las mismas voces
          (chord.ordered[voice] - chord.ordered[voice2]) % 12 == 7 &&
          (history.last.ordered[voice] - history.last.ordered[voice2]) % 12 == 7
        end
      end
    end
  end

  reject "parallel octave" do
    apply_on { |chord, history| !history.empty? && chord.soprano && chord.alto && chord.tenor && chord.bass }

    reject_if do |chord, history|
      (0..3).find do |voice|
        (0..3).to_a.tap { |vv| vv.delete voice }.find do |voice2|
          # 8ª entre 2 voces del acorde
          # 8ª en el acorde anterior con las mismas voces
          (chord.ordered[voice] - chord.ordered[voice2]) % 12 == 0 &&
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
      #pp n.combinations

      expect(result).to eq nil
    end
  end
end
