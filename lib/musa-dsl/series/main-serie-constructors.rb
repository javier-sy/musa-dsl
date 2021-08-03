require_relative '../core-ext/arrayfy'
require_relative '../core-ext/smart-proc-binder'

require_relative 'base-series'

using Musa::Extension::Arrayfy
using Musa::Extension::ExplodeRanges

# TODO: añadir en for: steps: (nº de pasos en los que repartir el incremento)

module Musa
  module Series::Constructors
    def UNDEFINED
      UndefinedSerie.new
    end

    def NIL
      NilSerie.new
    end

    def S(*values)
      FromArray.new values.explode_ranges
    end

    def H(**series_hash)
      FromHashOfSeries.new series_hash, false
    end

    def HC(**series_hash)
      FromHashOfSeries.new series_hash, true
    end

    def A(*series)
      FromArrayOfSeries.new series, false
    end

    def AC(*series)
      FromArrayOfSeries.new series, true
    end

    def E(*value_args, **key_args, &block)
      FromEvalBlockWithParameters.new *value_args, **key_args, &block
    end

    def FOR(from: nil, to: nil, step: nil)
      from ||= 0
      step ||= 1
      ForLoop.new from, to, step
    end

    def RND(*_values, values: nil, from: nil, to: nil, step: nil, random: nil)
      raise ArgumentError, "Can't use both direct values #{_values} and values named parameter #{values} at the same time." if values && !_values.empty?

      random = Random.new random if random.is_a?(Integer)
      random ||= Random.new

      values ||= _values

      if !values.empty? && from.nil? && to.nil? && step.nil?
        RandomValuesFromArray.new values.explode_ranges, random
      elsif values.empty? && !to.nil?
        from ||= 0
        step ||= 1
        RandomNumbersFromRange.new from, to, step, random
      else
        raise ArgumentError, 'cannot use values and from:/to:/step: together'
      end
    end

    def MERGE(*series)
      Sequence.new(series)
    end

    def RND1(*_values, values: nil, from: nil, to: nil, step: nil, random: nil)
      raise ArgumentError, "Can't use both direct values #{_values} and values named parameter #{values} at the same time." if values && !_values.empty?

      random = Random.new random if random.is_a?(Integer)
      random ||= Random.new

      values ||= _values

      if !values.empty? && from.nil? && to.nil? && step.nil?
        RandomValueFromArray.new values.explode_ranges, random
      elsif values.empty? && !to.nil?
        from ||= 0
        step ||= 1
        RandomNumberFromRange.new from, to, step, random
      else
        raise ArgumentError, 'cannot use values and from:/to:/step: parameters together'
      end
    end

    def SIN(start_value: nil, steps: nil, amplitude: nil, center: nil)
      amplitude ||= 1.0
      center ||= 0.0
      start_value ||= center
      SinFunction.new start_value, steps, amplitude, center
    end

    def FIBO()
      Fibonacci.new
    end

    def HARMO(error: nil, extended: nil)
      error ||= 0.5
      extended ||= false
      HarmonicNotes.new error, extended
    end

    ###
    ### Implementation
    ###

    class UndefinedSerie
      include Series::Serie.base

      def initialize
        mark_as_undefined!
      end
    end

    private_constant :UndefinedSerie

    class NilSerie
      include Series::Serie.base

      def initialize
        mark_as_prototype!
      end

      def _next_value; nil; end
    end

    private_constant :NilSerie

    class FromArray
      include Series::Serie.base

      def initialize(values = nil, extends = nil)
        @values = values
        mark_as_prototype!

        x = self
        extends.arrayfy.each do |e|
          x.extend(e)
        end

        init
      end

      attr_accessor :values

      private def _init
        @index = 0
      end

      private def _next_value
        if @values && @index < @values.size
          value = @values[@index]
          @index += 1
        else
          value = nil
        end

        value
      end
    end

    # private_constant :FromArray

    class Sequence
      include Series::Serie.with(sources: true)

      def initialize(series)
        self.sources = series
        init
      end

      attr_reader :sources

      private def _init
        @index = 0
        @restart_sources = false
      end

      private def _restart
        @sources[0].restart
        @restart_sources = true
      end

      private def _next_value
        value = nil

        if @index < @sources.size
          value = @sources[@index].next_value

          if value.nil?
            @index += 1
            if @index < @sources.size
              @sources[@index].restart if @restart_sources
              value = next_value
            end
          end
        end

        value
      end

      def infinite?
        !!@sources.find(&:infinite?)
      end
    end

    private_constant :Sequence

    class FromEvalBlockWithParameters
      include Series::Serie.with(smart_block: true)

      using Extension::DeepCopy

      def initialize(*parameters, **key_parameters, &block)
        raise ArgumentError, 'Yield block is undefined' unless block

        @original_value_parameters = parameters
        @original_key_parameters = key_parameters

        self.proc = block

        mark_as_prototype!

        init
      end

      def parameters
        @original_value_parameters
      end

      def parameters=(values)
        @original_value_parameters = values
      end

      def key_parameters
        @original_key_parameters
      end

      def key_parameters=(key_values)
        @original_key_parameters = key_values
      end

      private def _init
        @value_parameters = @original_value_parameters.clone(deep: true)
        @key_parameters = @original_key_parameters.clone(deep: true)

        @first = true
        @value = nil
      end

      private def _next_value
        @value = if !@value.nil? || @value.nil? && @first
                   @value = @block.call(*@value_parameters, last_value: @value, caller: self, **@key_parameters)
                 else
                   nil
                 end

        @first = false
        @value
      end
    end

    private_constant :FromEvalBlockWithParameters

    class ForLoop
      include Series::Serie.base

      def initialize(from, to, step)
        @from = from
        @to = to
        @step = step

        sign_adjust_step

        mark_as_prototype!

        init
      end

      attr_reader :from, :to, :step

      def from=(value)
        @from = value
        sign_adjust_step
      end

      def to=(value)
        @to = value
        sign_adjust_step
      end

      def step=(value)
        @step = value
        sign_adjust_step
      end

      private def _init
        @value = @from - @step
      end

      private def _next_value
        if @value
          @value += @step
          value = @value
        end

        @value = nil if @to && @value && (@value >= @to && @step.positive? || @value <= @to && @step.negative?)

        value
      end

      def infinite?
        @to.nil?
      end

      private def sign_adjust_step
        @step = (-@step if @to && (@from < @to && @step < 0 || @from > @to && @step > 0)) || @step
      end
    end

    private_constant :ForLoop

    class RandomValueFromArray
      include Series::Serie.base

      def initialize(values, random)
        @values = values
        @random = random

        mark_as_prototype!

        init
      end

      attr_accessor :values, :random

      private def _init
        @value = nil
      end

      private def _next_value
        if @value
          nil
        else
          @value = @values[@random.rand(0...@values.size)]
        end
      end
    end

    private_constant :RandomValueFromArray

    class RandomNumberFromRange
      include Series::Serie.base

      def initialize(from, to, step, random)
        @from = from
        @to = to
        @step = step

        adjust_step

        @random = random

        mark_as_prototype!

        init
      end

      attr_reader :from

      def from=(value)
        @from = value
        sign_adjust_step
      end

      attr_reader :to

      def to=(value)
        @to = value
        sign_adjust_step
      end

      attr_reader :step

      def step=(value)
        @step = value
        sign_adjust_step
      end

      attr_accessor :random

      private def _init
        @value = nil
      end

      private def _next_value
        if @value
          nil
        else
          @value = @from + @random.rand(0..@step_count) * @step
        end
      end

      private def adjust_step
        @step = (-@step if @from < @to && @step < 0 || @from > @to && @step > 0) || @step
        @step_count = ((@to - @from) / @step).to_i
      end
    end

    private_constant :RandomNumberFromRange

    class RandomValuesFromArray
      include Series::Serie.base

      def initialize(values, random)
        @values = values.clone.freeze
        @random = random

        mark_as_prototype!

        init
      end

      attr_accessor :values
      attr_accessor :random

      private def _init
        @available_values = @values.dup
      end

      private def _next_value
        value = nil
        unless @available_values.empty?
          i = @random.rand(0...@available_values.size)
          value = @available_values[i]
          @available_values.delete_at i
        end
        value
      end
    end

    private_constant :RandomValuesFromArray

    class RandomNumbersFromRange
      include Series::Serie.base

      def initialize(from, to, step, random)
        @from = from
        @to = to
        @step = step

        adjust_step

        @random = random

        mark_as_prototype!

        init
      end

      attr_reader :from

      def from=(value)
        @from = value
        adjust_step
      end

      attr_reader :to

      def to=(value)
        @to = value
        adjust_step
      end

      attr_reader :step

      def step=(value)
        @step = value
        adjust_step
      end

      attr_accessor :random

      private def _init
        @available_steps = (0..@step_count).to_a
      end

      private def _next_value
        value = nil
        unless @available_steps.empty?
          i = @random.rand(0...@available_steps.size)
          value = @from + @available_steps[i] * @step unless @value
          @available_steps.delete_at i
        end
        value
      end

      private def adjust_step
        @step = (-@step if @from < @to && @step < 0 || @from > @to && @step > 0) || @step
        @step_count = ((@to - @from) / @step).to_i
      end
    end

    private_constant :RandomNumbersFromRange

    class FromHashOfSeries
      include Series::Serie.with(sources: true)

      def initialize(hash_of_series, cycle_all_series)
        self.sources = hash_of_series
        self.cycle = cycle_all_series

        init
      end

      attr_accessor :cycle

      private def _init
        @have_current = false
        @value = nil
      end

      private def _restart
        @sources.values.each(&:restart)
      end

      private def _next_value
        unless @have_current && @value.nil?
          pre_value = @sources.collect { |key, serie| [key, serie.peek_next_value] }.to_h

          nils = 0
          pre_value.each do |key, value|
            if value.nil?
              @sources[key].next_value
              nils += 1
            end
          end

          if nils.zero?
            @value = @sources.collect { |key, serie| [key, serie.next_value] }.to_h

          elsif nils < @sources.size && @cycle
            _soft_restart
            @value = next_value

          else
            @value = nil
          end

          @have_current = true
        end

        @value
      end

      private def _soft_restart
        @sources.each do |_key, serie|
          serie.restart if serie.current_value.nil?
        end
      end
    end

    private_constant :FromHashOfSeries

    class FromArrayOfSeries
      include Series::Serie.with(sources: true)

      def initialize(series_array, cycle_all_series)
        self.sources = series_array
        self.cycle = cycle_all_series

        init
      end

      attr_accessor :cycle

      private def _init
        @have_current = false
        @value = nil
      end

      private def _restart
        @sources.each(&:restart)
      end

      private def _next_value
        unless @sources.empty? || @have_current && @value.nil?
          pre_value = @sources.collect(&:peek_next_value)

          nils = 0
          pre_value.each_index do |i|
            if pre_value[i].nil?
              @sources[i].next_value
              nils += 1
            end
          end

          if nils.zero?
            @value = @sources.collect(&:next_value)

          elsif nils < @sources.size && @cycle
            _soft_restart
            @value = next_value

          else
            @value = nil
          end

          @have_current = true
        end

        @value
      end

      private def _soft_restart
        @sources.each do |serie|
          serie.restart if serie.current_value.nil?
        end
      end
    end

    private_constant :FromArrayOfSeries

    class SinFunction
      include Series::Serie.base

      def initialize(start, steps, amplitude, center)
        @start = start.to_f

        @steps = steps
        @amplitude = amplitude.to_f
        @center = center.to_f

        update

        mark_as_prototype!

        init
      end

      attr_reader :start

      def start=(value)
        @start = value.to_f
        update
      end

      attr_reader :steps

      def steps=(value)
        @steps = value
        update
      end

      attr_reader :amplitude

      def amplitude=(value)
        @amplitude = value
        update
      end

      attr_reader :center

      def center=(value)
        @center = value
        update
      end

      private def _init
        @position = 0
      end

      private def _next_value
        value = nil
        unless @position >= @steps
          value = Math.sin(@offset + @step_size * @position) * (@amplitude / 2.0) + @center
          @position += 1
        end
        value
      end

      private def update
        y = 2 * (@start - @center) / @amplitude
        warn "WARNING: value for offset calc #{y} is outside asin range" if y < -1 || y > 1
        y = 1.0 if y > 1.0 # por los errores de precisión infinitesimal en el cálculo de y cuando es muy próximo a 1.0
        y = -1.0 if y < -1.0

        @offset = Math.asin(y)
        @step_size = 2.0 * Math::PI / @steps
      end

      def to_s
        "offset: #{@offset.round(3)}rd amplitude: #{@amplitude.round(3)} center: #{@center.round(3)} length: #{@length} step_size: #{@step_size.round(6)}"
      end
    end

    private_constant :SinFunction

    class Fibonacci
      include Series::Serie.base

      def initialize
        mark_as_prototype!
        init
      end

      private def _init
        @a = 0
        @b = 1
      end

      private def _next_value
        initial_b = @b
        @b = @a + @b
        @a = initial_b

        @a
      end

      def infinite?
        true
      end
    end

    private_constant :Fibonacci

    class HarmonicNotes
      include Series::Serie.base

      def initialize(error, extended)
        @error = error
        @extended = extended

        mark_as_prototype!

        init
      end

      attr_reader :error

      def error=(value)
        @error = value
      end

      attr_reader :extended

      def extended=(value)
        @extended = value
      end

      def _init
        @harmonic = 0
      end

      def _next_value
        begin
          @harmonic += 1

          candidate_note = 12 * Math::log(@harmonic, 2)

          lo = candidate_note.floor
          hi = candidate_note.ceil

          best = (candidate_note - lo) <= (hi - candidate_note) ? lo : hi

          error = candidate_note - best

        end until error.abs <= @error

        if @extended
          { pitch: best, error: error }
        else
          best
        end
      end

      def infinite?
        true
      end
    end

    private_constant :HarmonicNotes
  end
end
