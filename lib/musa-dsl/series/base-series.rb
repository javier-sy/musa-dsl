require 'forwardable'

module Musa

	module ProtoSerie
		def restart
			self
		end

		def next_value
			nil
		end

		def infinite?
			false
		end
	end

	module SerieOperations
	end

	class Serie
		include ProtoSerie
		include SerieOperations

		def initialize basic_serie
			@serie = basic_serie
		end

		def restart
			@have_peeked_next_value = false
			@peeked_next_value = nil
			@have_current_value = false
			@current_value = nil

			@serie.restart

			self
		end

		def next_value
			unless @have_current_value && @current_value.nil?
				if @have_peeked_next_value
					@have_peeked_next_value = false
					@current_value = @peeked_next_value
				else
					@current_value = @serie.next_value
				end
			end

			propagate_value @current_value

			@current_value
		end

		def peek_next_value
			unless @have_peeked_next_value
				@have_peeked_next_value = true
				@peeked_next_value = @serie.next_value
			end
			@peeked_next_value
		end

		def current_value
			@current_value
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
end
