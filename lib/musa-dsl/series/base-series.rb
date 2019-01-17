require 'musa-dsl/mods/duplicate'
require 'musa-dsl/generative/generative-grammar'

module Musa
  module SerieOperations end

  module Serie
    include SerieOperations

    alias_method :d, :duplicate

    def dr
      duplicate.restart
    end

    def prototype?
      !!@is_prototype
    end

    def mark_as_prototype!
      unless @is_prototype
        restart
        @is_prototype = true
      end
      self
    end

    alias_method :p, :mark_as_prototype!

    def instance
      if @is_prototype
        new = duplicate
        new.mark_as_instance!
      else
        self
      end
    end

    alias_method :i, :instance

    def mark_as_instance!
      @is_prototype = false
      restart
    end

    protected :mark_as_instance!

    def pn
      mark_as_prototype!.to_node
    end

    class PrototypeSerieError < RuntimeError
      def initialize
        super
      end
    end

    def restart
      raise PrototypeSerieError if @is_prototype

      @_have_peeked_next_value = false
      @_peeked_next_value = nil
      @_have_current_value = false
      @_current_value = nil

      _restart if respond_to? :_restart

      self
    end

    def next_value
      raise PrototypeSerieError if @is_prototype

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

    def peek_next_value
      raise PrototypeSerieError if @is_prototype

      unless @_have_peeked_next_value
        @_have_peeked_next_value = true
        @_peeked_next_value = _next_value
      end

      @_peeked_next_value
    end

    def current_value
      raise PrototypeSerieError if @is_prototype

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

      dr ||= !prototype?

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

    alias_method :n, :to_node

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
