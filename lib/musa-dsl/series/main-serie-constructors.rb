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

		def E(start: nil, with: nil, &block)
			if start
				Serie.new BasicSerieFromAutoEvalBlockOnSeed.new(start: start, &block)
			else
				Serie.new BasicSerieFromEvalBlock.new(&block)
			end
		end

		def FOR(from: 0, to:, step: 1)
			Serie.new ForLoopBasicSerie.new(from: from, to: to, step: step)
		end

		def RND(*values, from: nil, to: nil, step: nil)
			if !values.empty? && from.nil? && to.nil? && step.nil?
				Serie.new RandomFromArrayBasicSerie.new(values.explode_ranges)
			elsif values.empty?
				Serie.new RandomNumberBasicSerie.new(from: from, to: to, step: step)
			else
				raise ArgumentError, "cannot use values and from:/to:/step: simultaneously"
			end
		end

		def H(**series_hash)
			Serie.new BasicSerieFromHash.new(series_hash)
		end

		def A(*series)
			Serie.new BasicSerieFromArrayOfSeries.new(series)
		end

		def SIN(start_value: 0.0, steps:, frequency: nil, period: nil, amplitude: 1, center: 0)
			Serie.new BasicSerieSinFunction.new start_value: start_value, steps: steps, period: period || Rational(1, frequency), amplitude: amplitude, center: center
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
				@value = start
				@block = block

				@current = nil
				@first = true
			end

			def restart
				@current = nil
			end

			def next_value
				if @first
					@first = false
					@current = @value
				else
					@current = @block.call @current
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
			end

			def next_value
				if @have_peeked_next_value
					@have_peeked_next_value = false
					value = @peek_next_value
				else
					value = @block.call @index
					@index += 1
				end

				value
			end
		end

		private_constant :BasicSerieFromEvalBlock

		class ForLoopBasicSerie
			def initialize from:, to:, step:
				@from = from
				@to = to
				@step = step

				restart
			end

			def restart
				@value = @from 
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

		class RandomFromArrayBasicSerie
			def initialize values
				@values = values
				@random = Random.new

				restart
			end

			def restart
				@value = @values[@random.rand(0...@values.size)]
			end

			def next_value
				v = @value
				@value = nil
				return v
			end
		end

		private_constant :RandomFromArrayBasicSerie

		class RandomNumberBasicSerie
			def initialize from: nil, to: nil, step: nil
				from ||= 0
				step ||= 1

				@from = from
				@to = to
				@step = step

				@range = ((@to - @from) / @step).ceil

				@random = Random.new

				restart
			end

			def restart
				while !@value || @value > @to
					@value = @from + @random.rand(0..@range) * @step
				end
			end

			def next_value
				v = @value
				@value = nil
				return v
			end
		end

		private_constant :RandomNumberBasicSerie

		class BasicSerieFromHash
			include ProtoSerie

			def initialize series
				@series = series
			end

			def restart
				@series.each_value do |serie|
					serie.restart
				end
			end

			def next_value
				value = @series.collect { |key, serie| puts "key #{key} has no serie" if serie.nil? ; [ key, serie.next_value ] }.to_h

				if value.find { |key, value| value.nil? }
					nil
				else
					value
				end
			end
		end

		private_constant :BasicSerieFromHash

		class BasicSerieFromArrayOfSeries
			include ProtoSerie

			def initialize series
				@series = series
			end

			def restart
				@series.each do |serie|
					serie.restart
				end
			end

			def next_value
				value = @series.collect { |serie| serie.next_value }

				if value.find { |value| value.nil? }
					nil
				else
					value
				end
			end
		end

		private_constant :BasicSerieFromArrayOfSeries

		class BasicSerieSinFunction
			include ProtoSerie

			def initialize start_value:, steps:, period:, amplitude:, center:

				start_value = start_value.to_f unless start_value.is_a? Float

				@length = (steps * period).to_f if period

				@amplitude = amplitude.to_f
				@center = center.to_f

				y = (start_value - @center) / @amplitude
				puts "WARNING: value for offset calc #{y} is outside asin range" if y < -1 || y > 1
				y = 1.0 if y > 1.0 # por los errores de precisión infinitesimal en el cálculo de y cuando es muy próximo a 1.0
				y = -1.0 if y < -1.0

				@offset = Math::asin(y)

				@step_size = 2.0 * Math::PI / @length

				restart
			end

			def next_value
				v = Math::sin(@offset + @step_size * @position) * @amplitude + @center
				@position += 1
				v
			end

			def restart
				@position = 0
			end

			def infinite?
				true
			end

			def to_s
				"offset: #{@offset.round(3)}rd amplitude: #{@amplitude.round(3)} center: #{@center.round(3)} length: #{@length} step_size: #{@step_size.round(6)}"
			end
		end

		private_constant :BasicSerieSinFunction	
	end
end