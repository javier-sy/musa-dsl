require 'musa-dsl/series'

module Musa

  class Markov
    include Serie

    attr_accessor :start, :finish, :random, :transitions

    def initialize transitions:, start:, finish:, random: nil
      @transitions = transitions

      @start = start
      @finish = finish

      @random = Random.new random if random.is_a?(Integer)
      @random ||= Random.new

      @procedure_binders = {}

      restart
    end

    def _restart
      @current = nil
      @finished = false
      @history = []
    end

    def _next_value
      if @finished
        @current = nil
      else
        if @current.nil?
          @current = @start
        else
          if @transitions.has_key? @current
            options = @transitions[@current]

            case options
            when Array
              @current = options[@random.rand(0...options.size)]

            when Hash
              total = accumulated = 0.0
              options.each_value { |probability| total += probability.abs }
              r = @random.rand total

              @current = options.find { |key, probability|
                accumulated += probability;
                r >= accumulated - probability && r < accumulated }[0]

            when Proc
              procedure_binder = @procedure_binders[options] ||= KeyParametersProcedureBinder.new options
              @current = procedure_binder.call @history
            else
              raise ArgumentError, "Option #{option} is not allowed. Only Array, Hash or Proc are allowed."
            end
          else
            raise RuntimeError, "No transition defined for #{@current}"
          end
        end

        @history << @current
        @finished = true if @current == @finish
      end

      @current
    end

    # TODO implement infinite? regarding finish and transitions graph
    def infinite?
      false
    end

    def deterministic?
      false
    end
  end
end
