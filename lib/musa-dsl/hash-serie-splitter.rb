module Musa
	class HashSerieSplitter
		def initialize(hash_serie)
			@proxy = HashSerieKeyProxy.new hash_serie
			@series = {}
		end

		def [](key)
			if @series.has_key? key
				serie = @series[key]
			else
				serie = @series[key] = Serie.new HashSplittedSerie.new(@proxy, key: key)
			end
		end

		private

		class HashSerieKeyProxy
			def initialize(hash_serie)
				@serie = hash_serie
				@values = {}
			end

			def restart
				@serie.restart
				@values = {}
			end

			def next_value(key)

				return nil unless @values

				value = @values[key]

				if value.nil?
					@values = @serie.next_value
					value = @values[key] if @values				
				end
				
				@values[key] = nil if @values

				value
			end

			def peek_next_value(key)
				value = @values[key]

				if value.nil?
					peek_values = @serie.peek_next_value
					value = peek_values[key] if peek_values				
				end

				value
			end
		end

		class HashSplittedSerie
			include BasicSerie

			def initialize(proxy, key:)
				@proxy = proxy
				@key = key
			end

			def restart
				@proxy.restart
			end

			def next_value
				@proxy.next_value(@key)
			end

			def peek_next_value
				@proxy.peek_next_value(@key)
			end
		end
	end
end


