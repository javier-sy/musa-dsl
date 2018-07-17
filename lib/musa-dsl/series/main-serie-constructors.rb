require 'musa-dsl/mods/arrayfy'

# TODO añadir en for: steps: (nº de pasos en los que repartir el incremento)

module Musa
	module Series

		def NIL
			Serie.new NilBasicSerie.new
		end

		def S(*values)
			Serie.new BasicSerieFromArray.new(values.explode_ranges)
		end

		def H(**series_hash)
			Serie.new BasicSerieFromHash.new(series_hash, false)
		end

		def HC(**series_hash)
			Serie.new BasicSerieFromHash.new(series_hash, true)
		end

		def A(*series)
			Serie.new BasicSerieFromArrayOfSeries.new(series, false)
		end

		def AC(*series)
			Serie.new BasicSerieFromArrayOfSeries.new(series, true)
		end

		def E(**args, &block)
			if args.has_key?(:start) && args.length == 1
				Serie.new BasicSerieFromAutoEvalBlockOnSeed.new(args[:start], &block)
			elsif args.length == 0
				Serie.new BasicSerieFromEvalBlock.new(&block)
			else
				raise ArgumentError, 'only optional start: argument is allowed'
			end
		end

		def FOR(from: nil, to:, step: nil)
			from ||= 0
			step ||= 1
			Serie.new ForLoopBasicSerie.new(from, to, step)
		end

		def RND(*values, from: nil, to: nil, step: nil, random: nil)
			random = Random.new random if random.is_a?(Integer)
			random ||= Random.new

			if !values.empty? && from.nil? && to.nil? && step.nil?
				Serie.new RandomValuesFromArrayBasicSerie.new(values.explode_ranges, random)
			elsif values.empty? && !to.nil?
				from ||= 0
				step ||= 1
				Serie.new RandomNumbersFromRangeBasicSerie.new(from, to, step, random)
			else
				raise ArgumentError, "cannot use values and from:/to:/step: together"
			end
		end

		def RND1(*values, from: nil, to: nil, step: nil, random: nil)
			random = Random.new random if random.is_a?(Integer)
			random ||= Random.new

			if !values.empty? && from.nil? && to.nil? && step.nil?
				Serie.new RandomValueFromArrayBasicSerie.new(values.explode_ranges, random)
			elsif values.empty? && !to.nil?
				from ||= 0
				step ||= 1
				Serie.new RandomNumberFromRangeBasicSerie.new(from, to, step, random)
			else
				raise ArgumentError, "cannot use values and from:/to:/step: parameters together"
			end
		end

		def SIN(start_value: nil, steps:, amplitude: nil, center: nil)
			start_value ||= 0.0
			amplitude ||= 1
			center ||= 0
			Serie.new BasicSerieSinFunction.new start_value, steps, amplitude, center
		end

		###
		### Implementation
		###

		class NilBasicSerie
			include ProtoSerie
		end

		private_constant :NilBasicSerie

		class BasicSerieFromArray
			include ProtoSerie

			def initialize array
				@array = array.clone
				@index = 0
			end

			def restart
				@index = 0

				self
			end

			def next_value
				if @index < @array.size
					value = @array[@index]
					@index += 1
				else
					value = nil
				end

				value
			end
		end

		private_constant :BasicSerieFromArray

		class BasicSerieFromAutoEvalBlockOnSeed
			include ProtoSerie

			def initialize start, &block
				@start = start
				@block = block

				@current = nil
				@first = true
			end

			def restart
				@current = nil
				@first = true

				self
			end

			def next_value
				if @first
					@first = false
					@current = @start
				else
					@current = @block.call @current unless @current.nil?
				end

				@current
			end
		end

		private_constant :BasicSerieFromAutoEvalBlockOnSeed

		class BasicSerieFromEvalBlock
			include ProtoSerie

			def initialize &block
				@block = block
				restart
			end

			def restart
				@index = 0

				self
			end

			def next_value
				if @have_peeked_next_value
					@have_peeked_next_value = false
					value = @peek_next_value
				else
					@value = @block.call @index unless @value.nil? && @index > 0
					value = @value
					@index += 1
				end

				value
			end
		end

		private_constant :BasicSerieFromEvalBlock

		class ForLoopBasicSerie
			include ProtoSerie

			def initialize from, to, step
				@from = from
				@to = to
				@step = step

				restart
			end

			def restart
				@value = @from
				self
			end

			def next_value
				if @value
					value = @value
					@value = @value + @step
				end

				@value = nil if @value && (@value > @to && @step.positive? || @value < @to && @step.negative?)

				value
			end
		end

		private_constant :ForLoopBasicSerie

		class RandomValueFromArrayBasicSerie
			include ProtoSerie

			def initialize values, random
				@values = values
				@random = random

				restart
			end

			def restart
				@value = nil
				self
			end

			def next_value
				@value = @values[@random.rand(0...@values.size)] unless @value
			end
		end

		private_constant :RandomValueFromArrayBasicSerie

		class RandomNumberFromRangeBasicSerie
			include ProtoSerie

			def initialize from, to, step, random
				@from = from
				@to = to
				@step = step

				@random = random

				@step_count = ((@to - @from) / @step).to_i

				restart
			end

			def restart
				@value = nil
				self
			end

			def next_value
				@value = @from + @random.rand(0..@step_count) * @step unless @value
			end
		end

		private_constant :RandomNumberFromRangeBasicSerie

		class RandomValuesFromArrayBasicSerie
			include ProtoSerie

			def initialize values, random
				@values = values
				@random = random

				restart
			end

			def restart
				@available_values = @values.clone
				self
			end

			def next_value
				value = nil
				unless @available_values.empty?
					i = @random.rand(0...@available_values.size)
					value = @available_values[i]
					@available_values.delete_at i
				end
				value
			end
		end

		private_constant :RandomValuesFromArrayBasicSerie

		class RandomNumbersFromRangeBasicSerie
			include ProtoSerie

			def initialize from, to, step, random
				@from = from
				@to = to
				@step = step

				@random = random

				@step_count = ((@to - @from) / @step).to_i

				restart
			end

			def restart
				@available_steps = (0..@step_count).to_a
				self
			end

			def next_value
				value = nil
				unless @available_steps.empty?
					i = @random.rand(0...@available_steps.size)
					value = @from + @available_steps[i] * @step unless @value
					@available_steps.delete_at i
				end
				value
			end
		end

		private_constant :RandomNumbersFromRangeBasicSerie

		class BasicSerieFromHash
			include ProtoSerie

			def initialize series, cycle_all_series
				@series = series
				@cycle_all_series = cycle_all_series
				@have_current = false
				@value = nil
			end

			def restart
				@have_current = false
				@value = nil

				@series.each do |key, serie|
					serie.restart if serie.current_value.nil?
				end

				self
			end

			def next_value
				unless @have_current && @value.nil?
					pre_value = @series.collect { |key, serie| [ key, serie.peek_next_value ] }.to_h

					nils = 0
					pre_value.each do |key, value|
						if value.nil?
							@series[key].next_value
							nils += 1
						end
					end

					if nils == 0
						@value = @series.collect { |key, serie| [ key, serie.next_value ] }.to_h
					elsif nils < @series.size && @cycle_all_series
						restart
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
			include ProtoSerie

			def initialize series, cycle_all_series
				@series = series
				@cycle_all_series = cycle_all_series
				@have_current = false
				@value = nil
			end

			def restart
				@have_current = false
				@value = nil

				@series.each do |serie|
					serie.restart if serie.current_value.nil?
				end

				self
			end

			def next_value
				unless @have_current && @value.nil?
					pre_value = @series.collect { |serie| serie.peek_next_value }

					nils = 0
					pre_value.each_index do |i|
						if pre_value[i].nil?
							@series[i].next_value
							nils += 1
						end
					end

					if nils == 0
						@value = @series.collect { |serie| serie.next_value }
					elsif nils < @series.size && @cycle_all_series
						restart
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

		class BasicSerieSinFunction
			include ProtoSerie

			def initialize start_value, steps, amplitude, center

				start_value = start_value.to_f

				@steps = steps
				@amplitude = amplitude.to_f
				@center = center.to_f

				y = (start_value - @center) / @amplitude
				warn "WARNING: value for offset calc #{y} is outside asin range" if y < -1 || y > 1
				y = 1.0 if y > 1.0 # por los errores de precisión infinitesimal en el cálculo de y cuando es muy próximo a 1.0
				y = -1.0 if y < -1.0

				@offset = Math::asin(y)

				@step_size = 2.0 * Math::PI / @steps

				restart
			end

			def next_value
				value = nil
				unless @position == @steps
					value = Math::sin(@offset + @step_size * @position) * @amplitude + @center
					@position += 1
				end
				value
			end

			def restart
				@position = 0

				self
			end

			def to_s
				"offset: #{@offset.round(3)}rd amplitude: #{@amplitude.round(3)} center: #{@center.round(3)} length: #{@length} step_size: #{@step_size.round(6)}"
			end
		end

		private_constant :BasicSerieSinFunction
	end
end
