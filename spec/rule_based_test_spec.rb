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

    def reject reason, &block
      @rejections ||= []
      @rejections << Rejection.new(reason, block)
    end

    def ended_when &block
      @ended_when = block
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

    def initialize reason, block = nil
      @reason = reason
      @block = block

      @apply_on = []
      @rejections_if = []
    end

    def apply_on &block
      @apply_on << block
    end

    def reject_if &block
      @rejections_if << block
    end

    def applies_on? element, previous_objects
      @apply_on.each do |apply_on|
        return true if apply_on.call(element, previous_objects)
      end
      return false
    end

    def rejects? object, previous_objects
      @block.call object, previous_objects
    end

    AllChildrenRejected = Rejection.new "All children rejected"
  end

  class Node
    attr_reader :parent, :children, :object, :rejected

    def initialize object = nil, parent = nil
      @parent = parent
      @children = []
      @object = object

      @rejected = nil
    end

    def update_rejection_by_children!
      reject! Rejection::AllChildrenRejected, propagate_parent: true if !@children.find { |n| !n.rejected }
    end

    def reject! rejection, propagate_parent: nil
      propagate_parent ||= false

      @rejected = rejection

      if @rejected && propagate_parent
        @parent.update_rejection_by_children!
      end
    end

    def previous_objects
      objects = []
      n = self
      while n = n.parent
        objects << n.object
      end
      objects.reverse
    end
  end

  def compute_children element, node = nil
    node ||= Node.new

    puts "compute_children: element = #{element}"

    previous_objects = node.previous_objects

    puts "compute_children: previous_objects = #{previous_objects}"

    self.class.rules.each do |rule|
      puts "compute_children: checking rule #{rule.name}..."

      if rule.applies_on? element, previous_objects
        puts "compute_children: checking rule #{rule.name}... applies!"

        rule.generate_possibilities(element, previous_objects).each do |object|
          puts "compute_children: generated #{object}"

          node.children << Node.new(object, node)
        end
      end
    end


    self.class.rejections.each do |rejection|
      node.children.each do |child|
        if rejection.applies_on? child.object, previous_objects
          if rejection.rejects? child.object, previous_objects
            child.reject! rejection
            break
          end
        end
      end
    end

    node.update_rejection_by_children!

    node
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
    apply_on { |chord, pre| chord.fundamental && chord.third && chord.fifth && !chord.duplicated }

    possibility { |chord, pre| chord.duplicated = :fundamental; chord.duplicate_on = -12 }
    possibility { |chord, pre| chord.duplicated = :fundamental; chord.duplicate_on = +12 }
    possibility { |chord, pre| chord.duplicated = :third; chord.duplicate_on = +12 }
    possibility { |chord, pre| chord.duplicated = :third; chord.duplicate_on = 0 }
    possibility { |chord, pre| chord.duplicated = :fifth; chord.duplicate_on = +12 }
    possibility { |chord, pre| chord.duplicated = :fifth; chord.duplicate_on = 0 }
  end

  ended_when do |chord|
    chord.fundamental && chord.third && chord.fifth && chord.duplicated
  end


  reject "octave apart" do
    apply_on { |chord, pre| chord.soprano && chord.alto && chord.tenor && chord.bass }

    reject_if do |chord, pre|
      chord.soprano - chord.alto > 12 ||
      chord.alto - chord.tenor > 12 ||
      chord.tenor - chord.bass > 12
    end
  end

  reject "parallel fifth" do |chord, pre|
    apply_on { |chord, pre| chord.soprano && chord.alto && chord.tenor && chord.bass }

    reject_if do |chord, pre|
      (1..4).each do |voice|
        (1..4).to_a.tap { |vv| vv.delete voice }.each do |voice2|
          # 5ª entre 2 voces del acorde
          if (chord.ordered[voice] - chord.ordered[voice2]) % 12 == 7
            # 5ª en el acorde anterior con las mismas voces
            if (pre.last[voice] - pre.last[voice2]) % 12 == 7
              return true
            end
          end
        end
      end
      return false
    end
  end

  reject "parallel octave" do |chord, pre|
    apply_on { |chord, pre| chord.soprano && chord.alto && chord.tenor && chord.bass }

    reject_if do |chord, pre|
      (1..4).each do |voice|
        (1..4).to_a.tap { |vv| vv.delete voice }.each do |voice2|
          # 8ª entre 2 voces del acorde
          if (chord.ordered[voice] - chord.ordered[voice2]) % 12 == 0
            # 8ª en el acorde anterior con las mismas voces
            if (pre.last[voice] - pre.last[voice2]) % 12 == 0
              return true
            end
          end
        end
      end
      return false
    end
  end
end

RSpec.describe "Rules" do # Musa::Rules
	context "Prototype" do
		it "Basic definition" do
      rules = ChordProgression.new

      result = rules.compute_children Chord.new(60)

      puts "result = #{result}"

      #result = rules.apply Chord.new(60), Chord.new(67), Chord.new(65), Chord.new(60)

      expect(result).to eq nil
    end
  end
end
