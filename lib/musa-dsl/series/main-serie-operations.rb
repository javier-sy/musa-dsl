module Musa

	module SerieOperations

		def repeat times = nil, condition: nil, &condition_block
			condition ||= condition_block

			if times || condition
				Serie.new BasicSerieRepeater.new(self, times, &condition)
			else
				Serie.new BasicSerieInfiniteRepeater.new(self)
			end
		end

		def autorestart
			Serie.new BasicSerieAutorestart.new(self)
		end

		def hashify *keys
			Serie.new BasicHashSerieFromArraySerie.new(self, keys)
		end

		def shift shift
			Serie.new BasicSerieShifter.new(self, shift)
		end

		def remove positions
			Serie.new BasicSerieRemover.new(self, positions)
		end

		def lock
			Serie.new BasicSerieLocker.new(self)
		end

		def reverse
			Serie.new BasicSerieReverser.new(self)
		end

		def randomize duplicate: nil
			Serie.new BasicSerieRandomizer.new(self)
		end

		def eval block = nil, with: nil, on_restart: nil, &yield_block
			block ||= yield_block
			Serie.new BasicSerieFromEvalBlockOnSerie.new(self, with: with, on_restart: on_restart, &block)
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
			Serie.new SequenceBasicSerie.new([self.duplicate, serie.duplicate])
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

		def to_a(recursive = nil)

			def copy_included_modules source, target
				target.tap do
					source.singleton_class.included_modules.each do |m|
						target.extend m unless target.is_a? m
					end
				end
			end

			def process value
				case value
				when Serie
					value.to_a(true)
				when Array
					a = value.collect { |v| v.is_a?(Serie) ? v.to_a(true) : process(v) }
					copy_included_modules value, a
				when Hash
					h = value.collect { |k, v| [ process(k), v.is_a?(Serie) ? v.to_a(true) : process(v) ] }.to_h
					copy_included_modules value, h
				else
					value
				end
			end

			recursive ||= false

			throw 'Cannot convert to array an infinite serie' if @serie.infinite?

			serie = @serie.duplicate.restart

			array = []

			while value = serie.next_value
				if recursive
					array << process(value)
				else
					array << value
				end
			end

			array
		end

		###
		### Implementation
		###

		class SequenceBasicSerie
			include ProtoSerie

			def initialize(series)
				@series = series
				@index = 0
			end

			def restart
				@index = 0
				@series[@index].restart

				self
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

				self
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

				self
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

				self
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

				@count = 0

				@condition_block = condition_block
				@condition_block ||= proc { @count < times } if times

				raise ArgumentError, "times or condition block are mandatory" unless @condition_block
			end

			def restart
				@serie.restart
				@count = 0

				self
			end

			def next_value
				value = @serie.next_value

				if value.nil?
					@count += 1

					if self.instance_eval &@condition_block
						@serie.restart
						value = @serie.next_value
					end
				end

				value
			end
		end

		private_constant :BasicSerieRepeater

		class BasicSerieAutorestart
			include ProtoSerie

			def initialize(serie)
				@serie = serie
				@restart_on_next = false
			end

			def restart
				@serie.restart

				self
			end

			def next_value
				if @restart_on_next
					@serie.restart
					@restart_on_next = false
				end

				value = @serie.next_value

				if value.nil?
					@restart_on_next = true
				end

				value
			end
		end

		private_constant :BasicSerieAutorestart

		class CutterSerie
			include ProtoSerie

			def initialize(serie, length)
				@serie = serie
				@length = length

				restart
			end

			def restart
				@serie.restart

				self
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

					self
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

				self
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

		class BasicSerieLocker
			include ProtoSerie

			def initialize(serie)
				@serie = serie
				@values = []

				@first_round = true

				restart
			end

			def restart
				@index = 0

				self
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

				self
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
				restart
			end

			def restart
				@serie.restart
				@values = @serie.to_a

				@random = Random.new

				self
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

				self
			end

			def next_value
				value = @serie.next_value
				return value unless value.nil?
				@shifted.shift
			end
		end

		private_constant :BasicSerieShifter

		class BasicSerieRemover
			include ProtoSerie

			def initialize(serie, remove)
				@serie = serie
				@remove = remove
				restart
			end

			def restart
				@serie.restart

				@remove.times { @serie.next_value }

				self
			end

			def next_value
				@serie.next_value
			end
		end

		private_constant :BasicSerieShifter

		class BasicSerieFromEvalBlockOnSerie
			include ProtoSerie

			def initialize(serie, with: nil, on_restart: nil, &block)

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
				@on_restart = on_restart
			end

			def restart
				@serie.restart
				@with_serie.restart if @with_serie

				@on_restart.call if @on_restart

				self
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

		class BasicHashSerieFromArraySerie
			include ProtoSerie

			def initialize(serie, keys)
				@serie = serie
				@keys = keys
			end

			def restart
				@serie.restart

				self
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
	end
end
