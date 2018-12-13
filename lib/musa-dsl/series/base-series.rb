module Musa
  module SerieOperations
  end

  module Serie
    include SerieOperations

    def restart
      @_have_peeked_next_value = false
      @_peeked_next_value = nil
      @_have_current_value = false
      @_current_value = nil

      _restart if respond_to? :_restart

      self
    end

    def next_value
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
      unless @_have_peeked_next_value
        @_have_peeked_next_value = true
        @_peeked_next_value = _next_value
      end

      @_peeked_next_value
    end

    def current_value
      @_current_value
    end

    def infinite?
      false
    end

    def deterministic?
      true
    end

    alias r restart
    alias d duplicate

    def dr
      duplicate.restart
    end

    protected

    def propagate_value(value)
      @_slaves.each { |s| s.push_next_value value } if @_slaves
    end
  end

  class SlaveSerie
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

    def deterministic?
      false
    end

    def push_next_value(value)
      @next_value << value
    end
  end
end
