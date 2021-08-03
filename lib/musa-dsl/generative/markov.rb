require_relative '../series'

module Musa

  # TODO: adapt to series prototyping

  module Markov
    class Markov
      include Musa::Extension::SmartProcBinder
      include Musa::Series::Serie.base

      def initialize(transitions:, start:, finish: nil, random: nil)
        @transitions = transitions.clone.freeze

        @start = start
        @finish = finish

        @random = Random.new random if random.is_a?(Integer)
        @random ||= Random.new

        @procedure_binders = {}

        mark_as_prototype!
        init
      end

      attr_accessor :start
      attr_accessor :finish
      attr_accessor :random
      attr_accessor :transitions

      private def _init
        @current = nil
        @finished = false
        @history = []
      end

      private def _next_value
        if @finished
          @current = nil
        else
          if @current.nil?
            @current = @start
          else
            if @transitions.has_key?(@current)
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
                procedure_binder = @procedure_binders[options] ||= SmartProcBinder.new(options)
                @current = procedure_binder.call @history
              else
                raise ArgumentError, "Option #{option} is not allowed. Only Array, Hash or Proc are allowed."
              end
            else
              raise RuntimeError, "No transition defined for #{@current}"
            end
          end

          @history << @current
          @finished = true if !@finish.nil? && (@current == @finish)
        end

        @current
      end

      def infinite?
        @finish.nil?
      end
    end
  end
end

