module Musa
  # TODO: full test cases

  module SerieOperations
    def split(buffered: nil, master: nil)
      buffered ||= false

      return HashSplitter.new HashSplitter::KeyProxy.new(self) if master.nil? && !buffered
      return HashSplitter.new HashSplitter::MasterSlaveKeyProxy.new(self, master) if !master.nil? && !buffered
      return HashSplitter.new HashSplitter::BufferedKeyProxy.new(self) if buffered
    end

    class HashSplitter
      def initialize(proxy)
        @proxy = proxy
        @series = {}
      end

      def [](key)
        serie = if @series.key? key
                  @series[key]
                else
                  @series[key] = Splitted.new(@proxy, key: key)
                end
      end

      class KeyProxy
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
            before_values = @values.collect { |k, v| [k, v] unless v.nil? }.compact.to_h

            @values = @serie.next_value
            value = @values[key] if @values

            warn "Warning: splitted serie #{@serie} values #{before_values} are being lost" if !value.nil? && !before_values.empty?
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

      class BufferedKeyProxy
        def initialize(hash_serie)
          @serie = hash_serie
          @values = {}
        end

        def restart
          @serie.restart
          @values = {}
        end

        def next_value(key)
          value = nil

          if @values[key].nil? || @values[key].empty?
            hash_value = @serie.next_value

            if hash_value
              hash_value.each do |k, v|
                @values[k] = [] if @values[k].nil?
                @values[k] << v
              end
            end
          end

          value = @values[key].shift if @values[key]

          value
        end

        def peek_next_value(key)
          value = nil

          if @values[key] && !@values[key].empty?
            value = @values[key].first
          else
            peek_values = @serie.peek_next_value
            value = peek_values[key] if peek_values
          end

          value
        end
      end

      class MasterSlaveKeyProxy
        def initialize(hash_serie, master)
          @serie = hash_serie
          @master = master
          @values = {}
          @values_counter = {}
        end

        def restart
          @serie.restart
          @values = {}
          @values_counter = {}
        end

        def next_value(key)
          return nil unless @values

          value = @values[key]

          if value.nil?
            @values = @serie.next_value

            value = @values[key] if @values

            # warn "Info: splitted serie #{@serie} use count on next_value: #{@values_counter}"
            @values_counter = {}
          end

          @values_counter[key] ||= 0
          @values_counter[key] += 1

          @values[key] = nil if key == @master && @values

          value
        end

        def peek_next_value(key)
          return nil unless @values

          value = @values[key]

          if value.nil?
            peek_values = @serie.peek_next_value
            value = peek_values[key] if peek_values
          end

          value
        end
      end

      class Splitted
        include Serie

        def initialize(proxy, key:)
          @proxy = proxy
          @key = key
        end

        def _restart
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

    private_constant :HashSplitter
  end
end
