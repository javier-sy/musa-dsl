require 'musa-dsl/core-ext/duplicate'
require 'musa-dsl/generative/generative-grammar'

module Musa
  module SerieOperations end

  module SeriePrototyping
    def prototype?
      @is_instance ? false : true
    end

    def instance?
      @is_instance ? true : false
    end

    def prototype
      if @is_instance
        @instance_of || (@instance_of = clone.tap(&:_prototype).mark_as_prototype!)
      else
        self
      end
    end

    def _prototype
      nil
    end

    alias_method :p, :prototype

    def mark_as_prototype!
      @is_instance = nil
      freeze
    end

    protected :_prototype, :mark_as_prototype!

    def mark_regarding!(source)
      if source.prototype?
        mark_as_prototype!
      else
        mark_as_instance!
      end
    end

    protected :mark_regarding!

    def instance
      if @is_instance
        self
      else
        clone(freeze: false).tap(&:_instance).mark_as_instance!(self)
      end
    end

    alias_method :i, :instance

    def _instance
      nil
    end

    def mark_as_instance!(prototype = nil)
      @instance_of = prototype
      @is_instance = true
      self
    end

    protected :_instance, :mark_as_instance!

    class PrototypingSerieError < RuntimeError
      def initialize(message = nil)
        message ||= 'This serie is a prototype serie: cannot be consumed. To consume the serie use an instance serie via .instance method'
        super message
      end
    end
  end

  module Serie
    include SeriePrototyping
    include SerieOperations

    def restart
      raise PrototypingSerieError unless @is_instance

      @_have_peeked_next_value = false
      @_peeked_next_value = nil
      @_have_current_value = false
      @_current_value = nil

      _restart if respond_to? :_restart

      self
    end

    def next_value
      raise PrototypingSerieError unless @is_instance

      unless @_have_current_value && @_current_value.nil?
        if @_have_peeked_next_value
          @_have_peeked_next_value = false
          @_current_value = @_peeked_next_value
        else
          @_current_value = _next_value
        end
      end

      propagate_value @_current_value

      @_current_value
    end

    alias_method :v, :next_value

    def peek_next_value
      raise PrototypingSerieError unless @is_instance

      unless @_have_peeked_next_value
        @_have_peeked_next_value = true
        @_peeked_next_value = _next_value
      end

      @_peeked_next_value
    end

    def current_value
      raise PrototypingSerieError unless @is_instance

      @_current_value
    end

    def infinite?
      false
    end

    # TODO: test case
    def to_a(recursive: nil, duplicate: nil, restart: nil, dr: nil)

      def copy_included_modules(source, target)
        target.tap do
          source.singleton_class.included_modules.each do |m|
            target.extend m unless target.is_a? m
          end
        end
      end

      def process(value)
        case value
        when Serie
          value.to_a(recursive: true, restart: false, duplicate: false)
        when Array
          a = value.clone
          a.collect! { |v| v.is_a?(Serie) ? v.to_a(recursive: true, restart: false, duplicate: false) : process(v) }
        when Hash
          h = value.clone
          h.transform_values! { |v| v.is_a?(Serie) ? v.to_a(recursive: true, restart: false, duplicate: false) : process(v) }
        else
          value
        end
      end

      recursive ||= false

      dr ||= instance?

      duplicate = dr if duplicate.nil?
      restart = dr if restart.nil?

      throw 'Cannot convert to array an infinite serie' if infinite?

      array = []

      serie = instance

      serie = serie.duplicate if duplicate
      serie = serie.restart if restart

      while value = serie.next_value
        array << if recursive
                   process(value)
                 else
                   value
                 end
      end

      array
    end

    alias_method :a, :to_a

    def to_node(**attributes)
      Nodificator.to_node(self, **attributes)
    end

    alias_method :node, :to_node

    class Nodificator
      extend Musa::GenerativeGrammar

      def self.to_node(serie, **attributes)
        N(serie, **attributes)
      end
    end

    private_constant :Nodificator

    protected

    def propagate_value(value)
      @_slaves.each { |s| s.push_next_value value } if @_slaves
    end
  end

  class Slave
    include Serie

    attr_reader :master

    def initialize(master)
      @master = master
      @next_value = []
    end

    def _restart
      throw OperationNotAllowedError, "SlaveSerie #{self}: slave series cannot be restarted"
    end

    def next_value
      value = @next_value.shift

      raise "Warning: slave serie #{self} has lost sync with his master serie #{@master}" if value.nil? && !@master.peek_next_value.nil?

      propagate_value value

      value
    end

    def peek_next_value
      value = @next_value.first

      raise "Warning: slave serie #{self} has lost sync with his master serie #{@master}" if value.nil? && !@master.peek_next_value.nil?

      value
    end

    def infinite?
      @master.infinite?
    end

    def push_next_value(value)
      @next_value << value
    end
  end
end
