module Musa
  module Series
    module SerieOperations
      def split
        Splitter.new(Splitter::BufferedProxy.new(self))
      end

      class Splitter
        def initialize(proxy)
          @proxy = proxy
          @series = {}
        end

        def [](key_or_index)
          if @series.has_key?(key_or_index)
            @series[key_or_index]
          else
            @series[key_or_index] = Split.new(@proxy, key_or_index)
          end
        end

        class BufferedProxy
          include SeriePrototyping

          def initialize(hash_or_array_serie)
            @source = hash_or_array_serie
            restart restart_source: false

            mark_regarding! @source
          end

          protected def _prototype!
            @source = @source.prototype
          end

          protected def _instance!
            @source = @source.instance
            restart
          end

          def restart(restart_source: true)
            @source.restart if restart_source
            @values = nil
          end

          def next_value(key_or_index)
            if @values.nil? || @values[key_or_index].nil? || @values[key_or_index].empty?
              hash_or_array_value = @source.next_value

              case hash_or_array_value
              when Hash
                @values ||= {}
                hash_or_array_value.each do |k, v|
                  @values[k] ||= []
                  @values[k] << v
                end
              when Array
                @values ||= []
                hash_or_array_value.each_index do |i|
                  @values[i] ||= []
                  @values[i] << hash_or_array_value[i]
                end
              end
            end

            if @values && !@values[key_or_index].nil?
              @values[key_or_index].shift
            else
              nil
            end
          end
        end

        class Split
          include Serie

          def initialize(proxy, key_or_index)
            @proxy = proxy
            @key_or_index = key_or_index

            mark_regarding! @proxy
          end

          def _prototype!
            @proxy = @proxy.prototype
          end

          def _instance!
            @proxy = @proxy.instance
          end

          def _restart
            @proxy.restart
          end

          def _next_value
            @proxy.next_value(@key_or_index)
          end
        end

        private_constant :Split
      end

      private_constant :Splitter
    end
  end
end
