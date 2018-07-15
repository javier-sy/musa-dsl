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
    "Chord: fundamental = #{@fundamental} third = #{@third} fifth = #{@fifth} duplicated = #{@duplicated} on #{@duplicate_on}"
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

    def applies_on? element, previous_objects
      @apply_on.each do |apply_on|
        return true if apply_on.call(element, previous_objects)
      end
      return false
    end

    def generate_possibilities element, previous_objects
      @possibilities.collect do |possibility|
        element.duplicate.tap { |e| possibility.call e, previous_objects }
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

    def update_rejection_by_children!
      reject! Rejection::AllChildrenRejected, propagate_parent: true if !@children.empty? && !@children.find { |n| !n.rejected }

      self
    end

    def reject! rejection, propagate_parent: nil
      propagate_parent ||= false

      @rejected = rejection
      puts "reject!: propagate_parent #{@rejected.reason}" if propagate_parent

      if @rejected && propagate_parent && @parent
        @parent.update_rejection_by_children!
      end

      self
    end

    def mark_as_ended!
      @ended = true

      self
    end

    def ended?
      @ended
    end

    def previous_objects
      objects = []
      n = self
      while n && n.object
        objects << n.object
        n = n.parent
      end
      return objects.reverse
    end

    def fish
      purged = []

      @children.each do |node|
        unless node.rejected
          if node.ended?
            purged << node.object
          else
            node.fish.each do |object|
              purged << object
            end
          end
        end
      end

      return purged
    end

    protected

    def parent= new_parent
      @parent = new_parent
    end
  end

  def compute_children object, confirmed_node = nil, node = nil, rules = nil
    node ||= Node.new
    rules ||= self.class.rules.clone

    previous_objects = confirmed_node.previous_objects if confirmed_node
    previous_objects ||= []

    puts "compute_children: previous_objects = #{previous_objects}"

    rule = rules.find { |r| r.applies_on? object, previous_objects }

    if rule
      #puts "compute_children: checking rule #{rule.name}... applies!"

      rules.delete rule

      rule.generate_possibilities(object, previous_objects).each do |new_object|

        new_node = Node.new(new_object, node)
        new_node.mark_as_ended! if self.class.ended_when.call new_object

        #puts "compute_children: generated #{new_object} [#{'Ended' if new_node.ended?}]"

        rejection = calc_rejected new_node, previous_objects
        #puts "compute_children: generated #{new_object}... rejected because #{rejection.reason}" if rejection
        new_node.reject! rejection if rejection

        node.children << new_node
      end

      node.update_rejection_by_children!
    end

    unless rules.empty?
      node.children.each do |node|
        compute_children node.object, confirmed_node, node, rules.clone unless node.rejected || node.ended?
      end
    end

    node
  end

  def calc_rejected node, previous_objects
    self.class.rejections.find do |rejection|
      rejection.applies_on?(node.object, previous_objects) && rejection.rejects?(node.object, previous_objects)
    end
  end

  def process list, node = nil

    list = list.clone

    node ||= Node.new

    object = list.shift

    if object
      result = compute_children object, node

      result.fish.each do |o|
        n = node.add(o).mark_as_ended!
        process list, n
      end
    end

    return node
  end


end

class ChordProgression
  include Rules

  rule "fundamental" do
    apply_on { |chord, pre| !chord.fundamental }

    possibility { |chord, pre| chord.fundamental = @fundamental }
    possibility { |chord, pre| chord.fundamental = @fundamental + 12 }
    possibility { |chord, pre| chord.fundamental = @fundamental - 12 }
  end

  rule "3º" do
    apply_on { |chord, pre| chord.fundamental && !chord.third }

    possibility { |chord, pre| chord.third = chord.fundamental + 4 }
    possibility { |chord, pre| chord.third = chord.fundamental + 4 + 12 }
    possibility { |chord, pre| chord.third = chord.fundamental + 4 + 24 }
  end

  rule "5º" do
    apply_on { |chord, pre| chord.fundamental && !chord.fifth }

    possibility { |chord, pre| chord.fifth = chord.fundamental + 7 }
    possibility { |chord, pre| chord.fifth = chord.fundamental + 7 + 12 }
    possibility { |chord, pre| chord.fifth = chord.fundamental + 7 + 24 }
  end

  rule "duplication" do
    apply_on { |chord, pre| chord.fundamental && !chord.duplicated }

    possibility { |chord, pre| chord.duplicated = :fundamental; chord.duplicate_on = -12 }
    possibility { |chord, pre| chord.duplicated = :fundamental; chord.duplicate_on = +12 }
    possibility { |chord, pre| chord.duplicated = :third; chord.duplicate_on = +12 }
    possibility { |chord, pre| chord.duplicated = :third; chord.duplicate_on = +24 }
    possibility { |chord, pre| chord.duplicated = :fifth; chord.duplicate_on = +12 }
    possibility { |chord, pre| chord.duplicated = :fifth; chord.duplicate_on = +24 }
  end

  ended_when do |chord|
    chord.soprano && chord.alto && chord.tenor && chord.bass
  end

  reject "more than octave apart bass - tenor" do
    apply_on { |chord, pre| chord.tenor && chord.bass }
    reject_if { |chord, pre| chord.tenor - chord.bass > 12 }
  end

  reject "more than octave apart tenor - alto" do
    apply_on { |chord, pre| chord.alto && chord.tenor }
    reject_if { |chord, pre| chord.alto - chord.tenor > 12 }
  end

  reject "more than octave apart alto - soprano" do
    apply_on { |chord, pre| chord.soprano && chord.alto }
    reject_if { |chord, pre| chord.soprano - chord.alto > 12 }
  end

=begin
  reject "parallel fifth" do
    apply_on { |chord, pre| !pre.empty? && chord.soprano && chord.alto && chord.tenor && chord.bass }

    reject_if do |chord, pre|
      (0..3).find do |voice|
        (0..3).to_a.tap { |vv| vv.delete voice }.find do |voice2|
          # 5ª entre 2 voces del acorde
          # 5ª en el acorde anterior con las mismas voces
          (chord.ordered[voice] - chord.ordered[voice2]) % 12 == 7 &&
          (pre.last.ordered[voice] - pre.last.ordered[voice2]) % 12 == 7
        end
      end
    end
  end

  reject "parallel octave" do
    apply_on { |chord, pre| !pre.empty? && chord.soprano && chord.alto && chord.tenor && chord.bass }

    reject_if do |chord, pre|
      (0..3).find do |voice|
        (0..3).to_a.tap { |vv| vv.delete voice }.find do |voice2|
          # 8ª entre 2 voces del acorde
          # 8ª en el acorde anterior con las mismas voces
          (chord.ordered[voice] - chord.ordered[voice2]) % 12 == 0 &&
          (pre.last.ordered[voice] - pre.last.ordered[voice2]) % 12 == 0
        end
      end
    end
  end
=end
end

RSpec.describe "Rules" do # Musa::Rules

	context "Prototype" do
		it "Basic definition" do
      include Musa::Series

      rules = ChordProgression.new

      l = [Chord.new(60), Chord.new(63), Chord.new(65)]

      n = rules.process l

      #pp n.fish
      pp n

      expect(result).to eq nil
    end
  end
end
