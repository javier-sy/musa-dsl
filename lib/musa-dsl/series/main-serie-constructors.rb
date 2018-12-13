require 'musa-dsl/mods/arrayfy'

# TODO: añadir en for: steps: (nº de pasos en los que repartir el incremento)

module Musa
  module Series
    def NIL
      NilBasicSerie.new
    end

    def S(*values)
      BasicSerieFromArray.new values.explode_ranges
    end

    def H(**series_hash)
      BasicSerieFromHash.new series_hash, false
    end

    def HC(**series_hash)
      BasicSerieFromHash.new series_hash, true
    end

    def A(*series)
      BasicSerieFromArrayOfSeries.new series, false
    end

    def AC(*series)
      BasicSerieFromArrayOfSeries.new series, true
    end

    def SS(serie)
      BasicSerieFromSerieOfSeries.new serie
    end

    def E(**args, &block)
      if args.key?(:start) && args.length == 1
        BasicSerieFromAutoEvalBlockOnSeed.new args[:start], &block
      elsif args.empty?
        BasicSerieFromEvalBlock.new &block
      else
        raise ArgumentError, 'only optional start: argument is allowed'
      end
    end

    def FOR(from: nil, to: nil, step: nil)
      from ||= 0
      step ||= 1
      ForLoopBasicSerie.new from, to, step
    end

    def RND(*values, from: nil, to: nil, step: nil, random: nil)
      random = Random.new random if random.is_a?(Integer)
      random ||= Random.new

      if !values.empty? && from.nil? && to.nil? && step.nil?
        RandomValuesFromArrayBasicSerie.new values.explode_ranges, random
      elsif values.empty? && !to.nil?
        from ||= 0
        step ||= 1
        RandomNumbersFromRangeBasicSerie.new from, to, step, random
      else
        raise ArgumentError, 'cannot use values and from:/to:/step: together'
      end
    end

    def RND1(*values, from: nil, to: nil, step: nil, random: nil)
      random = Random.new random if random.is_a?(Integer)
      random ||= Random.new

      if !values.empty? && from.nil? && to.nil? && step.nil?
        RandomValueFromArrayBasicSerie.new values.explode_ranges, random
      elsif values.empty? && !to.nil?
        from ||= 0
        step ||= 1
        RandomNumberFromRangeBasicSerie.new from, to, step, random
      else
        raise ArgumentError, 'cannot use values and from:/to:/step: parameters together'
      end
    end

    def SIN(start_value: nil, steps: nil, amplitude: nil, center: nil)
      start_value ||= 0.0
      amplitude ||= 1.0
      center ||= 0.0
      SinFunctionSerie.new start_value, steps, amplitude, center
    end

    def FIBO()
      FibonacciSerie.new
    end

    def HARMO(error: nil, extended: nil)
      error ||= 0.5
      extended ||= false
      HarmonicNotesSerie.new error, extended
    end

    ###
    ### Implementation
    ###

    class NilBasicSerie
      include Serie
      def _next_value
        nil
      end
    end

    private_constant :NilBasicSerie

    class BasicSerieFromArray
      include Serie

      attr_accessor :values

      def initialize(values = nil)
        @values = values
        @index = 0
      end

      def _restart
        @index = 0
      end

      def _next_value
        if @values && @index < @values.size
          value = @values[@index]
          @index += 1
        else
          value = nil
        end

        value
      end
    end

    private_constant :BasicSerieFromArray

    class BasicSerieFromAutoEvalBlockOnSeed
      include Serie

      attr_accessor :start, :block

      def initialize(start, &block)
        @start = start
        @block = block

        @current = nil
        @first = true
      end

      def _restart
        @current = nil
        @first = true
      end

      def _next_value
        if @first
          @first = false
          @current = @start
        else
          raise 'Block is undefined' unless @block

          @current = @block.call @current unless @current.nil?
        end

        @current
      end
    end

    private_constant :BasicSerieFromAutoEvalBlockOnSeed

    class BasicSerieFromEvalBlock
      include Serie

      attr_accessor :block

      def initialize(&block)
        @block = block
        _restart
      end

      def _restart
        @index = 0
        @value = nil
      end

      def _next_value
        raise 'Block is undefined' unless @block

        @value = @block.call @index unless @value.nil? && @index > 0
        value = @value
        @index += 1

        value
      end
    end

    private_constant :BasicSerieFromEvalBlock

    class ForLoopBasicSerie
      include Serie

      attr_reader :from, :to, :step

      def initialize(from, to, step)
        @from = from
        @to = to
        @step = step

        sign_adjust_step

        _restart
      end

      def from=(from)
        @from = from
        sign_adjust_step
      end

      def to=(to)
        @to = to
        sign_adjust_step
      end

      def step=(step)
        @step = step
        sign_adjust_step
      end

      def _restart
        @value = @from
      end

      def _next_value
        if @value
          value = @value
          @value += @step
        end

        @value = nil if @to && @value && (@value > @to && @step.positive? || @value < @to && @step.negative?)

        value
      end

      def infinite?
        @to.nil?
      end

      private

      def sign_adjust_step
        @step = (-@step if @to && (@from < @to && @step < 0 || @from > @to && @step > 0)) || @step
      end
    end

    private_constant :ForLoopBasicSerie

    class RandomValueFromArrayBasicSerie
      include Serie

      attr_accessor :values, :random

      def initialize(values, random)
        @values = values
        @random = random

        _restart
      end

      def _restart
        @value = nil
      end

      def _next_value
        if @value
          nil
        else
          @value = @values[@random.rand(0...@values.size)]
        end
      end

      def deterministic?
        false
      end
    end

    private_constant :RandomValueFromArrayBasicSerie

    class RandomNumberFromRangeBasicSerie
      include Serie

      attr_reader :from, :to, :step
      attr_accessor :random

      def initialize(from, to, step, random)
        @from = from
        @to = to
        @step = step

        adjust_step

        @random = random

        _restart
      end

      def from=(from)
        @from = from
        adjust_step
      end

      def to=(to)
        @to = to
        adjust_step
      end

      def step=(step)
        @step = step
        adjust_step
      end

      def _restart
        @value = nil
      end

      def _next_value
        if @value
          nil
        else
          @value = @from + @random.rand(0..@step_count) * @step
        end
      end

      def deterministic?
        false
      end

      private

      def adjust_step
        @step = (-@step if @from < @to && @step < 0 || @from > @to && @step > 0) || @step
        @step_count = ((@to - @from) / @step).to_i
      end
    end

    private_constant :RandomNumberFromRangeBasicSerie

    class RandomValuesFromArrayBasicSerie
      include Serie

      attr_accessor :values, :random

      def initialize(values, random)
        @values = values
        @random = random

        _restart
      end

      def _restart
        @available_values = @values.clone
      end

      def _next_value
        value = nil
        unless @available_values.empty?
          i = @random.rand(0...@available_values.size)
          value = @available_values[i]
          @available_values.delete_at i
        end
        value
      end

      def deterministic?
        false
      end
    end

    private_constant :RandomValuesFromArrayBasicSerie

    class RandomNumbersFromRangeBasicSerie
      include Serie

      attr_reader :from, :to, :step
      attr_accessor :random

      def initialize(from, to, step, random)
        @from = from
        @to = to
        @step = step

        adjust_step

        @random = random

        _restart
      end

      def from=(from)
        @from = from
        adjust_step
      end

      def to=(to)
        @to = to
        adjust_step
      end

      def step=(step)
        @step = step
        adjust_step
      end

      def _restart
        @available_steps = (0..@step_count).to_a
      end

      def _next_value
        value = nil
        unless @available_steps.empty?
          i = @random.rand(0...@available_steps.size)
          value = @from + @available_steps[i] * @step unless @value
          @available_steps.delete_at i
        end
        value
      end

      def deterministic?
        false
      end

      private

      def adjust_step
        @step = (-@step if @from < @to && @step < 0 || @from > @to && @step > 0) || @step
        @step_count = ((@to - @from) / @step).to_i
      end
    end

    private_constant :RandomNumbersFromRangeBasicSerie

    class BasicSerieFromHash
      include Serie

      attr_accessor :sources, :cycle

      def initialize(series_hash, cycle_all_series)
        @sources = series_hash
        @cycle = cycle_all_series

        _restart false
      end

      def _restart(restart_sources = true)
        @have_current = false
        @value = nil

        if restart_sources
          @sources.each do |_key, serie|
            serie.restart
          end
        end
      end

      def _soft_restart
        @sources.each do |_key, serie|
          serie.restart if serie.current_value.nil?
        end
      end

      def _next_value
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
    end

    private_constant :BasicSerieFromHash

    class BasicSerieFromArrayOfSeries
      include Serie

      attr_accessor :sources, :cycle

      def initialize(series_array, cycle_all_series)
        @sources = series_array
        @cycle = cycle_all_series

        _restart false
      end

      def _restart(restart_sources = true)
        @have_current = false
        @value = nil

        if restart_sources
          @sources.each do |serie|
            serie.restart if serie.current_value.nil?
          end
        end
      end

      def _soft_restart
        @sources.each do |serie|
          serie.restart if serie.current_value.nil?
        end
      end

      def _next_value
        unless @have_current && @value.nil?
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
    end

    private_constant :BasicSerieFromArrayOfSeries

    class BasicSerieFromSerieOfSeries
      include Serie

      attr_accessor :source

      def initialize(serie)
        @source = serie
        _restart false
      end

      def _restart(restart_sources = true)
        if restart_sources
          @source.restart
          @restart_each_serie = true
        end
        @current_serie = nil
      end

      def _next_value
        value = nil

        restart_current_serie_if_needed = false

        if @current_serie.nil?
          @current_serie = @source.next_value

          if @restart_each_serie
            @current_serie.restart if @current_serie
          else
            restart_current_serie_if_needed = true
          end
        end

        if @current_serie
          value = @current_serie.next_value

          if value.nil?
            if restart_current_serie_if_needed
              @current_serie.restart
            else
              @current_serie = nil
            end

            value = _next_value
          end
        end

        value
      end
    end

    private_constant :BasicSerieFromSerieOfSeries

    class SinFunctionSerie
      include Serie

      attr_reader :start, :steps, :amplitude, :center

      def initialize(start, steps, amplitude, center)
        @start = start.to_f

        @steps = steps
        @amplitude = amplitude.to_f
        @center = center.to_f

        @require_update = true

        _restart
      end

      def start=(start)
        @start = start.to_f
        @require_update = true
      end

      def steps=(steps)
        @steps = steps
        @require_update = true
      end

      def amplitude=(amplitude)
        @amplitude = amplitude.to_f
        @require_update = true
      end

      def center=(center)
        @center = center.to_f
        @require_update = true
      end

      def _next_value
        update if @require_update

        value = nil
        unless @position >= @steps
          value = Math.sin(@offset + @step_size * @position) * @amplitude + @center
          @position += 1
        end
        value
      end

      def _restart
        @position = 0
      end

      def to_s
        "offset: #{@offset.round(3)}rd amplitude: #{@amplitude.round(3)} center: #{@center.round(3)} length: #{@length} step_size: #{@step_size.round(6)}"
      end

      private

      def update
        @require_update = false

        y = (@start - @center) / @amplitude
        warn "WARNING: value for offset calc #{y} is outside asin range" if y < -1 || y > 1
        y = 1.0 if y > 1.0 # por los errores de precisión infinitesimal en el cálculo de y cuando es muy próximo a 1.0
        y = -1.0 if y < -1.0

        @offset = Math.asin(y)
        @step_size = 2.0 * Math::PI / @steps
      end
    end

    private_constant :SinFunctionSerie

    class FibonacciSerie
      include Serie

      def initialize
        _restart
      end

      def _restart
        @a = 0
        @b = 1
      end

      def _next_value
        initial_b = @b
        @b = @a + @b
        @a = initial_b

        @a
      end

      def infinite?
        true
      end
    end

    private_constant :FibonacciSerie

    class HarmonicNotesSerie
      include Serie

      attr_reader :error, :extended

      def initialize(error, extended)
        @error = error
        @extended = extended
        _restart
      end

      def error=(error)
        @error = error
        @needs_restart = true
      end

      def extended=(extended)
        @extended = extended
        @needs_restart = true
      end

      def _restart
        @harmonic = 0
        @needs_restart = false
      end

      def _next_value
        restart if @needs_restart

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

      def deterministic?
        true
      end
    end

    private_constant :HarmonicNotesSerie
  end
end
