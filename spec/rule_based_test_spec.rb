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

module Rules
  class << self
    def included base
      base.extend ClassMethods
    end
  end

  module ClassMethods
    attr_reader :rules, :rejections

    def rule name, &block
      @rules ||= []
      @rules << Rule.new(name).tap { |r| r.as_context_run block }
    end

    def ended_when &block
      if block_given?
        @ended_when = block
      else
        @ended_when
      end
    end

    def reject reason, &block
      @rejections ||= []
      @rejections << Rejection.new(reason).tap { |r| r.as_context_run block }
    end
  end

  class Rule
    attr_reader :name, :apply_on, :possibilities

    def initialize name
      @name = name
      @apply_on = []
      @possibilities = []
    end

    def apply_on &block
      @apply_on << block
    end

    def possibility &block
      @possibilities << block
    end

    def applies_on? object, history
      @apply_on.each do |apply_on|
        return true if apply_on.call(object, history)
      end
      return false
    end

    def generate_possibilities object, history
      @possibilities.collect do |possibility|
        object.duplicate.tap { |o| possibility.call o, history }
      end
    end
  end

  class Rejection
    attr_reader :reason, :apply_on, :rejections_if

    def initialize reason
      @reason = reason

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
        return true if apply_on.call(object, previous_objects)
      end
      return false
    end

    def rejects? object, previous_objects
      @rejections_if.each do |rejection|
        return true if rejection.call(object, previous_objects)
      end
      return false
    end

    AllChildrenRejected = Rejection.new "All children rejected"
  end

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

  def generate_possibilities object, confirmed_node = nil, node = nil, rules = nil
    node ||= Node.new
    rules ||= self.class.rules.clone

    history = confirmed_node.history if confirmed_node
    history ||= []

    rule = rules.find { |r| r.applies_on? object, history }

    if rule
      rules.delete rule

      rule.generate_possibilities(object, history).each do |new_object|

        new_node = Node.new(new_object, node)
        new_node.mark_as_ended! if self.class.ended_when.call new_object

        rejection =
          self.class.rejections.find { |rejection|
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
end

class ChordProgression
  include Rules

  rule "fundamental" do
    apply_on { |chord| !chord.fundamental }

    possibility { |chord| chord.fundamental = @fundamental }
    possibility { |chord| chord.fundamental = @fundamental + 12 }
    possibility { |chord| chord.fundamental = @fundamental - 12 }
  end

  rule "3º" do
    apply_on { |chord| chord.fundamental && !chord.third }

    possibility { |chord| chord.third = chord.fundamental + 4 - 12 }
    possibility { |chord| chord.third = chord.fundamental + 4 }
    possibility { |chord| chord.third = chord.fundamental + 4 + 12 }
    possibility { |chord| chord.third = chord.fundamental + 4 + 24 }
  end

  rule "5º" do
    apply_on { |chord| chord.fundamental && !chord.fifth }

    possibility { |chord| chord.fifth = chord.fundamental + 7 - 12 }
    possibility { |chord| chord.fifth = chord.fundamental + 7 }
    possibility { |chord| chord.fifth = chord.fundamental + 7 + 12 }
    possibility { |chord| chord.fifth = chord.fundamental + 7 + 24 }
  end

  rule "duplication" do
    apply_on { |chord| chord.fundamental && !chord.duplicated }

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
      include Musa::Series

      rules = ChordProgression.new

      l = [Chord.new(60), Chord.new(65), Chord.new(67)]

      n = rules.apply l

      #pp n.fish
      pp n.combinations

      expect(result).to eq nil
    end
  end
end
