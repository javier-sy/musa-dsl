# TODO reorganizar estructura de ficheros, modules y clases de Series y hash-serie-splitter.rb

# TODO añadir en for: steps: (nº de pasos en los que repartir el incremento)

require 'musa-dsl/mods/duplicate'
require 'musa-dsl/mods/arrayfy'

module Musa

	module ProtoSerie

		def restart
		end

		def next_value
			nil
		end

		def infinite?
			false
		end
	end

	module SerieOperations

		def repeat times = nil, &condition_block
			if times || condition_block
				Serie.new BasicSerieRepeater.new(self, times, &condition_block)
			else
				Serie.new BasicSerieInfiniteRepeater.new(self)
			end
		end

		def hashify *keys
			Serie.new BasicHashSerieFromArraySerie.new(self, keys)
		end

		def shift shift
			Serie.new BasicSerieShifter.new(self, shift)
		end

		def lock
			Serie.new BasicSerieLocker.new(self)
		end

		def reverse
			Serie.new BasicSerieReverser.new(self)
		end

		def randomize
			Serie.new BasicSerieRandomizer.new(self)
		end

		def eval with: nil, &block
			Serie.new BasicSerieFromEvalBlockOnSerie.new(self, with: with, &block)
		end

		def select *indexed_series, **hash_series
			Serie.new SelectorBasicSerie.new(self, indexed_series, hash_series)
		end

		def select_serie *indexed_series, **hash_series
			Serie.new SelectorFullSerieBasicSerie.new(self, indexed_series, hash_series)
		end

		def after *series
			Serie.new SequenceBasicSerie.new([self, *series])
		end

		def + serie
			Serie.new SequenceBasicSerie.new [self, serie]
		end

		def cut length
			Serie.new CutterSerie.new(self, length)
		end

		def merge
			Serie.new MergeSerieOfSeries.new(self)
		end

		def slave
			slave_serie = SlaveSerie.new self	
					
			@slaves ||= []
			@slaves << slave_serie

			return slave_serie
		end

		def duplicate
			Duplicate.duplicate(self)
		end

		def to_a
			throw 'Cannot convert to array an infinite serie' if @serie.infinite?

			@serie.restart

			array = []

			while value = @serie.next_value
				array << value
			end

			array
		end
	end

	class Serie
		include ProtoSerie
		include SerieOperations

		def initialize(basic_serie)
			@serie = basic_serie
		end

		def restart
			@have_peeked_next_value = false
			@peeked_next_value = nil
			@serie.restart
		end

		def next_value
			if @have_peeked_next_value
				@have_peeked_next_value = false
				value = @peeked_next_value
			else
				value = @serie.next_value
			end

			propagate_value value

			return value
		end

		def peek_next_value
			if @have_peeked_next_value
				@peeked_next_value
			else
				@have_peeked_next_value = true
				@peeked_next_value = @serie.next_value
			end
		end

		def infinite?
			@serie.infinite?
		end

		protected

		def propagate_value(value)
			@slaves.each {|s| s.push_next_value value } if @slaves
		end
	end

	class SlaveSerie < Serie
		def initialize(master)
			@master = master
			@next_value = []
		end

		def restart
			throw OperationNotAllowedError, "SlaveSerie #{self}: slave series cannot be restart"
		end

		def next_value
			value = @next_value.shift

			raise "Warning: slave serie #{self} has lost sync with his master serie #{@master}" if value.nil? && !@master.peek_next_value.nil?

			propagate_value value

			return value
		end

		def peek_next_value
			value = @next_value.first

			raise "Warning: slave serie #{self} has lost sync with his master serie #{@master}" if value.nil? && !@master.peek_next_value.nil?
			
			return value
		end

		def infinite?
			@master.infinite?
		end

		def push_next_value(value)
			@next_value << value
		end
	end

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
			Serie.new BasicSerieFromArrayOfArrays.new(series)
		end

		def SIN(start_value: 0.0, steps:, frequency: nil, period: nil, amplitude: 1, center: 0)
			Serie.new BasicSerieSinFunction.new start_value: start_value, steps: steps, period: period || Rational(1, frequency), amplitude: amplitude, center: center
		end
		
		###
		###
		###

		class NilBasicSerie
			include ProtoSerie
		end

		private_constant :NilBasicSerie

		class SequenceBasicSerie
			include ProtoSerie
		
			def initialize(series)
				@series = series
				@index = 0
			end

			def restart
				@index = 0
				@series[@index].restart
			end

			def next_value
				value = nil
				
				if @index < @series.size
					value = @series[@index].next_value

					if value.nil?
						@index += 1
						if @index < @series.size
							@series[@index].restart
							value = next_value
						end
					end
				end

				value
			end

			def infinite?
				!!@series.find { |serie| serie.infinite? }
			end
		end

		private_constant :SequenceBasicSerie

		class SelectorBasicSerie
			include ProtoSerie
		
			def initialize(selector, indexed_series, hash_series)
				@selector = selector

				if indexed_series && !indexed_series.empty?
					@series = indexed_series
				elsif hash_series && !hash_series.empty?
					@series = hash_series
				end
			end

			def restart
				@selector.restart
				@series.each { |serie| serie.restart } if @series.is_a? Array
				@series.each { |key, serie| serie.restart } if @series.is_a? Hash
			end

			def next_value
				value = nil

				index_or_key = @selector.next_value

				if !index_or_key.nil?
					value = @series[index_or_key].next_value
				end

				value
			end

			def infinite?
				!!( @selector.infinite? && !(@series.find { |serie| !serie.infinite? }) )
			end
		end

		private_constant :SelectorBasicSerie

		class SelectorFullSerieBasicSerie
			include ProtoSerie
		
			def initialize(selector, indexed_series, hash_series)
				@selector = selector

				if indexed_series && !indexed_series.empty?
					@series = indexed_series
				elsif hash_series && !hash_series.empty?
					@series = hash_series
				end
			end

			def restart
				@selector.restart
				@series.each { |serie| serie.restart }
			end

			def next_value
				value = nil

				if !@index_or_key.nil?
					value = @series[@index_or_key].next_value
				end

				if value.nil?
					@index_or_key = @selector.next_value

					value = next_value unless @index_or_key.nil?
				end

				value
			end

			def infinite?
				!!(@selector.infinite? || (@series.find { |serie| serie.infinite? }))
			end
		end

		private_constant :SelectorFullSerieBasicSerie

		class BasicSerieInfiniteRepeater
			include ProtoSerie

			def initialize(serie)
				@serie = serie
			end

			def restart
				@serie.restart
			end

			def next_value
				value = @serie.next_value
				
				if value.nil?
					@serie.restart
					value = @serie.next_value
				end

				value
			end

			def infinite?
				true
			end
		end	

		private_constant :BasicSerieInfiniteRepeater

		class BasicSerieRepeater
			include ProtoSerie

			def initialize(serie, times = nil, &condition_block)
				@serie = serie
				
				@condition_block = condition_block
				@condition_block ||= ->() { @count < times } if times

				raise ArgumentError, "times or condition block are mandatory" unless @condition_block

				@count = 0
			end

			def restart
				@serie.restart
				@count = 0
			end

			def next_value
				value = @serie.next_value

				if value.nil?
					@count += 1

					if @condition_block.call
						@serie.restart
						value = @serie.next_value
					end
				end

				value
			end
		end	

		private_constant :BasicSerieRepeater

		class CutterSerie
			include ProtoSerie

			def initialize(serie, length)
				@serie = serie
				@length = length

				restart
			end

			def restart
				@serie.restart
			end

			def next_value
				@previous.materialize if @previous
				
				if @serie.peek_next_value
					Serie.new @previous = CutSerie.new(@serie, @length)
				else
					nil
				end
			end

			private

			class CutSerie
				include ProtoSerie

				def initialize(serie, length)
					@serie = serie
					@length = length

					@values = []
					restart
				end

				def restart
					@count = 0
				end

				def next_value
					value ||= @values[@count]
					value ||= @values[@count] = @serie.next_value if @count < @length

					@count += 1

					value
				end

				def materialize
					(@values.size..@length - 1).each { |i| @values[i] = @serie.next_value }
				end
			end
		end

		private_constant :CutterSerie

		class MergeSerieOfSeries
			include ProtoSerie

			def initialize(serie)
				@serie = serie

				restart
			end

			def restart
				@serie.restart
				@current = nil
			end

			def next_value
				value = nil

				@current = @serie.next_value unless @current
				
				if @current
					value = @current.next_value

					if value.nil?
						@current = nil
						value = next_value
					end
				else
					value = nil
				end

				value
			end
		end

		private_constant :MergeSerieOfSeries

		class ForLoopBasicSerie
			def initialize(from:, to:, step:)
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

		class RandomNumberBasicSerie
			def initialize(from: nil, to: nil, step: nil)
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

		class RandomFromArrayBasicSerie
			def initialize(values)
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

		class BasicSerieLocker
			def initialize(serie)
				@serie = serie
				@values = []

				@first_round = true

				restart
			end

			def restart
				@index = 0
			end

			def next_value
				if @first_round
					value = @serie.next_value

					if value.nil?
						@first_round = false
					end
				else
					if @index < @values.size
						value = @values[@index]
						@index += 1
					else
						value = nil
					end
				end

				value
			end
		end

		private_constant :BasicSerieLocker

		class BasicSerieReverser
			include ProtoSerie

			def initialize(serie)
				raise ArgumentError, "cannot reverse an infinite serie #{serie}" if serie.infinite?
				@serie = serie
				restart
			end

			def restart
				@serie.restart
				@reversed = BasicSerieFromArray.new next_values_array_of(@serie).reverse
			end

			def next_value
				@reversed.next_value
			end

			private

			def next_values_array_of(serie)
				array = []

				while !(value = serie.next_value).nil? do
					array << value
				end

				array
			end
		end

		private_constant :BasicSerieReverser

		class BasicSerieRandomizer
			include ProtoSerie

			def initialize(serie)
				raise ArgumentError, "cannot randomize an infinite serie #{serie}" if serie.infinite?
				@serie = serie
				@random = Random.new
				restart
			end

			def restart
				@serie.restart
				@values = @serie.to_a
			end

			def next_value
				if @values.size > 0
					position = @random.rand(0...@values.size)
					value = @values[position]
					
					@values.delete_at position
				else
					value = nil
				end

				return value
			end
		end

		private_constant :BasicSerieRandomizer

		class BasicSerieShifter
			include ProtoSerie

			def initialize(serie, shift)
				raise ArgumentError, "cannot shift to right an infinite serie #{serie}" if shift > 0 && serie.infinite?
				raise ArgumentError, "cannot shift to right: function not yet implemented" if shift > 0

				@serie = serie
				@shift = shift
				restart
			end

			def restart
				@serie.restart

				@shifted = []
				@shift.abs.times { || @shifted << @serie.next_value } if @shift < 0
			end

			def next_value
				value = @serie.next_value
				return value unless value.nil?
				@shifted.shift
			end
		end

		private_constant :BasicSerieShifter

		class BasicSerieFromArray
			include ProtoSerie

			def initialize(array)
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

			def initialize(start, &block)
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

		class BasicSerieFromEvalBlockOnSerie
			include ProtoSerie

			def initialize(serie, with: nil, &block)
				
				if serie.is_a? Array
					@serie = BasicSerieFromArray.new serie
				elsif serie.is_a? Serie
					@serie = serie
				else
					raise ArgumentError, "serie is not an Array nor a Serie: #{serie}"
				end

				if with
					if with.is_a? Array
						@with_serie = BasicSerieFromArray.new with
					elsif with.is_a? Serie
						@with_serie = with
					else
						raise ArgumentError, "with_serie is not an Array nor a Serie: #{with_serie}"
					end
				end

				@block = block
			end

			def restart
				@serie.restart
				@with_serie.restart if @with_serie
			end

			def next_value
				next_value = @serie.next_value

				if @block && !next_value.nil?
					next_with = @with_serie.next_value if @with_serie

					if next_with
						@block.call next_value, next_with
					else
						@block.call next_value
					end
				else
					next_value
				end
			end
		end

		private_constant :BasicSerieFromEvalBlockOnSerie

		class BasicSerieFromEvalBlock
			include ProtoSerie

			def initialize(&block)
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

		class BasicSerieFromHash
			include ProtoSerie

			def initialize(series)
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

		class BasicHashSerieFromArraySerie
			include ProtoSerie

			def initialize(serie, keys)
				@serie = serie
				@keys = keys
			end

			def restart
				@serie.restart
			end

			def next_value
				array = @serie.next_value

				return nil unless array

				value = array.length.times.collect { |i| [ @keys[i], array[i] ] }.to_h

				if value.find { |key, value| value.nil? }
					nil
				else
					value
				end
			end
		end

		private_constant :BasicHashSerieFromArraySerie

		class BasicSerieFromArrayOfSeries
			include ProtoSerie

			def initialize(series)
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

			def initialize(start_value:, steps:, period:, amplitude:, center:)

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